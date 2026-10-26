// The words the tutor may use, each with one reviewed vocalised spelling. A spelling that two entries share is
// ambiguous (more than one reading) and is never allowed in a line, because the voice could say the wrong word.
import { hasMarks, plainVariants, prefixSplits, stripMarks, vocalisePrefix } from "./hebrew.ts";
import lexiconJson from "./lexicon/he-child.v1.json" with { type: "json" };
import blocklistJson from "./lexicon/blocklist.he.json" with { type: "json" };

export interface Entry {
  /** The vocalised form. */
  form: string;
  /** The same letters without niqqud. */
  plain: string;
  /** Every everyday spelling without niqqud (with or without the vowel letters that modern spelling adds). */
  spellings: string[];
  /** The value, for a number word. */
  num?: number;
  /** Who the form speaks to (`2m`, `2f`, `2pl`) or who speaks (`1m`, `1f`, `1pl`). */
  tags: ReadonlySet<string>;
}

export type Resolution =
  | { ok: true; form: string; entry?: Entry; prefix: string }
  | { ok: false; reason: "unknown" | "ambiguous" };

export class Lexicon {
  readonly byPlain = new Map<string, Entry[]>();

  constructor(words: readonly string[]) {
    for (const w of words) {
      const [formPart, ...tags] = w.split("|");
      // `form=spelling`: a spelling that the marks do not predict (עַכְשָׁו is written עכשיו).
      const [form, ...alternates] = formPart.split("=");
      const entry: Entry = {
        form,
        plain: stripMarks(form),
        spellings: [...new Set([...plainVariants(form), ...alternates])],
        tags: new Set(),
        num: undefined,
      };
      const tagSet = new Set<string>();
      for (const t of tags.flatMap((x) => x.split(","))) {
        const m = /^num:(\d{1,2})$/.exec(t);
        if (m) entry.num = Number(m[1]);
        else if (t) tagSet.add(t);
      }
      (entry as { tags: ReadonlySet<string> }).tags = tagSet;
      for (const spelling of entry.spellings) {
        const list = this.byPlain.get(spelling) ?? [];
        if (!list.some((e) => e.form === entry.form)) list.push(entry);
        this.byPlain.set(spelling, list);
      }
    }
  }

  get size(): number {
    return this.byPlain.size;
  }

  /** Spellings with more than one reading. */
  ambiguous(): string[] {
    return [...this.byPlain].filter(([, l]) => l.length > 1).map(([p]) => p);
  }

  /**
   * One word of a line: its reading, from the item's own words (`extra`, plain to vocalised) or the lexicon, with a
   * prefix split off if the whole word is not known.
   */
  resolve(plain: string, extra: ReadonlyMap<string, string> = new Map()): Resolution {
    const whole = this.#direct(plain, extra);
    if (whole.ok || whole.reason === "ambiguous") return whole;
    for (const { prefix, rest } of prefixSplits(plain)) {
      const r = this.#direct(rest, extra);
      if (r.ok) return { ok: true, form: vocalisePrefix(prefix, rest) + r.form, entry: r.entry, prefix };
      if (r.reason === "ambiguous") return r;
    }
    return { ok: false, reason: "unknown" };
  }

  #direct(plain: string, extra: ReadonlyMap<string, string>): Resolution {
    const own = extra.get(plain);
    if (own !== undefined) return { ok: true, form: own, prefix: "" };
    const list = this.byPlain.get(plain);
    if (!list) return { ok: false, reason: "unknown" };
    if (list.length > 1) return { ok: false, reason: "ambiguous" };
    return { ok: true, form: list[0].form, entry: list[0], prefix: "" };
  }

  /** Every spelling of every number word with this value (prefixed forms are found through [resolve]). */
  numberWordsOf(value: number): string[] {
    return [...this.byPlain].filter(([, l]) => l.some((e) => e.num === value)).map(([spelling]) => spelling);
  }
}

export interface Blocklist {
  /** Category name to phrases of plain words, e.g. "איך קוראים לך". */
  [category: string]: string[];
}

export const loadBlocklist = (): Blocklist => (blocklistJson as { phrases: Blocklist }).phrases;

export function loadLexicon(): Lexicon {
  return new Lexicon((lexiconJson as { words: string[] }).words);
}

/** What the checker of the lexicon file itself looks for. Returns the problems found (empty when it is sound). */
export function lexiconProblems(words: readonly string[]): string[] {
  const problems: string[] = [];
  const seen = new Map<string, string>();
  for (const w of words) {
    const [form, ...alternates] = w.split("|")[0].split("=");
    if (!/^[א-תְ-ׇ]+$/.test(form)) problems.push(`${w}: only Hebrew letters and niqqud`);
    for (const a of alternates) {
      if (!/^[א-ת]+$/.test(a)) problems.push(`${w}: a spelling is plain Hebrew letters`);
      else if (!hasMarks(form) && form.length > 1) problems.push(`${w}: no niqqud`);
    }
    for (const spelling of [...plainVariants(form), ...alternates]) {
      const old = seen.get(spelling);
      if (old !== undefined && old !== form) problems.push(`${spelling}: two readings (${old}, ${form})`);
      seen.set(spelling, form);
    }
    for (const t of w.split("|").slice(1).flatMap((x) => x.split(","))) {
      if (!/^(num:\d{1,2}|2m|2f|2pl|1m|1f|1pl)$/.test(t)) problems.push(`${w}: unknown tag ${t}`);
    }
  }
  return problems;
}
