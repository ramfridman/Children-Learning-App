// Runs every reviewed live-helper line (content/tutor-lines/hero-son.json) through the server's ten checks
// (supabase/functions/_shared/validator.ts) against the starter-pack test vector (testvectors/publish-starter.json).
// A line that fails can never be sent, so it is never voiced. Free and offline; needs Node 22.18 or later (it reads .ts files).
//
//   node tools/check_tutor_lines.mjs                 all lines; prints the failing ones
//   SAY="..." node tools/check_tutor_lines.mjs       the same, but the band C / form m / hint 0 line of give.butterflies.4 is replaced
//                                                    by SAY (to try a rewording before it goes into the file)
//
// The check uses the line as the model would send it: plain letters (the lexicon vocalises), no "!", the speaking
// character a boy ("hero-son"), the parent's address form from the line, the hint level from the line.
import { readFileSync } from "node:fs";
import { fileURLToPath, pathToFileURL } from "node:url";

const root = fileURLToPath(new URL("../", import.meta.url));
const shared = pathToFileURL(root + "supabase/functions/_shared/").href;
const { validateReply } = await import(shared + "validator.ts");
const { loadLexicon, loadBlocklist } = await import(shared + "lexicon.ts");
const vector = JSON.parse(readFileSync(root + "testvectors/publish-starter.json", "utf8"));
const lines = JSON.parse(readFileSync(root + "content/tutor-lines/hero-son.json", "utf8"));
const lex = loadLexicon();
const blocklist = loadBlocklist();

let failing = 0;
for (const l of lines) {
  const it = vector.items.find((i) => i.item_id === l.item);
  if (!it) {
    console.log("no item in the test vector:", l.item);
    failing++;
    continue;
  }
  const facts = {
    band: l.band,
    promptText: it.prompt_text,
    numberSet: it.number_set,
    allowedActions: it.allowed_actions,
    hintThreshold: it.hint_threshold,
    objectIds: it.object_ids,
    answers: it.answers,
  };
  const turn = { hintLevel: l.hint, addressForm: l.form, characterGender: "m", characterNames: ["נִיצִי", "גִּבּוֹר"] };
  const swap = process.env.SAY && l.item === "give.butterflies.4" && l.band === "C" && l.form === "m" && l.hint === 0;
  const say = swap ? process.env.SAY : l.say.replace(/!/g, "");
  const reply = { say, next: "none", hl: [], mis: null, reveals: false, safety: "none" };
  const v = validateReply(reply, facts, turn, lex, blocklist);
  if (!v.ok) {
    failing++;
    console.log(l.item, l.band, l.form, "hint", l.hint, JSON.stringify(v.failures), JSON.stringify(v.unknown ?? []), "|", say);
  }
}
console.log("checked", lines.length, "failing", failing);
process.exitCode = failing ? 1 : 0;
