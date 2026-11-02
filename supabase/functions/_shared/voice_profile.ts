// How a live tutor line is said: the same format, model, voice settings and respellings as the voice packs, taken from
// content/voices.json through the generated voice_profile_data.ts, so the helper sounds like the rest of the app.
import { VOICE_PROFILE } from "./voice_profile_data.ts";

/** Everything that shapes the sound of one line, apart from the voice id. */
export interface VoiceSpec {
  /** The text to send: the vocalised line with the pack's respellings applied. */
  text: string;
  modelId: string;
  outputFormat: string;
  settings: Record<string, number | boolean>;
}

/** The id of the profile every cached clip is stored under, so a clip made another way is never served. */
export const VOICE_PROFILE_ID: string = VOICE_PROFILE.id;

type Rules = Readonly<Record<string, readonly string[]>>;
interface Settings {
  settings: Readonly<Record<string, number | boolean>>;
  styles: Readonly<Record<string, Readonly<Record<string, number | boolean>>>>;
  styleRules: Rules;
}

/** The Eleven v4 models ignore these two ("Style and Speed sliders are not available in Eleven v4"). */
const NOT_FOR_V4 = ["style", "speed"];

/** Respells known tricky words (the number two) exactly as `voice_gen` does before it voices the packs. */
export function respelled(text: string, pronunciation: Readonly<Record<string, string>>): string {
  let out = text;
  for (const [from, to] of Object.entries(pronunciation)) out = out.replaceAll(from, to);
  return out;
}

/**
 * The pack's style for a live line, by the same `styleRules` as the pack. A live line has no `vo:` id, so it is named
 * by its help level in the pack's own words: the first question (hint 0) is `live.prompt` (an `ask`), help 1 and 2
 * are `live.h1`, `live.h2` (a `hint`), help 3 is `live.h3` (a `hint3`). A rule that starts with * matches the END of
 * the id, any other the START; the first style that matches wins, in the order written.
 */
export function styleOfLive(hintLevel: number, rules: Rules = VOICE_PROFILE.styleRules): string | null {
  const id = `live.${hintLevel === 0 ? "prompt" : `h${hintLevel}`}`;
  for (const [style, patterns] of Object.entries(rules)) {
    if (patterns.some((p) => p.startsWith("*") ? id.endsWith(p.slice(1)) : id.startsWith(p))) return style;
  }
  return null;
}

/** The settings of the pack for a line at [hintLevel]: the usual ones with the style on top, key by key. */
export function settingsFor(
  hintLevel: number,
  modelId: string = VOICE_PROFILE.modelId,
  profile: Settings = VOICE_PROFILE,
): Record<string, number | boolean> {
  const style = styleOfLive(hintLevel, profile.styleRules);
  const merged: Record<string, number | boolean> = {
    ...profile.settings,
    ...(style ? profile.styles[style] : {}),
  };
  const out: Record<string, number | boolean> = {};
  for (const k of Object.keys(merged).sort()) {
    if (!(modelId.startsWith("eleven_v4") && NOT_FOR_V4.includes(k))) out[k] = merged[k];
  }
  return out;
}

/** What to send for [vocalised], a line that passed the ten checks, spoken at [hintLevel] (0 to 3). */
export function voiceSpecFor(vocalised: string, hintLevel: number): VoiceSpec {
  return {
    text: respelled(vocalised, VOICE_PROFILE.pronunciation),
    modelId: VOICE_PROFILE.modelId,
    outputFormat: VOICE_PROFILE.outputFormat,
    settings: settingsFor(hintLevel),
  };
}
