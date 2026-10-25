// Checks that one certificate was signed by another one's key.
//
// WebCrypto in the Edge runtime only accepts P-256 with SHA-256 and P-384 with SHA-384, but
// Google's attestation chains also contain P-384 keys signing with SHA-256. When WebCrypto
// refuses a link, an ECDSA link on P-256 or P-384 is checked with our own verifier (../ecdsa.ts).
// Anything else the runtime cannot do is reported by name, so the log says what to add.
import type * as x509 from "npm:@peculiar/x509@2.2.0";
import { type CurveName, ecdsaVerifyDigest } from "../ecdsa.ts";
import type { Bytes } from "../b64.ts";
import { readTlv } from "../der.ts";

export class ChainUnsupported extends Error {}

const CURVE_BYTES: Record<CurveName, number> = { "P-256": 32, "P-384": 48 };
const HASHES = new Set(["SHA-256", "SHA-384", "SHA-512"]);

type KeyAlg = { name?: string; namedCurve?: string; modulusLength?: number };
type SigAlg = { hash?: { name?: string } };

/**
 * A compact, public description of how `cert` is verified by `issuer`'s key, for the log:
 * key type and size ("ec384", "rsa4096") then the hash ("h256").
 */
export function algTag(cert: x509.X509Certificate, issuer: x509.X509Certificate): string {
  try {
    const k = issuer.publicKey.algorithm as KeyAlg;
    const kind = (k.name ?? "").toLowerCase().startsWith("ec") ? "ec" : "rsa";
    const size = k.namedCurve ?? String(k.modulusLength ?? "");
    const h = (cert.signatureAlgorithm as SigAlg).hash?.name ?? "";
    return `${kind}${size.replace(/\D/g, "")}h${h.replace(/\D/g, "")}`;
  } catch {
    return "unknown";
  }
}

/** The signed part of a certificate (tbsCertificate): the first element inside the outer SEQUENCE. */
function tbsOf(cert: x509.X509Certificate): Bytes {
  const outer = readTlv(new Uint8Array(cert.rawData), 0);
  return outer.value.slice(0, readTlv(outer.value, 0).end) as Bytes;
}

/** Our own check for an ECDSA link WebCrypto refused; null if this link is not one we can do. */
async function verifyEcdsaLink(cert: x509.X509Certificate, issuer: x509.X509Certificate) {
  const k = issuer.publicKey.algorithm as KeyAlg;
  const hash = (cert.signatureAlgorithm as SigAlg).hash?.name;
  if (k.name !== "ECDSA" || !hash || !HASHES.has(hash)) return null;
  const curve = k.namedCurve as CurveName;
  const size = CURVE_BYTES[curve];
  if (!size) return null;
  const spki = new Uint8Array(issuer.publicKey.rawData);
  const point = spki.subarray(spki.length - (1 + 2 * size));
  const digest = new Uint8Array(await crypto.subtle.digest(hash, tbsOf(cert)));
  return ecdsaVerifyDigest(curve, point, digest, new Uint8Array(cert.signature));
}

/** True/false for a checked signature; throws ChainUnsupported (with a log label) if it cannot be checked. */
export async function certSignedBy(
  cert: x509.X509Certificate,
  issuer: x509.X509Certificate,
  position: number,
  now: Date,
): Promise<boolean> {
  try {
    return await cert.verify({ publicKey: issuer, date: now });
  } catch {
    // WebCrypto refused this pairing; fall through to our own check where there is one.
  }
  let own: boolean | null = null;
  try {
    own = await verifyEcdsaLink(cert, issuer);
  } catch {
    own = null;
  }
  if (own === null) throw new ChainUnsupported(`chain_alg_${position}_${algTag(cert, issuer)}`);
  return own;
}
