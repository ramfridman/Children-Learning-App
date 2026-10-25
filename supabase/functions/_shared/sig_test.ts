import { assert } from "./testassert.ts";
import {
  derToRaw,
  importDeviceKey,
  looksLikeP256Spki,
  pointIsOnP256,
  SPKI_LENGTH,
  verifyDeviceSignature,
} from "./sig.ts";
import { bytes, loadVectors, rawToDer, utf8 } from "./testutil.ts";

Deno.test("every shared test vector verifies (DER with 31, 32 and 33 byte integers)", async () => {
  const vectors = await loadVectors();
  assert.deepEqual(new Set(vectors.flatMap((v) => v.der_integer_lengths)).has(33), true);
  assert.deepEqual(new Set(vectors.flatMap((v) => v.der_integer_lengths)).has(31), true);
  for (const v of vectors) {
    const spki = bytes(v.public_key_spki_b64url);
    assert.equal(spki.length, SPKI_LENGTH);
    assert.ok(
      await verifyDeviceSignature(spki, utf8(v.canonical), bytes(v.signature_der_b64url)),
      v.name,
    );
  }
});

Deno.test("a changed field, a changed key or a changed signature fails", async () => {
  const [a, b] = await loadVectors();
  const spki = bytes(a.public_key_spki_b64url);
  const sig = bytes(a.signature_der_b64url);
  const lines = a.canonical.split("\n");
  for (let i = 0; i < lines.length; i++) {
    const changed = [...lines];
    changed[i] = changed[i] + "x";
    assert.equal(await verifyDeviceSignature(spki, utf8(changed.join("\n")), sig), false, `line ${i}`);
  }
  assert.equal(await verifyDeviceSignature(spki, utf8(a.canonical.replace("POST", "GET_")), sig), false);
  assert.equal(
    await verifyDeviceSignature(bytes(b.public_key_spki_b64url), utf8(a.canonical), sig),
    false,
    "other device's key",
  );
  for (let i = 0; i < sig.length; i++) {
    const flipped = sig.slice();
    flipped[i] ^= 1;
    assert.equal(await verifyDeviceSignature(spki, utf8(a.canonical), flipped), false, `byte ${i}`);
  }
});

Deno.test("derToRaw is strict about what DER it accepts", async () => {
  const [a] = await loadVectors();
  const der = bytes(a.signature_der_b64url);
  const raw = derToRaw(der);
  assert.ok(raw && raw.length === 64);
  assert.deepEqual(rawToDer(raw!), der);

  const hex = (h: string) => Uint8Array.from(h.match(/../g)!.map((x) => parseInt(x, 16)));
  const r = "11".repeat(32);
  const ok = hex(`3044 0220${r} 0220${r}`.replaceAll(" ", ""));
  assert.ok(derToRaw(ok));
  const cases: Record<string, Uint8Array> = {
    empty: new Uint8Array(0),
    raw_64_bytes: crypto.getRandomValues(new Uint8Array(64)),
    wrong_outer_tag: (() => {
      const x = ok.slice();
      x[0] = 0x31;
      return x;
    })(),
    outer_length_short: (() => {
      const x = ok.slice();
      x[1] -= 1;
      return x;
    })(),
    trailing_byte: Uint8Array.from([...ok.slice(0, 1), ok[1] + 1, ...ok.slice(2), 0]),
    long_form_length: Uint8Array.from([0x30, 0x81, 0x44, ...ok.slice(2)]),
    negative_integer: hex(`3044 0220${"ff" + "11".repeat(31)} 0220${r}`.replaceAll(" ", "")),
    padded_not_minimal: hex(`3045 0221 00${r} 0220${r}`.replaceAll(" ", "")),
    zero_integer: hex(`3008 0201 00 0220${"11".repeat(32)}`.replaceAll(" ", "")).slice(0, 9),
    integer_too_big: hex(`3046 0221 00ff${"11".repeat(31)} 0221 00${r}`.replaceAll(" ", "")),
    integer_length_overruns: hex("3006 0220 1111 0201 01".replaceAll(" ", "")),
    wrong_inner_tag: hex(`3044 0420${r} 0220${r}`.replaceAll(" ", "")),
    one_integer_only: hex(`3022 0220${r}`.replaceAll(" ", "")),
  };
  for (const [name, input] of Object.entries(cases)) assert.equal(derToRaw(input), null, name);
});

Deno.test("public keys: only a 91-byte uncompressed P-256 SPKI on the curve is accepted", async () => {
  const [a] = await loadVectors();
  const spki = bytes(a.public_key_spki_b64url);
  assert.ok(looksLikeP256Spki(spki));
  assert.ok(pointIsOnP256(spki));
  assert.ok(await importDeviceKey(spki));

  assert.equal(await importDeviceKey(spki.slice(0, 90) as typeof spki), null, "too short");
  assert.equal(await importDeviceKey(new Uint8Array(91)), null, "zeros");
  const wrongCurve = new Uint8Array(
    await crypto.subtle.exportKey(
      "spki",
      (await crypto.subtle.generateKey({ name: "ECDSA", namedCurve: "P-384" }, true, ["sign", "verify"]))
        .publicKey,
    ),
  );
  assert.equal(await importDeviceKey(wrongCurve), null, "P-384");
  const offCurve = spki.slice();
  offCurve[offCurve.length - 1] ^= 0xff;
  assert.equal(await importDeviceKey(offCurve), null, "point not on the curve");
  const compressed = spki.slice();
  compressed[26] = 0x02;
  assert.equal(await importDeviceKey(compressed), null, "compressed marker");
});

Deno.test("verifyDeviceSignature never throws on garbage", async () => {
  const [a] = await loadVectors();
  assert.equal(await verifyDeviceSignature(new Uint8Array(3), utf8("x"), new Uint8Array(3)), false);
  assert.equal(
    await verifyDeviceSignature(bytes(a.public_key_spki_b64url), utf8(a.canonical), new Uint8Array(0)),
    false,
  );
});

Deno.test("the on-curve check agrees with WebCrypto for 25 freshly generated keys", async () => {
  for (let i = 0; i < 25; i++) {
    const kp = await crypto.subtle.generateKey({ name: "ECDSA", namedCurve: "P-256" }, true, ["sign"]);
    const spki = new Uint8Array(await crypto.subtle.exportKey("spki", kp.publicKey));
    assert.ok(pointIsOnP256(spki));
    const bent = spki.slice();
    bent[60] ^= 1;
    assert.equal(pointIsOnP256(bent), false);
  }
  // x or y at or above the field prime is refused even when the equation happens to balance mod p.
  const spki = new Uint8Array(91);
  spki.set(bytes((await loadVectors())[0].public_key_spki_b64url).subarray(0, 27));
  spki.fill(0xff, 27);
  assert.equal(pointIsOnP256(spki), false);
});
