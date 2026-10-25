// The signed-request format, exactly as in docs/PLAN.md › "Signed requests: the exact format".
//
//   v1 \n POST \n /<function> \n <unix-ms> \n <uuidv4 nonce> \n <base64url sha256(body)> \n <device id>
//
// Every field is validated before it is joined, so no field can carry a newline or otherwise
// change where one field ends and the next begins.

export const SIGNATURE_VERSION = "v1";
export const MAX_SKEW_MS = 60_000;
/** Used by the three pre-enrolment calls, which are signed with the new key and no device yet. */
export const NIL_DEVICE_ID = "00000000-0000-0000-0000-000000000000";

export const HEADER_DEVICE_ID = "x-device-id";
export const HEADER_TIMESTAMP = "x-timestamp";
export const HEADER_NONCE = "x-nonce";
export const HEADER_SIGNATURE = "x-signature";

const UUID_V4 = /^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/;
const UUID_ANY = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/;
const FUNCTION_NAME = /^[a-z][a-z0-9-]{0,63}$/;
const HASH_B64URL = /^[A-Za-z0-9_-]{43}$/; // 32 bytes

export const isUuidV4 = (s: string): boolean => UUID_V4.test(s);
export const isUuid = (s: string): boolean => UUID_ANY.test(s);
export const isFunctionName = (s: string): boolean => FUNCTION_NAME.test(s);

export interface CanonicalParts {
  functionName: string;
  timestampMs: number;
  nonce: string;
  bodyHashB64url: string;
  deviceId: string;
}

/** Throws a plain Error (a programming error) if any part is malformed. */
export function canonicalString(p: CanonicalParts): string {
  if (!FUNCTION_NAME.test(p.functionName)) throw new Error("bad function name");
  if (!Number.isSafeInteger(p.timestampMs) || p.timestampMs < 0) throw new Error("bad timestamp");
  if (!UUID_V4.test(p.nonce)) throw new Error("bad nonce");
  if (!HASH_B64URL.test(p.bodyHashB64url)) throw new Error("bad body hash");
  if (!UUID_ANY.test(p.deviceId)) throw new Error("bad device id");
  return [
    SIGNATURE_VERSION,
    "POST",
    `/${p.functionName}`,
    String(p.timestampMs),
    p.nonce,
    p.bodyHashB64url,
    p.deviceId,
  ].join("\n");
}

export type SkewResult = { ok: true } | { ok: false; serverTimeMs: number };

/** A gap of more than 60 s either way is refused; the caller returns the server's time. */
export function checkSkew(timestampMs: number, nowMs: number): SkewResult {
  return Math.abs(nowMs - timestampMs) <= MAX_SKEW_MS ? { ok: true } : { ok: false, serverTimeMs: nowMs };
}
