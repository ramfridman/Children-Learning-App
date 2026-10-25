// Test-only kit: an in-memory Store, fake services, and a signer that talks to a real handler
// exactly as a phone would. Never imported by a function.
import type { DeviceRecord } from "./auth.ts";
import { b64urlEncode, type Bytes, sha256B64url } from "./b64.ts";
import { canonicalString } from "./canonical.ts";
import type { Services } from "./handler.ts";
import type { DeviceSummary, RevokeReason, Store } from "./store.ts";
import { rawToDer, utf8 } from "./testutil.ts";

export const NOW = 1_800_000_000_000;

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
    },
    randomBytes: (n) => crypto.getRandomValues(new Uint8Array(n)) as Bytes,
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
