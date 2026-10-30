// The family's alerts of the last 30 days, newest first. Parent devices only. The child's words come only while the
// family keeps them (SEC-28).
import type { FunctionSpec } from "../_shared/handler.ts";

export const KEEP_MS = 30 * 86_400_000;

export const spec: FunctionSpec = {
  name: "alert-list",
  access: { kind: "device", roles: ["parent"] },
  shape: {},
  run: async (ctx) => {
    const familyId = ctx.auth!.device.familyId;
    const keepWords = (await ctx.svc.store.getSettings(familyId))?.rules.keepWords !== false;
    const rows = await ctx.svc.store.listAlerts(familyId, ctx.svc.nowMs() - KEEP_MS);
    return {
      alerts: rows.map((a) => ({
        id: a.id,
        child_id: a.childId,
        category: a.category,
        severity: a.severity,
        count: a.count,
        detail: a.detail,
        words: keepWords ? a.words : "",
        key: a.key,
        at: a.clientAtMs,
        read_at: a.readAtMs,
      })),
    };
  },
};
