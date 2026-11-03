// The parent's rules for the family (time limits, rest hours, the weekly windows, the lock, whether the child's words
// are kept in alerts, whether the AI helper is on, whether trophy ceremonies play, the promises a parent attached to a
// trophy, and for each child which languages are on with their switches). One document; the last write wins and the server
// counts the versions. Parent devices only.
// The document is checked field by field: anything it does not name is refused.
import { GatewayError } from "../_shared/errors.ts";
import type { FunctionSpec } from "../_shared/handler.ts";
import { CHILD_ID } from "../child-put/handler.ts";

const isInt = (v: unknown, lo: number, hi: number): boolean =>
  typeof v === "number" && Number.isInteger(v) && v >= lo && v <= hi;
const isObject = (v: unknown): v is Record<string, unknown> =>
  v !== null && typeof v === "object" && !Array.isArray(v);

/** A trophy as the app names it: `trophy:<land>:<tier>`. */
export const TROPHY_KEY = /^trophy:[a-z]{3,12}:(bronze|silver|gold)$/;
/** A parent's promise: 1 to 60 characters, no control characters and no angle brackets (it is shown in the parent screens). */
// deno-lint-ignore no-control-regex
export const RIBBON_TEXT = /^[^\u0000-\u001f\u007f<>]{1,60}$/u;
/** No links and no addresses in a promise. */
export const RIBBON_LINK = /(https?:|www\.|:\/\/|@|\.(com|net|org|il|io|co|app|me)\b)/i;
/** At most this many promises in all (the whole document must stay small). */
export const MAX_RIBBONS = 30;

/** The language courses (docs/languages/frame.md section 1.5). */
export const LANGUAGE_COURSES = ["eng", "heb", "rus"] as const;
/** At most this many children have language settings (the document has room for no more). */
export const MAX_LANGUAGE_CHILDREN = 6;

/**
 * One switch of a language page: its kind, its range or values, and the courses it belongs to. Mirrored in
 * `testvectors/language-settings.json`, which the app is tested against.
 */
type LanguageSwitch =
  | { t: "bool"; courses: readonly string[] }
  | { t: "int"; min: number; max: number; courses: readonly string[] }
  | { t: "enum"; values: readonly string[]; courses: readonly string[] };
export const LANGUAGE_SWITCHES: Record<string, LanguageSwitch> = {
  on: { t: "bool", courses: ["eng", "heb", "rus"] },
  voice: { t: "bool", courses: ["eng", "heb", "rus"] },
  personal: { t: "bool", courses: ["eng", "heb", "rus"] },
  band: { t: "int", min: 0, max: 2, courses: ["eng", "heb", "rus"] },
  oralOnly: { t: "bool", courses: ["eng"] },
  readCheck: { t: "bool", courses: ["heb"] },
  lettersBefore5: { t: "bool", courses: ["rus"] },
  stress: { t: "enum", values: ["on", "off"], courses: ["rus"] },
  route: { t: "enum", values: ["new", "heritage", "reader"], courses: ["rus"] },
};
/** The questionnaire of each course: the questions and the answers they take. Enums only, nothing free-text. */
export const LANGUAGE_QUESTIONNAIRE: Record<string, Record<string, readonly string[]>> = {
  eng: { knowsLetters: ["no", "some"] },
  heb: {},
  rus: {
    home: ["none", "oneParent", "bothParents", "grandparentsOthers"],
    understands: ["no", "some", "most"],
    speaks: ["no", "words", "sentences"],
    letters: ["no", "some", "most"],
    reads: ["no", "syllables", "words", "sentences"],
  },
};

