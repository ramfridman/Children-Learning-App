// A child device joins a family with the 6-digit code a parent made. No session exists yet, so
// the call is limited per IP address, and wrong codes are limited three ways: 5 per challenge,
// 20 attempts an hour per address, and a small hourly budget of attempts for the whole service (checked before the code is looked at,
// so guessing cannot continue past it).
import { authenticatePreEnrolment } from "../_shared/auth.ts";
import { b64urlDecode } from "../_shared/b64.ts";
import { enrolFields, proveDevice } from "../_shared/enrol.ts";
import { GatewayError } from "../_shared/errors.ts";
import { type FunctionSpec, hourStart } from "../_shared/handler.ts";
import { hashPairingCode, ipKey } from "../_shared/keyed.ts";

export const TRIES_PER_HOUR_PER_IP = 20;
export const ATTEMPTS_PER_HOUR_GLOBAL = 100;

export const spec: FunctionSpec = {
  name: "device-pair",
  access: { kind: "public" },
  shape: { ...enrolFields, code: { t: "string", max: 6, pattern: /^\d{6}$/ } },
  run: async (ctx) => {
    const { svc, body } = ctx;
    const now = svc.nowMs();
    const window = hourStart(now);

    // 1. The caller holds the private key for the public key they ask us to trust.
    await authenticatePreEnrolment(
      ctx.req,
      "device-pair",
      ctx.raw,
      b64urlDecode(body.public_key as string)!,
      svc,
    );

    // 2. Limits before any work is done.
    const ip = await ipKey(ctx.req, svc.secrets.ipHashKey);
    if (!(await svc.store.rateLimitHit("pair_try", ip.text, window, TRIES_PER_HOUR_PER_IP))) {
      throw new GatewayError("rate_limited", "pair_ip_rate");
    }

    if (!(await svc.store.rateLimitHit("pair_global", "all", window, ATTEMPTS_PER_HOUR_GLOBAL))) {
      throw new GatewayError("rate_limited", "pair_global_rate");
    }

    // 3. Challenge and code. A wrong code adds to the challenge's failed attempts (dead at 5).
    const challenge = b64urlDecode(body.challenge as string)!;
    const codeHash = await hashPairingCode(svc.secrets.pairingCodeKey, body.code as string);
    const peek = await svc.store.pairPeek({ challenge, codeHash });
    if (!peek.ok) {
      throw new GatewayError("unauthorized", peek.reason);
    }

    // 4. Genuine hardware (or the local-stack allowlist), before anything is burned.
    const p = await proveDevice(svc, body);

    // 5. A one-time sign-in for the family's guardian account, then the atomic join.
    const session = await svc.mintSession(peek.guardianUserId);
    const done = await svc.store.pairComplete({
      challenge,
      codeHash,
      publicKey: p.publicKey,
      platform: p.platform,
      attestationKind: p.kind,
      securityLevel: p.level,
      appVersion: p.appVersion,
    });
    if (!done.ok) {
      if (done.reason === "device_limit") throw new GatewayError("device_limit", "device_limit");
      if (done.reason === "key_in_use") throw new GatewayError("device_limit", "key_in_use");
      throw new GatewayError("unauthorized", done.reason);
    }
    return {
      device_id: done.deviceId,
      role: "child",
      security_level: p.level,
      token_hash: session.tokenHash,
    };
  },
};
