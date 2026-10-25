// Proves the whole chain (token, device signature, nonce, family, role) end to end. Does nothing else.
import type { FunctionSpec } from "../_shared/handler.ts";

export const spec: FunctionSpec = {
  name: "signed-ping",
  access: { kind: "device", roles: ["parent", "child"] },
  shape: {},
  run: (ctx) => Promise.resolve({ ok: true, role: ctx.auth!.device.role, server_time: ctx.svc.nowMs() }),
};
