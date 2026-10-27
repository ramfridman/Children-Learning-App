import { assert } from "./_shared/testassert.ts";
import { type ModelAnswer, type ModelClient, ModelFailed, type ModelRequest } from "./_shared/anthropic.ts";
import { type VoiceAnswer, type VoiceClient, type VoiceRequest } from "./_shared/elevenlabs.ts";
import { DEFAULT_TUTOR_BUDGET, makeHandler, type Services } from "./_shared/handler.ts";
import type { PublishedPack } from "./_shared/store.ts";
import { fakeServices, FakeStore, plainPost, PUBLISH_SECRET } from "./_shared/testkit.ts";
import { spec } from "./tutor-prewarm/handler.ts";

const vector = JSON.parse(
  await Deno.readTextFile(new URL("../../testvectors/publish-starter.json", import.meta.url)),
);

const toPack = (): PublishedPack => ({
  packId: vector.pack_id,
  packVersion: vector.pack_version,
  manifestSha256: vector.manifest_sha256,
  items: vector.items.map((i: Record<string, unknown>) => ({
    itemId: i.item_id,
    revision: i.revision,
    template: i.template,
    band: i.band,
    skillIds: i.skill_ids,
    llmAllowed: i.llm_allowed,
    goal: i.goal,
    promptText: i.prompt_text,
    answers: i.answers,
    numberSet: i.number_set,
    allowedActions: i.allowed_actions,
    hintThreshold: i.hint_threshold,
    objectIds: i.object_ids,
  })),
  misconceptions: vector.misconceptions.map((m: Record<string, unknown>) => ({
    tag: m.tag,
    skillIds: m.skill_ids,
    description: m.description,
  })),
  characters: [],
});

const GOOD = {
  say: "בואו נספור לאט",
  next: "replay_prompt_slow",
  hl: [] as string[],
  mis: "M-CNT-DOUBLE",
  reveals: false,
  safety: "none",
};

class FakeModel implements ModelClient {
  calls: ModelRequest[] = [];
  delayMs = 0;
  async complete(req: ModelRequest): Promise<ModelAnswer> {
    this.calls.push(req);
    // Like the real client: a reply slower than the deadline it was given is a timeout.
    if (this.delayMs > req.timeoutMs) {
      await new Promise((r) => setTimeout(r, req.timeoutMs));
      throw new ModelFailed("timeout");
    }
    if (this.delayMs > 0) await new Promise((r) => setTimeout(r, this.delayMs));
    return { text: JSON.stringify(GOOD), inputTokens: 1000, outputTokens: 40 };
  }
}

class FakeVoice implements VoiceClient {
  calls: VoiceRequest[] = [];
  deleted: string[] = [];
  speak(req: VoiceRequest): Promise<VoiceAnswer> {
    this.calls.push(req);
    return Promise.resolve({
      audio: new Uint8Array(300).fill(7),
      mime: "audio/mpeg",
      requestId: `req-${this.calls.length}`,
      historyItemId: `hist${this.calls.length}abc`,
    });
  }
  deleteHistory(id: string) {
    this.deleted.push(id);
    return Promise.resolve();
  }
}

async function setup() {
  const store = new FakeStore();
  await store.publishContent(toPack());
  store.characters.set("nitzi", {
    nameHe: "נִיצִי",
    gender: "f",
    voiceId: "abcDEF0123456789",
    personal: false,
  });
  store.config.set("tutor_enabled", true);
  store.config.set("live_voice_enabled", true);
  store.config.set("elevenlabs_model_id", "test-model-1");
  const model = new FakeModel();
  const voice = new FakeVoice();
  const svc: Services = {
    ...fakeServices(store),
    tutor: { model, voice, budget: { ...DEFAULT_TUTOR_BUDGET } },
  };
  const handler = makeHandler(spec, () => svc);
  const body = (over: Record<string, unknown> = {}) => ({
    mode: "plan",
    pack_id: "starter",
    pack_version: vector.pack_version,
    character_ids: ["nitzi"],
    bands: ["A"],
    address_forms: ["n"],
    hint_level_tags: 2,
    limit: 25,
    offset: 0,
    max_micro_usd: 5_000_000,
    count: 1,
    ...over,
  });
  const ask = (o: Record<string, unknown> = {}, secret: string | null = PUBLISH_SECRET) =>
    handler(plainPost("tutor-prewarm", body(o), secret === null ? {} : { "x-publish-secret": secret }));
  return { store, model, voice, svc, ask };
}

Deno.test("tutor-prewarm: no secret and a wrong secret are refused, and nothing is made", async () => {
  const { ask, model, voice } = await setup();
  assert.equal((await ask({ mode: "make" }, null)).status, 401);
  assert.equal((await ask({ mode: "make" }, "wrong-wrong-wrong-wrong-wrong-wrong")).status, 401);
  assert.equal(model.calls.length, 0);
  assert.equal(voice.calls.length, 0);
});

Deno.test("tutor-prewarm: plan counts the lines and the cost and spends nothing", async () => {
  const { ask, model, voice } = await setup();
  const r = await ask();
  assert.equal(r.status, 200);
  const j = await r.json();
  assert.equal(j.cached, 0);
  assert.equal(j.lines, j.to_make);
  assert.equal(j.lines > 0, true, "the starter pack has items that allow the AI");
  assert.equal(j.est_micro_usd > 0, true);
  assert.equal(j.est_voice_chars, j.to_make * 45);
  assert.equal(model.calls.length, 0, "a plan never calls the model");
  assert.equal(voice.calls.length, 0, "a plan never calls the voice");
});

