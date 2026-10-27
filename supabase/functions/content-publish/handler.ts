// Publishes the item index of one signed pack to the server tables that the tutor's prompt is built from.
// Callable only from the owner's computer, with the publish secret. It sends no audio and nothing a device
// could have written; the index is made from the verified pack by `pack_builder publish`.
import { GatewayError } from "../_shared/errors.ts";
import type { FunctionSpec } from "../_shared/handler.ts";
import type { Shape } from "../_shared/schema.ts";
import type { PublishedItem, PublishedPack } from "../_shared/store.ts";

export const MAX_PUBLISH_BYTES = 256 * 1024;

const id = (max: number) => ({ t: "string", max, pattern: /^[a-z0-9][a-z0-9._-]{0,63}$/ }) as const;
const text = (max: number) => ({ t: "string", max, pattern: /^[^\p{Cc}\p{Cf}\p{Zl}\p{Zp}]+$/u }) as const;
const tag = { t: "string", max: 20, pattern: /^M-[A-Z]{2,5}-[A-Z0-9]{2,12}$/ } as const;
const skill = { t: "string", max: 12, pattern: /^[A-Z]{2,5}-[A-Z]-[0-9]{2}$/ } as const;

const answer: Shape = {
  id: { t: "string", max: 16, pattern: /^[a-z][a-z0-9-]{0,15}$/ },
  value: { t: "int", min: -999, max: 9999, optional: true },
  label: { ...text(80), optional: true },
  misconception: { ...tag, optional: true },
  correct: { t: "bool" },
};

const item: Shape = {
  item_id: id(64),
  revision: { t: "int", min: 1, max: 9999 },
  template: { t: "string", max: 32, pattern: /^[a-z][a-z0-9_]{1,31}$/ },
  band: { t: "enum", values: ["A", "B", "C"] },
  skill_ids: { t: "array", of: skill, maxItems: 10 },
  llm_allowed: { t: "bool" },
  goal: text(300),
  prompt_text: text(400),
  answers: { t: "array", of: { t: "object", shape: answer }, maxItems: 8 },
  number_set: { t: "array", of: { t: "int", min: -999, max: 9999 }, maxItems: 40 },
  allowed_actions: { t: "array", of: { t: "string", max: 40, pattern: /^[a-z_]{2,40}$/ }, maxItems: 12 },
  hint_threshold: { t: "int", min: 1, max: 3 },
  object_ids: {
    t: "array",
    of: { t: "string", max: 40, pattern: /^[a-z0-9][a-z0-9_-]{0,39}$/ },
    maxItems: 40,
  },
};

const misconception: Shape = {
  tag,
  skill_ids: { t: "array", of: skill, maxItems: 10 },
  description: text(300),
};

const character: Shape = {
  character_id: { t: "string", max: 40, pattern: /^[a-z0-9-]{2,40}$/ },
  name_he: { t: "string", max: 40, pattern: /^[א-תְ-ׇ ]+$/ },
  gender: { t: "enum", values: ["m", "f"] },
  voice_id: { t: "string", max: 40, pattern: /^[A-Za-z0-9]{10,40}$/, optional: true },
  personal: { t: "bool" },
};

export const spec: FunctionSpec = {
  name: "content-publish",
  access: { kind: "publish" },
  maxBodyBytes: MAX_PUBLISH_BYTES,
  shape: {
    pack_id: { t: "string", max: 41, pattern: /^[a-z0-9-]{3,41}$/ },
    pack_version: { t: "string", max: 14, pattern: /^[0-9]{1,4}\.[0-9]{1,4}\.[0-9]{1,4}$/ },
    manifest_sha256: { t: "string", max: 64, pattern: /^[0-9a-f]{64}$/ },
    items: { t: "array", of: { t: "object", shape: item }, maxItems: 400 },
    misconceptions: { t: "array", of: { t: "object", shape: misconception }, maxItems: 100 },
    characters: { t: "array", of: { t: "object", shape: character }, maxItems: 40 },
  },
  run: async (ctx) => {
    const b = ctx.body as {
      pack_id: string;
      pack_version: string;
      manifest_sha256: string;
      items: Array<Record<string, unknown>>;
      misconceptions: Array<Record<string, unknown>>;
      characters: Array<Record<string, unknown>>;
    };
    const items: PublishedItem[] = b.items.map((i) => ({
      itemId: i.item_id as string,
      revision: i.revision as number,
      template: i.template as string,
      band: i.band as "A" | "B" | "C",
      skillIds: i.skill_ids as string[],
      llmAllowed: i.llm_allowed as boolean,
      goal: i.goal as string,
      promptText: i.prompt_text as string,
      answers: (i.answers as Array<Record<string, unknown>>).map((a) => ({
        id: a.id as string,
        ...(a.value === undefined ? {} : { value: a.value as number }),
        ...(a.label === undefined ? {} : { label: a.label as string }),
        ...(a.misconception === undefined ? {} : { misconception: a.misconception as string }),
        correct: a.correct as boolean,
      })),
      numberSet: i.number_set as number[],
      allowedActions: i.allowed_actions as string[],
      hintThreshold: i.hint_threshold as number,
      objectIds: i.object_ids as string[],
    }));
    // Meaning, beyond the shape: one right answer, no repeated ids, at least one skill.
    const seen = new Set<string>();
    for (const it of items) {
      if (seen.has(it.itemId)) throw new GatewayError("bad_request", "duplicate_item");
      seen.add(it.itemId);
      if (it.skillIds.length < 1) throw new GatewayError("bad_request", "no_skill");
      if (it.answers.length < 1 || it.answers.filter((a) => a.correct).length !== 1) {
        throw new GatewayError("bad_request", "one_correct_answer");
      }
      if (new Set(it.answers.map((a) => a.id)).size !== it.answers.length) {
        throw new GatewayError("bad_request", "duplicate_answer");
      }
    }
    const pack: PublishedPack = {
      packId: b.pack_id,
      packVersion: b.pack_version,
      manifestSha256: b.manifest_sha256,
      items,
      misconceptions: b.misconceptions.map((m) => ({
        tag: m.tag as string,
        skillIds: m.skill_ids as string[],
        description: m.description as string,
      })),
      characters: b.characters.map((c) => ({
        characterId: c.character_id as string,
        nameHe: c.name_he as string,
        gender: c.gender as "m" | "f",
        voiceId: (c.voice_id as string | undefined) ?? null,
        personal: c.personal as boolean,
      })),
    };
    const result = await ctx.svc.store.publishContent(pack);
    if (result === "older") throw new GatewayError("bad_request", "version_older");
    if (result === "conflict") throw new GatewayError("bad_request", "version_conflict");
    return {
      result,
      items: items.length,
      misconceptions: pack.misconceptions.length,
      characters: pack.characters.length,
    };
  },
};
