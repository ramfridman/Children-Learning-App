// The tutor's prompt: server code, a fixed template filled only from the server's own tables. Nothing a device sends
// ever becomes text in it (a device sends ids, numbers and enums), and the one free-text field of the content rows
// (the author's goal) is stripped of anything that could close a tag. The prompt holds nothing secret.
import { hebrewRuns, stripMarks } from "./hebrew.ts";
import type { Lexicon } from "./lexicon.ts";
import { type Band, LIMITS, type TurnFacts } from "./validator.ts";

export const PROMPT_VERSION = "p4";

export interface PromptItem {
  itemId: string;
  band: Band;
  goal: string;
  promptText: string;
  numberSet: number[];
  allowedActions: string[];
  hintThreshold: number;
  objectIds: string[];
  answers: Array<{ id: string; value?: number; label?: string; misconception?: string; correct: boolean }>;
}

export interface Attempt {
  /** The id of the option chosen, or `n=4` for a count given. */
  option: string;
  /** `incorrect` or `unsure`. */
  result: string;
  misconception?: string;
}

/** Teaching moves: misconception tag (or `default`) to help levels to the different ways to help at that level. */
export type Moves = Readonly<Record<string, readonly (readonly string[])[]>>;

/** The moves from the server's config row (the file `content/tutor-moves.json`); anything malformed is left out. */
export function movesOf(raw: unknown): Moves {
  const src = (raw as { moves?: unknown } | null)?.moves;
  if (src === null || typeof src !== "object" || Array.isArray(src)) return {};
  const out: Record<string, string[][]> = {};
  for (const [tag, levels] of Object.entries(src as Record<string, unknown>)) {
    if (!/^(default|M-[A-Z]{2,5}-[A-Z0-9]{2,12})$/.test(tag) || !Array.isArray(levels)) continue;
    const clean = levels.slice(0, 3).map((alts) =>
      Array.isArray(alts)
        ? alts.filter((a): a is string => typeof a === "string" && a.length >= 8 && a.length <= 240).slice(
          0,
          4,
        )
        : []
    );
    if (clean.length > 0 && clean.every((alts) => alts.length > 0)) out[tag] = clean;
  }
  return out;
}

/**
 * The one teaching move for this line, or null. The help level picks the row (a mistake without a tag, or the level 0
 * of the first help, uses the first row); the band and the address form pick among the alternatives, so that the
 * lines of different cells differ while the same cell always gets the same move.
 */
export function moveFor(
  moves: Moves,
  mistake: string,
  hintLevel: number,
  band: Band,
  form: TurnFacts["addressForm"],
): string | null {
  const rows = moves[mistake] ?? moves["default"];
  if (!rows) return null;
  const alts = rows[Math.min(Math.max(hintLevel, 1), rows.length) - 1];
  if (!alts || alts.length === 0) return null;
  const at = ({ A: 0, B: 1, C: 2 }[band] * 3 + { f: 0, m: 1, n: 2 }[form] + hintLevel) % alts.length;
  return alts[at];
}

const ADDRESS: Record<TurnFacts["addressForm"], string> = {
  n: 'Speak to the child in the plural or "let\'s" forms only (בואו, נספור, נסו). Never use a singular masculine or feminine form of "you".',
  m: 'The child is addressed as masculine singular (נסה, בוא), but plural and "let\'s" forms are still best.',
  f: 'The child is addressed as feminine singular (נסי, בואי), but plural and "let\'s" forms are still best.',
};

/** Characters that could close or fake a tag, or start a new instruction line. */
const safe = (s: string): string =>
  s.replace(/[<>\p{Cc}\p{Cf}]/gu, " ").replace(/\s+/g, " ").trim().slice(0, 400);

/** The part of the prompt that never changes for a band and address form: cached by the model provider. */
export function systemPrompt(band: Band, form: TurnFacts["addressForm"], lex: Lexicon): string {
  const limit = LIMITS[band];
  const vocabulary = [...new Set([...lex.byPlain.values()].flat().map((e) => stripMarks(e.form)))].sort()
    .join(" ");
  return [
    "You are the voice of a friendly computer helper for a young child who is learning maths, in Hebrew.",
    "You are a computer helper, not a person, and you never claim to be human or to have feelings.",
    'Reply with ONE JSON object and nothing else, with exactly these keys: {"say":"...","next":"...","hl":[],"mis":null,"reveals":false,"safety":"none"}.',
    `"say": Hebrew letters only. No niqqud, no digits (write numbers as words), no Latin letters, no emoji, no placeholders. At most ${limit.words} words and ${limit.sentences} sentence(s). One short question or one short encouraging step; never a lecture.`,
    ADDRESS[form],
    "Use ONLY words from <vocabulary> and the words of the item and of the guide's name, spelled exactly as listed (the list uses the short spelling, so write נספר not נספור). You may add the one-letter prefixes ו ה ב כ ל מ ש to a word. Count your words before you answer; keep well under the limit.",
    'Teach like a calm, kind friend sitting beside the child: say the ONE thing to do next, in simple words, not what went wrong. Never say or hint that the child is wrong; never repeat the question word for word. Fit the help to the likely misconception described below (for example, if objects are skipped: touch each one; if one is counted twice: one touch, one number), not a general "try again". Prefer "let\'s" and plural forms.',
    "Never ask personal questions (name, home, school, family, photos). Never mention purchases, links, brands or anything scary. Never create pressure or guilt. Stay on the task.",
    "Never state the correct answer, or a number that is not in the item, unless the hint level is at or above the threshold.",
    '"next" is one of the allowed actions or "none". "hl" lists object ids to highlight, only from the list. "mis" is the misconception tag that fits the mistake, or null. "reveals" is true only if the line states the answer. "safety" is always "none".',
    `<vocabulary>${vocabulary}</vocabulary>`,
  ].join("\n");
}

