import { assert } from "./_shared/testassert.ts";
import { plainVariants, prefixSplits, sentenceCount, stripMarks, vocalisePrefix } from "./_shared/hebrew.ts";
import { lexiconProblems, loadBlocklist, loadLexicon } from "./_shared/lexicon.ts";
import lexiconJson from "./_shared/lexicon/he-child.v1.json" with { type: "json" };

Deno.test("the lexicon file is sound: Hebrew only, niqqud on every word, one reading for every spelling, known tags", () => {
  const problems = lexiconProblems((lexiconJson as { words: string[] }).words);
  assert.deepEqual(problems, []);
});

Deno.test("the lexicon is marked as unreviewed until an editor approves it", () => {
  assert.equal((lexiconJson as { review: string }).review, "needs-editor");
  assert.ok(loadLexicon().size > 400);
});

Deno.test("a word is known by every everyday spelling: with its marks stripped, and with the vowel letters modern spelling adds", () => {
  assert.deepEqual(plainVariants("נִסְפֹּר").sort(), ["ניספור", "ניספר", "נספור", "נספר"].sort());
  assert.ok(plainVariants("אָדֹם").includes("אדום"));
  assert.ok(plainVariants("אָדֹם").includes("אדם"));
  assert.deepEqual(plainVariants("שָׁלוֹשׁ"), ["שלוש"]);
  assert.ok(plainVariants("כְּחֻלָּה").includes("כחולה"));
});

Deno.test("the lexicon finds words in either spelling, and a prefix is taken off when the whole word is unknown", () => {
  const lex = loadLexicon();
  for (const spelling of ["נספור", "נספר"]) {
    const r = lex.resolve(spelling);
    assert.ok(r.ok && r.form === "נִסְפֹּר", spelling);
  }
  const prefixed = lex.resolve("והפרחים");
  assert.ok(prefixed.ok);
  if (prefixed.ok) {
    assert.equal(stripMarks(prefixed.form), "והפרחים");
    assert.ok(prefixed.form.startsWith("וְהַ"), prefixed.form);
  }
  assert.deepEqual(lex.resolve("בננה"), { ok: false, reason: "unknown" });
  assert.deepEqual(lex.resolve("xyz"), { ok: false, reason: "unknown" });
});

Deno.test("a spelling with two readings is never resolved", () => {
  const lex = new (loadLexicon().constructor as new (w: string[]) => ReturnType<typeof loadLexicon>)([
    "סֵפֶר",
    "סִפֵּר",
  ]);
  assert.deepEqual(lex.resolve("ספר"), { ok: false, reason: "ambiguous" });
  assert.deepEqual(lexiconProblems(["סֵפֶר", "סִפֵּר"]).length > 0, true);
});

Deno.test("the number words of the lexicon carry their values, in both genders, and the construct forms", () => {
  const lex = loadLexicon();
  for (
    const [word, value] of [["שלוש", 3], ["שלושה", 3], ["שלושת", 3], ["ארבע", 4], ["חמישה", 5], ["שבע", 7], [
      "שמונה",
      8,
    ]] as const
  ) {
    const r = lex.resolve(word);
    assert.ok(r.ok && r.entry?.num === value, `${word} is ${value}`);
  }
  assert.ok(lex.numberWordsOf(3).includes("שלוש") && lex.numberWordsOf(3).includes("שלושה"));
});

Deno.test("prefix helpers: splits, vocalisation and sentence counting", () => {
  assert.deepEqual(prefixSplits("והפרחים").map((s) => s.prefix), ["ו", "וה", "והפ".slice(0, 2)].slice(0, 2));
  assert.equal(vocalisePrefix("ה", "פרח"), "הַ");
  assert.equal(vocalisePrefix("ה", "אדום"), "הָ");
  assert.equal(vocalisePrefix("ל", "ספור"), "לְ");
  assert.equal(sentenceCount("בואו נספור."), 1);
  assert.equal(sentenceCount("בואו נספור. מה ראינו?"), 2);
  assert.equal(sentenceCount("בואו נספור"), 1);
});

Deno.test("the blocklist has its categories and only plain words", () => {
  const b = loadBlocklist();
  for (const c of ["personal", "purchase", "brand", "fear", "link", "pressure"]) {
    assert.ok(b[c] && b[c].length > 3, c);
    for (const phrase of b[c]) assert.ok(/^[א-ת ]+$/.test(phrase), `${c}: ${phrase}`);
  }
});
