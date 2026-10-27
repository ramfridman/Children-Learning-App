// A parent has seen the family's alerts: every unread one is marked read. Parent devices only.
import type { FunctionSpec } from "../_shared/handler.ts";

export const spec: FunctionSpec = {
  name: "alert-read",
  access: { kind: "device", roles: ["parent"] },
  shape: {},
  run: async (ctx) => ({
    marked: await ctx.svc.store.markAlertsRead(ctx.auth!.device.familyId, ctx.svc.nowMs()),
  }),
};
