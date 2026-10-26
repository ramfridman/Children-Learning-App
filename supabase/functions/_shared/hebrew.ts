// Hebrew text helpers for the tutor's validator. Small, pure, and checked against the same vectors as the app's Dart
// matcher (testvectors/hebrew.json), so the two sides read Hebrew the same way.

/** Niqqud, cantillation marks and the other combining marks of the Hebrew block. */
const MARKS = /[֑-ׇ]/g;

export const stripMarks = (s: string): string => s.replace(MARKS, "");
export const hasMarks = (s: string): boolean => /[֑-ׇ]/.test(s);

/** Maximal runs of Hebrew letters, in order. (Marks never appear in a model reply; see the validator.) */
export const hebrewRuns = (s: string): string[] => s.match(/[א-ת]+/g) ?? [];

/** The one-letter prefixes: and, the, in, as, to, from, that. */
export const PREFIX_LETTERS = "והבכלמש";

/** Splits a leading run of prefix letters (at most three) off a word, shortest first. */
export function prefixSplits(word: string): Array<{ prefix: string; rest: string }> {
  const out: Array<{ prefix: string; rest: string }> = [];
  for (let k = 1; k <= 3 && k < word.length; k++) {
    const prefix = word.slice(0, k);
    if ([...prefix].every((c) => PREFIX_LETTERS.includes(c))) out.push({ prefix, rest: word.slice(k) });
  }
  return out;
}

/**
 * The vocalisation of a prefix before a word. A simple table, not Hebrew grammar: the ה of "the" takes qamats before
 * א ע ר and segol before ח, and every other prefix takes its usual vowel. Words where this is wrong are written out in
 * full in the lexicon, which takes priority.
 */
export function vocalisePrefix(prefix: string, restPlain: string): string {
  const first = restPlain[0] ?? "";
  return [...prefix].map((c, i) => {
    const last = i === prefix.length - 1;
    switch (c) {
      case "ה":
        return last && "אער".includes(first) ? "הָ" : last && first === "ח" ? "הֶ" : "הַ";
      case "ו":
        return "וְ";
      case "ב":
        return "בְּ";
      case "כ":
        return "כְּ";
      case "ל":
        return "לְ";
      case "מ":
        return "מִ";
      default:
        return "שֶׁ";
    }
  }).join("");
}

/**
 * The ways a vocalised word is written without niqqud in everyday Hebrew. Modern spelling adds vowel letters that the
 * marks do not show: a vav after a holam or a qubuts, a yod after a hiriq. A model may write either, so a word is
 * known by all of them: with its marks stripped, and with each such letter added or not.
 */
export function plainVariants(vocalised: string): string[] {
  // Each letter of the word with its marks.
  const letters = vocalised.match(/[א-ת][֑-ׇ]*/g) ?? [];
  let forms = [""];
  letters.forEach((l, i) => {
    const base = l[0];
    const marks = l.slice(1);
    const next = letters[i + 1]?.[0];
    const last = i === letters.length - 1;
    const optional: string[] = [];
    if (!last && base !== "ו" && /[ֹֻ]/.test(marks) && next !== "ו") optional.push("ו");
    if (!last && /ִ/.test(marks) && next !== "י") optional.push("י");
    const next2: string[] = [];
    for (const f of forms) {
      next2.push(f + base);
      for (const extra of optional) next2.push(f + base + extra);
    }
    forms = next2;
  });
  return [...new Set(forms)];
}

/** Counts sentences: runs of text ended by . ? or ! (a line with no ending counts as one). */
export function sentenceCount(s: string): number {
  const parts = s.split(/[.?!]+/).map((p) => p.trim()).filter((p) => p.length > 0);
  return Math.max(1, parts.length);
}
