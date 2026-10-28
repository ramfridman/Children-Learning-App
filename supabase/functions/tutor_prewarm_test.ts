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

Deno.test("tutor-prewarm: evaluate asks the model only, keeps nothing, and says which checks refused which lines and which words", async () => {
  const { ask, model, voice, store } = await setup();
  model.complete = (req) => {
    model.calls.push(req);
    // The first line of the grid gets a good reply; the others get one unknown word and a good one on the retry.
    const bad = { ...GOOD, say: "בואו נאכל בננה" };
    const first = model.calls.length === 1;
    const retry = req.user.includes("refused");
    return Promise.resolve({
      text: JSON.stringify(first || retry ? GOOD : bad),
      inputTokens: 1000,
      outputTokens: 40,
    });
  };
  const plan = await (await ask({ mode: "plan" })).json();
  assert.equal(typeof plan.est_eval_micro_usd, "number");
  const j = await (await ask({ mode: "evaluate" })).json();
  assert.equal(j.rows.length, plan.lines);
  assert.equal(j.rows[0].firstTry, true);
  assert.equal(j.rows[0].passed, true);
  const second = j.rows[1];
  assert.equal(second.firstTry, false);
  assert.equal(second.attempts, 2);
  assert.equal(second.passed, true, "the retry fixed it");
  assert.deepEqual(second.checks, ["vocabulary"]);
  assert.deepEqual(second.unknown, ["נאכל", "בננה"]);
  assert.equal(voice.calls.length, 0, "no voice is made");
  assert.equal(store.cache.size, 0, "nothing is kept");
  assert.equal(j.spent_micro_usd > 0, true);
});

const cell = (say: string, over: Record<string, unknown> = {}) => ({
  item: "count.butterflies.3",
  mistake: "default",
  hint: 0,
  band: "A",
  form: "n",
  character: "nitzi",
  say,
  ...over,
});

Deno.test("tutor-prewarm: voice speaks exactly the approved sentences, re-checks them, and asks the model for nothing", async () => {
  const { ask, model, voice, store } = await setup();
  const j = await (await ask({
    mode: "voice",
    lines: [cell("בואו נספור לאט"), cell("בואו נאכל בננה", { band: "B" })],
  })).json();
  assert.equal(j.made, 1);
  assert.equal(j.results[0].ok, true);
  assert.equal(j.results[1].ok, false);
  assert.equal(j.results[1].rule, "validator_failed");
  assert.ok(String(j.results[1].detail).includes("vocabulary"), j.results[1].detail);
  assert.equal(model.calls.length, 0, "no model call");
  assert.equal(voice.calls.length, 1, "voice only for the sentence that passed");
  assert.equal(voice.calls[0].text, "בּוֹאוּ נִסְפֹּר לְאַט", "the lexicon's one reading is what is voiced");
  const kept = [...store.cache.keys()].filter((k) => k.includes("approved"));
  assert.equal(kept.length, 1, "kept under the approved version");
});

Deno.test("tutor-prewarm: an edited sentence replaces the approved one, and a cell with an approved line counts as made", async () => {
  const { ask, voice, store, model } = await setup();
  await ask({ mode: "voice", lines: [cell("בואו נספור לאט")] });
  await ask({ mode: "voice", lines: [cell("בואו נספור יחד")] });
  assert.equal(voice.calls.length, 2);
  const only = [...store.cache.entries()].filter(([k]) => k.includes("approved"));
  assert.equal(only.length, 1, "one line for the cell");
  assert.equal(only[0][1].line, "בּוֹאוּ נִסְפֹּר יַחַד", "the edit won");
  const plan = await (await ask({ mode: "plan", bands: ["A"], address_forms: ["n"] })).json();
  assert.ok(plan.cached >= 1, "the approved cell is already made");
  const made = await (await ask({ mode: "make", bands: ["A"], address_forms: ["n"] })).json();
  assert.equal(made.cached >= 1, true, "make leaves it alone");
  assert.equal(model.calls.length > 0, true, "other cells are still made by the model");
});

Deno.test("tutor-prewarm: voice takes only plain Hebrew, at most 25 lines, and needs lines", async () => {
  const { ask } = await setup();
  for (const lines of [[cell("hello there")], [cell("בואו נספור 3")], [cell("א")], []]) {
    const r = await ask({ mode: "voice", lines });
    assert.equal(r.status, 400);
  }
  assert.equal(
    (await ask({ mode: "voice", lines: Array.from({ length: 26 }, () => cell("בואו נספור")) })).status,
    400,
  );
  assert.equal((await ask({ mode: "voice" })).status, 400);
});

Deno.test("tutor-prewarm: carry copies the approved lines to a newer pack version for the items that did not change, and costs nothing", async () => {
  const { ask, store, model, voice } = await setup();
  await ask({
    mode: "voice",
    lines: [cell("בואו נספור לאט"), cell("בואו נספור לאט", { item: "pick.red.flower" })],
  });
  const approved = [...store.cache.keys()].filter((k) => k.includes("approved"));
  assert.equal(approved.length, 2);
  // The next version of the pack: one item is the same, one was revised.
  const next = toPack();
  next.packVersion = "0.3.0";
  next.manifestSha256 = "b".repeat(64);
  const revised = next.items.find((i) => i.itemId === "pick.red.flower")!;
  revised.revision = revised.revision + 1;
  assert.equal(await store.publishContent(next), "published");
  const callsBefore = [model.calls.length, voice.calls.length];

  const r = await ask({ mode: "carry", pack_version: "0.3.0", from_version: vector.pack_version });
  assert.equal(r.status, 200);
  const j = await r.json();
  assert.equal(j.carried, 1, "only the item whose revision did not change");
  const there = [...store.cache.keys()].filter((k) => k.includes("/0.3.0/") && k.includes("approved"));
  assert.equal(there.length, 1);
  assert.ok(there[0].includes("count.butterflies.3"));
  assert.deepEqual([model.calls.length, voice.calls.length], callsBefore, "no model call and no voice");
  assert.equal(
    store.cache.get(there[0])!.line,
    store.cache.get(approved.find((k) => k.includes("count.butterflies.3"))!)!.line,
    "the same line, with its sound",
  );
  assert.equal(
    (await (await ask({ mode: "carry", pack_version: "0.3.0", from_version: vector.pack_version })).json())
      .carried,
    0,
    "again: nothing more",
  );
});

Deno.test("tutor-prewarm: carry leaves lines that were not approved alone, and needs an older version", async () => {
  const { ask, store } = await setup();
  await ask({ mode: "make", bands: ["A"], address_forms: ["n"], limit: 2 });
  const made = [...store.cache.keys()].filter((k) => !k.includes("approved"));
  assert.ok(made.length > 0, "lines made by the model exist");
  const next = toPack();
  next.packVersion = "0.3.0";
  next.manifestSha256 = "c".repeat(64);
  await store.publishContent(next);
  const j = await (await ask({ mode: "carry", pack_version: "0.3.0", from_version: vector.pack_version }))
    .json();
  assert.equal(j.carried, 0, "only reviewed lines are carried");
  assert.equal((await ask({ mode: "carry", pack_version: "0.3.0" })).status, 400, "from_version is needed");
  assert.equal((await ask({ mode: "carry", pack_version: "0.3.0", from_version: "0.3.0" })).status, 400);
  assert.equal((await ask({ mode: "carry", pack_version: "0.3.0", from_version: "x" })).status, 400);
  assert.equal(
    (await ask({ mode: "carry", pack_version: "0.3.0", from_version: "0.2.0" }, null)).status,
    401,
  );
});
