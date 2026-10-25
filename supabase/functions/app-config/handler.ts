// Kill switches and settings the app reads on start. Anything not explicitly switched on is off,
// so a missing row can never turn an AI feature on by accident.
import type { FunctionSpec } from "../_shared/handler.ts";

export const SWITCHES = ["tutor_enabled", "voice_enabled"] as const;

export const spec: FunctionSpec = {
  name: "app-config",
  access: { kind: "device", roles: ["parent", "child"] },
  shape: {},
  run: async (ctx) => {
    const out: Record<string, unknown> = { server_time: ctx.svc.nowMs() };
    for (const key of SWITCHES) out[key] = (await ctx.svc.store.getConfig(key)) === true;
    return out;
  },
};
