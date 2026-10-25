import { assert } from "./testassert.ts";
import { b64urlDecode, b64urlEncode, sha256B64url } from "./b64.ts";
import { utf8 } from "./testutil.ts";

Deno.test("base64url round-trips every length and uses the URL alphabet", () => {
  for (let n = 0; n < 40; n++) {
    const data = crypto.getRandomValues(new Uint8Array(n));
    const text = b64urlEncode(data);
    assert.match(text, /^[A-Za-z0-9_-]*$/);
    assert.deepEqual(b64urlDecode(text), data);
  }
  assert.equal(b64urlEncode(Uint8Array.from([0xfb, 0xff, 0xfe])), "-__-");
});

Deno.test("base64url refuses padding, the wrong alphabet, impossible lengths and non-canonical tails", () => {
  for (const bad of ["AA==", "A+A=", "A/A", "A", "AAAAA", "AB", " AA", "AA\n", "é"]) {
    assert.equal(b64urlDecode(bad), null, JSON.stringify(bad));
  }
});

Deno.test("sha256 is the known value for an empty body", async () => {
  assert.equal(await sha256B64url(utf8("")), "47DEQpj8HBSa-_TImW-5JCeuQeRkm5NMpJWZG3hSuFU");
});
