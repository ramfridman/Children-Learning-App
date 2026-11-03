// Makes a line's voice with ElevenLabs, with plain fetch. The key never leaves the gateway, the voice id comes from
// the server's own character table, and the history item is deleted right after use.
const BASE = "https://api.elevenlabs.io";

/** The voice settings sent with a request (the same shape `content/voices.json` has). */
export interface VoiceSettings {
  stability: number;
  similarity_boost: number;
  use_speaker_boost: boolean;
}

/** The small format a tutor line uses unless the caller names another. */
export const DEFAULT_OUTPUT_FORMAT = "mp3_22050_32";

export interface VoiceRequest {
  voiceId: string;
  modelId: string;
  text: string;
  timeoutMs: number;
  /** An `mp3_<rate>_<kbps>` format; [DEFAULT_OUTPUT_FORMAT] when absent. */
  outputFormat?: string;
  /** Sent as `voice_settings` when given (the child's name clip uses the pack's settings). */
  settings?: VoiceSettings;
}

export interface VoiceAnswer {
  audio: Uint8Array;
  mime: "audio/mpeg";
  requestId: string | null;
  historyItemId: string | null;
}

export interface VoiceClient {
  speak(req: VoiceRequest): Promise<VoiceAnswer>;
  /**
   * Deletes the provider's copy of a line. True when it is gone (or was already); false when the provider refused, was
   * slow (3 s) or could not be reached. A failure is never an error for the child, but the caller says so in its log.
   */
  deleteHistory(historyItemId: string): Promise<boolean>;
}

/** How long one delete of the provider's history may take. */
const HISTORY_DELETE_MS = 3000;

/** [VoiceClient.deleteHistory] with one more try after a failure. */
export async function deleteHistoryWithRetry(voice: VoiceClient, historyItemId: string): Promise<boolean> {
  return await voice.deleteHistory(historyItemId) || await voice.deleteHistory(historyItemId);
}

export class VoiceFailed extends Error {
  /** `detail` is only ever the HTTP status and the provider's fixed status word, never any text of the body. */
  constructor(readonly reason: "timeout" | "status" | "network" | "empty", readonly detail?: string) {
    super(reason);
  }
}

/** The provider's status word ("voice_not_found", ...), kept only when it is a plain lower-case word. */
async function statusWord(res: Response): Promise<string> {
  try {
    const d = (await res.json() as { detail?: { status?: unknown } }).detail?.status;
    return typeof d === "string" && /^[a-z_]{3,40}$/.test(d) ? ` ${d}` : "";
  } catch {
    return "";
  }
}

export function elevenLabsClient(apiKey: string, fetchFn: typeof fetch = fetch): VoiceClient {
  return {
    async speak(req) {
      const ctl = new AbortController();
      const timer = setTimeout(() => ctl.abort(), req.timeoutMs);
      try {
        const res = await fetchFn(
          `${BASE}/v1/text-to-speech/${encodeURIComponent(req.voiceId)}?output_format=${
            encodeURIComponent(req.outputFormat ?? DEFAULT_OUTPUT_FORMAT)
          }`,
          {
            method: "POST",
            signal: ctl.signal,
            headers: { "xi-api-key": apiKey, "content-type": "application/json" },
            body: JSON.stringify({
              text: req.text,
              model_id: req.modelId,
              language_code: "he",
              ...(req.settings ? { voice_settings: req.settings } : {}),
            }),
          },
        );
        if (!res.ok) {
          throw new VoiceFailed("status", `HTTP ${res.status}${await statusWord(res)}`);
        }
        const audio = new Uint8Array(await res.arrayBuffer());
        if (audio.length < 100) throw new VoiceFailed("empty");
        return {
          audio,
          mime: "audio/mpeg",
          requestId: res.headers.get("request-id"),
          historyItemId: res.headers.get("history-item-id"),
        };
      } catch (e) {
        if (e instanceof VoiceFailed) throw e;
        throw new VoiceFailed(ctl.signal.aborted ? "timeout" : "network");
      } finally {
        clearTimeout(timer);
      }
    },

    async deleteHistory(id) {
      if (!/^[A-Za-z0-9]{6,60}$/.test(id)) return false;
      const ctl = new AbortController();
      const timer = setTimeout(() => ctl.abort(), HISTORY_DELETE_MS);
      try {
        const res = await fetchFn(`${BASE}/v1/history/${id}`, {
          method: "DELETE",
          signal: ctl.signal,
          headers: { "xi-api-key": apiKey },
        });
        await res.body?.cancel();
        // Gone, or already gone (404). A refusal (a key without the history permission, a 429, a 5xx) is not "deleted".
        return res.ok || res.status === 404;
      } catch {
        return false;
      } finally {
        clearTimeout(timer);
      }
    },
  };
}