/** Throws unless [value] is the family's language settings: child id, then course, then known switches with known values. */
function checkLanguages(value: unknown, bad: (why: string) => GatewayError): void {
  if (!isObject(value) || Object.keys(value).length > MAX_LANGUAGE_CHILDREN) throw bad("languages");
  for (const [id, byCourse] of Object.entries(value)) {
    if (!CHILD_ID.test(id) || !isObject(byCourse)) throw bad("languages");
    for (const [course, switches] of Object.entries(byCourse)) {
      if (!(LANGUAGE_COURSES as readonly string[]).includes(course) || !isObject(switches)) {
        throw bad("languages");
      }
      for (const [name, v] of Object.entries(switches)) {
        if (name === "q") {
          const asks = LANGUAGE_QUESTIONNAIRE[course];
          if (!isObject(v)) throw bad("language_questionnaire");
          for (const [question, answer] of Object.entries(v)) {
            if (
              !Object.hasOwn(asks, question) || typeof answer !== "string" || !asks[question].includes(answer)
            ) {
              throw bad("language_questionnaire");
            }
          }
          continue;
        }
        const sw = Object.hasOwn(LANGUAGE_SWITCHES, name) ? LANGUAGE_SWITCHES[name] : undefined;
        if (!sw || !sw.courses.includes(course)) throw bad("language_switch");
        const ok = sw.t === "bool"
          ? typeof v === "boolean"
          : sw.t === "int"
          ? isInt(v, sw.min, sw.max)
          : typeof v === "string" && sw.values.includes(v);
        if (!ok) throw bad("language_switch");
      }
    }
  }
}
/**
 * The most bytes the document may take as UTF-8 JSON. The table holds at most 12,288 bytes of `jsonb` (`pg_column_size`), which is
 * the text plus the structure; 10,000 leaves room, so a document that passes here can always be stored, and a parent who
 * writes too much gets a 400 instead of a 500 (SEC-L0-3). The characters of `rules_json` are counted too (the shape), but a
 * promise of emoji is four bytes a character.
 */
export const MAX_RULES_BYTES = 10_000;

/** Throws `bad_request` unless [rules] is a settings document the app can read. */
export function checkRules(rules: unknown): Record<string, unknown> {
  const bad = (why: string) => new GatewayError("bad_request", `rules_${why}`);
  if (!isObject(rules)) throw bad("not_object");
  if (new TextEncoder().encode(JSON.stringify(rules)).length > MAX_RULES_BYTES) throw bad("too_large");
  for (const [key, value] of Object.entries(rules)) {
    switch (key) {
      case "limitByBand":
        if (!isObject(value)) throw bad("limits");
        for (const [band, v] of Object.entries(value)) {
          if (!["A", "B", "C"].includes(band) || !isInt(v, 5, 180)) throw bad("limits");
        }
        break;
      case "limitByChild": {
        if (!isObject(value) || Object.keys(value).length > 12) throw bad("child_limits");
        for (const [id, v] of Object.entries(value)) {
          if (!CHILD_ID.test(id) || !isInt(v, 5, 180)) throw bad("child_limits");
        }
        break;
      }
      case "ribbons": {
        // child id, then trophy key, then the words: only the family's own phones ever read them.
        if (!isObject(value) || Object.keys(value).length > 12) throw bad("ribbons");
        let total = 0;
        for (const [id, byTrophy] of Object.entries(value)) {
          if (!CHILD_ID.test(id) || !isObject(byTrophy) || Object.keys(byTrophy).length > 18) {
            throw bad("ribbons");
          }
          for (const [key, text] of Object.entries(byTrophy)) {
            if (!TROPHY_KEY.test(key) || typeof text !== "string") throw bad("ribbons");
            if (!RIBBON_TEXT.test(text) || RIBBON_LINK.test(text)) throw bad("ribbon_text");
            total++;
          }
        }
        if (total > MAX_RIBBONS) throw bad("ribbons");
        break;
      }
      case "languages":
        checkLanguages(value, bad);
        break;
      case "restOn":
      case "lockWhenDone":
      case "keepWords":
      case "aiHelper":
      case "ceremonies":
        if (typeof value !== "boolean") throw bad(key);
        break;
      case "restStartMinute":
      case "restEndMinute":
        if (!isInt(value, 0, 1439)) throw bad(key);
        break;
      case "schedule": {
        if (!isObject(value)) throw bad("schedule");
        for (const [day, windows] of Object.entries(value)) {
          if (!/^[1-7]$/.test(day) || !Array.isArray(windows) || windows.length > 3) throw bad("schedule");
          for (const w of windows) {
            if (!Array.isArray(w) || w.length !== 2 || !isInt(w[0], 0, 1439) || !isInt(w[1], 0, 1439)) {
              throw bad("schedule");
            }
          }
        }
        break;
      }
      default:
        throw bad("unknown_key");
    }
  }
  return rules;
}

export const spec: FunctionSpec = {
  name: "settings-put",
  access: { kind: "device", roles: ["parent"] },
  shape: { rules_json: { t: "string", max: 10_000 } },
  run: async (ctx) => {
    let parsed: unknown;
    try {
      parsed = JSON.parse(ctx.body.rules_json as string);
    } catch {
      throw new GatewayError("bad_request", "rules_not_json");
    }
    const rules = checkRules(parsed);
    const version = await ctx.svc.store.putSettings(ctx.auth!.device.familyId, rules);
    return { version };
  },
};
