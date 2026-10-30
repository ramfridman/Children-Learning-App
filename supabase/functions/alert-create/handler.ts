// A device tells the family's parents about something worth knowing (an alert found on the device). The alert is
// saved once (the same key is the same alert), and the parents' phones get one push that says only that there is a new
// alert, except for the two quiet word alerts (a check, and the weekly note of swearing), which are in the app only. A
// word alert said again is sent again with a higher count: the family keeps the higher count, with no second push. The
// child's words are kept only when the family keeps them: the device leaves them out when its parent said no, and the
// server drops them when the family's rules say no (SEC-28, decided inside the insert itself, SEC-32). A time ahead of
// the server's clock is stored as the server's time, never refused (SEC-30): a phone whose clock runs fast still delivers
// its alerts. Routine alerts ring the parents' phones at most PUSHES_PER_DAY_PER_FAMILY times a day and acts at most
// ACT_PUSHES_PER_DAY_PER_FAMILY times, from their own budget (SEC-27, SEC-31); the alerts after that are saved and shown,
// without a push. The severity is the device's word and is not checked against the category (older builds sent other
// values; the parent screen takes the tier from the category).
import { GatewayError } from "../_shared/errors.ts";
import { notifyParents } from "../_shared/fcm.ts";
import type { FunctionSpec } from "../_shared/handler.ts";
import { CHILD_ID } from "../child-put/handler.ts";

export const ALERTS_PER_HOUR_PER_DEVICE = 300;

/// The most pushes a family's phones get in a day (UTC) for routine alerts; the push holds no content, so nothing is
/// lost after it.
export const PUSHES_PER_DAY_PER_FAMILY = 20;

/// The pushes a day kept for acts (`disclosure`), which routine alerts cannot spend.
export const ACT_PUSHES_PER_DAY_PER_FAMILY = 10;

export const CATEGORIES = [
  "pastLimit",
  "restHours",
  "gateAttempts",
  "guessing",
  "frustration",
  "inappropriateWords",
  "disclosure",
  "absence",
  "ribbonEarned",
  "concern",
] as const;

/// The alerts about what a child said: the only ones that may carry the words, and whose count may grow.
export const WORD_CATEGORIES: ReadonlySet<string> = new Set(["inappropriateWords", "disclosure", "concern"]);

/// Word alerts that never push: a check (tier 2) and the weekly note (tier 3).
export const QUIET_CATEGORIES: ReadonlySet<string> = new Set(["inappropriateWords", "concern"]);

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
    // The child's words belong only to the alerts that are about what was said.
    if (b.words && !WORD_CATEGORIES.has(b.category)) {
      throw new GatewayError("bad_request", "words_not_allowed");
    }
    const hour = new Date(Math.floor(ctx.svc.nowMs() / 3_600_000) * 3_600_000);
    if (!(await ctx.svc.store.rateLimitHit("alert_create", device.id, hour, ALERTS_PER_HOUR_PER_DEVICE))) {
      throw new GatewayError("rate_limited", "alert_create");
    }
    const settings = await ctx.svc.store.getSettings(device.familyId);
    const keepWords = settings?.rules.keepWords !== false;
    const status = await ctx.svc.store.insertAlert(device.familyId, device.id, {
      childId: b.child_id ?? null,
      category: b.category,
      severity: b.severity,
      count: b.count,
      detail: b.detail ?? "",
      words: keepWords ? b.words ?? "" : "",
      key: b.key,
      // Never later than the server's time (the database takes the earlier of the two as well).
      clientAtMs: Math.min(b.at, ctx.svc.nowMs()),
    });
    // One push, with a fixed phrase, only for an alert that is new and not a quiet one, and only so many a day.
    if (status === "new" && !QUIET_CATEGORIES.has(b.category)) {
      const day = new Date(Math.floor(ctx.svc.nowMs() / 86_400_000) * 86_400_000);
      const act = b.category === "disclosure";
      const allowed = act
        ? await ctx.svc.store.rateLimitHit(
          "alert_push_act",
          device.familyId,
          day,
          ACT_PUSHES_PER_DAY_PER_FAMILY,
        )
        : await ctx.svc.store.rateLimitHit("alert_push", device.familyId, day, PUSHES_PER_DAY_PER_FAMILY);
      if (allowed) {
        await notifyParents(ctx.svc.push, ctx.svc.store, device.familyId, device.id);
      }
    }
    return { status };
  },
};
