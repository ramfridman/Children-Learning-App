// The heart of a tutor line, shared by `tutor-turn` (a phone asks) and `tutor-prewarm` (the owner's computer asks ahead):
// the cache, the caps, the prompt, the model, the ten checks, the voice, and the bookkeeping.
//
// Rules this code keeps:
//  - nothing is spoken that did not pass the validator, and voice is made only for a line that passed;
//  - every failure (a switch, a cap, a slow model, a refused reply, a failed voice) becomes a RuleTutor reason, never an error;
//  - the prompt is built from the server's own tables; the model never sees anything a device sent;
//  - the child never waits more than the total budget (3 s), and mostly far less (the cache).
import { ModelFailed } from "./anthropic.ts";
import { VoiceFailed } from "./elevenlabs.ts";
import type { Services } from "./handler.ts";
import { loadBlocklist, loadLexicon } from "./lexicon.ts";
import type { CachedLine, CacheKey, TutorContext } from "./store.ts";
import {
  type Attempt,
  moveFor,
  type Moves,
  movesOf,
  PROMPT_VERSION,
  retryAdvice,
  systemPrompt,
  userPrompt,
} from "./tutor_prompt.ts";
import { type Failure, type TurnFacts, validateReply, VALIDATOR_VERSION } from "./validator.ts";

const lexicon = loadLexicon();
const blocklist = loadBlocklist();

/** A refused line, for the owner's speed test only: Hebrew letters and basic punctuation kept, the rest dropped. */
function refusedText(raw: unknown): string {
  const say = (raw as { say?: unknown } | null)?.say;
  return typeof say === "string" ? say.replace(/[^א-ת .,?!]/g, "").slice(0, 120) : "(no say)";
}

/** Settings in the `config` table, with the defaults the PLAN sets. Anything not switched on is off. */
export interface Settings {
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
  /** Teaching moves by misconception tag, help level and alternative (see content/tutor-moves.json). */
  moves: Moves;
}

export const CONFIG_KEYS = [
  "tutor_enabled",
  "live_voice_enabled",
  "tutor_session_cap",
  "tutor_day_cap",
  "tutor_prefetch_cap",
  "tutor_cost_cap_micro",
  "elevenlabs_model_id",
  "tutor_price_micro",
  "tutor_moves",
] as const;

const num = (v: unknown, d: number) => (typeof v === "number" && Number.isFinite(v) && v >= 0 ? v : d);

