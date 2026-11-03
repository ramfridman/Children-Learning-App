// The child's own name clip (B-42, docs/milestones/B42.md section 3.2): what the gateway sends to the voice, and the
// settings that switch it off or cap it. The name itself is read on the server from the child the parent saved; the phone
// sends two ids and nothing else.
import type { VoiceSettings } from "./elevenlabs.ts";

/** The format and voice settings of the recorded lines (`content/voices.json`; a test keeps them equal), so that the name
 * clip sounds like the lines it comes before. */
export const NAME_VOICE_FORMAT = "mp3_44100_64";
export const NAME_VOICE_SETTINGS: VoiceSettings = {
  stability: 0.5,
  similarity_boost: 0.8,
  use_speaker_boost: true,
};

/** The text sent for [spelling]: the name as a call, with a comma, so the voice lifts it and pauses (voice direction). */
export const nameVoiceText = (spelling: string): string => `${spelling},`;

/** The `config` keys the function reads. */
export const NAME_VOICE_CONFIG_KEYS = [
  "name_voice_enabled",
  "name_voice_day_cap",
  "elevenlabs_model_id",
  "tutor_price_micro",
] as const;

export interface NameVoiceSettings {
  /** The kill switch: anything but `true` is off. */
  enabled: boolean;
  /** Clips a family may make in a day. */
  dayCap: number;
  /** The model of the recorded lines, from the same key the tutor reads; null when it is not set. */
  modelId: string | null;
  /** Millionths of a dollar for 1,000 characters (the tutor's voice price, until the owner sets the real one). */
  priceVoicePer1k: number;
}

const num = (v: unknown, d: number) => (typeof v === "number" && Number.isFinite(v) && v >= 0 ? v : d);

/** The settings in the `config` table, with the defaults of PLAN.md: off until the owner switches it on, 20 clips a family a
 * day (a parent who listens and corrects the spelling needs a few). */
export function nameVoiceSettings(c: Record<string, unknown>): NameVoiceSettings {
  const price = (c.tutor_price_micro ?? {}) as Record<string, unknown>;
  return {
    enabled: c.name_voice_enabled === true,
    dayCap: num(c.name_voice_day_cap, 20),
    modelId: typeof c.elevenlabs_model_id === "string" && /^[A-Za-z0-9_.-]{3,60}$/.test(c.elevenlabs_model_id)
      ? c.elevenlabs_model_id
      : null,
    priceVoicePer1k: num(price.voice_per_1k_chars, 300_000),
  };
}
