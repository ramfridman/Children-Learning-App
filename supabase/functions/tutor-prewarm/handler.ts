// Makes tutor lines ahead of time, from the owner's computer, through the same pipeline as a phone's turn (the model, the
// ten checks, the voice) so that the first child already meets cache hits. Callable only with the publish secret.
//
//   plan     counts the lines and estimates the cost; makes nothing and spends nothing.
//   make     makes up to `limit` lines of the grid from `offset`, within `max_micro_usd`.
//   measure  makes `count` fresh lines (not kept) of the first entry and reports the server times of each.
//   evaluate asks the model (no voice, nothing kept) for up to `limit` lines of the grid from `offset` and reports, per
//            line, whether the ten checks passed, which ones refused it and which words had no single reading.
import { GatewayError } from "../_shared/errors.ts";
import type { FunctionSpec } from "../_shared/handler.ts";
import type { Services } from "../_shared/handler.ts";
import type { TutorContext } from "../_shared/store.ts";
import {
  APPROVED,
  CONFIG_KEYS,
  type LineParams,
  makeLine,
  type Settings,
  settings,
  type Timings,
} from "../_shared/tutor_core.ts";
import { PROMPT_VERSION } from "../_shared/tutor_prompt.ts";
import { VALIDATOR_VERSION } from "../_shared/validator.ts";

/** A line the owner would hear: rough figures for the estimate (the plan says so). */
const EST_INPUT_TOKENS = 1500;
const EST_OUTPUT_TOKENS = 80;
const EST_VOICE_CHARS = 45;

interface Body {
  mode: "plan" | "make" | "measure" | "evaluate" | "voice";
  pack_id: string;
  pack_version: string;
  character_ids: string[];
  bands: Array<"A" | "B" | "C">;
  address_forms: Array<"f" | "m" | "n">;
  hint_level_tags: number;
  limit: number;
  offset: number;
  max_micro_usd: number;
  count: number;
  lines?: ApprovedLine[];
}

/** A sentence a person approved for one cell of the grid (plain Hebrew, no niqqud: the lexicon vocalises it). */
interface ApprovedLine {
  item: string;
  mistake: string;
  hint: number;
  band: "A" | "B" | "C";
  form: "f" | "m" | "n";
  character: string;
  say: string;
}

interface Entry {
  itemId: string;
  mistake: string;
  hintLevel: number;
  band: "A" | "B" | "C";
  addressForm: "f" | "m" | "n";
  characterId: string;
}

