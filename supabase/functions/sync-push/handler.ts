// A device sends what children did (answers and visits), in order. The server numbers every event as it arrives; a
// retry of an event already there changes nothing; an event for a child the family does not have, or deleted, is
// refused by id so that the device stops sending it. Ids, numbers and fixed words only.
import { GatewayError } from "../_shared/errors.ts";
import type { FunctionSpec } from "../_shared/handler.ts";
import type { EventIn } from "../_shared/store.ts";
import { CHILD_ID } from "../child-put/handler.ts";

export const MAX_EVENTS = 40;
export const PUSHES_PER_HOUR_PER_DEVICE = 600;

/** An award key: `sticker:<lesson>:<n>`, `star:<skill>`, `trophy:<land>:<tier>`, `medal:<id>` or `deco:<n>`. */
export const AWARD_KEY =
  /^(sticker:[a-z0-9._-]{1,40}:[0-9]{1,4}|star:[A-Z]{2,5}-[A-C]-[0-9]{2}|trophy:[a-z]{3,12}:(bronze|silver|gold)|medal:[a-z0-9-]{2,30}|deco:[0-9]{1,3})$/;

const ms = { t: "int", min: 1_500_000_000_000, max: 4_100_000_000_000 } as const;
const word = (re: RegExp, max: number) => ({ t: "string", max, pattern: re, optional: true }) as const;

/** Every field an event may carry; which ones it must carry depends on its type (checked in `run`). */
const DATA = {
  // attempt
  activity_id: word(/^[a-z0-9][a-z0-9._-]{2,80}$/, 81),
  activity_revision: { t: "int", min: 0, max: 100_000, optional: true },
  pack_id: word(/^[a-z0-9-]{3,41}$/, 41),
  pack_version: word(/^[0-9]{1,4}\.[0-9]{1,4}\.[0-9]{1,4}$/, 14),
  lesson_id: word(/^[a-z0-9._-]{0,40}$/, 40),
  template: word(/^[a-z_]{2,30}$/, 30),
  template_version: word(/^[0-9.]{1,10}$/, 10),
  skill_id: word(/^[A-Z]{2,5}-[A-C]-[0-9]{2}$/, 11),
  result: { t: "enum", values: ["correct", "incorrect", "unsure"], optional: true },
  attempt_no: { t: "int", min: 1, max: 1000, optional: true },
  hint_level: { t: "int", min: 0, max: 3, optional: true },
  misconception_tag: word(/^(M-[A-Z]{2,5}-[A-Z0-9]{2,12})?$/, 20),
  response: word(/^[A-Za-z0-9=._-]{0,40}$/, 40),
  duration_ms: { t: "int", min: 0, max: 3_600_000, optional: true },
  input: { t: "enum", values: ["tap", "voice"], optional: true },
  // The device's own number for the visit an answer belongs to; with the device id it names the visit.
  session_local: { t: "int", min: 0, max: 1_000_000_000, optional: true },
  // session
  plan: word(/^[a-z0-9:._-]{0,80}$/, 80),
  started_at: { ...ms, optional: true },
  ended_at: { ...ms, optional: true },
  end_reason: { t: "enum", values: ["", "finished", "home", "limit"], optional: true },
  // reward (M8): what was given, as a kind and a key. The key names the award and nothing else.
  kind: { t: "enum", values: ["sticker", "star", "trophy", "medal", "decoration"], optional: true },
  key: word(AWARD_KEY, 80),
} as const;

const REQUIRED: Record<"attempt" | "session" | "reward", readonly string[]> = {
  attempt: [
    "activity_id",
    "activity_revision",
    "pack_id",
    "pack_version",
    "template",
    "template_version",
    "skill_id",
    "result",
    "attempt_no",
  ],
  session: ["plan", "started_at", "session_local"],
  reward: ["kind", "key"],
};

interface Body {
  events: Array<{
    id: string;
    child_id: string;
    at: number;
    engine: number;
    type: "attempt" | "session" | "reward";
    data: Record<string, unknown>;
  }>;
}

export const spec: FunctionSpec = {
  name: "sync-push",
  access: { kind: "device", roles: ["parent", "child"] },
  maxBodyBytes: 48 * 1024,
  shape: {
    events: {
      t: "array",
      maxItems: MAX_EVENTS,
      of: {
        t: "object",
        shape: {
          id: { t: "uuid" },
          child_id: { t: "string", max: 64, pattern: CHILD_ID },
          at: ms,
          engine: { t: "int", min: 1, max: 1000 },
          type: { t: "enum", values: ["attempt", "session", "reward"] },
          data: { t: "object", shape: DATA },
        },
      },
    },
  },
  run: async (ctx) => {
    const { device } = ctx.auth!;
    const hour = new Date(Math.floor(ctx.svc.nowMs() / 3_600_000) * 3_600_000);
    if (!(await ctx.svc.store.rateLimitHit("sync_push", device.id, hour, PUSHES_PER_HOUR_PER_DEVICE))) {
      throw new GatewayError("rate_limited", "sync_push");
    }
    const events: EventIn[] = (ctx.body as unknown as Body).events.map((e) => {
      for (const key of REQUIRED[e.type]) {
        if (!Object.hasOwn(e.data, key)) throw new GatewayError("bad_request", `event_missing_${key}`);
      }
      return {
        id: e.id,
        childId: e.child_id,
        clientAtMs: e.at,
        engineVersion: e.engine,
        type: e.type,
        payload: e.data,
      };
    });
    return await ctx.svc.store.insertEvents(device.familyId, device.id, events);
  },
};
