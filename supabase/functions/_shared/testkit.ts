// Test-only kit: an in-memory Store, fake services, and a signer that talks to a real handler
// exactly as a phone would. Never imported by a function.
import type { DeviceRecord } from "./auth.ts";
import { b64urlEncode, type Bytes, sha256B64url } from "./b64.ts";
import { canonicalString } from "./canonical.ts";
import type { Services } from "./handler.ts";
import { compareSemver } from "./semver.ts";
import type {
  AlertIn,
  AlertOut,
  CachedLine,
  CacheKey,
  ChildProfile,
  DeviceSummary,
  EventIn,
  EventOut,
  PublishedPack,
  RevokeReason,
  Store,
  TakeResult,
  TutorContext,
  TutorLogEntry,
  TutorLogRow,
} from "./store.ts";
import { rawToDer, utf8 } from "./testutil.ts";

export const NOW = 1_800_000_000_000;

/** The publish secret of the fake services (long enough to be accepted). */
export const PUBLISH_SECRET = ["fake", "value", "for", "tests", "only", "abcdefghijklmnop"].join("-");

export interface StoredDevice extends DeviceRecord {
  platform: "android" | "ios";
  securityLevel: string;
  createdAt: Date;
  lastSeenAt: Date | null;
}

export class FakeStore implements Store {
  devices = new Map<string, StoredDevice>();
  guardians = new Set<string>();
  nonces = new Set<string>();
  config = new Map<string, unknown>();
  counters = new Map<string, number>();
  challenges: Array<Parameters<Store["insertChallenge"]>[0]> = [];
  codes: Array<Parameters<Store["insertPairingCode"]>[0]> = [];
  touched: string[] = [];

