import { assert } from "./_shared/testassert.ts";
import { Lexicon, loadBlocklist, loadLexicon } from "./_shared/lexicon.ts";
import {
  type Band,
  type Failure,
  type ItemFacts,
  LIMITS,
  type TurnFacts,
  type TutorReply,
  validateReply,
  type Verdict,
} from "./_shared/validator.ts";

import { retryAdvice } from "./_shared/tutor_prompt.ts";

const lex = loadLexicon();
const blocklist = loadBlocklist();

interface VectorItem {
  item_id: string;
  band: Band;
  prompt_text: string;
  number_set: number[];
  allowed_actions: string[];
  hint_threshold: number;
  object_ids: string[];
  answers: Array<{ id: string; value?: number; label?: string; misconception?: string; correct: boolean }>;
}

const vector = JSON.parse(
  await Deno.readTextFile(new URL("../../testvectors/publish-starter.json", import.meta.url)),
) as { items: VectorItem[] };

const factsOf = (i: VectorItem, band: Band = i.band): ItemFacts => ({
  band,
  promptText: i.prompt_text,
  numberSet: i.number_set,
  allowedActions: i.allowed_actions,
  hintThreshold: i.hint_threshold,
  objectIds: i.object_ids,
  answers: i.answers,
});

const count3 = vector.items.find((i) => i.item_id === "count.butterflies.3")!;
const item = factsOf(count3);
const turn = (over: Partial<TurnFacts> = {}): TurnFacts => ({
  hintLevel: 0,
  addressForm: "n",
  characterGender: "f",
  characterNames: ["נִיצִי"],
  ...over,
});

const reply = (say: string, over: Partial<TutorReply> = {}): TutorReply => ({
  say,
  next: "replay_prompt_slow",
  hl: [],
  mis: null,
  reveals: false,
  safety: "none",
  ...over,
});

const check = (r: unknown, i: ItemFacts = item, t: TurnFacts = turn(), l: Lexicon = lex): Verdict =>
  validateReply(r, i, t, l, blocklist);
const fails = (v: Verdict): Failure[] => (v.ok ? [] : v.failures);

Deno.test("a good reply passes, and comes back as the one reading that will be voiced and captioned", () => {
  const v = check(reply("בואו נספור לאט"));
  assert.ok(v.ok, JSON.stringify(v));
  if (v.ok) {
    assert.equal(v.vocalised, "בּוֹאוּ נִסְפֹּר לְאַט");
    assert.equal(v.plain, "בואו נספור לאט");
  }
});

Deno.test("both spellings of a word pass, and a prefix is vocalised: 'the fingers'", () => {
  const v = check(reply("נסתכל על האצבעות"));
  assert.ok(v.ok, JSON.stringify(v));
  if (v.ok) assert.ok(v.vocalised.includes("הָאֶצְבָּעוֹת"), v.vocalised);
});

Deno.test("1. the reply must be exactly the agreed object", () => {
  for (const bad of [null, "text", 5, [], {}, { say: "בואו נספור" }]) {
    assert.deepEqual(fails(check(bad)), ["schema"]);
  }
  const extra = { ...reply("בואו נספור"), more: 1 };
  assert.deepEqual(fails(check(extra)), ["schema"]);
  assert.deepEqual(fails(check(reply("בואו נספור", { next: "Fly!" }))), ["schema"]);
  assert.deepEqual(fails(check(reply("בואו נספור", { safety: "other" }))), ["schema"]);
  assert.deepEqual(fails(check({ ...reply("בואו נספור"), reveals: "no" })), ["schema"]);
  assert.deepEqual(fails(check({ ...reply("בואו נספור"), hl: "o1" })), ["schema"]);
  assert.deepEqual(fails(check(reply(""))), ["schema"]);
});

