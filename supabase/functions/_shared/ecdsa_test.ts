import { assert } from "./testassert.ts";
import { type CurveName, ecdsaVerifyDigest } from "./ecdsa.ts";

// Fixed vectors made with OpenSSL (Node's crypto): public point, hash of "vector <curve> <hash>",
// and the DER signature. They include the pairing WebCrypto in the Edge runtime refuses (P-384 key,
// SHA-256 hash), which is why this verifier exists.
const VECTORS: { curve: CurveName; hash: string; point: string; digest: string; sig: string }[] = [
  { curve: "P-384", hash: "sha256", point: "0441052b82b1e7eeec6d22d5cbd168f619625675658587487b03af39ab15a3d2b1749f28c6ffed5c097e49c3ae850d83c40d0fed2b162008601dd7a713fbf66ede691cf308694641d516a72d84b825ab54c45437e455d3a04f42bace19cf6b5ed3", digest: "3164ff388b204cb18e236f82fe508c333a6429088c7c0818e0c072cd60c18432", sig: "3064023038eecbe936202d1f8a7ac4c0865f6613c53d75f0c45fc8690b5f014b41d121c23329e1f11b524c25cbaf2f6839f2cda80230128d78c148de37f8e703d339c96fe6d16d569261971517b19c8c129a96bb3cd2846ed5e1693396cfe25f15ebafb074d9" },
  { curve: "P-384", hash: "sha384", point: "046c3fc75fc44fd84449092fc845b167ab728cc309a7f55535d82155f24f394f3cd6d4c90bd47c5bc12759ebffa7071e87bb53bbd073816f86d73d5fef675fbd9d82a4389fea7d143a148623a961f3e1f2e5f11a2b94f050ff0ab2b75595f8e618", digest: "913e462d240ac5a8a394e86a6aa84d996296f58638446ab6739c3dab2e4c49de1927ee9d85a86cd41d9eee64d652e0eb", sig: "306402300b73976795a4c701e8e0cb83c6992db637b17ee62f15345037103f480b3d004fa18e739061dd8bdbffda7976f66885c50230061fb0e169776793d9ff1fc9c700e63f44c089a42324676a08787dd03b74d04f3bf90eef7b50ded786ce92319907175b" },
  { curve: "P-384", hash: "sha512", point: "04978591c3343c434aacaf1429c036cb1c1b8308ca6523f7d20f422d3df3a08282f7de769f9f92488f6a0d1847261455a1a868a54ae34c7c761fa94e7062153bfb8ae0b7d7ae5bdd23b51c39069314622a617b992024df4066e77ee7c866259a66", digest: "c5ce3d26aab235213bf60f770b5c0afc7e4a6cd4d83a2eadd1cfc5d8bd33d2484cee2958b4c0029c3904108d15a932119053c240cb5fa202c702ea7dc073a2e4", sig: "3066023100d5144debcec865072dad749e6a608fedf8a52ea8254da2a7c92bff2d6a2d80d07007389aec384ad24237382c30353cca023100dfc421737237b736619966568f571f1a43cba570d53792bc9c3951c7dff1430f591f20c8588157b71b754222f9646d6d" },
  { curve: "P-256", hash: "sha256", point: "042e8e5fe2b51ce61c0906b60305560b93cad0d55dc872ce79263a89700569e0d0e8b8bca8c4ddd838644cd9617d69343f6f7a64ecf9c7db3e898ae3f6a0608018", digest: "9b0b09bb849e6dbc1dda9c49d7f664490721b92d0ccfe54e7638bf9526f17b3d", sig: "3045022100ad86dc6f76bab9e9ef2cd5b0dbfa8d4cd09bf73680cdf503ff8a8bf5e69a683002201e54570a4f92821be98e0cb72a643e6da2e6c77c4ae69e1e878b3bb9b3f133ae" },
  { curve: "P-256", hash: "sha384", point: "046d1bcc95527bd2bf0ac49d1d557cf104a1ccc844e13dece43429de3a31e499827f71d3c8b28c0df5effb0d0e605862792273741cbee3894ea1c542b5397b2e2a", digest: "6f03abe75ba2b129aa57cc277fd7e0ff32efde758b2a88f9c9f2a8030bbf52245f2a086d2006108a433e8e5bcc343d12", sig: "3044022017730021e1266406187b9e79f27e2bba27a48c752ddbf9176113b21ca38700a802207d5c50744e11c306c78fc54df77d823ffc27e7fc3e060376363f357b111c235a" },
];

