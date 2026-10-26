// One tutor turn, start to finish: caps, cache, prompt, model, the ten checks, voice, and the answer, in one call.
//
// Rules this function keeps:
//  - the body is ids, numbers and enums; the prompt is built here from the server's own tables;
//  - nothing is spoken that did not pass the validator, and voice is made only for a line that passed;
//  - every failure (a switch, a cap, a slow model, a refused reply, a failed voice) is answered with a RuleTutor
//    reason and HTTP 200: the child never sees an error and the phone uses its authored line;
//  - the child never waits for more than the total budget on the server (3 s), and mostly far less (cache).
import { b64urlEncode } from "../_shared/b64.ts";
import { ModelFailed } from "../_shared/anthropic.ts";
import { VoiceFailed } from "../_shared/elevenlabs.ts";
import { GatewayError } from "../_shared/errors.ts";
import { type Context, type FunctionSpec, type Services } from "../_shared/handler.ts";
import { loadBlocklist, loadLexicon } from "../_shared/lexicon.ts";
import type { CachedLine, CacheKey, TutorContext } from "../_shared/store.ts";
import { type Attempt, PROMPT_VERSION, systemPrompt, userPrompt } from "../_shared/tutor_prompt.ts";
import { type Failure, type TurnFacts, validateReply, VALIDATOR_VERSION } from "../_shared/validator.ts";

export const REQUESTS_PER_MINUTE_PER_DEVICE = 60;

const lexicon = loadLexicon();
const blocklist = loadBlocklist();

/** Settings in the `config` table, with the defaults the PLAN sets. Anything not switched on is off. */
interface Settings {
  tutorEnabled: boolean;
  liveVoiceEnabled: boolean;
  sessionCap: number;
  dayCap: number;
  prefetchCap: number;
  costCapMicro: number;
  voiceModelId: string | null;
  priceInPerMtok: number;
  priceOutPerMtok: number;
  priceVoicePer1k: number;
}

const CONFIG_KEYS = [
  "tutor_enabled",
  "live_voice_enabled",
  "tutor_session_cap",
  "tutor_day_cap",
  "tutor_prefetch_cap",
  "tutor_cost_cap_micro",
  "elevenlabs_model_id",
  "tutor_price_micro",
] as const;

const num = (v: unknown, d: number) => (typeof v === "number" && Number.isFinite(v) && v >= 0 ? v : d);

function settings(c: Record<string, unknown>): Settings {
  const price = (c.tutor_price_micro ?? {}) as Record<string, unknown>;
  return {
    tutorEnabled: c.tutor_enabled === true,
    liveVoiceEnabled: c.live_voice_enabled === true,
    sessionCap: num(c.tutor_session_cap, 20),
    dayCap: num(c.tutor_day_cap, 60),
    prefetchCap: num(c.tutor_prefetch_cap, 40),
    // 0.50 dollars a family a day, until the owner sets another number.
    costCapMicro: num(c.tutor_cost_cap_micro, 500_000),
    voiceModelId:
      typeof c.elevenlabs_model_id === "string" && /^[A-Za-z0-9_.-]{3,60}$/.test(c.elevenlabs_model_id)
        ? c.elevenlabs_model_id
        : null,
    // Placeholders until the owner has checked the providers' prices: the cap works on what is written here.
    priceInPerMtok: num(price.in_per_mtok, 1_000_000),
    priceOutPerMtok: num(price.out_per_mtok, 5_000_000),
    priceVoicePer1k: num(price.voice_per_1k_chars, 300_000),
  };
}

export type RuleReason =
  | "kill_switch"
  | "not_configured"
  | "item_not_allowed"
  | "session_cap"
  | "day_cap"
  | "prefetch_cap"
  | "cost_cap"
  | "timeout"
  | "model_failed"
  | "validator_failed"
  | "no_voice"
  | "voice_failed";

interface Line {
  mistake: string;
  source: "live" | "cache" | "prefetch";
  line: string;
  caption: string | null;
  next: string;
  highlight: string[];
  misconception: string | null;
  audio: string | null;
  audio_mime: "audio/mpeg" | null;
}

type Result = Line | { mistake: string; rule: RuleReason };

function b64(bytes: Uint8Array): string {
  let s = "";
  for (let i = 0; i < bytes.length; i += 0x8000) s += String.fromCharCode(...bytes.subarray(i, i + 0x8000));
  return btoa(s);
}

