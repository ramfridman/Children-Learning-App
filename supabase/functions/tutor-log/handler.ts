// What the AI helper said to the family's children in the last 30 days, newest first (at most 100 lines), so that a parent
// can read it. Parent devices only.
import type { FunctionSpec } from "../_shared/handler.ts";

export const KEEP_MS = 30 * 86_400_000;
export const MAX_LINES = 100;

export const spec: FunctionSpec = {
  name: "tutor-log",
  access: { kind: "device", roles: ["parent"] },
  shape: {},
  run: async (ctx) => {
    const rows = await ctx.svc.store.tutorLogOf(
      ctx.auth!.device.familyId,
      ctx.svc.nowMs() - KEEP_MS,
      MAX_LINES,
    );
    return {
      entries: rows.map((r) => ({
        at: r.atMs,
        child_id: r.childRef,
        item_id: r.itemId,
        character_id: r.characterId,
        source: r.source,
        outcome: r.outcome,
        line: r.line,
      })),
    };
  },
};
