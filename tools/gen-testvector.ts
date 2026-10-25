// Regenerates testvectors/signed-request.json. Run only when the format changes:
//   deno run --allow-write=testvectors tools/gen-testvector.ts
// The private keys exist only in memory while this runs and are never written anywhere.
// Both the Deno tests and the Dart tests read the JSON, so the two sides cannot drift.
import { b64urlEncode, sha256B64url } from "../supabase/functions/_shared/b64.ts";
import { canonicalString } from "../supabase/functions/_shared/canonical.ts";

function rawToDer(raw: Uint8Array): Uint8Array {
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

type Want = (rLen: number, sLen: number) => boolean;
const wants: Record<string, { want: Want; body: string; fn: string }> = {
  typical: { want: (r, s) => r === 32 && s === 32, body: "{}", fn: "signed-ping" },
  // r starts with a high bit, so DER carries a leading 0x00 (33-byte INTEGER).
  r_with_leading_zero_byte: { want: (r) => r === 33, body: '{"label":"abc"}', fn: "device-list" },
  // r is shorter than 32 bytes, so DER drops the leading zero byte(s).
  short_r: { want: (r) => r < 32, body: '{"label":"שלום"}', fn: "device-revoke" },
  short_s: { want: (_r, s) => s < 32, body: "{}", fn: "app-config" },
};

const cases = [];
let n = 0;
for (const [name, w] of Object.entries(wants)) {
  for (;;) {
    const kp = await crypto.subtle.generateKey({ name: "ECDSA", namedCurve: "P-256" }, true, ["sign"]);
    const spki = new Uint8Array(await crypto.subtle.exportKey("spki", kp.publicKey));
    const nonce = crypto.randomUUID();
    const deviceId = crypto.randomUUID();
    const ts = 1793000000000 + n * 1000;
    const body = new TextEncoder().encode(w.body);
    const canonical = canonicalString({
      functionName: w.fn,
      timestampMs: ts,
      nonce,
      bodyHashB64url: await sha256B64url(body),
      deviceId,
    });
    const raw = new Uint8Array(
      await crypto.subtle.sign(
        { name: "ECDSA", hash: "SHA-256" },
        kp.privateKey,
        new TextEncoder().encode(canonical),
      ),
    );
    const der = rawToDer(raw);
    const rLen = der[3];
    const sLen = der[5 + rLen];
    if (!w.want(rLen, sLen)) continue;
    cases.push({
      name,
      function: w.fn,
      timestamp_ms: ts,
      nonce,
      device_id: deviceId,
      body: w.body,
      body_sha256_b64url: await sha256B64url(body),
      canonical,
      public_key_spki_b64url: b64urlEncode(spki),
      signature_der_b64url: b64urlEncode(der),
      der_integer_lengths: [rLen, sLen],
    });
    n++;
    break;
  }
}

const out = {
  description:
    "Signed-request test vectors. canonical = v1, POST, /<function>, unix ms, nonce, base64url SHA-256 of the UTF-8 body, device id, joined by LF. Signature: ECDSA P-256 / SHA-256 over the UTF-8 canonical string, DER encoded. Public key: SPKI DER, 91 bytes, base64url without padding.",
  cases,
};
await Deno.writeTextFile("testvectors/signed-request.json", JSON.stringify(out, null, 2) + "\n");
console.log(`wrote ${cases.length} cases`);