  getDevice(id: string) {
    return Promise.resolve(this.devices.get(id) ?? null);
  }
  isGuardian(userId: string, familyId: string) {
    return Promise.resolve(this.guardians.has(`${userId}/${familyId}`));
  }
  recordNonce(deviceId: string, nonce: string) {
    const k = `${deviceId}/${nonce}`;
    if (this.nonces.has(k)) return Promise.resolve(false);
    this.nonces.add(k);
    return Promise.resolve(true);
  }
  touchDevice(id: string) {
    this.touched.push(id);
    return Promise.resolve();
  }
  getConfig(key: string) {
    return Promise.resolve(this.config.get(key));
  }
  getConfigs(keys: readonly string[]) {
    return Promise.resolve(
      Object.fromEntries(keys.filter((k) => this.config.has(k)).map((k) => [k, this.config.get(k)])),
    );
  }
  rateLimitHit(scope: string, key: string, windowStart: Date, limit: number) {
    const k = `${scope}/${key}/${windowStart.getTime()}`;
    const n = this.counters.get(k) ?? 0;
    if (n >= limit) return Promise.resolve(false);
    this.counters.set(k, n + 1);
    return Promise.resolve(true);
  }
  insertChallenge(c: Parameters<Store["insertChallenge"]>[0]) {
    this.challenges.push(c);
    return Promise.resolve();
  }
  insertPairingCode(c: Parameters<Store["insertPairingCode"]>[0]) {
    const h = b64urlEncode(c.codeHash);
    if (this.codes.some((x) => b64urlEncode(x.codeHash) === h)) return Promise.resolve(false);
    this.codes.push(c);
    return Promise.resolve(true);
  }
  usedChallenges = new Set<string>();
  allowlist = new Set<string>();
  families = new Map<string, string>(); // user -> family
  consumeChallenge(c: { challenge: Bytes; purpose: "enroll" | "pair"; userId: string | null }) {
    const known = this.challenges.find((x) =>
      b64urlEncode(x.challenge) === b64urlEncode(c.challenge) && x.purpose === c.purpose &&
      x.userId === c.userId
    );
    const key = b64urlEncode(c.challenge);
    if (!known || this.usedChallenges.has(key) || known.expiresAt.getTime() <= this.nowMs) {
      return Promise.resolve(false);
    }
    this.usedChallenges.add(key);
    return Promise.resolve(true);
  }
  nowMs = NOW;
  devAllowlistHas(secretHash: Bytes) {
    return Promise.resolve(this.allowlist.has(b64urlEncode(secretHash)));
  }
  enrolParentDevice(e: Parameters<Store["enrolParentDevice"]>[0]) {
    let family = this.families.get(e.userId);
    if (!family) {
      family = crypto.randomUUID();
      this.families.set(e.userId, family);
      this.guardians.add(`${e.userId}/${family}`);
    }
    if (e.replaceDeviceId) {
      const old = this.devices.get(e.replaceDeviceId);
      if (!old || old.familyId !== family || old.revokedAt) {
        return Promise.resolve({ ok: false as const, reason: "no_such_device" as const });
      }
      old.revokedAt = new Date(this.nowMs);
    }
    const pk = b64urlEncode(e.publicKey);
    if ([...this.devices.values()].some((d) => b64urlEncode(d.publicKey) === pk)) {
      return Promise.resolve({ ok: false as const, reason: "key_in_use" as const });
    }
    if ([...this.devices.values()].filter((d) => d.familyId === family && !d.revokedAt).length >= 6) {
      return Promise.resolve({ ok: false as const, reason: "device_limit" as const });
    }
    const id = crypto.randomUUID();
    this.devices.set(id, {
      id,
      familyId: family,
      role: "parent",
      publicKey: e.publicKey,
      revokedAt: null,
      platform: e.platform,
      securityLevel: e.securityLevel,
      createdAt: new Date(this.nowMs),
      lastSeenAt: null,
    });
    return Promise.resolve({ ok: true as const, deviceId: id, familyId: family });
  }
  failedAttempts = new Map<string, number>();
  usedCodes = new Set<string>();
  pairPeek(c: { challenge: Bytes; codeHash: Bytes }) {
    const ck = b64urlEncode(c.challenge);
    const ch = this.challenges.find((x) => b64urlEncode(x.challenge) === ck && x.purpose === "pair");
    if (
      !ch || this.usedChallenges.has(ck) || ch.expiresAt.getTime() <= this.nowMs ||
      (this.failedAttempts.get(ck) ?? 0) >= 5
    ) {
      return Promise.resolve({ ok: false as const, reason: "challenge_invalid" as const });
    }
    const hk = b64urlEncode(c.codeHash);
    const code = this.codes.find((x) =>
      b64urlEncode(x.codeHash) === hk && !this.usedCodes.has(hk) && x.expiresAt.getTime() > this.nowMs
    );
    if (!code) {
      this.failedAttempts.set(ck, (this.failedAttempts.get(ck) ?? 0) + 1);
      return Promise.resolve({ ok: false as const, reason: "bad_code" as const });
    }
    const guardian = [...this.guardians].find((g) => g.endsWith(`/${code.familyId}`))!.split("/")[0];
    return Promise.resolve({ ok: true as const, familyId: code.familyId, guardianUserId: guardian });
  }
  pairComplete(c: Parameters<Store["pairComplete"]>[0]) {
    const peek = this.pairPeekSync(c);
    if (!peek.ok) return Promise.resolve(peek);
    const pk = b64urlEncode(c.publicKey);
    if ([...this.devices.values()].some((d) => b64urlEncode(d.publicKey) === pk)) {
      return Promise.resolve({ ok: false as const, reason: "key_in_use" as const });
    }
    if ([...this.devices.values()].filter((d) => d.familyId === peek.familyId && !d.revokedAt).length >= 6) {
      return Promise.resolve({ ok: false as const, reason: "device_limit" as const });
    }
    this.usedChallenges.add(b64urlEncode(c.challenge));
    this.usedCodes.add(b64urlEncode(c.codeHash));
    const id = crypto.randomUUID();
    this.devices.set(id, {
      id,
      familyId: peek.familyId,
      role: "child",
      publicKey: c.publicKey,
      revokedAt: null,
      platform: c.platform,
      securityLevel: c.securityLevel,
      createdAt: new Date(this.nowMs),
      lastSeenAt: null,
    });
    return Promise.resolve({ ok: true as const, deviceId: id, familyId: peek.familyId });
  }
  private pairPeekSync(c: { challenge: Bytes; codeHash: Bytes }) {
    const ck = b64urlEncode(c.challenge);
    const hk = b64urlEncode(c.codeHash);
    const ch = this.challenges.find((x) => b64urlEncode(x.challenge) === ck && x.purpose === "pair");
    if (!ch || this.usedChallenges.has(ck) || ch.expiresAt.getTime() <= this.nowMs) {
      return { ok: false as const, reason: "challenge_invalid" as const };
    }
    const code = this.codes.find((x) => b64urlEncode(x.codeHash) === hk && !this.usedCodes.has(hk));
    if (!code) return { ok: false as const, reason: "bad_code" as const };
    return { ok: true as const, familyId: code.familyId };
  }
  listActiveDevices(familyId: string): Promise<DeviceSummary[]> {
    return Promise.resolve(
      [...this.devices.values()].filter((d) => d.familyId === familyId && !d.revokedAt).map((d) => ({
        id: d.id,
        role: d.role,
        platform: d.platform,
        securityLevel: d.securityLevel,
        createdAt: d.createdAt,
        lastSeenAt: d.lastSeenAt,
      })),
    );
  }
  /** Published packs by id (only the current version is kept), and the characters by id. */
  packs = new Map<string, PublishedPack>();
  characters = new Map<
    string,
    { nameHe: string; gender: string; voiceId: string | null; personal: boolean }
  >();
  publishContent(p: PublishedPack) {
    const have = this.packs.get(p.packId);
    if (have) {
      const order = compareSemver(p.packVersion, have.packVersion);
      if (order < 0) return Promise.resolve("older" as const);
      if (order === 0 && have.manifestSha256 !== p.manifestSha256) {
        return Promise.resolve("conflict" as const);
      }
    }
    for (const c of p.characters) {
      const old = this.characters.get(c.characterId);
      this.characters.set(c.characterId, {
        nameHe: c.nameHe,
        gender: c.gender,
        voiceId: c.voiceId ?? old?.voiceId ?? null,
        personal: c.personal,
      });
    }
    if (have && have.packVersion === p.packVersion) return Promise.resolve("unchanged" as const);
    for (const i of p.items) this.itemRevisions.set(`${p.packId}/${p.packVersion}/${i.itemId}`, i.revision);
    this.packs.set(p.packId, p);
    return Promise.resolve("published" as const);
  }
  // ---- the tutor ----
  /** The revision of every item of every pack version ever published (a real database keeps the old versions too). */
  itemRevisions = new Map<string, number>();
  carryLines(packId: string, fromVersion: string, toVersion: string, promptVersion: string) {
    let carried = 0;
    for (const [key, line] of [...this.cache]) {
      const [pack, version, item, ...rest] = key.split("/");
      if (pack !== packId || version !== fromVersion || rest[rest.length - 2] !== promptVersion) continue;
      const was = this.itemRevisions.get(`${packId}/${fromVersion}/${item}`);
      const now = this.itemRevisions.get(`${packId}/${toVersion}/${item}`);
      if (was === undefined || was !== now) continue;
      const to = [pack, toVersion, item, ...rest].join("/");
      if (!this.cache.has(to)) {
        this.cache.set(to, line);
        carried++;
      }
    }
    return Promise.resolve(carried);
  }
  cache = new Map<string, CachedLine>();
  cacheGets = 0;
  logs: TutorLogRow[] = [];
  tutorCounters = new Map<string, number>();
  costMicro = new Map<string, number>();
  private cacheKey = (k: CacheKey) =>
    [
      k.packId,
      k.packVersion,
      k.itemId,
      k.mistake,
      k.hintLevel,
      k.band,
      k.addressForm,
      k.characterId,
      k.promptVersion,
      k.validatorVersion,
    ]
      .join("/");
  tutorContext(packId: string, packVersion: string, itemId: string, characterId: string) {
    const p = this.packs.get(packId);
    const it = p && p.packVersion === packVersion ? p.items.find((i) => i.itemId === itemId) : undefined;
    if (!p || !it) return Promise.resolve(null);
    const c = this.characters.get(characterId);
    const ctx: TutorContext = {
      itemId: it.itemId,
      band: it.band,
      llmAllowed: it.llmAllowed,
      goal: it.goal,
      promptText: it.promptText,
      numberSet: it.numberSet,
      allowedActions: it.allowedActions,
      hintThreshold: it.hintThreshold,
      objectIds: it.objectIds,
      answers: it.answers,
      descriptions: Object.fromEntries(p.misconceptions.map((m) => [m.tag, m.description])),
      character: c ? { nameHe: c.nameHe, gender: c.gender as "m" | "f", voiceId: c.voiceId } : null,
    };
    return Promise.resolve(ctx);
  }
  tutorItemIds(packId: string, packVersion: string) {
    const p = this.packs.get(packId);
    return Promise.resolve(
      p && p.packVersion === packVersion
        ? p.items.filter((i) => i.llmAllowed).map((i) => i.itemId).sort()
        : [],
    );
  }
  cacheGet(k: CacheKey) {
    this.cacheGets++;
    return Promise.resolve(this.cache.get(this.cacheKey(k)) ?? null);
  }
  cachePut(k: CacheKey, v: CachedLine, replace = false) {
    if (replace || !this.cache.has(this.cacheKey(k))) this.cache.set(this.cacheKey(k), v);
    return Promise.resolve();
  }
  tutorTake(p: Parameters<Store["tutorTake"]>[0]): Promise<TakeResult> {
    const day = Math.floor(p.nowMs / 86_400_000);
    const bump = (scope: string, key: string, cap: number) => {
      const k = `${scope}/${key}/${day}`;
      const n = this.tutorCounters.get(k) ?? 0;
      if (n >= cap) return false;
      this.tutorCounters.set(k, n + 1);
      return true;
    };
    if ((this.costMicro.get(`${p.familyId}/${day}`) ?? 0) >= p.costCapMicro) {
      return Promise.resolve("cost_cap");
    }
    if (p.kind === "prefetch") {
      return Promise.resolve(bump("prefetch", p.sessionRef, p.prefetchCap) ? "ok" : "prefetch_cap");
    }
    if (!bump("day", p.childRef, p.dayCap)) return Promise.resolve("day_cap");
    if (!bump("session", p.sessionRef, p.sessionCap)) {
      const k = `day/${p.childRef}/${day}`;
      this.tutorCounters.set(k, (this.tutorCounters.get(k) ?? 1) - 1);
      return Promise.resolve("session_cap");
    }
    return Promise.resolve("ok");
  }
  tutorCostAdd(familyId: string, micro: number, nowMs: number) {
    const k = `${familyId}/${Math.floor(nowMs / 86_400_000)}`;
    this.costMicro.set(k, (this.costMicro.get(k) ?? 0) + Math.max(0, micro));
    return Promise.resolve();
  }
  logTutor(row: TutorLogRow) {
    this.logs.push(row);
    return Promise.resolve();
  }

