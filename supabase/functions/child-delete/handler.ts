// Deletes a child: the profile, every event, alert and tutor log line of that child, and the daily counter, in one
// database transaction, leaving only a tombstone (an id) so that every other device deletes its local data too.
// Parent devices only. Deleting twice is harmless.
import type { FunctionSpec } from "../_shared/handler.ts";
import { CHILD_ID } from "../child-put/handler.ts";

export const spec: FunctionSpec = {
  name: "child-delete",
  access: { kind: "device", roles: ["parent"] },
  shape: { child_id: { t: "string", max: 64, pattern: CHILD_ID } },
  run: async (ctx) => {
    await ctx.svc.store.deleteChild(ctx.auth!.device.familyId, ctx.body.child_id as string);
    return { ok: true };
  },
};