Deno.test("2. only Hebrew letters and basic punctuation: no niqqud, digits, Latin, links, emoji or placeholders", () => {
  for (
    const say of [
      "בֹּואו נספור",
      "בואו נספור 3 פרפרים",
      "Hello נספור",
      "בואו נספור 😀",
      "בואו נספור www.x.com",
      "בואו נספור {child}",
      "בואו נספור <b>לאט</b>",
      "בואו נספור\nלאט",
    ]
  ) {
    assert.ok(fails(check(reply(say))).includes("characters"), say);
  }
});

Deno.test("3. length follows the band: words and sentences", () => {
  const ten = "בואו נספור לאט לאט לאט לאט לאט לאט לאט לאט";
  assert.ok(check(reply(ten)).ok, "ten words in band A");
  assert.ok(fails(check(reply(ten + " לאט"))).includes("length"), "eleven words in band A");
  assert.ok(fails(check(reply("בואו נספור. בואו נבדוק."))).includes("length"), "two sentences in band A");
  const b = factsOf(count3, "B");
  assert.ok(check(reply("בואו נספור. בואו נבדוק."), b).ok, "two sentences in band B");
  assert.ok(
    fails(check(reply("בואו נספור. בואו נבדוק. בואו נראה."), b)).includes("length"),
    "three in band B",
  );
  assert.equal(LIMITS.C.words, 20);
});

Deno.test("4. gender: a form that speaks to one child must match the parent's choice; the plural is always right", () => {
  assert.ok(fails(check(reply("נסה שוב"), item, turn({ addressForm: "f" }))).includes("gender"));
  assert.ok(fails(check(reply("נסי שוב"), item, turn({ addressForm: "m" }))).includes("gender"));
  assert.ok(fails(check(reply("נסה שוב"), item, turn({ addressForm: "n" }))).includes("gender"));
  assert.ok(fails(check(reply("נסי שוב"), item, turn({ addressForm: "n" }))).includes("gender"));
  assert.ok(check(reply("נסה שוב"), item, turn({ addressForm: "m" })).ok);
  assert.ok(check(reply("נסי שוב"), item, turn({ addressForm: "f" })).ok);
  assert.ok(check(reply("נסו שוב"), item, turn({ addressForm: "n" })).ok);
  // The guide speaking about itself.
  assert.ok(fails(check(reply("אני שמח"), item, turn({ characterGender: "f" }))).includes("gender"));
  assert.ok(check(reply("אני שמחה"), item, turn({ characterGender: "f" })).ok);
  assert.ok(check(reply("אני שמח"), item, turn({ characterGender: "m" })).ok);
});

Deno.test("5. no answer leak before the hint threshold, and the flag must be honest", () => {
  const t = turn({ hintLevel: 1 });
  for (const say of ["יש שלוש פרפרים", "יש שלושה פרפרים", "זה שלוש"]) {
    assert.ok(fails(check(reply(say), item, t)).includes("leak"), say);
  }
  assert.ok(fails(check(reply("בואו נספור", { reveals: true }), item, t)).includes("leak"));
  // From the threshold on, the answer may be said.
  assert.ok(check(reply("יש שלוש פרפרים"), item, turn({ hintLevel: 3 })).ok);
  // Wrong numbers are not a leak (but they must belong to the item: see the next check).
  assert.ok(!fails(check(reply("לא ארבע"), item, t)).includes("leak"));
});

Deno.test("6. maths stays true: every quantity belongs to the item, apart from idioms", () => {
  assert.ok(fails(check(reply("יש חמישה פרפרים"), item, turn({ hintLevel: 3 }))).includes("numbers"));
  assert.ok(fails(check(reply("בואו נספור תשע"), item, turn({ hintLevel: 3 }))).includes("numbers"));
  assert.ok(
    check(reply("נגע בכל פרפר פעם אחת"), item, turn({ hintLevel: 3 })).ok,
    "once is an idiom, not a quantity",
  );
  assert.ok(check(reply("יש ארבעה"), item, turn({ hintLevel: 3 })).ok, "four belongs to this item");
  // Every idiom counts, not only the last one that matches; "each one" is not a quantity, a bare "one" is.
  assert.ok(check(reply("נוגעים בכל אחד פעם אחת"), item, turn({ hintLevel: 3 })).ok, "each one, once");
  assert.ok(fails(check(reply("בואו נספור אחד"), item, turn({ hintLevel: 3 }))).includes("numbers"));
});