Deno.test("tutor-prewarm: make fills the cache, then a plan sees those lines as already made", async () => {
  const { ask, store, model } = await setup();
  const plan = await (await ask()).json();
  const r = await ask({ mode: "make" });
  assert.equal(r.status, 200);
  const j = await r.json();
  assert.equal(j.total, plan.lines);
  assert.equal(
    j.made + j.cached + Object.values(j.failed as Record<string, number>).reduce((a, b) => a + b, 0),
    j.next_offset,
  );
  assert.equal(j.made > 0, true);
  assert.equal(j.spent_micro_usd > 0, true);
  assert.equal(store.cache.size, j.made);
  assert.ok(
    model.calls.length >= j.made,
    "a line that needs repair takes a second model call, so there can be more calls than lines",
  );
  const again = await (await ask()).json();
  assert.equal(again.cached, j.made);
  assert.equal(again.to_make, plan.lines - j.made);
});

Deno.test("tutor-prewarm: make works in batches and a second run of the same batch costs nothing", async () => {
  const { ask, model } = await setup();
  const first = await (await ask({ mode: "make", limit: 2 })).json();
  assert.equal(first.next_offset, 2);
  assert.equal(first.done, false);
  const calls = model.calls.length;
  const repeat = await (await ask({ mode: "make", limit: 2 })).json();
  assert.equal(repeat.cached, first.made, "the lines already made are answered from the cache");
  assert.equal(repeat.made, 0);
  assert.equal(repeat.spent_micro_usd, 0);
  assert.equal(model.calls.length, calls, "no second model call for a line already made");
});

Deno.test("tutor-prewarm: make stops at the budget it was given", async () => {
  const { ask } = await setup();
  const j = await (await ask({ mode: "make", max_micro_usd: 1 })).json();
  assert.equal(j.done, true);
  assert.equal(j.next_offset, 1, "it stopped after the first line, which used up the budget");
  assert.equal(j.made + Object.values(j.failed as Record<string, number>).reduce((a, b) => a + b, 0), 1);
});

Deno.test("tutor-prewarm: nothing is made while the tutor switch is off", async () => {
  const { ask, store, model } = await setup();
  store.config.set("tutor_enabled", false);
  const r = await ask({ mode: "make" });
  assert.equal(r.status, 503);
  assert.equal(model.calls.length, 0);
  assert.equal((await ask({ mode: "plan" })).status, 200, "a plan is only counting, so it still works");
});

Deno.test("tutor-prewarm: measure makes fresh lines, keeps none, and reports the server times", async () => {
  const { ask, store, model } = await setup();
  const j = await (await ask({ mode: "measure", count: 3 })).json();
  assert.equal(j.runs.length, 3);
  assert.equal(model.calls.length, 3, "every run goes to the model: nothing is read from the cache");
  for (const run of j.runs) {
    assert.equal(run.rule, undefined);
    assert.equal(typeof run.server_ms, "number");
    assert.equal(typeof run.model_ms, "number");
    assert.equal(typeof run.voice_ms, "number");
  }
  assert.equal(store.cache.size, 0, "a measurement leaves nothing behind");
  assert.equal(j.spent_micro_usd > 0, true);
});

Deno.test("tutor-prewarm: a body with an unknown mode or a made-up character is not accepted", async () => {
  const { ask } = await setup();
  assert.equal((await ask({ mode: "everything" })).status, 400);
  assert.equal((await ask({ character_ids: ["Bad Id"] })).status, 400);
  assert.equal((await ask({ limit: 26 })).status, 400);
  const unknown = await (await ask({ character_ids: ["nobody"] })).json();
  assert.equal(unknown.lines, 0, "a character that does not exist adds no lines");
});

Deno.test("tutor-prewarm: a model slower than a live turn may wait still makes the line, and measure shows the times", async () => {
  const { ask, model, svc } = await setup();
  // A live turn would give the model 50 ms; nobody waits during pre-warm, so it gets far longer.
  svc.tutor!.budget = { ...DEFAULT_TUTOR_BUDGET, modelMs: 50, totalMs: 400 };
  model.delayMs = 120;
  const j = await (await ask({ mode: "measure", count: 2 })).json();
  assert.equal(j.runs.length, 2);
  for (const run of j.runs) {
    assert.equal(run.rule, undefined, "no timeout in pre-warm");
    assert.equal(run.model_ms >= 100, true, `the model time is reported (${run.model_ms} ms)`);
  }
});

Deno.test("tutor-prewarm: when a line cannot be made, measure still says how long the model had taken", async () => {
  const { ask, model } = await setup();
  model.complete = (req) => {
    model.calls.push(req);
    return Promise.reject(new ModelFailed("status"));
  };
  const j = await (await ask({ mode: "measure", count: 1 })).json();
  assert.equal(j.runs[0].rule, "model_failed");
  assert.equal(typeof j.runs[0].model_ms, "number");
  assert.equal(typeof j.runs[0].voice_ms, "number");
});