  // ---- the parent area (M7b) ----
  children = new Map<string, Map<string, ChildProfile>>();
  tombstones = new Map<string, Set<string>>();
  events: Array<EventOut & { familyId: string }> = [];
  private nextSeq = 1;

  upsertChild(familyId: string, c: ChildProfile) {
    if (this.tombstones.get(familyId)?.has(c.id)) return Promise.resolve("deleted" as const);
    const m = this.children.get(familyId) ?? new Map<string, ChildProfile>();
    m.set(c.id, { ...c });
    this.children.set(familyId, m);
    return Promise.resolve("saved" as const);
  }
  listChildren(familyId: string) {
    return Promise.resolve([...(this.children.get(familyId)?.values() ?? [])]);
  }
  listTombstones(familyId: string) {
    return Promise.resolve([...(this.tombstones.get(familyId) ?? [])]);
  }
  deleteChild(familyId: string, childId: string) {
    this.children.get(familyId)?.delete(childId);
    this.events = this.events.filter((e) => !(e.familyId === familyId && e.childId === childId));
    this.alerts = this.alerts.filter((a) => !(a.familyId === familyId && a.childId === childId));
    this.logs = this.logs.filter((l) => !(l.familyId === familyId && l.childRef === childId));
    const t = this.tombstones.get(familyId) ?? new Set<string>();
    t.add(childId);
    this.tombstones.set(familyId, t);
    return Promise.resolve();
  }
  insertEvents(familyId: string, deviceId: string, events: readonly EventIn[]) {
    let accepted = 0;
    let duplicates = 0;
    const refused: string[] = [];
    for (const e of events) {
      if (!this.children.get(familyId)?.has(e.childId)) {
        refused.push(e.id);
      } else if (this.events.some((x) => x.familyId === familyId && x.id === e.id)) {
        duplicates++;
      } else {
        this.events.push({ ...e, familyId, deviceId, seq: this.nextSeq++ });
        accepted++;
      }
    }
    return Promise.resolve({ accepted, duplicates, refused });
  }
  alerts: Array<AlertOut & { familyId: string }> = [];
  pushTokenRows: Array<{ familyId: string; deviceId: string; token: string; platform: "android" | "ios" }> =
    [];
  settings = new Map<string, { rules: Record<string, unknown>; version: number }>();

