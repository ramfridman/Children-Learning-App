// The ten checks that stand between the model and a child. The model only proposes; this code decides.
// Any failure means the app uses its pre-written RuleTutor line instead. Pure and synchronous: no clock, no network.
import { hebrewRuns, plainVariants, sentenceCount } from "./hebrew.ts";
import { type Blocklist, type Lexicon } from "./lexicon.ts";

export const VALIDATOR_VERSION = "v1";

/** Words and sentences a reply may have, by band (the one table of tutor limits). */
export const LIMITS = {
  A: { words: 10, sentences: 1 },
  B: { words: 15, sentences: 2 },
  C: { words: 20, sentences: 2 },
} as const;

export type Band = keyof typeof LIMITS;

export type Failure =
  | "schema"
  | "characters"
  | "length"
  | "gender"
  | "leak"
  | "numbers"
  | "vocabulary"
  | "pronunciation"
  | "blocklist"
  | "targets";

/** What the model is asked to write (short keys on purpose: fewer tokens, faster). */
export interface TutorReply {
  say: string;
  next: string;
  hl: string[];
  mis: string | null;
  reveals: boolean;
  safety: string;
}

export interface ItemFacts {
  band: Band;
  /** The authored question, vocalised: its words may be used. */
  promptText: string;
  numberSet: number[];
  allowedActions: string[];
  hintThreshold: number;
  objectIds: string[];
  answers: Array<{ id: string; value?: number; label?: string; misconception?: string; correct: boolean }>;
}

export interface TurnFacts {
  hintLevel: number;
  /** The parent's choice for how to address the child. `n`: plural and "let's" forms only. */
  addressForm: "f" | "m" | "n";
  characterGender: "m" | "f";
  /** The names of the speaking character, vocalised (a name is data, not vocabulary). */
  characterNames: string[];
}

export type Verdict =
  | { ok: true; reply: TutorReply; plain: string; vocalised: string }
  | { ok: false; failures: Failure[] };

/** Phrases that look like quantities but are not (once, one by one). Plain words. */
export const NUMBER_IDIOMS = ["פעם אחת", "אחד אחד", "אחת אחת", "אחד אחד"];

const REPLY_KEYS = ["say", "next", "hl", "mis", "reveals", "safety"];
const SAFETY_VALUES = ["none", "worry", "inappropriate"];

function asReply(x: unknown): TutorReply | null {
  if (x === null || typeof x !== "object" || Array.isArray(x)) return null;
  const o = x as Record<string, unknown>;
  const keys = Object.keys(o);
  if (keys.length !== REPLY_KEYS.length || !REPLY_KEYS.every((k) => keys.includes(k))) return null;
  if (typeof o.say !== "string" || o.say.length === 0 || o.say.length > 400) return null;
  if (typeof o.next !== "string" || !/^[a-z_]{2,40}$/.test(o.next)) return null;
  if (
    !Array.isArray(o.hl) || o.hl.length > 6 || !o.hl.every((h) => typeof h === "string" && h.length <= 40)
  ) return null;
  if (o.mis !== null && (typeof o.mis !== "string" || !/^M-[A-Z]{2,5}-[A-Z0-9]{2,12}$/.test(o.mis))) {
    return null;
  }
  if (typeof o.reveals !== "boolean") return null;
  if (typeof o.safety !== "string" || !SAFETY_VALUES.includes(o.safety)) return null;
  return o as unknown as TutorReply;
}

/** Plain words of an authored, vocalised text, as plain to vocalised: the item's own words. */
export function ownWords(texts: readonly string[]): Map<string, string> {
  const out = new Map<string, string>();
  for (const t of texts) {
    for (const w of t.match(/[א-תְ-ׇ]+/g) ?? []) {
      for (const spelling of plainVariants(w)) out.set(spelling, w);
    }
  }
  return out;
}

function containsPhrase(words: string[], phrase: string[], resolveBare: (w: string) => string[]): boolean {
  for (let i = 0; i + phrase.length <= words.length; i++) {
    let hit = true;
    for (let j = 0; j < phrase.length && hit; j++) {
      // The word itself, or the word with a one-letter prefix taken off (the prefix of "and", "the", ...).
      hit = resolveBare(words[i + j]).includes(phrase[j]);
    }
    if (hit) return true;
  }
  return false;
}