export function settings(c: Record<string, unknown>): Settings {
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
    moves: movesOf(c.tutor_moves),
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

export interface Line {
  mistake: string;
  source: "live" | "cache" | "prefetch" | "warm";
  line: string;
  caption: string | null;
  next: string;
  highlight: string[];
  misconception: string | null;
  audio: string | null;
  audio_mime: "audio/mpeg" | null;
}

export type Result = Line | { mistake: string; rule: RuleReason };

export interface LineParams {
  /** `turn` and `prefetch` count against the child's caps; `warm` (the owner's computer) uses its own budget. */
  kind: "turn" | "prefetch" | "warm";
  familyId: string | null;
  childRef: string;
  sessionRef: string;
  packId: string;
  packVersion: string;
  itemId: string;
  characterId: string;
  band: "A" | "B" | "C";
  addressForm: "f" | "m" | "n";
  hintLevel: number;
  mistake: string;
  attempts: Attempt[];
  /** For `warm`: what may still be spent, in millionths of a dollar (shared between lines, updated as they cost). */
  budget?: { remainingMicro: number; spentMicro: number };
  /** Skip the cache and do not keep the result (latency measuring). */
  fresh?: boolean;
  /** Ask the model and run the ten checks, then stop: no voice, nothing kept. The answer is in `timings.evaluation`. */
  modelOnly?: boolean;
}

export function b64(bytes: Uint8Array): string {
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

/** Pre-warm runs on the owner's computer with nobody waiting: it gets room, so a slow first call still makes a line. */
const WARM_BUDGET = {
  modelMs: 10_000,
  voiceMs: 10_000,
  retryMinLeftMs: 8_000,
  totalMs: 40_000,
  modelMaxTokens: 300,
};

/** What one model-only run found (the owner's evaluation): never reaches a device. */
export interface Evaluation {
  attempts: number;
  firstTry: boolean;
  passed: boolean;
  /** Every check that refused a reply in this run, and the plain words that had no single reading. */
  checks: string[];
  unknown: string[];
  /** The sentence of the last reply (Hebrew letters only), the one a child would hear if it passed. */
  say: string;
}

export interface Timings {
  modelMs: number;
  voiceMs: number;
  totalMs: number;
  evaluation?: Evaluation;
  /** Why a vendor call failed, as a short fixed phrase (for the owner's speed test only). */
  detail?: string;
}

/** One line for one mistake: from the cache, or made now. Never throws for a vendor or a validator failure. */
export async function makeLine(
  svc: Services,
  tctx: TutorContext,
  cfg: Settings,
  p: LineParams,
  started: number,
  timings?: Timings,
): Promise<Result> {
  const key: CacheKey = {
    packId: p.packId,
    packVersion: p.packVersion,
    itemId: p.itemId,
    mistake: p.mistake,
    hintLevel: p.hintLevel,
    band: p.band,
    addressForm: p.addressForm,
    characterId: p.characterId,
    promptVersion: PROMPT_VERSION,
    validatorVersion: VALIDATOR_VERSION,
  };
  const log = (
    source: "live" | "cache" | "prefetch" | "rule",
    outcome: string,
    extra: Partial<
      { line: string; failures: string[]; modelMs: number; voiceMs: number; requestId: string | null }
    > = {},
  ) =>
    p.familyId === null ? Promise.resolve() : svc.store.logTutor({
      familyId: p.familyId,
      childRef: p.childRef,
      sessionRef: p.sessionRef,
      packId: p.packId,
      packVersion: p.packVersion,
      itemId: p.itemId,
      characterId: p.characterId,
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
    if (timings) {
      timings.modelMs = extra.modelMs ?? 0;
      timings.voiceMs = extra.voiceMs ?? 0;
      timings.totalMs = performance.now() - started;
    }
    await log("rule", reason, extra);
    return { mistake: p.mistake, rule: reason };
  };
  const toLine = (c: CachedLine, source: Line["source"]): Line => ({
    mistake: p.mistake,
    source,
    line: c.line,
    caption: c.caption,
    next: c.next,
    highlight: c.highlight,
    misconception: p.mistake === "default" ? null : p.mistake,
    audio: c.audio ? b64(c.audio) : null,
    audio_mime: c.audio ? "audio/mpeg" : null,
  });
  const take = (): Promise<string> => {
    if (p.kind === "warm") {
      return Promise.resolve(p.budget && p.budget.remainingMicro <= 0 ? "cost_cap" : "ok");
    }
    return svc.store.tutorTake({
      familyId: p.familyId!,
      childRef: p.childRef,
      sessionRef: p.sessionRef,
      kind: p.kind,
      sessionCap: cfg.sessionCap,
      dayCap: cfg.dayCap,
      prefetchCap: cfg.prefetchCap,
      costCapMicro: cfg.costCapMicro,
      nowMs: svc.nowMs(),
    });
  };

  // A line already made and checked: no model, no voice, no cost.
  if (!p.fresh) {
    const cached = await svc.store.cacheGet(key);
    if (cached && cached.audio) {
      if (p.kind === "turn") {
        const t = await take();
        if (t !== "ok") return await ruleOut(t as RuleReason);
      }
      await log("cache", "ok", { line: cached.line });
      return toLine(cached, "cache");
    }
  }

  const tutor = svc.tutor;
  if (!tutor) return await ruleOut("not_configured");
  const taken = await take();
  if (taken !== "ok") return await ruleOut(taken as RuleReason);

  const turn: TurnFacts = {
    hintLevel: p.hintLevel,
    addressForm: p.addressForm,
    characterGender: tctx.character!.gender,
    characterNames: [tctx.character!.nameHe],
  };
  const item = { ...tctx, band: p.band };
  const descriptions = new Map(Object.entries(tctx.descriptions));
  const system = systemPrompt(p.band, p.addressForm, lexicon);
  const tb = p.kind === "warm" ? WARM_BUDGET : tutor.budget;
  const move = moveFor(cfg.moves, p.mistake, p.hintLevel, p.band, p.addressForm);

  let inTokens = 0;
  let outTokens = 0;
  let modelMs = 0;
  let reasons: string[] = [];
  const refused: string[] = [];
  const seenChecks = new Set<string>();
  const seenUnknown = new Set<string>();
  let attemptsMade = 0;
  let firstTry = false;
  let lastSay = "";
  let verdict: ReturnType<typeof validateReply> | null = null;
  const addCost = async (chars: number) => {
    const micro = (inTokens * cfg.priceInPerMtok + outTokens * cfg.priceOutPerMtok) / 1_000_000 +
      (chars / 1000) * cfg.priceVoicePer1k;
    if (p.budget) {
      p.budget.spentMicro += micro;
      p.budget.remainingMicro -= micro;
    }
    if (p.familyId !== null) await svc.store.tutorCostAdd(p.familyId, micro, svc.nowMs()).catch(() => {});
  };
  for (let attempt = 0; attempt < 2; attempt++) {
    const left = tb.totalMs - (performance.now() - started);
    if (left < 400) return await ruleOut("timeout", { modelMs });
    const t0 = performance.now();
    try {
      const ans = await tutor.model.complete({
        system,
        user: userPrompt(item, turn, p.attempts, descriptions, reasons, move),
        maxTokens: tb.modelMaxTokens,
        timeoutMs: Math.max(200, Math.min(tb.modelMs, left - 300)),
      });
      inTokens += ans.inputTokens;
      outTokens += ans.outputTokens;
      modelMs += performance.now() - t0;
      const raw = extractJson(ans.text);
      verdict = validateReply(raw, item, turn, lexicon, blocklist);
      attemptsMade++;
      lastSay = refusedText(raw);
      if (verdict.ok) firstTry = attemptsMade === 1;
      else {
        refused.push(`${verdict.failures.join("+")}: ${lastSay}`);
        for (const f of verdict.failures) seenChecks.add(f);
        for (const w of verdict.unknown ?? []) seenUnknown.add(w);
      }
    } catch (e) {
      modelMs += performance.now() - t0;
      await addCost(0);
      if (timings && e instanceof ModelFailed) {
        timings.detail = `model ${e.reason}${e.detail ? ` ${e.detail}` : ""}`;
      }
      return await ruleOut(e instanceof ModelFailed && e.reason === "timeout" ? "timeout" : "model_failed", {
        modelMs,
      });
    }
    if (verdict.ok) break;
    reasons = retryAdvice(p.band, item.numberSet, verdict);
    // One retry, and only if there is time for a whole second attempt.
    if (tb.totalMs - (performance.now() - started) < tb.retryMinLeftMs) break;
  }
  if (p.modelOnly) {
    await addCost(0);
    if (timings) {
      timings.evaluation = {
        attempts: attemptsMade,
        firstTry,
        passed: !!verdict && verdict.ok,
        checks: [...seenChecks],
        unknown: [...seenUnknown],
        say: lastSay,
      };
    }
    return await ruleOut("no_voice", { modelMs });
  }
  if (!verdict || !verdict.ok) {
    await addCost(0);
    if (timings && verdict && !verdict.ok) {
      timings.detail = `checks failed: ${verdict.failures.join(", ")} | refused: ${refused.join(" | ")}`;
    }
    return await ruleOut("validator_failed", {
      failures: verdict && !verdict.ok ? (verdict.failures as Failure[]) : [],
      modelMs,
    });
  }

  // Voice only for a line that passed, in the voice the server's own table names.
  const voiceId = tctx.character!.voiceId;
  if (!cfg.liveVoiceEnabled || !voiceId || !cfg.voiceModelId) {
    await addCost(0);
    return await ruleOut("no_voice", { line: verdict.plain, modelMs });
  }
  const vt0 = performance.now();
  let audio: Uint8Array;
  let requestId: string | null = null;
  try {
    const left = tb.totalMs - (performance.now() - started);
    if (left < 250) throw new VoiceFailed("timeout");
    const v = await tutor.voice.speak({
      voiceId,
      modelId: cfg.voiceModelId,
      text: verdict.vocalised,
      timeoutMs: Math.max(200, Math.min(tb.voiceMs, left - 50)),
    });
    audio = v.audio;
    requestId = v.requestId;
    // The provider keeps a history by default; ours is deleted at once (a failure here is not the child's concern).
    if (v.historyItemId) void tutor.voice.deleteHistory(v.historyItemId);
  } catch (e) {
    await addCost(0);
    if (timings && e instanceof VoiceFailed) {
      timings.detail = `voice ${e.reason}${e.detail ? ` ${e.detail}` : ""}`;
    }
    return await ruleOut("voice_failed", { line: verdict.plain, modelMs, voiceMs: performance.now() - vt0 });
  }
  const voiceMs = performance.now() - vt0;
  await addCost(verdict.vocalised.length);
  if (timings) {
    timings.modelMs = modelMs;
    timings.voiceMs = voiceMs;
    timings.totalMs = performance.now() - started;
  }

  const made: CachedLine = {
    line: verdict.vocalised,
    // Band A children get no caption for live lines; B and C get the vocalised line.
    caption: p.band === "A" ? null : verdict.vocalised,
    next: verdict.reply.next,
    highlight: verdict.reply.hl,
    audio,
  };
  if (!p.fresh) await svc.store.cachePut(key, made).catch(() => {});
  await log(p.kind === "turn" ? "live" : "prefetch", "ok", {
    line: verdict.plain,
    modelMs,
    voiceMs,
    requestId,
  });
  const line = toLine(made, p.kind === "turn" ? "live" : p.kind === "prefetch" ? "prefetch" : "warm");
  if (verdict.reply.mis !== null) line.misconception = verdict.reply.mis;
  return line;
}
