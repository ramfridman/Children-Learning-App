// The active devices of the caller's own family. Parent devices only.
import type { FunctionSpec } from "../_shared/handler.ts";

export const spec: FunctionSpec = {
  name: "device-list",
  access: { kind: "device", roles: ["parent"] },
  shape: {},
  run: async (ctx) => {
    const { device } = ctx.auth!;
    const rows = await ctx.svc.store.listActiveDevices(device.familyId);
    return {
      devices: rows.map((d) => ({
        id: d.id,
        role: d.role,
        platform: d.platform,
        security_level: d.securityLevel,
        created_at: d.createdAt.getTime(),
        last_seen_at: d.lastSeenAt ? d.lastSeenAt.getTime() : null,
        this_device: d.id === device.id,
      })),
    };
  },
};
