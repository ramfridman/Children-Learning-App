// A parent's phone gives the server its push address, so that it can be told there is a new alert. Parent devices only;
// a child device never receives pushes. A new token replaces the phone's old one.
import type { FunctionSpec } from "../_shared/handler.ts";

export const spec: FunctionSpec = {
  name: "push-token-register",
  access: { kind: "device", roles: ["parent"] },
  shape: {
    token: { t: "string", max: 4096, pattern: /^[A-Za-z0-9_:.-]{20,4096}$/ },
    platform: { t: "enum", values: ["android", "ios"] },
  },
  run: async (ctx) => {
    const { device } = ctx.auth!;
    await ctx.svc.store.upsertPushToken(
      device.familyId,
      device.id,
      ctx.body.token as string,
      ctx.body.platform as "android" | "ios",
    );
    return { ok: true };
  },
};
