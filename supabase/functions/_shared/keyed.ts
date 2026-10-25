// Keyed hashes for values that must not be stored in the clear: pairing codes (a 6-digit space is
// trivially brute-forced if only plainly hashed) and IP addresses used for rate limits.
import { b64urlEncode, type Bytes } from "./b64.ts";

export async function hmacSha256(key: Bytes, data: Bytes): Promise<Bytes> {
  const k = await crypto.subtle.importKey("raw", key, { name: "HMAC", hash: "SHA-256" }, false, ["sign"]);
  return new Uint8Array(await crypto.subtle.sign("HMAC", k, data)) as Bytes;
}

const utf8 = (s: string): Bytes => new TextEncoder().encode(s) as Bytes;

export const hashPairingCode = (key: Bytes, code: string): Promise<Bytes> =>
  hmacSha256(key, utf8(`pair:${code}`));

/** The caller's address as a keyed hash (never stored or logged raw). */
export async function ipKey(req: Request, key: Bytes): Promise<{ hash: Bytes; text: string }> {
  const fwd = req.headers.get("cf-connecting-ip") ?? req.headers.get("x-forwarded-for")?.split(",")[0] ?? "";
  const ip = /^[0-9a-fA-F:.]{3,45}$/.test(fwd.trim()) ? fwd.trim() : "unknown";
  const hash = await hmacSha256(key, utf8(`ip:${ip}`));
  return { hash, text: b64urlEncode(hash).slice(0, 22) };
}

/** A uniformly random 6-digit code (rejection sampling, so no modulo bias). */
export function sixDigitCode(random: (n: number) => Bytes): string {
  for (;;) {
    const b = random(4);
    const n = ((b[0] << 24) | (b[1] << 16) | (b[2] << 8) | b[3]) >>> 0;
    if (n < 4_294_000_000) return String(n % 1_000_000).padStart(6, "0");
  }
}