Deno.test("a refused line says which words and how many, and the retry advice names them", () => {
  const v = check(reply("בואי נספור יחד בבננה"));
  assert.ok(!v.ok);
  if (!v.ok) {
    assert.ok(v.unknown?.includes("בבננה") || v.unknown?.includes("נספור"), JSON.stringify(v.unknown));
    const advice = retryAdvice("A", item.numberSet, v).join(" ");
    assert.ok(advice.includes("not allowed") && advice.includes(v.unknown![0]), advice);
  }
  const long = check(reply("בואו נספור את הפרפרים אחד אחד ונגע בכל פרפר פעם אחת ועוד"));
  assert.ok(!long.ok);
  if (!long.ok) {
    assert.ok(long.wordCount! > LIMITS.A.words);
    assert.ok(retryAdvice("A", item.numberSet, long).join(" ").includes(`at most ${LIMITS.A.words} words`));
  }
});

Deno.test("7. vocabulary: a word the lexicon does not know is refused", () => {
  assert.ok(fails(check(reply("בואו נאכל בננה"))).includes("vocabulary"));
  assert.ok(fails(check(reply("בואו נספור פיל"))).includes("vocabulary"));
  assert.ok(check(reply("בואו נספור פרחים")).ok);
});

Deno.test("8. pronunciation: a spelling with two readings is refused", () => {
  const ambiguous = new Lexicon(["בּוֹאוּ", "נִסְפֹּר", "סֵפֶר", "סִפֵּר"]);
  const v = check(reply("בואו נספור ספר"), item, turn(), ambiguous);
  assert.deepEqual(fails(v), ["pronunciation"]);
});

Deno.test("9. blocklists: personal questions, purchases, brands, fear, links and pressure", () => {
  for (
    const say of [
      "איך קוראים לך",
      "מה השם שלך",
      "איפה אתה גר",
      "אפשר לקנות",
      "בואו נראה גוגל",
      "זה מפחיד",
      "אל תלך",
    ]
  ) {
    assert.ok(fails(check(reply(say))).includes("blocklist"), say);
  }
  assert.ok(!fails(check(reply("בואו נספור לאט"))).includes("blocklist"));
});

Deno.test("10. targets: highlights are this item's objects, the action is allowed, the misconception is active, no safety flag", () => {
  assert.ok(check(reply("בואו נספור", { hl: ["o1", "obj-2"], mis: "M-CNT-DOUBLE" })).ok);
  assert.ok(fails(check(reply("בואו נספור", { hl: ["zzz"] }))).includes("targets"));
  assert.ok(fails(check(reply("בואו נספור", { next: "fly_away" }))).includes("targets"));
  assert.ok(check(reply("בואו נספור", { next: "none" })).ok);
  assert.ok(fails(check(reply("בואו נספור", { mis: "M-GEO-OTHER" }))).includes("targets"));
  assert.ok(fails(check(reply("בואו נספור", { safety: "worry" }))).includes("targets"));
});

Deno.test("a name is data: the guide's own name may be said, another name may not", () => {
  assert.ok(check(reply("אני ניצי")).ok);
  assert.ok(fails(check(reply("אני דני"))).includes("vocabulary"));
});

Deno.test("all failures are reported, not only the first", () => {
  const v = check(reply("בואו נאכל בננה 😀"));
  assert.ok(!v.ok);
  assert.ok(fails(v).includes("characters") && fails(v).includes("vocabulary"));
});

// ---- the evaluation suite: 300 scenarios ------------------------------------------------------------------------

