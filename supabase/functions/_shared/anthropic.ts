// Calls Claude (Haiku 5.5) with plain fetch: no SDK, nothing to audit. Only the gateway ever holds the key.
export const ANTHROPIC_MODEL = "claude-haiku-5-5";
const ENDPOINT = "https://api.anthropic.com/v1/messages";

export interface ModelRequest {
  system: string;
  user: string;
  maxTokens: number;
  timeoutMs: number;
}

export interface ModelAnswer {
  text: string;
  inputTokens: number;
  outputTokens: number;
}

export interface ModelClient {
  complete(req: ModelRequest): Promise<ModelAnswer>;
}

export class ModelFailed extends Error {
  constructor(readonly reason: "timeout" | "status" | "format" | "network") {
    super(reason);
  }
}

export function anthropicClient(apiKey: string, fetchFn: typeof fetch = fetch): ModelClient {
  return {
    async complete(req) {
      const ctl = new AbortController();
      const timer = setTimeout(() => ctl.abort(), req.timeoutMs);
      try {
        const res = await fetchFn(ENDPOINT, {
          method: "POST",
          signal: ctl.signal,
          headers: {
            "x-api-key": apiKey,
            "anthropic-version": "2023-06-01",
            "content-type": "application/json",
          },
          body: JSON.stringify({
            model: ANTHROPIC_MODEL,
            max_tokens: req.maxTokens,
            // The fixed part is marked for the provider's prompt cache: a faster, cheaper start.
            system: [{ type: "text", text: req.system, cache_control: { type: "ephemeral" } }],
            messages: [{ role: "user", content: req.user }],
          }),
        });
        // The body of an error can echo the request: only the status is kept.
        if (!res.ok) {
          await res.body?.cancel();
          throw new ModelFailed("status");
        }
        const j = await res.json() as {
          content?: Array<{ type: string; text?: string }>;
          usage?: { input_tokens?: number; output_tokens?: number; cache_read_input_tokens?: number };
        };
        const text = j.content?.find((c) => c.type === "text")?.text;
        if (typeof text !== "string") throw new ModelFailed("format");
        return {
          text,
          inputTokens: (j.usage?.input_tokens ?? 0) + (j.usage?.cache_read_input_tokens ?? 0),
          outputTokens: j.usage?.output_tokens ?? 0,
        };
      } catch (e) {
        if (e instanceof ModelFailed) throw e;
        throw new ModelFailed(ctl.signal.aborted ? "timeout" : "network");
      } finally {
        clearTimeout(timer);
      }
    },
  };
}
