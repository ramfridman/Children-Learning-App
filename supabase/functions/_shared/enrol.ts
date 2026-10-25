// Shared by device-enroll and device-pair: the request fields every new device sends, and the
// proof that the key belongs to a genuine device (or, in the local stack only, to the allowlist).
import { type AllowedApp, verifyAndroidKeyAttestation } from "./attest/android.ts";
import { b64urlDecode, type Bytes, sha256 } from "./b64.ts";
import { GatewayError } from "./errors.ts";
import type { Services } from "./handler.ts";
import type { Shape } from "./schema.ts";
import { looksLikeP256Spki } from "./sig.ts";

export const enrolFields = {
  challenge: { t: "b64url", minBytes: 32, maxBytes: 32 },
  public_key: { t: "b64url", minBytes: 91, maxBytes: 91 },
  platform: { t: "enum", values: ["android", "ios"] },
  attestation_kind: { t: "enum", values: ["key_attestation", "app_attest", "dev_allowlist"] },
  chain: { t: "array", of: { t: "b64url", minBytes: 100, maxBytes: 4096 }, maxItems: 6, optional: true },
  dev_secret: { t: "string", max: 128, pattern: /^[A-Za-z0-9_-]{16,128}$/, optional: true },
  app_version: { t: "string", max: 40, pattern: /^[0-9A-Za-z._+-]{1,40}$/, optional: true },
} as const satisfies Shape;

export interface Proven {
  publicKey: Bytes;
  challenge: Bytes;
  platform: "android" | "ios";
  kind: "key_attestation" | "app_attest" | "dev_allowlist";
  level: "strongbox" | "tee" | "secure_enclave" | "dev";
  appVersion: string | null;
}

const refuse = (reason: string) => new GatewayError("forbidden", reason);

async function androidPolicy(svc: Services) {
  const apps = await svc.store.getConfig("android_allowed_apps");
  const ok = Array.isArray(apps) && apps.length > 0 &&
    apps.every((a) =>
      a && typeof a.package_name === "string" && Array.isArray(a.cert_sha256) &&
      a.cert_sha256.every((d: unknown) => typeof d === "string" && /^[0-9a-f]{64}$/.test(d))
    );
  // Fail closed: with no list of our own apps, nothing is accepted.
  if (!ok) throw new GatewayError("unavailable", "android_policy_missing");
  const allowed: AllowedApp[] = apps.map((a: { package_name: string; cert_sha256: string[] }) => ({
    packageName: a.package_name,
    certSha256: a.cert_sha256,
  }));
  const relaxed = (await svc.store.getConfig("android_require_verified_boot")) === false;
  return { apps: allowed, requireVerifiedBoot: !relaxed, rootsPem: svc.androidRootsPem };
}

/** Checks the attestation. The challenge must already have been consumed by the caller. */
export async function proveDevice(svc: Services, body: Record<string, unknown>): Promise<Proven> {
  const publicKey = b64urlDecode(body.public_key as string)!;
  const challenge = b64urlDecode(body.challenge as string)!;
  const platform = body.platform as "android" | "ios";
  const kind = body.attestation_kind as Proven["kind"];
  const appVersion = (body.app_version as string | undefined) ?? null;
  if (!looksLikeP256Spki(publicKey)) throw new GatewayError("bad_request", "public_key_not_p256");
  const done = (level: Proven["level"]): Proven => ({
    publicKey,
    challenge,
    platform,
    kind,
    level,
    appVersion,
  });

  if (kind === "dev_allowlist") {
    if (!svc.allowDevEnrolment) throw refuse("dev_enrolment_off");
    const secret = body.dev_secret as string | undefined;
    if (!secret) throw new GatewayError("bad_request", "dev_secret_missing");
    if (!(await svc.store.devAllowlistHas(await sha256(new TextEncoder().encode(secret) as Bytes)))) {
      throw refuse("dev_secret_unknown");
    }
    return done("dev");
  }
  if (kind === "key_attestation") {
    if (platform !== "android") throw new GatewayError("bad_request", "kind_platform_mismatch");
    const chain = (body.chain as string[] | undefined)?.map((c) => b64urlDecode(c)!);
    if (!chain) throw new GatewayError("bad_request", "chain_missing");
    const r = await verifyAndroidKeyAttestation(
      chain,
      { challenge, publicKeySpki: publicKey },
      await androidPolicy(svc),
      svc.nowMs(),
    );
    if (!r.ok) throw refuse(`attestation_${r.reason}`);
    return done(r.securityLevel);
  }
  // App Attest belongs to the iOS gate.
  if (platform !== "ios") throw new GatewayError("bad_request", "kind_platform_mismatch");
  throw new GatewayError("unavailable", "ios_attestation_pending");
}
