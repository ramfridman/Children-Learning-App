// The four checks every function makes, in this order, each against injected services so tests
// can drive every refusal without a database or a token issuer:
//   1. the session token (verified here, against the project's signing keys);
//   2. the signed request: headers, clock (±60 s), the device's signature, then the one-time number;
//   3. the device is active and belongs to the family of the token's user;
//   4. the device's role may call this function.
// Public error codes are deliberately few; the precise reason goes only to the redacted log.
import { b64urlDecode, type Bytes, sha256B64url } from "./b64.ts";
import {
  canonicalString,
  checkSkew,
  HEADER_DEVICE_ID,
  HEADER_NONCE,
  HEADER_SIGNATURE,
  HEADER_TIMESTAMP,
  isUuid,
  isUuidV4,
  NIL_DEVICE_ID,
} from "./canonical.ts";
import { GatewayError } from "./errors.ts";
import { verifyDeviceSignature } from "./sig.ts";

export type Role = "parent" | "child";

export interface DeviceRecord {
  id: string;
  familyId: string;
  role: Role;
  publicKey: Bytes;
  revokedAt: Date | null;
}

export interface AuthDeps {
  nowMs(): number;
  /** Verifies the bearer token against the project's signing keys. Null if it is not valid. */
  verifyToken(bearer: string): Promise<{ userId: string; issuedAt: number | null } | null>;
  getDevice(id: string): Promise<DeviceRecord | null>;
  isGuardian(userId: string, familyId: string): Promise<boolean>;
  /** Stores the nonce; returns false if this device has already used it. */
  recordNonce(deviceId: string, nonce: string): Promise<boolean>;
}

export interface Authenticated {
  userId: string;
  issuedAt: number | null;
  device: DeviceRecord;
  body: Bytes;
}

const refuse = (reason: string) => new GatewayError("unauthorized", reason);

function bearerOf(req: Request): string {
  const h = req.headers.get("authorization") ?? "";
  const m = /^Bearer ([A-Za-z0-9._-]{10,4096})$/.exec(h);
  if (!m) throw refuse("no_token");
  return m[1];
}

interface SignedParts {
  deviceId: string;
  timestampMs: number;
  nonce: string;
  signature: Bytes;
  canonical: Bytes;
}

async function parseSigned(req: Request, fn: string, body: Bytes, nowMs: number): Promise<SignedParts> {
  const deviceId = req.headers.get(HEADER_DEVICE_ID) ?? "";
  const ts = req.headers.get(HEADER_TIMESTAMP) ?? "";
  const nonce = req.headers.get(HEADER_NONCE) ?? "";
  const sig = req.headers.get(HEADER_SIGNATURE) ?? "";
  if (!isUuid(deviceId)) throw refuse("bad_device_header");
  if (!/^\d{1,15}$/.test(ts)) throw refuse("bad_time_header");
  if (!isUuidV4(nonce)) throw refuse("bad_nonce_header");
  const signature = b64urlDecode(sig);
  if (!signature || signature.length === 0) throw refuse("bad_signature_header");

  const timestampMs = Number(ts);
  const skew = checkSkew(timestampMs, nowMs);
  if (!skew.ok) throw new GatewayError("clock_skew", "clock_skew", { serverTimeMs: skew.serverTimeMs });

  const canonical = new TextEncoder().encode(
    canonicalString({
      functionName: fn,
      timestampMs,
      nonce,
      bodyHashB64url: await sha256B64url(body),
      deviceId,
    }),
  ) as Bytes;
  return { deviceId, timestampMs, nonce, signature, canonical };
}

export async function authenticate(
  req: Request,
  fn: string,
  body: Bytes,
  allowedRoles: readonly Role[],
  deps: AuthDeps,
): Promise<Authenticated> {
  // 1. Token.
  const claims = await deps.verifyToken(bearerOf(req));
  if (!claims) throw refuse("bad_token");

  // 2. Signed request. The device must exist to know its key, but unknown, revoked and
  //    bad-signature all look the same to the caller.
  const p = await parseSigned(req, fn, body, deps.nowMs());
  if (p.deviceId === NIL_DEVICE_ID) throw refuse("nil_device");
  const device = await deps.getDevice(p.deviceId);
  if (!device) throw refuse("unknown_device");
  if (!(await verifyDeviceSignature(device.publicKey, p.canonical, p.signature))) {
    throw refuse("bad_signature");
  }
  // The nonce is stored only after the signature is proven, so strangers cannot use up nonces.
  if (!(await deps.recordNonce(device.id, p.nonce))) throw refuse("replayed_nonce");

  // 3. Device active, and in the family of the token's user.
  if (device.revokedAt) throw refuse("revoked_device");
  if (!(await deps.isGuardian(claims.userId, device.familyId))) throw refuse("wrong_family");

  // 4. Role.
  if (!allowedRoles.includes(device.role)) throw new GatewayError("forbidden", "role_not_allowed");

  return { userId: claims.userId, issuedAt: claims.issuedAt, device, body };
}

/**
 * For the three calls made before a device exists. They are signed with the new key and the nil
 * device id; the caller supplies that key (from the request body or the challenge row). There is
 * no nonce row, because there is no device row yet: replay is stopped by the single-use challenge
 * and the 60 s clock window, and by per-family and per-IP limits on the functions themselves.
 */
export async function authenticatePreEnrolment(
  req: Request,
  fn: string,
  body: Bytes,
  publicKey: Bytes,
  deps: Pick<AuthDeps, "nowMs">,
): Promise<{ nonce: string }> {
  const p = await parseSigned(req, fn, body, deps.nowMs());
  if (p.deviceId !== NIL_DEVICE_ID) throw refuse("expected_nil_device");
  if (!(await verifyDeviceSignature(publicKey, p.canonical, p.signature))) throw refuse("bad_signature");
  return { nonce: p.nonce };
}
