// Android Key Attestation: proves the P-256 signing key was made inside this phone's secure
// hardware (TEE or StrongBox), by an unmodified, locked device, for our app, and for this one
// enrolment (the challenge). Works for sideloaded builds and needs no Google service.
//
// Not yet checked here: Google's revocation list for individual attestation keys
// (https://android.googleapis.com/attestation/status). Tracked in docs/PLAN.md.
import "reflect-metadata";
import * as x509 from "@peculiar/x509";
import { type Bytes, sha256 } from "../b64.ts";
import { children, DerError, expect, readTlv, smallInt, type Tlv } from "../der.ts";
import { GOOGLE_ATTESTATION_ROOTS } from "../trust/google_roots.ts";

export const KEY_DESCRIPTION_OID = "1.3.6.1.4.1.11129.2.1.17";
export const MAX_CHAIN = 6;

export interface AllowedApp {
  /** Android package name, e.g. "com.example.nitznutz" */
  packageName: string;
  /** Lower-case hex SHA-256 of each signing certificate allowed for that package. */
  certSha256: string[];
}

export interface AndroidPolicy {
  apps: AllowedApp[];
  /** Require a locked bootloader and verified boot (true outside lab devices). */
  requireVerifiedBoot: boolean;
  /** Trusted roots; PEM strings. Defaults to Google's published roots. */
  rootsPem?: readonly string[];
}

export type AttestResult =
  | { ok: true; securityLevel: "tee" | "strongbox"; packageName: string }
  | { ok: false; reason: string };

const fail = (reason: string): AttestResult => ({ ok: false, reason });
const hex = (b: Uint8Array) => [...b].map((x) => x.toString(16).padStart(2, "0")).join("");
const eq = (a: Uint8Array, b: Uint8Array) => a.length === b.length && a.every((x, i) => x === b[i]);

function findTag(list: Tlv[], tag: number): Tlv | undefined {
  return list.find((t) => t.cls === 2 && t.tag === tag);
}

/** The inner element of an explicit context tag such as [702] INTEGER. */
function inner(t: Tlv): Tlv {
  return readTlv(t.value, 0);
}

async function verifyChain(certs: x509.X509Certificate[], roots: x509.X509Certificate[], now: Date) {
  for (let i = 0; i < certs.length; i++) {
    const c = certs[i];
    if (now < c.notBefore || now > c.notAfter) return "cert_not_valid_now";
    if (i > 0) {
      const bc = c.getExtension(x509.BasicConstraintsExtension);
      if (!bc || !bc.ca) return "issuer_not_ca";
    }
  }
  for (let i = 0; i < certs.length - 1; i++) {
    if (!(await certs[i].verify({ publicKey: certs[i + 1], date: now }))) return "bad_chain_signature";
  }
  const top = certs[certs.length - 1];
  for (const root of roots) {
    if (now < root.notBefore || now > root.notAfter) continue;
    if (eq(new Uint8Array(top.rawData), new Uint8Array(root.rawData))) return null;
    if (await top.verify({ publicKey: root, date: now })) return null;
  }
  return "untrusted_root";
}