  insertAlert(familyId: string, deviceId: string, a: AlertIn) {
    if (a.childId !== null && !this.children.get(familyId)?.has(a.childId)) {
      return Promise.resolve("refused" as const);
    }
    if (this.alerts.some((x) => x.familyId === familyId && x.key === a.key)) {
      return Promise.resolve("duplicate" as const);
    }
    this.alerts.push({ ...a, familyId, deviceId, id: crypto.randomUUID(), readAtMs: null });
    return Promise.resolve("new" as const);
  }
  listAlerts(familyId: string, sinceMs: number) {
    return Promise.resolve(
      this.alerts.filter((a) => a.familyId === familyId && a.clientAtMs >= sinceMs)
        .sort((x, y) => y.clientAtMs - x.clientAtMs).map(({ familyId: _f, ...rest }) => rest),
    );
  }
  markAlertsRead(familyId: string, nowMs: number) {
    let n = 0;
    for (const a of this.alerts) {
      if (a.familyId === familyId && a.readAtMs === null) {
        a.readAtMs = nowMs;
        n++;
      }
    }
    return Promise.resolve(n);
  }
  upsertPushToken(familyId: string, deviceId: string, token: string, platform: "android" | "ios") {
    this.pushTokenRows = this.pushTokenRows.filter((t) => t.deviceId !== deviceId);
    this.pushTokenRows.push({ familyId, deviceId, token, platform });
    return Promise.resolve();
  }
  removePushToken(deviceId: string) {
    this.pushTokenRows = this.pushTokenRows.filter((t) => t.deviceId !== deviceId);
    return Promise.resolve();
  }
  pushTokens(familyId: string) {
    return Promise.resolve(
      this.pushTokenRows.filter((t) => t.familyId === familyId).map(({ familyId: _f, ...r }) => r),
    );
  }
  getSettings(familyId: string) {
    return Promise.resolve(this.settings.get(familyId) ?? null);
  }
  putSettings(familyId: string, rules: Record<string, unknown>) {
    const version = (this.settings.get(familyId)?.version ?? 0) + 1;
    this.settings.set(familyId, { rules, version });
    return Promise.resolve(version);
  }
  tutorLogOf(familyId: string, sinceMs: number, limit: number): Promise<TutorLogEntry[]> {
    return Promise.resolve(
      this.logs.filter((l) => l.familyId === familyId).slice(0, limit).map((l) => ({
        atMs: sinceMs,
        childRef: l.childRef,
        itemId: l.itemId,
        characterId: l.characterId,
        source: l.source,
        outcome: l.outcome,
        line: l.line,
      })),
    );
  }
  pullEvents(familyId: string, after: number, limit: number) {
    const all = this.events.filter((e) => e.familyId === familyId && e.seq > after).sort((a, b) =>
      a.seq - b.seq
    );
    return Promise.resolve({
      more: all.length > limit,
      events: all.slice(0, limit).map(({ familyId: _f, ...rest }) => rest),
    });
  }
  revokeDevice(familyId: string, deviceId: string, _reason: RevokeReason) {
    const d = this.devices.get(deviceId);
    if (!d || d.familyId !== familyId || d.revokedAt) return Promise.resolve(false);
    d.revokedAt = new Date(NOW);
    return Promise.resolve(true);
  }
}

