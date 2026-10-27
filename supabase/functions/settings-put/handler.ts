// The parent's rules for the family (time limits, rest hours, the weekly windows, the lock, whether the child's words
// are kept in alerts, whether the AI helper is on). One document; the last write wins and the server counts the versions. Parent devices only.
// The document is checked field by field: anything it does not name is refused.
import { GatewayError } from "../_shared/errors.ts";
import type { FunctionSpec } from "../_shared/handler.ts";
import { CHILD_ID } from "../child-put/handler.ts";

const isInt = (v: unknown, lo: number, hi: number): boolean =>
  typeof v === "number" && Number.isInteger(v) && v >= lo && v <= hi;
const isObject = (v: unknown): v is Record<string, unknown> =>
  v !== null && typeof v === "object" && !Array.isArray(v);

/** Throws `bad_request` unless [rules] is a settings document the app can read. */
export function checkRules(rules: unknown): Record<string, unknown> {
  const bad = (why: string) => new GatewayError("bad_request", `rules_${why}`);
  if (!isObject(rules)) throw bad("not_object");
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
      case "restOn":
      case "lockWhenDone":
      case "keepWords":
      case "aiHelper":
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
  shape: { rules_json: { t: "string", max: 4000 } },
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
