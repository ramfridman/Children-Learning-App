// One tutor turn, start to finish: caps, cache, prompt, model, the ten checks, voice, and the answer, in one call.
// The work is in `_shared/tutor_core.ts`; this function checks who is asking and what they ask.
//
// Every failure (a switch, a cap, a slow model, a refused reply, a failed voice) is answered with a RuleTutor
// reason and HTTP 200: the child never sees an error and the phone uses its authored line.
import { GatewayError } from "../_shared/errors.ts";
import type { Context, FunctionSpec } from "../_shared/handler.ts";
import { CONFIG_KEYS, makeLine, type Result, type RuleReason, settings } from "../_shared/tutor_core.ts";

export const REQUESTS_PER_MINUTE_PER_DEVICE = 60;

interface Body {
  child_ref: string;
  session_ref: string;
  pack_id: string;
  pack_version: string;
  item_id: string;
  character_id: string;
  band: "A" | "B" | "C";
  address_form: "f" | "m" | "n";
  hint_level: number;
  mode: "turn" | "prefetch";
  mistakes: string[];
  attempts: Array<{ option: string; result: string; misconception?: string }>;
}

const ref = { t: "string", max: 64, pattern: /^[A-Za-z0-9-]{8,64}$/ } as const;
const id = (max: number) => ({ t: "string", max, pattern: /^[a-z0-9][a-z0-9._-]{0,63}$/ }) as const;
const mistake = { t: "string", max: 20, pattern: /^(default|M-[A-Z]{2,5}-[A-Z0-9]{2,12})$/ } as const;

export const spec: FunctionSpec = {
  name: "tutor-turn",
  access: { kind: "device", roles: ["parent", "child"] },
  shape: {
    child_ref: ref,
    session_ref: ref,
    pack_id: { t: "string", max: 41, pattern: /^[a-z0-9-]{3,41}$/ },
    pack_version: { t: "string", max: 14, pattern: /^[0-9]{1,4}\.[0-9]{1,4}\.[0-9]{1,4}$/ },
    item_id: id(64),
    character_id: { t: "string", max: 40, pattern: /^[a-z0-9-]{2,40}$/ },
    band: { t: "enum", values: ["A", "B", "C"] },
    address_form: { t: "enum", values: ["f", "m", "n"] },
    hint_level: { t: "int", min: 0, max: 3 },
    mode: { t: "enum", values: ["turn", "prefetch"] },
    mistakes: { t: "array", of: mistake, maxItems: 3 },
    attempts: {
      t: "array",
      maxItems: 3,
      of: {
        t: "object",
        shape: {
          option: { t: "string", max: 16, pattern: /^[a-z0-9=-]{1,16}$/ },
          result: { t: "enum", values: ["incorrect", "unsure"] },
          misconception: { t: "string", max: 20, pattern: /^M-[A-Z]{2,5}-[A-Z0-9]{2,12}$/, optional: true },
        },
      },
    },
  },
  run: async (ctx: Context) => {
    const started = performance.now();
    const body = ctx.body as unknown as Body;
    const { device } = ctx.auth!;
    const svc = ctx.svc;
    if (body.mistakes.length === 0 || (body.mode === "turn" && body.mistakes.length !== 1)) {
      throw new GatewayError("bad_request", "mistakes");
    }
    const minute = new Date(Math.floor(svc.nowMs() / 60_000) * 60_000);
    if (!(await svc.store.rateLimitHit("tutor_req", device.id, minute, REQUESTS_PER_MINUTE_PER_DEVICE))) {
      throw new GatewayError("rate_limited", "tutor_rate");
    }
    const cfg = settings(await svc.store.getConfigs(CONFIG_KEYS));
    const rule = (reason: RuleReason) => ({
      results: body.mistakes.map((m) => ({ mistake: m, rule: reason })),
      server_ms: Math.round(performance.now() - started),
    });
    if (!cfg.tutorEnabled) return rule("kill_switch");

    const tctx = await svc.store.tutorContext(
      body.pack_id,
      body.pack_version,
      body.item_id,
      body.character_id,
    );
    // Every id must exist for the pack version named: a made-up id is a bad request, not a RuleTutor case.
    if (!tctx || !tctx.character) throw new GatewayError("bad_request", "unknown_item_or_character");
    for (const m of body.mistakes) {
      if (m !== "default" && !tctx.answers.some((a) => a.misconception === m)) {
        throw new GatewayError("bad_request", "unknown_mistake");
      }
    }
    if (!tctx.llmAllowed) return rule("item_not_allowed");

    const out: Result[] = await Promise.all(body.mistakes.map((m) =>
      makeLine(svc, tctx, cfg, {
        kind: body.mode,
        familyId: device.familyId,
        childRef: body.child_ref,
        sessionRef: body.session_ref,
        packId: body.pack_id,
        packVersion: body.pack_version,
        itemId: body.item_id,
        characterId: body.character_id,
        band: body.band,
        addressForm: body.address_form,
        hintLevel: body.hint_level,
        mistake: m,
        attempts: body.attempts.map((a) => ({
          option: a.option,
          result: a.result,
          misconception: a.misconception,
        })),
      }, started)
    ));
    return { results: out, server_ms: Math.round(performance.now() - started) };
  },
};
