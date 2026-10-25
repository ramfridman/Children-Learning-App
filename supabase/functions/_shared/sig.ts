// ECDSA P-256 / SHA-256 verification for device-signed requests.
// Platforms hand back DER signatures; WebCrypto wants raw r‖s (IEEE P1363). We convert, strictly.

import type { Bytes } from "./b64.ts";

const P256_SPKI_PREFIX = Uint8Array.from([
  0x30,
  0x59,
  0x30,
  0x13,
  0x06,
  0x07,
  0x2a,
  0x86,
  0x48,
  0xce,
  0x3d,
  0x02,
  0x01,
  0x06,
  0x08,
  0x2a,
  0x86,
  0x48,
  0xce,
  0x3d,
  0x03,
  0x01,
  0x07,
  0x03,
  0x42,
  0x00,
  0x04,
]);
export const SPKI_LENGTH = 91;

/** DER `SEQUENCE { INTEGER r, INTEGER s }` to 64 raw bytes, or null if it is not strictly that. */
export function derToRaw(der: Uint8Array): Bytes | null {
  // A P-256 signature is at most 72 bytes, so every length fits in one byte (short form).
  if (der.length < 8 || der.length > 72) return null;
  if (der[0] !== 0x30 || der[1] !== der.length - 2) return null;
  let pos = 2;
  const ints: Uint8Array[] = [];
  for (let n = 0; n < 2; n++) {
    if (der[pos] !== 0x02) return null;
    const len = der[pos + 1];
    if (len === undefined || len < 1 || len > 33 || pos + 2 + len > der.length) return null;
    const v = der.subarray(pos + 2, pos + 2 + len);
    if ((v[0] & 0x80) !== 0) return null; // negative
    if (v.length > 1 && v[0] === 0x00 && (v[1] & 0x80) === 0) return null; // not minimal
    const mag = v[0] === 0x00 ? v.subarray(1) : v;
    if (mag.length === 0 || mag.length > 32) return null; // zero or too big
    ints.push(mag);
    pos += 2 + len;
  }
  if (pos !== der.length) return null; // trailing bytes
  const raw: Bytes = new Uint8Array(64);
  raw.set(ints[0], 32 - ints[0].length);
  raw.set(ints[1], 64 - ints[1].length);
  return raw;
}

/** True if the bytes are an uncompressed P-256 SubjectPublicKeyInfo (91 bytes). */
export function looksLikeP256Spki(spki: Uint8Array): boolean {
  if (spki.length !== SPKI_LENGTH) return false;
  for (let i = 0; i < P256_SPKI_PREFIX.length; i++) if (spki[i] !== P256_SPKI_PREFIX[i]) return false;
  return true;
}

const P = (1n << 256n) - (1n << 224n) + (1n << 192n) + (1n << 96n) - 1n;
const B = 0x5ac635d8aa3a93e7b3ebbd55769886bc651d06b0cc53b0f63bce3c3e27d2604bn;

const toBig = (b: Uint8Array): bigint => b.reduce((acc, x) => (acc << 8n) | BigInt(x), 0n);
/**
 * Checks y² = x³ − 3x + b (mod p) ourselves. Some WebCrypto builds (Deno's among them) import an
 * SPKI whose point is not on the curve; we do not rely on the runtime for that check.
 */
export function pointIsOnP256(spki: Uint8Array): boolean {
  if (!looksLikeP256Spki(spki)) return false;
  const x = toBig(spki.subarray(27, 59));
  const y = toBig(spki.subarray(59, 91));
  if (x >= P || y >= P) return false;
  const lhs = (y * y) % P;
  const rhs = (((x * x) % P) * x - 3n * x + B) % P;
  return lhs === ((rhs + P) % P);
}

export async function importDeviceKey(spki: Bytes): Promise<CryptoKey | null> {
  if (!pointIsOnP256(spki)) return null;
  try {
    return await crypto.subtle.importKey("spki", spki, { name: "ECDSA", namedCurve: "P-256" }, false, [
      "verify",
    ]);
  } catch {
    return null;
  }
}

/** Never throws: any malformed input is simply "not valid". */
export async function verifyDeviceSignature(
  spki: Bytes,
  message: Bytes,
  derSignature: Uint8Array,
): Promise<boolean> {
  const raw = derToRaw(derSignature);
  if (!raw) return false;
  const key = await importDeviceKey(spki);
  if (!key) return false;
  try {
    return await crypto.subtle.verify({ name: "ECDSA", hash: "SHA-256" }, key, raw, message);
  } catch {
    return false;
  }
}
