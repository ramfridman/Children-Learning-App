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
    c.speak({ voiceId: "abc", modelId: "m", text: "t", timeoutMs: 1000 })
  );
  assert.equal(e.reason, "status");
  assert.equal(e.detail, "HTTP 404 voice_not_found");
});
