// A device asks for everything that happened after the last event it saw. The cursor is the server's own number, so a
// device's clock never decides what is sent. The answer also carries the family's children (with their nicknames) and
// the children that were deleted, so that every device ends up with the same family.
import type { FunctionSpec } from "../_shared/handler.ts";

export const PULL_LIMIT = 100;

export const spec: FunctionSpec = {
  name: "sync-pull",
  access: { kind: "device", roles: ["parent", "child"] },
  shape: {
    after: { t: "int", min: 0, max: Number.MAX_SAFE_INTEGER },
    limit: { t: "int", min: 1, max: PULL_LIMIT },
  },
  run: async (ctx) => {
    const { device } = ctx.auth!;
    const after = ctx.body.after as number;
    const limit = ctx.body.limit as number;
    const [page, children, tombstones] = await Promise.all([
      ctx.svc.store.pullEvents(device.familyId, after, limit),
      ctx.svc.store.listChildren(device.familyId),
      ctx.svc.store.listTombstones(device.familyId),
    ]);
    const last = page.events.length > 0 ? page.events[page.events.length - 1].seq : after;
    return {
      events: page.events.map((e) => ({
        seq: e.seq,
        id: e.id,
        child_id: e.childId,
        device_id: e.deviceId,
        at: e.clientAtMs,
        engine: e.engineVersion,
        type: e.type,
        data: e.payload,
      })),
      more: page.more,
      next: last,
      children: children.map((c) => ({
        id: c.id,
        nickname: c.nickname,
        avatar_id: c.avatarId,
        companion_id: c.companionId,
        address_form: c.addressForm,
        age_band: c.ageBand,
      })),
      tombstones,
    };
  },
};