const unhex = (h: string) => Uint8Array.from(h.match(/../g)!.map((x) => parseInt(x, 16)));

for (const v of VECTORS) {
  Deno.test(`ecdsa ${v.curve} ${v.hash}: a real signature verifies, tampering does not`, () => {
    const point = unhex(v.point);
    const digest = unhex(v.digest);
    const sig = unhex(v.sig);
    assert.ok(ecdsaVerifyDigest(v.curve, point, digest, sig));

    const badDigest = digest.slice();
    badDigest[0] ^= 1;
    assert.ok(!ecdsaVerifyDigest(v.curve, point, badDigest, sig));

    const badSig = sig.slice();
    badSig[badSig.length - 1] ^= 1;
    assert.ok(!ecdsaVerifyDigest(v.curve, point, digest, badSig));

    const offCurve = point.slice();
    offCurve[offCurve.length - 1] ^= 1;
    assert.ok(!ecdsaVerifyDigest(v.curve, offCurve, digest, sig));

    // A public key from another vector (same curve) must not verify this signature.
    const other = VECTORS.find((o) => o.curve === v.curve && o.point !== v.point)!;
    assert.ok(!ecdsaVerifyDigest(v.curve, unhex(other.point), digest, sig));
  });
}

Deno.test("ecdsa: malformed inputs are refused, never thrown", () => {
  const v = VECTORS[0];
  const point = unhex(v.point);
  const digest = unhex(v.digest);
  const sig = unhex(v.sig);
  assert.ok(!ecdsaVerifyDigest(v.curve, point, digest, new Uint8Array(0)));
  assert.ok(!ecdsaVerifyDigest(v.curve, point, digest, new Uint8Array(96))); // not DER
  assert.ok(!ecdsaVerifyDigest(v.curve, point, digest, sig.subarray(0, sig.length - 1)));
  assert.ok(!ecdsaVerifyDigest(v.curve, point.subarray(0, 50), digest, sig));
  const compressed = point.slice();
  compressed[0] = 2;
  assert.ok(!ecdsaVerifyDigest(v.curve, compressed, digest, sig));
  // r = 0 and s = 0 as DER: 30 06 02 01 00 02 01 00
  assert.ok(!ecdsaVerifyDigest(v.curve, point, digest, unhex("3006020100020100")));
  // r = n (out of range) on P-384, s = 1
  const n384 =
    "ffffffffffffffffffffffffffffffffffffffffffffffffc7634d81f4372ddf581a0db248b0a77aecec196accc52973";
  assert.ok(!ecdsaVerifyDigest("P-384", point, digest, unhex(`3036023100${n384}020101`)));
});

function rawToDer(raw: Uint8Array): Uint8Array {
  const half = raw.length / 2;
  const int = (b: Uint8Array) => {
    let i = 0;
    while (i < b.length - 1 && b[i] === 0) i++;
    const body = b[i] & 0x80 ? Uint8Array.from([0, ...b.subarray(i)]) : b.subarray(i);
    return Uint8Array.from([2, body.length, ...body]);
  };
  const r = int(raw.subarray(0, half));
  const s = int(raw.subarray(half));
  return Uint8Array.from([0x30, r.length + s.length, ...r, ...s]);
}

Deno.test("ecdsa agrees with the runtime's own WebCrypto where WebCrypto can do the pairing", async () => {
  const pairs = [["P-256", "SHA-256"], ["P-384", "SHA-384"]] as const;
  for (const [curve, hash] of pairs) {
    for (let i = 0; i < 8; i++) {
      const alg = { name: "ECDSA", namedCurve: curve };
      const kp = await crypto.subtle.generateKey(alg, true, ["sign", "verify"]);
      const msg = crypto.getRandomValues(new Uint8Array(40 + i));
      const raw = new Uint8Array(await crypto.subtle.sign({ name: "ECDSA", hash }, kp.privateKey, msg));
      const point = new Uint8Array(await crypto.subtle.exportKey("raw", kp.publicKey));
      const digest = new Uint8Array(await crypto.subtle.digest(hash, msg));
      assert.ok(ecdsaVerifyDigest(curve, point, digest, rawToDer(raw)), `${curve} ${hash} #${i}`);
      digest[1] ^= 1;
      assert.ok(!ecdsaVerifyDigest(curve, point, digest, rawToDer(raw)));
    }
  }
});
