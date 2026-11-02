// Builds `voice_profile_data.ts` from `content/voices.json`, so the gateway speaks a live line with the same output
// format, model, voice settings, styles and respellings as `voice_gen` uses for the voice packs. An Edge Function
// cannot read the repo's `content/` folder when deployed, so the few values it needs are checked in as a generated
// file, and `voice_profile_test.ts` fails when the two differ.
//
// After a change to content/voices.json, from the repo root:
//   deno run --allow-read=content,supabase --allow-write=supabase/functions/_shared/voice_profile_data.ts supabase/functions/_shared/voice_profile_gen.ts

export interface VoicesJson {
  modelId: string;
  outputFormat: string;
  settings: Record<string, unknown>;
  styles: Record<string, Record<string, unknown>>;
  styleRules: Record<string, string[]>;
  pronunciation: Record<string, string>;
}

/** The numbers ElevenLabs knows and the range each may take; `use_speaker_boost` is the one switch. */
const RANGES: Record<string, [number, number]> = {
  stability: [0, 1],
  similarity_boost: [0, 1],
  style: [0, 1],
  speed: [0.7, 1.2],
};
const HEBREW_MODELS = ["eleven_v4", "eleven_v4_turbo", "eleven_v3", "eleven_v3_conversational"];

/** The rules `voice_gen` also applies (voice_gen_lib.dart checkModel, checkFormat, settingsToSend). */
export function checkVoices(v: VoicesJson): void {
  if (!HEBREW_MODELS.includes(v.modelId)) throw new Error(`"${v.modelId}" is not a model that reads Hebrew`);
  if (!/^mp3_44100_(64|96|128|192)$/.test(v.outputFormat)) {
    throw new Error(`the output format "${v.outputFormat}" is not MP3 at 44.1 kHz and 64 kbps or more`);
  }
  for (const [name, s] of [["settings", v.settings], ...Object.entries(v.styles)] as const) {
    for (const [k, x] of Object.entries(s)) {
      const r = RANGES[k];
      if (k === "use_speaker_boost") {
        if (typeof x !== "boolean") throw new Error(`${name}: use_speaker_boost is true or false`);
      } else if (!r || typeof x !== "number" || !Number.isFinite(x) || x < r[0] || x > r[1]) {
        throw new Error(`${name}: "${k}" is not a voice setting in range`);
      }
    }
  }
  if (typeof v.settings.stability !== "number" || typeof v.settings.similarity_boost !== "number") {
    throw new Error("settings need an explicit stability and similarity_boost");
  }
  for (const [style, patterns] of Object.entries(v.styleRules)) {
    if (!(style in v.styles)) throw new Error(`styleRules names the unknown style "${style}"`);
    for (const p of patterns) {
      if (p === "" || p === "*") throw new Error("a style pattern is not empty or a bare *");
    }
  }
}

const hex = (b: ArrayBuffer) => [...new Uint8Array(b)].map((x) => x.toString(16).padStart(2, "0")).join("");

/** The text of `voice_profile_data.ts` for [v]. The id changes whenever anything that shapes the sound changes. */
export async function renderProfile(v: VoicesJson): Promise<string> {
  checkVoices(v);
  const data = {
    modelId: v.modelId,
    outputFormat: v.outputFormat,
    settings: v.settings,
    styles: v.styles,
    styleRules: v.styleRules,
    pronunciation: v.pronunciation,
  };
  const digest = hex(await crypto.subtle.digest("SHA-256", new TextEncoder().encode(JSON.stringify(data))));
  const id = `${v.outputFormat}.${v.modelId}.${digest.slice(0, 12)}`;
  return [
    "// Generated from content/voices.json by voice_profile_gen.ts. Do not edit by hand: change voices.json and run the",
    "// generator (the command is at the top of voice_profile_gen.ts); voice_profile_test.ts fails when they differ.",
    "// deno-fmt-ignore-file",
    "",
    `export const VOICE_PROFILE = ${JSON.stringify({ id, ...data }, null, 2)} as const;`,
    "",
  ].join("\n");
}

if (import.meta.main) {
  const voices = JSON.parse(
    await Deno.readTextFile(new URL("../../../content/voices.json", import.meta.url)),
  );
  await Deno.writeTextFile(new URL("./voice_profile_data.ts", import.meta.url), await renderProfile(voices));
}
