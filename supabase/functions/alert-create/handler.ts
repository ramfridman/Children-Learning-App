// A device tells the family's parents about something worth knowing (an alert found on the device). The alert is
// saved once (the same key is the same alert), and the parents' phones get one push that says only that there is a new
// alert. The child's words are in the alert only when the parent allowed keeping them; the device decides that.
import { GatewayError } from "../_shared/errors.ts";
import { notifyParents } from "../_shared/fcm.ts";
import type { FunctionSpec } from "../_shared/handler.ts";
import { CHILD_ID } from "../child-put/handler.ts";

export const ALERTS_PER_HOUR_PER_DEVICE = 300;

export const CATEGORIES = [
  "pastLimit",
  "restHours",
  "gateAttempts",
  "guessing",
  "frustration",
  "inappropriateWords",
  "disclosure",
  "absence",
] as const;

interface Body {
  child_id?: string;
  category: (typeof CATEGORIES)[number];
  severity: "info" | "attention" | "important";
  count: number;
  detail?: string;
  words?: string;
  key: string;
  at: number;
}

export const spec: FunctionSpec = {
  name: "alert-create",
  access: { kind: "device", roles: ["parent", "child"] },
  shape: {
    child_id: { t: "string", max: 64, pattern: CHILD_ID, optional: true },
    category: { t: "enum", values: CATEGORIES },
    severity: { t: "enum", values: ["info", "attention", "important"] },
    count: { t: "int", min: 0, max: 100_000 },
    detail: { t: "string", max: 80, pattern: /^[A-Za-z0-9._:=-]*$/, optional: true },
    words: { t: "string", max: 200, pattern: /^[֐-׿A-Za-z0-9 .,?!'"-]*$/, optional: true },
    key: { t: "string", max: 120, pattern: /^[A-Za-z0-9._:=-]{1,120}$/ },
    at: { t: "int", min: 1_500_000_000_000, max: 4_100_000_000_000 },
  },
  run: async (ctx) => {
    const { device } = ctx.auth!;
    const b = ctx.body as unknown as Body;
    // An alert about a child names the child; only one about the parent gate does not.
    if (b.category !== "gateAttempts" && b.child_id === undefined) {
      throw new GatewayError("bad_request", "child_missing");
    }
    // The child's words belong only to the two alerts that are about what was said.
    if (b.words && b.category !== "inappropriateWords" && b.category !== "disclosure") {
      throw new GatewayError("bad_request", "words_not_allowed");
    }
    const hour = new Date(Math.floor(ctx.svc.nowMs() / 3_600_000) * 3_600_000);
    if (!(await ctx.svc.store.rateLimitHit("alert_create", device.id, hour, ALERTS_PER_HOUR_PER_DEVICE))) {
      throw new GatewayError("rate_limited", "alert_create");
    }
    const status = await ctx.svc.store.insertAlert(device.familyId, device.id, {
      childId: b.child_id ?? null,
      category: b.category,
      severity: b.severity,
      count: b.count,
      detail: b.detail ?? "",
      words: b.words ?? "",
      key: b.key,
      clientAtMs: b.at,
    });
    // One push, with a fixed phrase, only for an alert that is new.
    if (status === "new") await notifyParents(ctx.svc.push, ctx.svc.store, device.familyId, device.id);
    return { status };
  },
};
