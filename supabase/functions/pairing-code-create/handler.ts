// A parent device asks for a 6-digit code to pair a child device. The code lives 10 minutes
// (9 here, for the same clock-drift reason as challenges) and is stored only as a keyed hash.
import { GatewayError } from "../_shared/errors.ts";
import { type FunctionSpec, hourStart } from "../_shared/handler.ts";
import { hashPairingCode, sixDigitCode } from "../_shared/keyed.ts";

export const CODE_SECONDS = 540;
export const CODES_PER_HOUR = 5;

export const spec: FunctionSpec = {
  name: "pairing-code-create",
  access: { kind: "device", roles: ["parent"] },
  shape: {},
  run: async (ctx) => {
    const { device } = ctx.auth!;
    const now = ctx.svc.nowMs();
    if (
      !(await ctx.svc.store.rateLimitHit("pairing_code", device.familyId, hourStart(now), CODES_PER_HOUR))
    ) {
      throw new GatewayError("rate_limited", "pairing_code_rate");
    }
    const expiresAt = new Date(now + CODE_SECONDS * 1000);
    for (let attempt = 0; attempt < 5; attempt++) {
      const code = sixDigitCode(ctx.svc.randomBytes);
      const codeHash = await hashPairingCode(ctx.svc.secrets.pairingCodeKey, code);
      if (
        await ctx.svc.store.insertPairingCode({
          familyId: device.familyId,
          byDevice: device.id,
          codeHash,
          expiresAt,
        })
      ) {
        return { code, expires_at: expiresAt.getTime() };
      }
    }
    throw new GatewayError("unavailable", "pairing_code_collision");
  },
};
