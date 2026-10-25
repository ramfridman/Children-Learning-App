// Base64url without padding (RFC 4648 §5). Strict on input: anything else is refused.
// Uses only the runtime's own btoa/atob, so there is no dependency to approve.

/** WebCrypto wants buffers backed by a plain ArrayBuffer, not a possibly shared one. */
export type Bytes = Uint8Array<ArrayBuffer>;

const B64URL = /^[A-Za-z0-9_-]*$/;

export function b64urlEncode(bytes: Uint8Array): string {
  let bin = "";
  for (let i = 0; i < bytes.length; i++) bin += String.fromCharCode(bytes[i]);
  return btoa(bin).replaceAll("+", "-").replaceAll("/", "_").replace(/=+$/, "");
}

/** Returns null for anything that is not canonical unpadded base64url. */
export function b64urlDecode(text: string): Bytes | null {
  if (!B64URL.test(text) || text.length % 4 === 1) return null;
  const padded = text.replaceAll("-", "+").replaceAll("_", "/") +
    "=".repeat((4 - (text.length % 4)) % 4);
  let bin: string;
  try {
    bin = atob(padded);
  } catch {
    return null;
  }
  const out: Bytes = new Uint8Array(bin.length);
  for (let i = 0; i < bin.length; i++) out[i] = bin.charCodeAt(i);
  // Reject non-canonical encodings (stray low bits in the last character).
  return b64urlEncode(out) === text ? out : null;
}

export async function sha256(data: Bytes): Promise<Bytes> {
  return new Uint8Array(await crypto.subtle.digest("SHA-256", data));
}

export async function sha256B64url(data: Bytes): Promise<string> {
  return b64urlEncode(await sha256(data));
}