export async function verifyAndroidKeyAttestation(
  chainDer: Uint8Array[],
  expected: { challenge: Uint8Array; publicKeySpki: Uint8Array },
  policy: AndroidPolicy,
  nowMs: number,
): Promise<AttestResult> {
  try {
    if (chainDer.length < 2 || chainDer.length > MAX_CHAIN) return fail("chain_length");
    const certs = chainDer.map((d) => new x509.X509Certificate(d as Bytes));
    const roots = (policy.rootsPem ?? GOOGLE_ATTESTATION_ROOTS.map((r) => r.pem)).map((p) =>
      new x509.X509Certificate(p)
    );
    const chainProblem = await verifyChain(certs, roots, new Date(nowMs));
    if (chainProblem) return fail(chainProblem);

    // The attested key must be the very key that will sign requests.
    const leaf = certs[0];
    if (!eq(new Uint8Array(leaf.publicKey.rawData), expected.publicKeySpki)) return fail("key_mismatch");

    const ext = leaf.getExtension(KEY_DESCRIPTION_OID);
    if (!ext) return fail("no_attestation_extension");
    const kd = expect(readTlv(new Uint8Array(ext.value), 0), 0, 16, "KeyDescription");
    const f = children(kd.value);
    if (f.length < 8) return fail("short_key_description");
    const attestationVersion = smallInt(f[0]);
    const attestationLevel = smallInt(f[1]);
    const keyMintLevel = smallInt(f[3]);
    const challenge = expect(f[4], 0, 4, "challenge").value;
    if (attestationVersion < 3) return fail("attestation_too_old");
    if (!eq(challenge, expected.challenge)) return fail("challenge_mismatch");
    if (attestationLevel !== 1 && attestationLevel !== 2) return fail("software_attestation");
    if (keyMintLevel !== attestationLevel) return fail("security_level_mismatch");

    const software = children(expect(f[6], 0, 16, "softwareEnforced").value);
    const hardware = children(expect(f[7], 0, 16, "teeEnforced").value);

    // Properties of the key itself, enforced by the secure hardware.
    const algorithm = findTag(hardware, 2);
    const curve = findTag(hardware, 10);
    const origin = findTag(hardware, 702);
    const purpose = findTag(hardware, 1);
    if (!algorithm || smallInt(inner(algorithm)) !== 3) return fail("not_ec_key");
    if (!curve || smallInt(inner(curve)) !== 1) return fail("not_p256");
    if (!origin || smallInt(inner(origin)) !== 0) return fail("key_not_generated_on_device");
    if (!purpose || !children(inner(purpose).value).some((p) => smallInt(p) === 2)) {
      return fail("no_sign_purpose");
    }

    // The phone's own state.
    if (policy.requireVerifiedBoot) {
      const rot = findTag(hardware, 704);
      if (!rot) return fail("no_root_of_trust");
      const r = children(expect(inner(rot), 0, 16, "RootOfTrust").value);
      const locked = r[1]?.value[0] !== 0;
      const bootState = smallInt(r[2]);
      if (!locked || bootState !== 0) return fail("bootloader_unlocked_or_unverified");
    }

    // Which app made the key: package name and signing certificate.
    const appId = findTag(software, 709) ?? findTag(hardware, 709);
    if (!appId) return fail("no_app_id");
    const aai = children(expect(readTlv(inner(appId).value, 0), 0, 16, "AttestationApplicationId").value);
    const packages = children(expect(aai[0], 0, 17, "package set").value).map((p) => {
      const pi = children(expect(p, 0, 16, "package info").value);
      return new TextDecoder().decode(expect(pi[0], 0, 4, "package name").value);
    });
    const digests = children(expect(aai[1], 0, 17, "digest set").value).map((d) =>
      hex(expect(d, 0, 4, "digest").value)
    );
    if (packages.length !== 1) return fail("multiple_packages");
    const allowed = policy.apps.find((a) => a.packageName === packages[0]);
    if (!allowed) return fail("package_not_allowed");
    if (digests.length === 0 || !digests.every((d) => allowed.certSha256.includes(d))) {
      return fail("signing_cert_not_allowed");
    }

    return {
      ok: true,
      securityLevel: attestationLevel === 2 ? "strongbox" : "tee",
      packageName: packages[0],
    };
  } catch (e) {
    return fail(
      e instanceof DerError
        ? `malformed:${e.message.replace(/[^a-z ]/g, "").replaceAll(" ", "_")}`
        : "malformed",
    );
  }
}

/** SHA-256 of a signing certificate, as the lower-case hex used in AllowedApp. */
export async function certDigestHex(certDer: Uint8Array): Promise<string> {
  return hex(await sha256(certDer as Bytes));
}