/** What to tell the model when its reply was refused: one plain sentence per failed check, with the specifics it needs. */
export function retryAdvice(
  band: Band,
  numberSet: readonly number[],
  v: { failures: readonly string[]; unknown?: readonly string[]; wordCount?: number },
): string[] {
  const limit = LIMITS[band];
  const out: string[] = [];
  for (const f of v.failures) {
    if (f === "length") {
      out.push(
        `It was too long (${
          v.wordCount ?? "too many"
        } words): at most ${limit.words} words in total and ${limit.sentences} sentence(s). Cut words.`,
      );
    } else if (f === "vocabulary" || f === "pronunciation") {
      const bad = (v.unknown ?? []).map((w) => safe(w)).join(" ");
      out.push(
        `These words are not allowed${
          bad ? ` (${bad})` : ""
        }: use only words that appear in <vocabulary> (with the ו ה ב כ ל מ ש prefixes), spelled exactly as listed there; pick other words.`,
      );
    } else if (f === "numbers") {
      out.push(
        `It named a quantity that is not in the item. The only number words you may use are for: ${
          numberSet.join(", ") || "none"
        }. Avoid אחד and אחת except in the phrase פעם אחת.`,
      );
    } else if (f === "leak") out.push("It gave the answer away too early.");
    else out.push(`The check "${f}" failed.`);
  }
  return out;
}

/** The part that depends on the item and the turn. */
export function userPrompt(
  item: PromptItem,
  turn: TurnFacts,
  attempts: readonly Attempt[],
  descriptions: ReadonlyMap<string, string>,
  retryReasons: readonly string[] = [],
  move: string | null = null,
): string {
  const plain = (t: string) => hebrewRuns(stripMarks(t)).join(" ");
  const options = item.answers
    .map((a) =>
      `${a.id}${a.value !== undefined ? `=${a.value}` : ""}${a.label ? ` (${plain(a.label)})` : ""}${
        a.correct ? " [correct]" : ""
      }`
    )
    .join("; ");
  const tags = [...new Set(item.answers.map((a) => a.misconception).filter((m): m is string => !!m))];
  const lines = [
    `<item id="${safe(item.itemId)}" band="${item.band}">`,
    `goal: ${safe(item.goal)}`,
    `question the child heard: ${plain(item.promptText)}`,
    `options: ${safe(options)}`,
    `numbers in the item: ${item.numberSet.join(", ") || "none"}`,
    `hint level now: ${turn.hintLevel}; the answer may be stated from level ${item.hintThreshold}`,
    `the child's last attempts: ${
      attempts.length === 0
        ? "none yet"
        : attempts.map((a) =>
          `${safe(a.option)} (${safe(a.result)}${a.misconception ? `, ${safe(a.misconception)}` : ""})`
        ).join("; ")
    }`,
    `likely misconceptions: ${
      tags.length === 0 ? "none" : tags.map((t) => `${t}: ${safe(descriptions.get(t) ?? "")}`).join(" | ")
    }`,
    `allowed next actions: ${item.allowedActions.join(", ") || "none"}`,
    `object ids: ${item.objectIds.join(", ")}`,
    `the guide is called ${turn.characterNames.map((n) => plain(n)).join(" ")} and speaks as ${
      turn.characterGender === "f" ? "a girl" : "a boy"
    }`,
    "</item>",
  ];
  if (move) {
    lines.push(
      `Teaching move for this line (say it in your own simple Hebrew words, do not translate it word for word): ${
        safe(move)
      }`,
    );
  }
  if (retryReasons.length > 0) {
    lines.push(`Your previous reply was refused. ${retryReasons.join(" ")} Write a new one that fixes this.`);
  }
  lines.push("Write the JSON reply now.");
  return lines.join("\n");
}
