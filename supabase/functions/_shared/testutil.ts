// Test helpers only. Never imported by a function.
import { b64urlDecode, type Bytes } from "./b64.ts";

export interface Vector {
  name: string;
  function: string;
  timestamp_ms: number;
  nonce: string;
  device_id: string;
  body: string;
  body_sha256_b64url: string;
  canonical: string;
  public_key_spki_b64url: string;
  signature_der_b64url: string;
  der_integer_lengths: number[];
}

export async function loadVectors(): Promise<Vector[]> {
  const url = new URL("../../../testvectors/signed-request.json", import.meta.url);
  return JSON.parse(await Deno.readTextFile(url)).cases;
}

export const bytes = (b64: string): Bytes => {
  const out = b64urlDecode(b64);
  if (!out) throw new Error("bad test input");
  return out;
};
export const utf8 = (s: string): Bytes => new TextEncoder().encode(s) as Bytes;

export function rawToDer(raw: Uint8Array): Uint8Array {
  const int = (b: Uint8Array) => {
    let i = 0;
    while (i < b.length - 1 && b[i] === 0) i++;
    let v = b.subarray(i);
    if (v[0] & 0x80) v = Uint8Array.from([0, ...v]);
    return Uint8Array.from([0x02, v.length, ...v]);
  };
  const r = int(raw.subarray(0, 32));
  const s = int(raw.subarray(32));
  return Uint8Array.from([0x30, r.length + s.length, ...r, ...s]);
}
