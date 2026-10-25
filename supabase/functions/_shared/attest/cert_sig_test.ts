import "npm:reflect-metadata@0.2.2";
import * as x509 from "npm:@peculiar/x509@2.2.0";
import { assert } from "../testassert.ts";
import { certSignedBy, ChainUnsupported } from "./cert_sig.ts";

// Made with OpenSSL: a P-384 root (self-signed) and a P-256 leaf signed by it with ECDSA-SHA256.
// That pairing (P-384 issuer key, SHA-256 hash) is exactly what the Edge runtime's WebCrypto refuses
// and what Google's attestation chains contain, so it must still verify.
const ROOT = `
-----BEGIN CERTIFICATE-----
MIIBxDCCAUqgAwIBAgIUKQDiB6p2V2jwUEuDk0zaUCpHRaQwCgYIKoZIzj0EAwIw
GTEXMBUGA1UEAwwOVGVzdCBSb290IFAzODQwHhcNMjYxMDI1MTczNDUwWhcNMzYx
MDIyMTczNDUwWjAZMRcwFQYDVQQDDA5UZXN0IFJvb3QgUDM4NDB2MBAGByqGSM49
AgEGBSuBBAAiA2IABEBvAUJjL/yDPCBBP2YSTWM4wxrYJwfbMw4TS6EVAC1ozKjH
YWTix0UBma0pPvsYF2SuFbUUCRLIFqyYh5Z+z8GZd3kQRQVI6MxJQOyWSSWQTwfo
h2C1lHvpvKnb0T7udaNTMFEwHQYDVR0OBBYEFCwRpedU15BVBcukKaU1HPvDzCKK
MB8GA1UdIwQYMBaAFCwRpedU15BVBcukKaU1HPvDzCKKMA8GA1UdEwEB/wQFMAMB
Af8wCgYIKoZIzj0EAwIDaAAwZQIwfjMpxO9mmNHt1m4jh8aO7++Jjcf1dlMTso8T
cUyyfukW7jtQyT7No6f8Xpdpv9lpAjEA0koq7sFUIf/xEqgzSLdhrxgZ7cZr5ikS
TOTPc9p6ZjiWveh5qVpLHBnBYkU/61uu
-----END CERTIFICATE-----
`;
const LEAF = `
-----BEGIN CERTIFICATE-----
MIIBkTCCARegAwIBAgIUIo3zjGI3v9VhsC4/BsBQP17L1kQwCgYIKoZIzj0EAwIw
GTEXMBUGA1UEAwwOVGVzdCBSb290IFAzODQwHhcNMjYxMDI1MTczNDUwWhcNMjcx
MDI1MTczNDUwWjAUMRIwEAYDVQQDDAlUZXN0IExlYWYwWTATBgcqhkjOPQIBBggq
hkjOPQMBBwNCAARriRTNjc/OGhuTAyevR8VopRo8Ol7A9R4GtqxyyzcEeI7SD0M2
hYixwE2ewhCXsF/t5rANQf1WfEq2Ihnsg9Qao0IwQDAdBgNVHQ4EFgQUGoECA/WZ
RFDpcm7pB4Hui4bcE2kwHwYDVR0jBBgwFoAULBGl51TXkFUFy6QppTUc+8PMIoow
CgYIKoZIzj0EAwIDaAAwZQIxAKNEZc9XvwMdXuvzK5qeU/qTHrg1hnHUO9NyNwdr
wYvrxqAIEclyqzvo0NpLtXaAZwIwHeZ1ON1x9KWaG70EyGC8HThbX91iYI9a9iic
ix94rh2gIjmy5CMWVs+Za+qUI7dV
-----END CERTIFICATE-----
`;

const root = new x509.X509Certificate(ROOT.trim());
const leaf = new x509.X509Certificate(LEAF.trim());
const when = new Date(leaf.notBefore.getTime() + 86_400_000);

Deno.test("a link signed by a P-384 key with SHA-256 verifies (WebCrypto cannot do this one)", async () => {
  assert.ok(await certSignedBy(leaf, root, 0, when));
});

Deno.test("the same link is rejected for a certificate that did not sign it", async () => {
  // The leaf's own key cannot have signed the leaf (it is signed by the root).
  assert.ok(!(await certSignedBy(leaf, leaf, 0, when)));
  // And the root does not verify against the leaf's key.
  assert.ok(!(await certSignedBy(root, leaf, 0, when)));
});

Deno.test("a tampered certificate is rejected", async () => {
  const der = new Uint8Array(leaf.rawData).slice();
  der[40] ^= 1; // inside the signed part
  let tampered: x509.X509Certificate | undefined;
  try {
    tampered = new x509.X509Certificate(der);
  } catch {
    return; // no longer parses: also a rejection
  }
  let verdict: boolean | "unsupported" = "unsupported";
  try {
    verdict = await certSignedBy(tampered, root, 0, when);
  } catch (e) {
    assert.ok(e instanceof ChainUnsupported || e instanceof Error);
    return;
  }
  assert.ok(verdict === false);
});
