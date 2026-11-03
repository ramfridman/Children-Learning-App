// Makes the sound of a child's name in a friend's voice, for a parent who tapped "listen" (B-42, docs/milestones/B42.md
// section 3.2). The phone sends two ids. The spelling is read here from the child the parent saved (`child-put`), the voice
// from the server's own character table, and the clip goes back to that one phone: nothing is stored (not the sound, not
// the name), nothing is logged but the outcome, and the provider's copy is deleted at once.
//
// A kill switch (`name_voice_enabled`, off until the owner sets it) and a cap per family per day (`name_voice_day_cap`).
import { VoiceFailed } from "../_shared/elevenlabs.ts";
import { GatewayError } from "../_shared/errors.ts";
import type { FunctionSpec } from "../_shared/handler.ts";
import {
  NAME_VOICE_CONFIG_KEYS,
  NAME_VOICE_FORMAT,
  NAME_VOICE_SETTINGS,
  nameVoiceSettings,
  nameVoiceText,
} from "../_shared/name_voice.ts";
import { isSpokenName } from "../_shared/name_spoken.ts";
import { CHILD_ID } from "../child-put/handler.ts";

/** The longest the provider may take: a parent is waiting at a button, not a child at a lesson. */
const VOICE_MS = 8000;

interface Body {
  child_id: string;
  character_id: string;
}

/** Standard base64, in chunks (the sound is some kilobytes; the arguments of one call stay small). */
function base64(bytes: Uint8Array): string {
  let s = "";
  for (let i = 0; i < bytes.length; i += 0x8000) s += String.fromCharCode(...bytes.subarray(i, i + 0x8000));
  return btoa(s);
}

export const spec: FunctionSpec = {
  name: "name-voice",
  access: { kind: "device", roles: ["parent"] },
  shape: {
    child_id: { t: "string", max: 64, pattern: CHILD_ID },
    character_id: { t: "string", max: 40, pattern: /^[a-z0-9-]{2,40}$/ },
  },
  run: async (ctx) => {
    const b = ctx.body as unknown as Body;
    const svc = ctx.svc;
    const familyId = ctx.auth!.device.familyId;
    const cfg = nameVoiceSettings(await svc.store.getConfigs(NAME_VOICE_CONFIG_KEYS));
    if (!cfg.enabled) throw new GatewayError("unavailable", "name_voice_off");
    if (!svc.voice || !cfg.modelId) throw new GatewayError("unavailable", "name_voice_not_configured");

    // Everything that can be refused is refused before anything is spent.
    const child = await svc.store.childNameSpoken(familyId, b.child_id);
    if (!child) throw new GatewayError("not_found", "no_such_child");
    if (child.spelling === null) throw new GatewayError("bad_request", "no_spelling");
    if (!isSpokenName(child.spelling)) throw new GatewayError("bad_request", "bad_spelling");
    const character = await svc.store.characterVoice(b.character_id);
    if (!character) throw new GatewayError("bad_request", "unknown_character");
    if (!character.voiceId) throw new GatewayError("unavailable", "no_voice");

    const day = new Date(Math.floor(svc.nowMs() / 86_400_000) * 86_400_000);
    if (!(await svc.store.rateLimitHit("name_voice_day", familyId, day, cfg.dayCap))) {
      throw new GatewayError("rate_limited", "name_voice_cap");
    }

    const text = nameVoiceText(child.spelling);
    let sound;
    try {
      sound = await svc.voice.speak({
        voiceId: character.voiceId,
        modelId: cfg.modelId,
        text,
        timeoutMs: VOICE_MS,
        outputFormat: NAME_VOICE_FORMAT,
        settings: NAME_VOICE_SETTINGS,
      });
    } catch (e) {
      throw new GatewayError("unavailable", e instanceof VoiceFailed ? `voice_${e.reason}` : "voice_failed");
    }
    // The provider keeps a history by default; ours is deleted now (a failure is the nightly sweep's to catch).
    if (sound.historyItemId) await svc.voice.deleteHistory(sound.historyItemId);
    // The family's cost ledger gets the characters and the price, never the name.
    await svc.store.tutorCostAdd(familyId, (text.length / 1000) * cfg.priceVoicePer1k, svc.nowMs()).catch(
      () => {},
    );
    return { audio: base64(sound.audio), mime: sound.mime, chars: text.length };
  },
};
