import { assert } from "./_shared/testassert.ts";
import { anthropicClient, ModelFailed } from "./_shared/anthropic.ts";
import { elevenLabsClient, VoiceFailed } from "./_shared/elevenlabs.ts";

const json = (status: number, body: unknown) =>
  (() => Promise.resolve(new Response(JSON.stringify(body), { status }))) as unknown as typeof fetch;

async function failure<T extends Error>(run: () => Promise<unknown>): Promise<T> {
  try {
    await run();
  } catch (e) {
    return e as T;
  }
  throw new Error("expected a failure");
}

const req = { system: "s", user: "u", maxTokens: 10, timeoutMs: 1000 };

Deno.test("model errors keep the HTTP status and the provider's error word, and nothing from the body", async () => {
  const c = anthropicClient(
    "key",
    json(404, { error: { type: "not_found_error", message: "model: secret-looking text s u" } }),
  );
  const e = await failure<ModelFailed>(() => c.complete(req));
  assert.equal(e.reason, "status");
  assert.equal(e.detail, "HTTP 404 not_found_error");
  assert.equal(JSON.stringify(e).includes("secret-looking"), false);
});

Deno.test("an error word that is not a plain word is dropped, and so is an unreadable body", async () => {
  const c1 = anthropicClient("key", json(400, { error: { type: "Bad Type!<script>" } }));
  assert.equal((await failure<ModelFailed>(() => c1.complete(req))).detail, "HTTP 400");
  const c2 = anthropicClient(
    "key",
    (() => Promise.resolve(new Response("<html>", { status: 502 }))) as typeof fetch,
  );
  assert.equal((await failure<ModelFailed>(() => c2.complete(req))).detail, "HTTP 502");
});

Deno.test("voice errors keep the HTTP status and the provider's status word", async () => {
  const c = elevenLabsClient(
    "key",
    json(404, { detail: { status: "voice_not_found", message: "no such voice" } }),
  );
  const e = await failure<VoiceFailed>(() =>
    c.speak({
      voiceId: "abc",
      modelId: "m",
      outputFormat: "mp3_44100_64",
      settings: { stability: 0.5, similarity_boost: 0.8 },
      text: "t",
      timeoutMs: 1000,
    })
  );
  assert.equal(e.reason, "status");
  assert.equal(e.detail, "HTTP 404 voice_not_found");
});

Deno.test("the voice request asks for the pack's format and sends the settings explicitly; the key stays in a header", async () => {
  let seen: { url: string; headers: Headers; body: Record<string, unknown> } | null = null;
  const fetchFn = ((url: string, init: RequestInit) => {
    seen = { url, headers: new Headers(init.headers), body: JSON.parse(String(init.body)) };
    return Promise.resolve(new Response(new Uint8Array(200)));
  }) as unknown as typeof fetch;
  const settings = { stability: 0.65, similarity_boost: 0.8, use_speaker_boost: true };
  await elevenLabsClient("the-key", fetchFn).speak({
    voiceId: "abcDEF0123456789",
    modelId: "eleven_v4_turbo",
    outputFormat: "mp3_44100_64",
    settings,
    text: "שלום",
    timeoutMs: 1000,
  });
  assert.equal(
    seen!.url,
    "https://api.elevenlabs.io/v1/text-to-speech/abcDEF0123456789?output_format=mp3_44100_64",
  );
  assert.deepEqual(seen!.body, {
    text: "שלום",
    model_id: "eleven_v4_turbo",
    language_code: "he",
    voice_settings: settings,
  });
  assert.equal(seen!.headers.get("xi-api-key"), "the-key");
  assert.equal(JSON.stringify(seen!.body).includes("the-key"), false);
});

Deno.test("the model request turns thinking off and keeps the key in a header, not in the body", async () => {
  let seen: { headers: Headers; body: Record<string, unknown> } | null = null;
  const fetchFn = ((_url: string, init: RequestInit) => {
    seen = { headers: new Headers(init.headers), body: JSON.parse(String(init.body)) };
    return Promise.resolve(
      new Response(
        JSON.stringify({
          content: [{ type: "text", text: "{}" }],
          usage: { input_tokens: 5, output_tokens: 2 },
        }),
      ),
    );
  }) as unknown as typeof fetch;
  await anthropicClient("the-key", fetchFn).complete(req);
  assert.deepEqual(seen!.body.thinking, { type: "disabled" });
  assert.equal(seen!.body.model, "claude-haiku-5-5");
  assert.equal(seen!.headers.get("x-api-key"), "the-key");
  assert.equal(JSON.stringify(seen!.body).includes("the-key"), false);
});

Deno.test("a reply with no text says which blocks came back and why it stopped, in fixed words only", async () => {
  const c = anthropicClient(
    "key",
    json(200, { content: [{ type: "thinking", thinking: "private text" }], stop_reason: "max_tokens" }),
  );
  const e = await failure<ModelFailed>(() => c.complete(req));
  assert.equal(e.reason, "format");
  assert.equal(e.detail, "blocks thinking stop max_tokens");
});