/** Fake token: "tok.<user uuid>.<issued-at seconds>". Anything else is invalid. */
export const tokenFor = (userId: string, iat = NOW / 1000 - 5) => `tok.${userId}.${iat}`;

export function fakeServices(store: FakeStore, nowMs = () => NOW): Services {
  return {
    nowMs,
    store,
    verifyToken: (b) => {
      const m = /^tok\.([0-9a-f-]{36})\.(\d+)$/.exec(b);
      return Promise.resolve(m ? { userId: m[1], issuedAt: Number(m[2]) } : null);
    },
    secrets: {
      pairingCodeKey: new Uint8Array(32).fill(7) as Bytes,
      ipHashKey: new Uint8Array(32).fill(9) as Bytes,
      publishSecret: PUBLISH_SECRET,
    },
    randomBytes: (n) => crypto.getRandomValues(new Uint8Array(n)) as Bytes,
    allowDevEnrolment: false,
    mintSession: (id) => Promise.resolve({ tokenHash: `hash-for-${id}` }),
  };
}

export interface TestDevice {
  id: string;
  familyId: string;
  userId: string;
  priv: CryptoKey;
}

let counter = 0;
const uuid = (prefix: string, n: number) => `${prefix}-0000-4000-8000-${String(n).padStart(12, "0")}`;

