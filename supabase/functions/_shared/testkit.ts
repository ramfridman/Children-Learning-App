// Test-only kit: an in-memory Store, fake services, and a signer that talks to a real handler
// exactly as a phone would. Never imported by a function.
import type { DeviceRecord } from "./auth.ts";
import { b64urlEncode, type Bytes, sha256B64url } from "./b64.ts";
import { canonicalString } from "./canonical.ts";
import type { Services } from "./handler.ts";
import { compareSemver } from "./semver.ts";
import type {
  CachedLine,
  CacheKey,
  DeviceSummary,
  PublishedPack,
  RevokeReason,
  Store,
  TakeResult,
  TutorContext,
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
    this.packs.set(p.packId, p);
    return Promise.resolve("published" as const);
  }
  // ---- the tutor ----
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
  cachePut(k: CacheKey, v: CachedLine) {
    if (!this.cache.has(this.cacheKey(k))) this.cache.set(this.cacheKey(k), v);
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
