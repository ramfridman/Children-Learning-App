// The tutor's prompt: server code, a fixed template filled only from the server's own tables. Nothing a device sends
// ever becomes text in it (a device sends ids, numbers and enums), and the one free-text field of the content rows
// (the author's goal) is stripped of anything that could close a tag. The prompt holds nothing secret.
import { hebrewRuns, stripMarks } from "./hebrew.ts";
import type { Lexicon } from "./lexicon.ts";
import { type Band, LIMITS, type TurnFacts } from "./validator.ts";

export const PROMPT_VERSION = "p1";

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
    "Use ONLY words from <vocabulary> and the words of the item and of the guide's name. You may add the one-letter prefixes ו ה ב כ ל מ ש to a word.",
    "Never ask personal questions (name, home, school, family, photos). Never mention purchases, links, brands or anything scary. Never create pressure or guilt. Stay on the task.",
    "Never state the correct answer, or a number that is not in the item, unless the hint level is at or above the threshold.",
    '"next" is one of the allowed actions or "none". "hl" lists object ids to highlight, only from the list. "mis" is the misconception tag that fits the mistake, or null. "reveals" is true only if the line states the answer. "safety" is always "none".',
    `<vocabulary>${vocabulary}</vocabulary>`,
  ].join("\n");
}

/** The part that depends on the item and the turn. */
export function userPrompt(
  item: PromptItem,
  turn: TurnFacts,
  attempts: readonly Attempt[],
  descriptions: ReadonlyMap<string, string>,
  retryReasons: readonly string[] = [],
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
  if (retryReasons.length > 0) {
    lines.push(
      `Your previous reply was refused (${retryReasons.join(", ")}). Write a new one that fixes this.`,
    );
  }
  lines.push("Write the JSON reply now.");
  return lines.join("\n");
}