export async function addDevice(
  store: FakeStore,
  o: { family: string; user: string; role: "parent" | "child"; revoked?: boolean },
): Promise<TestDevice> {
  const kp = await crypto.subtle.generateKey({ name: "ECDSA", namedCurve: "P-256" }, true, ["sign"]);
  const id = uuid("d2d2d2d2", ++counter);
  store.devices.set(id, {
    id,
    familyId: o.family,
    role: o.role,
    publicKey: new Uint8Array(await crypto.subtle.exportKey("spki", kp.publicKey)) as Bytes,
    revokedAt: o.revoked ? new Date(NOW - 1000) : null,
    platform: "android",
    securityLevel: "tee",
    createdAt: new Date(NOW - 86_400_000),
    lastSeenAt: null,
  });
  store.guardians.add(`${o.user}/${o.family}`);
  return { id, familyId: o.family, userId: o.user, priv: kp.privateKey };
}

/** Sends a correctly signed request to a handler, as a phone would. */
export async function call(
  handler: (req: Request) => Promise<Response>,
  d: TestDevice,
  fn: string,
  body: unknown = {},
  o: { token?: string; ts?: number; nonce?: string } = {},
): Promise<Response> {
  const text = JSON.stringify(body);
  const nonce = o.nonce ?? crypto.randomUUID();
  const ts = o.ts ?? NOW;
  const canonical = canonicalString({
    functionName: fn,
    timestampMs: ts,
    nonce,
    bodyHashB64url: await sha256B64url(utf8(text)),
    deviceId: d.id,
  });
  const raw = new Uint8Array(
    await crypto.subtle.sign({ name: "ECDSA", hash: "SHA-256" }, d.priv, utf8(canonical)),
  );
  return handler(
    new Request(`https://x.test/functions/v1/${fn}`, {
      method: "POST",
      body: text,
      headers: {
        authorization: `Bearer ${o.token ?? tokenFor(d.userId)}`,
        "x-device-id": d.id,
        "x-timestamp": String(ts),
        "x-nonce": nonce,
        "x-signature": b64urlEncode(rawToDer(raw)),
      },
    }),
  );
}

export const plainPost = (fn: string, body: unknown, headers: Record<string, string> = {}) =>
  new Request(`https://x.test/functions/v1/${fn}`, { method: "POST", body: JSON.stringify(body), headers });

export const FAMILY_A = uuid("a1a1a1a1", 1);
export const FAMILY_B = uuid("b1b1b1b1", 1);
export const USER_A = uuid("aaaaaaaa", 1);
export const USER_B = uuid("bbbbbbbb", 1);

/** A pre-enrolment request: signed with the new key and the nil device id, carrying a session token. */
export async function callSelfSigned(
  handler: (req: Request) => Promise<Response>,
  priv: CryptoKey,
  fn: string,
  body: unknown,
  o: { token?: string; ts?: number; unsigned?: boolean } = {},
): Promise<Response> {
  const text = JSON.stringify(body);
  const nonce = crypto.randomUUID();
  const ts = o.ts ?? NOW;
  const canonical = canonicalString({
    functionName: fn,
    timestampMs: ts,
    nonce,
    bodyHashB64url: await sha256B64url(utf8(text)),
    deviceId: "00000000-0000-0000-0000-000000000000",
  });
  const raw = new Uint8Array(
    await crypto.subtle.sign({ name: "ECDSA", hash: "SHA-256" }, priv, utf8(canonical)),
  );
  const headers: Record<string, string> = {
    "x-device-id": "00000000-0000-0000-0000-000000000000",
    "x-timestamp": String(ts),
    "x-nonce": nonce,
    "x-signature": b64urlEncode(rawToDer(raw)),
  };
  if (o.token !== "") headers.authorization = `Bearer ${o.token ?? tokenFor(USER_A)}`;
  if (o.unsigned) {
    for (const h of ["x-device-id", "x-timestamp", "x-nonce", "x-signature"]) delete headers[h];
  }
  return handler(new Request(`https://x.test/functions/v1/${fn}`, { method: "POST", body: text, headers }));
}
