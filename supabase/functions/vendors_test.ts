import { assert } from "./_shared/testassert.ts";
import { anthropicClient, ModelFailed } from "./_shared/anthropic.ts";
import {
  deleteHistoryWithRetry,
  elevenLabsClient,
  type VoiceClient,
  VoiceFailed,
} from "./_shared/elevenlabs.ts";

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

// ---- the provider's history (SEC-B42-1): a delete that did not happen is told, not hidden ----

const answering = (status: number) =>
  ((_u: string | URL | Request, _init?: RequestInit) =>
    Promise.resolve(new Response(null, { status }))) as unknown as typeof fetch;

Deno.test("history delete: gone (2xx) or already gone (404) is true; a refusal or a server error is false", async () => {
  for (
    const [status, want] of [[200, true], [204, true], [404, true], [401, false], [429, false], [
      500,
      false,
    ]] as const
  ) {
    const c = elevenLabsClient("key", answering(status));
    assert.equal(await c.deleteHistory("hist1abcdef"), want, `status ${status}`);
  }
});

Deno.test("history delete: a request that cannot be made, or an id that is not one, is false", async () => {
  const down = (() => Promise.reject(new TypeError("offline"))) as unknown as typeof fetch;
  assert.equal(await elevenLabsClient("key", down).deleteHistory("hist1abcdef"), false);
  const calls: string[] = [];
  const spy = ((
    u: string,
  ) => (calls.push(u), Promise.resolve(new Response(null, { status: 200 })))) as unknown as typeof fetch;
  assert.equal(await elevenLabsClient("key", spy).deleteHistory("../x"), false);
  assert.equal(calls.length, 0, "an odd id never reaches the provider");
});

Deno.test("history delete: a provider that hangs is given up on after about 3 seconds", async () => {
  const hangs = ((_u: string, init: RequestInit) =>
    new Promise((_resolve, reject) => {
      init.signal!.addEventListener("abort", () => reject(new DOMException("aborted", "AbortError")));
    })) as unknown as typeof fetch;
  const t0 = performance.now();
  assert.equal(await elevenLabsClient("key", hangs).deleteHistory("hist1abcdef"), false);
  const took = performance.now() - t0;
  assert.ok(took >= 2900 && took < 4500, `took ${took} ms`);
});

Deno.test("history delete: one more try after a failure, none after a success", async () => {
  const voice = (results: boolean[]) => {
    const asked: string[] = [];
    const v = {
      speak: () => Promise.reject(new Error("unused")),
      deleteHistory: (id: string) => (asked.push(id), Promise.resolve(results.shift() ?? false)),
    } as VoiceClient;
    return { v, asked };
  };
  const ok = voice([true]);
  assert.equal(await deleteHistoryWithRetry(ok.v, "hist1abcdef"), true);
  assert.equal(ok.asked.length, 1);
  const second = voice([false, true]);
  assert.equal(await deleteHistoryWithRetry(second.v, "hist1abcdef"), true);
  assert.equal(second.asked.length, 2);
  const never = voice([false, false, false]);
  assert.equal(await deleteHistoryWithRetry(never.v, "hist1abcdef"), false);
  assert.equal(never.asked.length, 2, "one retry, not more");
});