export const spec: FunctionSpec = {
  name: "tutor-prewarm",
  access: { kind: "publish" },
  shape: {
    mode: { t: "enum", values: ["plan", "make", "measure", "evaluate", "voice"] },
    pack_id: { t: "string", max: 41, pattern: /^[a-z0-9-]{3,41}$/ },
    pack_version: { t: "string", max: 14, pattern: /^[0-9]{1,4}\.[0-9]{1,4}\.[0-9]{1,4}$/ },
    character_ids: { t: "array", of: { t: "string", max: 40, pattern: /^[a-z0-9-]{2,40}$/ }, maxItems: 12 },
    bands: { t: "array", of: { t: "enum", values: ["A", "B", "C"] }, maxItems: 3 },
    address_forms: { t: "array", of: { t: "enum", values: ["f", "m", "n"] }, maxItems: 3 },
    hint_level_tags: { t: "int", min: 0, max: 3 },
    limit: { t: "int", min: 1, max: 25 },
    offset: { t: "int", min: 0, max: 100_000 },
    max_micro_usd: { t: "int", min: 0, max: 20_000_000 },
    count: { t: "int", min: 1, max: 10 },
    lines: {
      t: "array",
      maxItems: 25,
      optional: true,
      of: {
        t: "object",
        shape: {
          item: { t: "string", max: 80, pattern: /^[a-z0-9][a-z0-9._-]{2,79}$/ },
          mistake: { t: "string", max: 20, pattern: /^(default|M-[A-Z]{2,5}-[A-Z0-9]{2,12})$/ },
          hint: { t: "int", min: 0, max: 3 },
          band: { t: "enum", values: ["A", "B", "C"] },
          form: { t: "enum", values: ["f", "m", "n"] },
          character: { t: "string", max: 40, pattern: /^[a-z0-9-]{2,40}$/ },
          say: { t: "string", max: 200, pattern: /^[א-ת .,?!:'"-]{2,200}$/ },
        },
      },
    },
  },
  run: async (ctx) => {
    const b = ctx.body as unknown as Body;
    const svc = ctx.svc;
    const cfg = settings(await svc.store.getConfigs(CONFIG_KEYS));
    const contexts = new Map<string, TutorContext>();
    const grid: Entry[] = [];
    for (const itemId of await svc.store.tutorItemIds(b.pack_id, b.pack_version)) {
      for (const characterId of b.character_ids) {
        const tctx = await svc.store.tutorContext(b.pack_id, b.pack_version, itemId, characterId);
        if (!tctx || !tctx.character) continue;
        contexts.set(`${itemId}/${characterId}`, tctx);
        const tags = [...new Set(tctx.answers.map((a) => a.misconception).filter((m): m is string => !!m))]
          .sort();
        for (const band of b.bands) {
          for (const addressForm of b.address_forms) {
            grid.push({ itemId, mistake: "default", hintLevel: 0, band, addressForm, characterId });
            for (const t of tags) {
              grid.push({ itemId, mistake: t, hintLevel: b.hint_level_tags, band, addressForm, characterId });
            }
          }
        }
      }
    }

    if (b.mode === "plan") {
      let cached = 0;
      for (const e of grid) {
        if (
          await svc.store.cacheGet({ ...keyOf(b, e), promptVersion: APPROVED }) ||
          await svc.store.cacheGet(keyOf(b, e))
        ) cached++;
      }
      const todo = grid.length - cached;
      return {
        lines: grid.length,
        cached,
        to_make: todo,
        est_micro_usd: Math.round(todo * estimateMicro(cfg)),
        est_voice_chars: todo * EST_VOICE_CHARS,
        // The model only, two attempts at most for every line of the grid, nothing cached.
        est_eval_micro_usd: Math.round(grid.length * 2 * estimateModelMicro(cfg)),
        prompt_version: PROMPT_VERSION,
        validator_version: VALIDATOR_VERSION,
        // How many mistake types have teaching moves in the server's config: 0 means the prompts carry none.
        moves_tags: Object.keys(cfg.moves).length,
        voice_micro_per_1k: cfg.priceVoicePer1k,
      };
    }

    if (!cfg.tutorEnabled) throw new GatewayError("unavailable", "tutor_off");
    const budget = { remainingMicro: b.max_micro_usd, spentMicro: 0 };
    const started = performance.now();

    if (b.mode === "measure") {
      const e = grid[0];
      if (!e) throw new GatewayError("bad_request", "empty_grid");
      const tctx = contexts.get(`${e.itemId}/${e.characterId}`)!;
      const runs: Array<{ rule?: string; server_ms: number; model_ms?: number; voice_ms?: number }> = [];
      for (let i = 0; i < b.count; i++) {
        const t0 = performance.now();
        const timings: Timings = { modelMs: 0, voiceMs: 0, totalMs: 0 };
        const r = await makeLine(svc, tctx, cfg, paramsOf(b, e, budget, true), t0, timings);
        runs.push(
          {
            ..."rule" in r ? { rule: r.rule } : {},
            server_ms: Math.round(timings.totalMs),
            model_ms: Math.round(timings.modelMs),
            voice_ms: Math.round(timings.voiceMs),
            ...timings.detail ? { detail: timings.detail } : {},
          },
        );
      }
      return { runs, spent_micro_usd: Math.round(budget.spentMicro) };
    }

    if (b.mode === "evaluate") {
      const rows: Array<Record<string, unknown>> = [];
      let processed = 0;
      for (const e of grid.slice(b.offset, b.offset + b.limit)) {
        const tctx = contexts.get(`${e.itemId}/${e.characterId}`)!;
        const timings: Timings = { modelMs: 0, voiceMs: 0, totalMs: 0 };
        const r = await makeLine(
          svc,
          tctx,
          cfg,
          { ...paramsOf(b, e, budget, true), modelOnly: true },
          performance.now(),
          timings,
        );
        const ev = timings.evaluation;
        rows.push({
          item: e.itemId,
          mistake: e.mistake,
          hint: e.hintLevel,
          band: e.band,
          form: e.addressForm,
          character: e.characterId,
          ...ev ? ev : { rule: "rule" in r ? r.rule : "unknown", detail: timings.detail ?? "" },
          model_ms: Math.round(timings.modelMs),
        });
        processed++;
        if (budget.remainingMicro <= 0) break;
      }
      return {
        rows,
        spent_micro_usd: Math.round(budget.spentMicro),
        next_offset: b.offset + processed,
        done: b.offset + processed >= grid.length || budget.remainingMicro <= 0,
        total: grid.length,
      };
    }

    if (b.mode === "voice") {
      if (!b.lines || b.lines.length === 0) throw new GatewayError("bad_request", "no_lines");
      const results: Array<Record<string, unknown>> = [];
      let made = 0;
      for (const l of b.lines) {
        const tctx = await svc.store.tutorContext(b.pack_id, b.pack_version, l.item, l.character);
        const where = { item: l.item, mistake: l.mistake, hint: l.hint, band: l.band, form: l.form };
        if (!tctx || !tctx.character) {
          results.push({ ...where, ok: false, rule: "no_such_item_or_character" });
          continue;
        }
        const timings: Timings = { modelMs: 0, voiceMs: 0, totalMs: 0 };
        const r = await makeLine(
          svc,
          tctx,
          cfg,
          {
            ...paramsOf(b, { ...entryOf(l) }, budget, false),
            approvedSay: l.say,
          },
          performance.now(),
          timings,
        );
        if ("rule" in r) {
          results.push({ ...where, ok: false, rule: r.rule, detail: timings.detail ?? "" });
        } else {
          made++;
          results.push({ ...where, ok: true });
        }
        if (budget.remainingMicro <= 0) break;
      }
      return { made, results, spent_micro_usd: Math.round(budget.spentMicro) };
    }

    // make
    const slice = grid.slice(b.offset, b.offset + b.limit);
    const failed: Record<string, number> = {};
    let made = 0;
    let cached = 0;
    let processed = 0;
    for (const e of slice) {
      const tctx = contexts.get(`${e.itemId}/${e.characterId}`)!;
      const timings: Timings = { modelMs: 0, voiceMs: 0, totalMs: 0 };
      const r = await makeLine(svc, tctx, cfg, paramsOf(b, e, budget, false), performance.now(), timings);
      if ("rule" in r) {
        // A refused line says which checks refused it (check codes only), so the tally shows what to tune.
        const codes = /^checks failed: ([a-z, ]+)/.exec(timings.detail ?? "")?.[1];
        const key = codes ? `${r.rule} [${codes.replaceAll(", ", "+")}]` : r.rule;
        failed[key] = (failed[key] ?? 0) + 1;
      } else if (r.source === "cache") cached++;
      else made++;
      processed++;
      if (budget.remainingMicro <= 0) break;
    }
    return {
      made,
      cached,
      failed,
      spent_micro_usd: Math.round(budget.spentMicro),
      next_offset: b.offset + processed,
      done: b.offset + processed >= grid.length || budget.remainingMicro <= 0,
      total: grid.length,
      server_ms: Math.round(performance.now() - started),
    };
  },
};

const entryOf = (l: ApprovedLine): Entry => ({
  itemId: l.item,
  mistake: l.mistake,
  hintLevel: l.hint,
  band: l.band,
  addressForm: l.form,
  characterId: l.character,
});

const keyOf = (b: Body, e: Entry) => ({
  packId: b.pack_id,
  packVersion: b.pack_version,
  itemId: e.itemId,
  mistake: e.mistake,
  hintLevel: e.hintLevel,
  band: e.band,
  addressForm: e.addressForm,
  characterId: e.characterId,
  promptVersion: PROMPT_VERSION,
  validatorVersion: VALIDATOR_VERSION,
});

function paramsOf(
  b: Body,
  e: Entry,
  budget: { remainingMicro: number; spentMicro: number },
  fresh: boolean,
): LineParams {
  return {
    kind: "warm",
    familyId: null,
    childRef: "prewarm",
    sessionRef: "prewarm",
    packId: b.pack_id,
    packVersion: b.pack_version,
    itemId: e.itemId,
    characterId: e.characterId,
    band: e.band,
    addressForm: e.addressForm,
    hintLevel: e.hintLevel,
    mistake: e.mistake,
    attempts: [],
    budget,
    fresh,
  };
}

function estimateModelMicro(cfg: Settings): number {
  return (EST_INPUT_TOKENS * cfg.priceInPerMtok + EST_OUTPUT_TOKENS * cfg.priceOutPerMtok) / 1_000_000;
}

function estimateMicro(cfg: Settings): number {
  return (EST_INPUT_TOKENS * cfg.priceInPerMtok + EST_OUTPUT_TOKENS * cfg.priceOutPerMtok) / 1_000_000 +
    (EST_VOICE_CHARS / 1000) * cfg.priceVoicePer1k;
}

export type { Services };