/** The first JSON object in a model's text, or null. */
export function extractJson(text: string): unknown {
  const a = text.indexOf("{");
  const b = text.lastIndexOf("}");
  if (a < 0 || b <= a) return null;
  try {
    return JSON.parse(text.slice(a, b + 1));
  } catch {
    return null;
  }
}

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

    const out = await Promise.all(body.mistakes.map((m) => oneMistake(ctx, body, tctx, cfg, m, started)));
    return { results: out, server_ms: Math.round(performance.now() - started) };
  },
};

async function oneMistake(
  ctx: Context,
  body: Body,
  tctx: TutorContext,
  cfg: Settings,
  mistakeTag: string,
  started: number,
): Promise<Result> {
  const svc: Services = ctx.svc;
  const { device } = ctx.auth!;
  const kind = body.mode === "prefetch" ? "prefetch" : "turn";
  const key: CacheKey = {
    packId: body.pack_id,
    packVersion: body.pack_version,
    itemId: body.item_id,
    mistake: mistakeTag,
    hintLevel: body.hint_level,
    band: body.band,
    addressForm: body.address_form,
    characterId: body.character_id,
    promptVersion: PROMPT_VERSION,
    validatorVersion: VALIDATOR_VERSION,
  };
  const log = (
    source: "live" | "cache" | "prefetch" | "rule",
    outcome: string,
    extra: Partial<{
      line: string;
      failures: string[];
      modelMs: number;
      voiceMs: number;
      requestId: string | null;
    }> = {},
  ) =>
    svc.store.logTutor({
      familyId: device.familyId,
      childRef: body.child_ref,
      sessionRef: body.session_ref,
      packId: body.pack_id,
      packVersion: body.pack_version,
      itemId: body.item_id,
      characterId: body.character_id,
      source,
      outcome,
      line: extra.line ?? null,
      validatorOk: source === "rule" ? (extra.failures ? false : null) : true,
      validatorFailures: extra.failures ?? [],
      promptVersion: PROMPT_VERSION,
      totalMs: performance.now() - started,
      modelMs: extra.modelMs ?? null,
      voiceMs: extra.voiceMs ?? null,
      elevenRequestId: extra.requestId ?? null,
    }).catch(() => {});
  const ruleOut = async (reason: RuleReason, extra: Parameters<typeof log>[2] = {}): Promise<Result> => {
    await log("rule", reason, extra);
    return { mistake: mistakeTag, rule: reason };
  };
  const toLine = (c: CachedLine, source: Line["source"]): Line => ({
    mistake: mistakeTag,
    source,
    line: c.line,
    caption: c.caption,
    next: c.next,
    highlight: c.highlight,
    misconception: mistakeTag === "default" ? null : mistakeTag,
    audio: c.audio ? b64(c.audio) : null,
    audio_mime: c.audio ? "audio/mpeg" : null,
  });

  // A line already made and checked: no model, no voice, no cost.
  const cached = await svc.store.cacheGet(key);
  if (cached && cached.audio) {
    if (kind === "turn") {
      const take = await svc.store.tutorTake(takeArgs(svc, body, device.familyId, kind, cfg));
      if (take !== "ok") return await ruleOut(take);
    }
    await log("cache", "ok", { line: cached.line });
    return toLine(cached, "cache");
  }

  const tutor = svc.tutor;
  if (!tutor) return await ruleOut("not_configured");
  const take = await svc.store.tutorTake(takeArgs(svc, body, device.familyId, kind, cfg));
  if (take !== "ok") return await ruleOut(take);

  const turn: TurnFacts = {
    hintLevel: body.hint_level,
    addressForm: body.address_form,
    characterGender: tctx.character!.gender,
    characterNames: [tctx.character!.nameHe],
  };
  const item = { ...tctx, band: body.band };
  const descriptions = new Map(Object.entries(tctx.descriptions));
  const attempts: Attempt[] = body.attempts.map((a) => ({
    option: a.option,
    result: a.result,
    misconception: a.misconception,
  }));
  const system = systemPrompt(body.band, body.address_form, lexicon);

  let inTokens = 0;
  let outTokens = 0;
  let modelMs = 0;
  let reasons: string[] = [];
  let verdict: ReturnType<typeof validateReply> | null = null;
  for (let attempt = 0; attempt < 2; attempt++) {
    const left = tutor.budget.totalMs - (performance.now() - started);
    if (left < 400) return await ruleOut("timeout", { modelMs });
    const t0 = performance.now();
    try {
      const ans = await tutor.model.complete({
        system,
        user: userPrompt(item, turn, attempts, descriptions, reasons),
        maxTokens: tutor.budget.modelMaxTokens,
        timeoutMs: Math.max(200, Math.min(tutor.budget.modelMs, left - 300)),
      });
      inTokens += ans.inputTokens;
      outTokens += ans.outputTokens;
      modelMs += performance.now() - t0;
      verdict = validateReply(extractJson(ans.text), item, turn, lexicon, blocklist);
    } catch (e) {
      modelMs += performance.now() - t0;
      await addCost(svc, device.familyId, cfg, inTokens, outTokens, 0);
      return await ruleOut(e instanceof ModelFailed && e.reason === "timeout" ? "timeout" : "model_failed", {
        modelMs,
      });
    }
    if (verdict.ok) break;
    reasons = verdict.failures;
    // One retry, and only if there is time for a whole second attempt.
    if (tutor.budget.totalMs - (performance.now() - started) < tutor.budget.retryMinLeftMs) break;
  }
  if (!verdict || !verdict.ok) {
    await addCost(svc, device.familyId, cfg, inTokens, outTokens, 0);
    return await ruleOut("validator_failed", {
      failures: verdict && !verdict.ok ? (verdict.failures as Failure[]) : [],
      modelMs,
    });
  }

  // Voice only for a line that passed, in the voice the server's own table names.
  const voiceId = tctx.character!.voiceId;
  if (!cfg.liveVoiceEnabled || !voiceId || !cfg.voiceModelId) {
    await addCost(svc, device.familyId, cfg, inTokens, outTokens, 0);
    return await ruleOut("no_voice", { line: verdict.plain, modelMs });
  }
  const vt0 = performance.now();
  let audio: Uint8Array;
  let requestId: string | null = null;
  try {
    const left = tutor.budget.totalMs - (performance.now() - started);
    if (left < 250) throw new VoiceFailed("timeout");
    const v = await tutor.voice.speak({
      voiceId,
      modelId: cfg.voiceModelId,
      text: verdict.vocalised,
      timeoutMs: Math.max(200, Math.min(tutor.budget.voiceMs, left - 50)),
    });
    audio = v.audio;
    requestId = v.requestId;
    // The provider keeps a history by default; ours is deleted at once (a failure here is not the child's concern).
    if (v.historyItemId) void tutor.voice.deleteHistory(v.historyItemId);
  } catch {
    await addCost(svc, device.familyId, cfg, inTokens, outTokens, 0);
    return await ruleOut("voice_failed", { line: verdict.plain, modelMs, voiceMs: performance.now() - vt0 });
  }
  const voiceMs = performance.now() - vt0;
  await addCost(svc, device.familyId, cfg, inTokens, outTokens, verdict.vocalised.length);

  const made: CachedLine = {
    line: verdict.vocalised,
    // Band A children get no caption for live lines; B and C get the vocalised line.
    caption: body.band === "A" ? null : verdict.vocalised,
    next: verdict.reply.next,
    highlight: verdict.reply.hl,
    audio,
  };
  await svc.store.cachePut(key, made).catch(() => {});
  await log(kind === "prefetch" ? "prefetch" : "live", "ok", {
    line: verdict.plain,
    modelMs,
    voiceMs,
    requestId,
  });
  const line = toLine(made, kind === "prefetch" ? "prefetch" : "live");
  if (verdict.reply.mis !== null) line.misconception = verdict.reply.mis;
  return line;
}

function takeArgs(svc: Services, body: Body, familyId: string, kind: "turn" | "prefetch", cfg: Settings) {
  return {
    familyId,
    childRef: body.child_ref,
    sessionRef: body.session_ref,
    kind,
    sessionCap: cfg.sessionCap,
    dayCap: cfg.dayCap,
    prefetchCap: cfg.prefetchCap,
    costCapMicro: cfg.costCapMicro,
    nowMs: svc.nowMs(),
  };
}

async function addCost(
  svc: Services,
  familyId: string,
  cfg: Settings,
  inTok: number,
  outTok: number,
  chars: number,
) {
  const micro = (inTok * cfg.priceInPerMtok + outTok * cfg.priceOutPerMtok) / 1_000_000 +
    (chars / 1000) * cfg.priceVoicePer1k;
  await svc.store.tutorCostAdd(familyId, micro, svc.nowMs()).catch(() => {});
}

void b64urlEncode;