const GOOD_A = [
  "בואו נספור לאט",
  "בואו נסתכל שוב",
  "בואו נבדוק יחד",
  "בואו ננסה עוד פעם",
  "נחשוב יחד על הדרך",
  "בואו נשים אצבע על כל פרפר",
  "יפה מאוד, בואו נמשיך",
  "כמעט, בואו נבדוק שוב",
  "רעיון טוב, בואו נראה",
  "אפשר לספור עם האצבעות",
  "תודה, בואו נתחיל",
  "בואו נבחר יחד",
];
const GOOD_BC = [
  "מה ראינו? בואו נספור שוב לאט",
  "בואו נבדוק יחד ואז נראה אם זה נכון",
  "כל הכבוד! ניסיתם דרך טובה",
  "בואו נחשוב יחד, ואז נבדוק שוב",
  "יפה מאוד. עכשיו בואו נמשיך",
];

interface Scenario {
  rule: Failure | "good";
  item: ItemFacts;
  turn: TurnFacts;
  reply: unknown;
}

function scenarios(): Scenario[] {
  const out: Scenario[] = [];
  const forms: Array<TurnFacts["addressForm"]> = ["n", "m", "f"];
  const genders: Array<TurnFacts["characterGender"]> = ["m", "f"];
  let k = 0;
  for (const vi of vector.items) {
    const bands: Band[] = vi.band === "A" ? ["A", "B", "C"] : [vi.band, "C"];
    for (const band of bands) {
      const it = factsOf(vi, band);
      const lines = band === "A" ? GOOD_A : [...GOOD_A.slice(0, 6), ...GOOD_BC];
      for (const line of lines) {
        const t = turn({ addressForm: forms[k % 3], characterGender: genders[k % 2], hintLevel: k % 4 });
        k++;
        // The 'next' and 'hl' of a good reply use what the item offers.
        const next = it.allowedActions[0] ?? "none";
        out.push({
          rule: "good",
          item: it,
          turn: t,
          reply: reply(line, { next, hl: it.objectIds.slice(0, 1) }),
        });
      }
    }
  }
  const base = factsOf(count3);
  const bad = (
    rule: Failure,
    say: string,
    over: Partial<TutorReply> = {},
    t: Partial<TurnFacts> = {},
    i = base,
  ) => out.push({ rule, item: i, turn: turn(t), reply: reply(say, over) });
  for (
    const say of [
      "בֹּואו נספור",
      "בואו נספור 3",
      "Hello",
      "בואו נספור 😀",
      "בואו נספור www.x.co",
      "בואו {child}",
      "בואו נספור‏",
      "בואו נספור @",
      "בואו נספור #",
    ]
  ) {
    for (let r = 0; r < 3; r++) bad("characters", say + " ".repeat(r));
  }
  for (
    const say of [
      "בואו נספור לאט לאט לאט לאט לאט לאט לאט לאט לאט",
      "בואו נספור. בואו נבדוק. בואו נראה.",
      "בואו נספור. בואו נבדוק.",
    ]
  ) {
    for (let r = 0; r < 9; r++) bad("length", say);
  }
  for (
    const [say, form] of [
      ["נסה שוב", "f"],
      ["נסי שוב", "m"],
      ["נסה שוב", "n"],
      ["נסי שוב", "n"],
      ["הסתכל שוב", "f"],
      ["הסתכלי שוב", "m"],
      ["בוא נספור", "n"],
      ["בואי נספור", "n"],
      ["אני שמח", "f"],
      ["אני שמחה", "m"],
    ] as const
  ) {
    const t = say.startsWith("אני") ? { characterGender: form === "f" ? "f" : "m" } : { addressForm: form };
    // For the first-person lines the gender of the guide is the opposite of the form of the line.
    const tt = say === "אני שמח"
      ? { characterGender: "f" as const }
      : say === "אני שמחה"
      ? { characterGender: "m" as const }
      : t;
    for (let r = 0; r < 3; r++) bad("gender", say + " ".repeat(r), {}, tt as Partial<TurnFacts>);
  }
  for (const say of ["יש שלוש פרפרים", "יש שלושה פרפרים", "זה שלוש", "שלוש!", "ספרנו שלושה", "הכל שלוש"]) {
    for (const h of [0, 1, 2]) {
      for (let r = 0; r < 2; r++) bad("leak", say + " ".repeat(r), {}, { hintLevel: h });
    }
  }
  for (let h = 0; h < 3; h++) {
    for (let r = 0; r < 4; r++) {
      bad("leak", "בואו נספור" + " ".repeat(r), { reveals: true }, { hintLevel: h });
    }
  }
  for (const say of ["יש חמישה פרפרים", "בואו נספור תשע", "יש שבעה", "בואו נספור שש", "יש עשרה פרחים"]) {
    for (let r = 0; r < 6; r++) bad("numbers", say + " ".repeat(r), {}, { hintLevel: 3 });
  }
  for (
    const say of [
      "בואו נאכל בננה",
      "בואו נספור פיל",
      "בואו נשחק כדורגל",
      "בואו נלך לים",
      "בואו נקנח בגלידה",
      "נשיר שיר",
    ]
  ) {
    for (let r = 0; r < 5; r++) bad("vocabulary", say + " ".repeat(r));
  }
  for (
    const say of [
      "איך קוראים לך",
      "מה השם שלך",
      "איפה אתה גר",
      "אפשר לקנות",
      "בואו נראה גוגל",
      "זה מפחיד",
      "אל תלך",
      "באיזה בית ספר",
      "מה מספר הטלפון",
    ]
  ) {
    for (let r = 0; r < 3; r++) bad("blocklist", say + " ".repeat(r));
  }
  for (
    const over of [{ hl: ["zzz"] }, { hl: ["o1", "zzz"] }, { next: "fly_away" }, { mis: "M-GEO-OTHER" }, {
      safety: "worry",
    }, { safety: "inappropriate" }]
  ) {
    for (let r = 0; r < 5; r++) bad("targets", "בואו נספור" + " ".repeat(r), over);
  }
  for (
    const r0 of [
      null,
      "x",
      {},
      { say: "בואו" },
      { ...reply("בואו נספור"), extra: 1 },
      { ...reply("בואו נספור"), next: 5 },
      { ...reply("בואו נספור"), hl: "o1" },
      { ...reply("בואו נספור"), reveals: "no" },
    ]
  ) {
    for (let r = 0; r < 4; r++) out.push({ rule: "schema", item: base, turn: turn(), reply: r0 });
  }
  return out;
}

