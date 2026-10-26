// ECDSA signature verification on P-256 and P-384 over an already-computed hash, using the audited
// `@noble/curves` library (Paul Miller; MIT; no install scripts; one dependency, `@noble/hashes`).
//
// Why this exists: the Edge runtime's WebCrypto only accepts P-256 with SHA-256 and P-384 with
// SHA-384. Google's attestation chains contain certificates signed with SHA-256 by a P-384 key, so
// the runtime refuses links of a perfectly valid chain. `attest/cert_sig.ts` calls this only after
// WebCrypto has thrown. It verifies, it never signs, and it only ever sees public values.

import { p256, p384 } from "npm:@noble/curves@2.0.1/nist.js";

export type CurveName = "P-256" | "P-384";

const CURVES = { "P-256": { curve: p256, size: 32 }, "P-384": { curve: p384, size: 48 } } as const;

/**
 * Verifies an ECDSA signature over an already-computed hash.
 *
 * @param publicPoint the public key as an uncompressed point: 0x04 ‖ X ‖ Y
 * @param digest the hash of the signed data (any length: the library cuts it to the curve's size)
 * @param signature DER encoded, as in certificates
 *
 * Never throws: anything malformed, off the curve or out of range is simply "not valid". High-S
 * signatures are accepted, because certificates are not covered by the malleability rule.
 */
export function ecdsaVerifyDigest(
  curve: CurveName,
  publicPoint: Uint8Array,
  digest: Uint8Array,
  signature: Uint8Array,
): boolean {
  const c = CURVES[curve];
  if (publicPoint.length !== 1 + 2 * c.size || publicPoint[0] !== 4) return false;
  try {
    return c.curve.verify(signature, digest, publicPoint, { prehash: false, format: "der", lowS: false });
  } catch {
    return false;
  }
}
