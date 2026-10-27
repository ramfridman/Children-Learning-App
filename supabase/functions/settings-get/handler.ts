// The family's rules as the parents last set them, and their version. Child devices read them too: the limits are
// kept on the child's device. `rules` is null until a parent has set any.
import type { FunctionSpec } from "../_shared/handler.ts";

export const spec: FunctionSpec = {
  name: "settings-get",
  access: { kind: "device", roles: ["parent", "child"] },
  shape: {},
  run: async (ctx) => {
    const s = await ctx.svc.store.getSettings(ctx.auth!.device.familyId);
    return s ? { rules: s.rules, version: s.version } : { rules: null, version: 0 };
  },
};
