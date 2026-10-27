// A parent's phone takes itself off the push list (the "Alerts on this phone" switch turned off). It affects only the
// phone that asks; a phone without a token is fine.
import type { FunctionSpec } from "../_shared/handler.ts";

export const spec: FunctionSpec = {
  name: "push-token-remove",
  access: { kind: "device", roles: ["parent"] },
  shape: {},
  run: async (ctx) => {
    await ctx.svc.store.removePushToken(ctx.auth!.device.id);
    return { ok: true };
  },
};
