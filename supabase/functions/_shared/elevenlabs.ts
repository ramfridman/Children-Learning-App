// Makes a line's voice with ElevenLabs, with plain fetch. The key never leaves the gateway, the voice id comes from
// the server's own character table, and the history item is deleted right after use.
const BASE = "https://api.elevenlabs.io";

export interface VoiceRequest {
  voiceId: string;
  modelId: string;
  text: string;
  timeoutMs: number;
}

export interface VoiceAnswer {
  audio: Uint8Array;
  mime: "audio/mpeg";
  requestId: string | null;
  historyItemId: string | null;
}

export interface VoiceClient {
  speak(req: VoiceRequest): Promise<VoiceAnswer>;
  /** Best effort: a failure is not an error for the child. */
  deleteHistory(historyItemId: string): Promise<void>;
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
          `${BASE}/v1/text-to-speech/${encodeURIComponent(req.voiceId)}?output_format=mp3_22050_32`,
          {
            method: "POST",
            signal: ctl.signal,
            headers: { "xi-api-key": apiKey, "content-type": "application/json" },
            body: JSON.stringify({ text: req.text, model_id: req.modelId, language_code: "he" }),
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
      if (!/^[A-Za-z0-9]{6,60}$/.test(id)) return;
      try {
        const res = await fetchFn(`${BASE}/v1/history/${id}`, {
          method: "DELETE",
          headers: { "xi-api-key": apiKey },
        });
        await res.body?.cancel();
      } catch {
        // The nightly sweep (M7) catches what this misses.
      }
    },
  };
}