export function validateReply(
  raw: unknown,
  item: ItemFacts,
  turn: TurnFacts,
  lex: Lexicon,
  blocklist: Blocklist,
): Verdict {
  const failures = new Set<Failure>();

  // 1. The reply parses and every enum is valid.
  const reply = asReply(raw);
  if (!reply) return { ok: false, failures: ["schema"] };

  // 2. Hebrew letters, spaces and basic punctuation only: no niqqud (the model never vocalises), no digits, no Latin,
  //    no links, no emoji, no placeholders.
  if (!/^[א-ת .,?!:'"-]+$/.test(reply.say)) failures.add("characters");
  const words = hebrewRuns(reply.say);

  // 3. Length for the band.
  const limit = LIMITS[item.band];
  if (words.length === 0 || words.length > limit.words || sentenceCount(reply.say) > limit.sentences) {
    failures.add("length");
  }

  // The item's own words and the speaking character's name are allowed on top of the lexicon.
  const extra = ownWords([
    item.promptText,
    ...item.answers.map((a) => a.label ?? ""),
    ...turn.characterNames,
  ]);

  // 7 and 8. Every word has exactly one reading and is in the vocabulary.
  const vocalisedWords: string[] = [];
  const resolutions = words.map((w) => lex.resolve(w, extra));
  for (const r of resolutions) {
    if (r.ok) vocalisedWords.push(r.form);
    else if (r.reason === "unknown") failures.add("vocabulary");
    else failures.add("pronunciation");
  }

  // 4. Gender: a form that speaks to one child must match the parent's choice; a first-person form, the guide's gender.
  for (const r of resolutions) {
    if (!r.ok || !r.entry) continue;
    const t = r.entry.tags;
    if (t.has("2m") && turn.addressForm !== "m") failures.add("gender");
    if (t.has("2f") && turn.addressForm !== "f") failures.add("gender");
    if (t.has("1m") && turn.characterGender !== "m") failures.add("gender");
    if (t.has("1f") && turn.characterGender !== "f") failures.add("gender");
  }

  // 6. Maths stays true: every quantity in the line belongs to the item (apart from listed idioms).
  let counted = words;
  const text = words.join(" ");
  for (const idiom of NUMBER_IDIOMS) {
    if (text.includes(idiom)) counted = words.join(" ").replace(idiom, " ").split(" ").filter((x) => x);
  }
  const allowedNumbers = new Set(item.numberSet);
  for (const w of counted) {
    const r = lex.resolve(w, extra);
    if (r.ok && r.entry?.num !== undefined && !allowedNumbers.has(r.entry.num)) failures.add("numbers");
  }

  // 5. No answer leak before the item's hint threshold.
  if (turn.hintLevel < item.hintThreshold) {
    if (reply.reveals) failures.add("leak");
    const spellings = (text: string) => (text.match(/[א-תְ-ׇ]+/g) ?? []).flatMap((w) => plainVariants(w));
    const promptPlain = new Set(spellings(item.promptText));
    const forbidden = new Set<string>();
    const right = item.answers.find((a) => a.correct);
    if (right) {
      if (right.value !== undefined) { for (const f of lex.numberWordsOf(right.value)) forbidden.add(f); }
      // A label's own words give the answer away only if the wrong options do not share them.
      const others = new Set(item.answers.filter((a) => !a.correct).flatMap((a) => spellings(a.label ?? "")));
      for (const w of spellings(right.label ?? "")) if (!others.has(w)) forbidden.add(w);
    }
    for (const f of promptPlain) forbidden.delete(f);
    for (const w of words) {
      const bare = new Set([w, ...[...Array(3).keys()].map((k) => w.slice(k + 1))]);
      for (const b of bare) if (forbidden.has(b)) failures.add("leak");
    }
  }

  // 9. Blocklists: personal questions, purchases, brands, fear, links, pressure.
  const bares = (w: string) => [w, ...[1, 2, 3].filter((k) => w.length > k + 1).map((k) => w.slice(k))];
  for (const phrases of Object.values(blocklist)) {
    for (const p of phrases) {
      if (containsPhrase(words, p.split(" "), bares)) failures.add("blocklist");
    }
  }

  // 10. Targets: object ids, the action, the misconception and the safety flag.
  const objects = new Set(item.objectIds);
  const active = new Set(item.answers.map((a) => a.misconception).filter((m): m is string => !!m));
  if (!reply.hl.every((h) => objects.has(h))) failures.add("targets");
  if (reply.next !== "none" && !item.allowedActions.includes(reply.next)) failures.add("targets");
  if (reply.mis !== null && !active.has(reply.mis)) failures.add("targets");
  if (reply.safety !== "none") failures.add("targets");

  if (failures.size > 0) return { ok: false, failures: [...failures] };

  // The line as it will be voiced and captioned: each Hebrew word replaced by its one reading.
  let i = 0;
  const vocalised = reply.say.replace(/[א-ת]+/g, () => vocalisedWords[i++]);
  return { ok: true, reply, plain: reply.say, vocalised };
}
