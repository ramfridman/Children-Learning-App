// A parent revokes one device of their own family. Its signed requests stop working at once.
import { GatewayError } from "../_shared/errors.ts";
import type { FunctionSpec } from "../_shared/handler.ts";

export const spec: FunctionSpec = {
  name: "device-revoke",
  access: { kind: "device", roles: ["parent"] },
  shape: { device_id: { t: "uuid" } },
  run: async (ctx) => {
    const { device } = ctx.auth!;
    const target = ctx.body.device_id as string;
    if (target === device.id) throw new GatewayError("bad_request", "cannot_revoke_self");
    // The family comes from the caller's own device, never from the request, so another family's
    // device id is simply "not found".
    if (!(await ctx.svc.store.revokeDevice(device.familyId, target, "parent"))) {
      throw new GatewayError("not_found", "no_such_device");
    }
    return { revoked: true };
  },
};
