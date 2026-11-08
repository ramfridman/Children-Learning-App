// The first (or an additional) parent device: a freshly signed-in guardian proves, with the
// challenge, that a genuine phone holds this signing key. Replaces an old device on request.
import { authenticatePreEnrolment } from "../_shared/auth.ts";
import { b64urlDecode } from "../_shared/b64.ts";
import { enrolFields, proveDevice } from "../_shared/enrol.ts";
import { GatewayError } from "../_shared/errors.ts";
import type { FunctionSpec } from "../_shared/handler.ts";
import { signedInByCodeRecently } from "../_shared/token.ts";

export const spec: FunctionSpec = {
  name: "device-enroll",
  access: { kind: "token" },
  shape: { ...enrolFields, replace_device_id: { t: "uuid", optional: true } },
  run: async (ctx) => {
    const { svc, body } = ctx;
    const userId = ctx.userId!;
    const now = svc.nowMs();

    // 1. The caller holds the private key for the public key they are asking us to trust.
    await authenticatePreEnrolment(
      ctx.req,
      "device-enroll",
      ctx.raw,
      b64urlDecode(body.public_key as string)!,
      svc,
    );

    // 2. A sign-in by emailed code in the last 10 minutes, so neither an old stolen token, nor a refresh, nor a
    //    password someone else set can add a device.
    if (!signedInByCodeRecently(ctx.amr, now)) {
      throw new GatewayError("unauthorized", "stale_sign_in");
    }

    // 3. The challenge is ours, was issued to this user, and is burned by this attempt.
    const challenge = b64urlDecode(body.challenge as string)!;
    if (!(await svc.store.consumeChallenge({ challenge, purpose: "enroll", userId }))) {
      throw new GatewayError("unauthorized", "challenge_invalid");
    }

    // 4. Genuine hardware (or the local-stack allowlist).
    const p = await proveDevice(svc, body);

    // 5. Record it.
    const r = await svc.store.enrolParentDevice({
      userId,
      replaceDeviceId: (body.replace_device_id as string | undefined) ?? null,
      publicKey: p.publicKey,
      platform: p.platform,
      attestationKind: p.kind,
      securityLevel: p.level,
      appVersion: p.appVersion,
    });
    if (!r.ok) {
      if (r.reason === "device_limit") throw new GatewayError("device_limit", "device_limit");
      if (r.reason === "key_in_use") throw new GatewayError("device_limit", "key_in_use");
      throw new GatewayError("not_found", "no_such_device");
    }
    return { device_id: r.deviceId, role: "parent", security_level: p.level };
  },
};