Deno.test("evaluation suite: every bad reply is refused for its own rule, and good replies are not wrongly refused", () => {
  const all = scenarios();
  assert.ok(all.length >= 300, `${all.length} scenarios`);
  const table = new Map<string, { n: number; ok: number }>();
  for (const s of all) {
    const v = check(s.reply, s.item, s.turn);
    const row = table.get(s.rule) ?? { n: 0, ok: 0 };
    row.n++;
    if (s.rule === "good") {
      if (v.ok) row.ok++;
      else assert.ok(false, `a good reply was refused (${fails(v).join(",")}): ${JSON.stringify(s.reply)}`);
    } else {
      assert.ok(!v.ok, `a bad reply for ${s.rule} passed: ${JSON.stringify(s.reply)}`);
      if (fails(v).includes(s.rule)) row.ok++;
      else {assert.ok(
          false,
          `refused for ${fails(v).join(",")} instead of ${s.rule}: ${JSON.stringify(s.reply)}`,
        );}
    }
    table.set(s.rule, row);
  }
  const good = table.get("good")!;
  assert.equal(good.ok, good.n, "no good reply wrongly refused (target: at most 10%)");
  // The per-rule table, for the milestone report (run with NN_PRINT_EVAL=1).
  if (Deno.env.get("NN_PRINT_EVAL") === "1") {
    const lines = [...table].map(([rule, r]) =>
      `${rule.padEnd(14)} ${String(r.n).padStart(4)} scenarios, ${r.ok} as expected`
    );
    // deno-lint-ignore no-console
    console.log(["EVAL", `total ${all.length}`, ...lines].join("\n"));
  }
});
