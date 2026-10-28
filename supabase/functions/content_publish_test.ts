import { assert } from "./_shared/testassert.ts";
import { makeHandler } from "./_shared/handler.ts";
import { fakeServices, FakeStore, plainPost, PUBLISH_SECRET } from "./_shared/testkit.ts";
import { PUBLISH_FAILS_PER_HOUR_PER_IP } from "./_shared/publish_secret.ts";
import { MAX_PUBLISH_BYTES, spec } from "./content-publish/handler.ts";

const goodItem = () => ({
  item_id: "count.butterflies.3",
  revision: 1,
  template: "count_tap",
  band: "A",
  skill_ids: ["NUM-A-03"],
  llm_allowed: true,
  goal: "touch each butterfly once and answer with the last number counted",
  prompt_text: "כַּמָּה פַּרְפָּרִים?",
  answers: [
    { id: "o1", value: 2, misconception: "M-CNT-SKIP", correct: false },
    { id: "o2", value: 3, correct: true },
  ],
  number_set: [2, 3],
  allowed_actions: ["show_fingers", "replay_prompt_slow"],
  hint_threshold: 3,
  object_ids: ["o1", "o2", "obj-0", "obj-1", "obj-2"],
});

const goodBody = (over: Record<string, unknown> = {}) => ({
  pack_id: "starter",
  pack_version: "0.2.0",
  manifest_sha256: "a".repeat(64),
  items: [goodItem()],
  misconceptions: [{ tag: "M-CNT-SKIP", skill_ids: ["NUM-A-03"], description: "the child skips an object" }],
  characters: [{ character_id: "nitzi", name_he: "נִיצִי", gender: "f", personal: false }],
  ...over,
});

function setup() {
  const store = new FakeStore();
  const svc = fakeServices(store);
  const handler = makeHandler(spec, () => svc);
  const publish = (body: unknown, secret: string | null = PUBLISH_SECRET) =>
    handler(plainPost("content-publish", body, secret === null ? {} : { "x-publish-secret": secret }));
  return { store, svc, handler, publish };
}
const code = async (r: Response) => (await r.json()).error as string;

Deno.test("content-publish: the right secret publishes a pack's item index", async () => {
  const { store, publish } = setup();
  const r = await publish(goodBody());
  assert.equal(r.status, 200);
  const j = await r.json();
  assert.deepEqual(j, { result: "published", items: 1, misconceptions: 1, characters: 1 });
  assert.equal(store.packs.get("starter")!.items[0].itemId, "count.butterflies.3");
  assert.equal(store.packs.get("starter")!.items[0].hintThreshold, 3);
  assert.equal(r.headers.get("access-control-allow-origin"), null);
});

Deno.test("content-publish: no secret, a wrong secret and a missing configuration are refused and change nothing", async () => {
  const { store, publish, svc } = setup();
  assert.equal((await publish(goodBody(), null)).status, 401);
  assert.equal((await publish(goodBody(), "wrong-wrong-wrong-wrong-wrong-wrong")).status, 401);
  assert.equal((await publish(goodBody(), PUBLISH_SECRET + "x")).status, 401);
  assert.equal((await publish(goodBody(), "")).status, 401);
  assert.equal(store.packs.size, 0);
  assert.equal(store.characters.size, 0);
  svc.secrets.publishSecret = undefined;
  assert.equal((await publish(goodBody())).status, 503, "no secret configured: unavailable, never open");
  svc.secrets.publishSecret = "short";
  assert.equal((await publish(goodBody(), "short")).status, 503, "a short secret is never accepted");
});

Deno.test("content-publish: wrong secrets are counted per caller and then answered with 'slow down'", async () => {
  const { publish } = setup();
  for (let i = 0; i < PUBLISH_FAILS_PER_HOUR_PER_IP; i++) {
    assert.equal((await publish(goodBody(), `wrong-secret-number-${i}-xxxxxxxx`)).status, 401);
  }
  assert.equal((await publish(goodBody(), "wrong-secret-again-xxxxxxxxxxxx")).status, 429);
});

Deno.test("content-publish: the same pack again is unchanged; the same version with other contents is a conflict; a lower version is refused; a higher one replaces", async () => {
  const { store, publish } = setup();
  assert.equal((await (await publish(goodBody())).json()).result, "published");
  assert.equal((await (await publish(goodBody())).json()).result, "unchanged");
  const clash = await publish(goodBody({ manifest_sha256: "b".repeat(64) }));
  assert.equal(clash.status, 400);
  assert.equal(await code(clash), "bad_request");
  assert.equal(store.packs.get("starter")!.manifestSha256, "a".repeat(64), "the published one is kept");
  const newer = await publish(goodBody({ pack_version: "0.3.0", manifest_sha256: "c".repeat(64) }));
  assert.equal((await newer.json()).result, "published");
  assert.equal(store.packs.get("starter")!.packVersion, "0.3.0");
  assert.equal((await publish(goodBody())).status, 400, "0.2.0 is older than 0.3.0");
  assert.equal(store.packs.get("starter")!.packVersion, "0.3.0");
});

Deno.test("content-publish: a voice chosen later is not erased by a publish that does not know it", async () => {
  const { store, publish } = setup();
  await publish(goodBody());
  await publish(goodBody({
    characters: [{
      character_id: "nitzi",
      name_he: "נִיצִי",
      gender: "f",
      personal: false,
      voice_id: "abcDEF0123456789",
    }],
  }));
  assert.equal(store.characters.get("nitzi")!.voiceId, "abcDEF0123456789");
  await publish(goodBody());
  assert.equal(store.characters.get("nitzi")!.voiceId, "abcDEF0123456789");
});

Deno.test("content-publish: the shape is strict", async () => {
  const { store, publish } = setup();
  const bad = async (body: unknown, why: string) => {
    const r = await publish(body);
    assert.equal(r.status, 400, why);
    assert.equal(store.packs.size, 0, `${why}: nothing published`);
  };
  await bad({ ...goodBody(), extra: 1 }, "unknown top-level field");
  await bad(goodBody({ pack_id: "Starter!" }), "pack id");
  await bad(goodBody({ pack_version: "1.0" }), "pack version");
  await bad(goodBody({ manifest_sha256: "xyz" }), "hash");
  await bad(goodBody({ items: [{ ...goodItem(), band: "D" }] }), "band");
  await bad(goodBody({ items: [{ ...goodItem(), surprise: true }] }), "unknown item field");
  await bad(goodBody({ items: [{ ...goodItem(), hint_threshold: 4 }] }), "hint threshold");
  await bad(goodBody({ items: [{ ...goodItem(), item_id: "Bad Id" }] }), "item id");
  await bad(goodBody({ items: [{ ...goodItem(), goal: "line\nbreak" }] }), "control characters");
  await bad(goodBody({ items: [{ ...goodItem(), skill_ids: ["numbers"] }] }), "skill id");
  await bad(goodBody({ items: [{ ...goodItem(), answers: [] }] }), "no answers");
  await bad(
    goodBody({
      items: [{ ...goodItem(), answers: [{ id: "o1", correct: false }, { id: "o2", correct: false }] }],
    }),
    "no correct answer",
  );
  await bad(
    goodBody({
      items: [{ ...goodItem(), answers: [{ id: "o1", correct: true }, { id: "o2", correct: true }] }],
    }),
    "two correct answers",
  );
  await bad(
    goodBody({
      items: [{ ...goodItem(), answers: [{ id: "o1", correct: true }, { id: "o1", correct: false }] }],
    }),
    "repeated answer id",
  );
  await bad(goodBody({ items: [goodItem(), goodItem()] }), "repeated item");
  await bad(goodBody({ misconceptions: [{ tag: "bad", skill_ids: ["NUM-A-03"], description: "x" }] }), "tag");
  await bad(
    goodBody({ characters: [{ character_id: "x1", name_he: "Nitzi", gender: "f", personal: false }] }),
    "a Latin character name",
  );
  await bad(
    goodBody({ characters: [{ character_id: "x1", name_he: "נִיצִי", gender: "x", personal: false }] }),
    "gender",
  );
  await bad(
    goodBody({
      characters: [{
        character_id: "x1",
        name_he: "נִיצִי",
        gender: "f",
        personal: false,
        voice_id: "no spaces!",
      }],
    }),
    "voice id",
  );
});

Deno.test("content-publish: the body is capped at 256 KB, and only POST is served", async () => {
  const { publish, handler } = setup();
  const big = goodBody({
    items: Array.from({ length: 5 }, (_, i) => ({ ...goodItem(), item_id: `i${i}`, goal: "x".repeat(300) })),
  });
  assert.equal((await publish(big)).status, 200, "a realistic index passes");
  const huge = "y".repeat(MAX_PUBLISH_BYTES + 10);
  const r = await handler(
    plainPost("content-publish", { pad: huge }, { "x-publish-secret": PUBLISH_SECRET }),
  );
  assert.equal(r.status, 413);
  for (const method of ["GET", "PUT", "OPTIONS"]) {
    assert.equal((await handler(new Request("https://x.test/f", { method }))).status, 400);
  }
});

Deno.test("content-publish: the index that the app's tool makes for the starter pack is accepted as it is", async () => {
  // testvectors/publish-starter.json is written by the Dart test of `pack_builder publish`, so the tool and this
  // function cannot drift apart without one of the two test suites failing.
  const vector = JSON.parse(
    await Deno.readTextFile(new URL("../../testvectors/publish-starter.json", import.meta.url)),
  );
  const { store, publish } = setup();
  const r = await publish(vector);
  assert.equal(r.status, 200, JSON.stringify(await r.clone().json()));
  const j = await r.json();
  assert.equal(j.result, "published");
  assert.equal(j.items, vector.items.length);
  assert.equal(store.packs.get("starter")!.items.length, vector.items.length);
  assert.ok(vector.items.length >= 138, "the Counting Hills content is in the index");
});

Deno.test("content-publish: a newer version keeps the approved lines of the items that did not change, and nothing else", async () => {
  const { store, publish } = setup();
  const second = { ...goodItem(), item_id: "pick.red.flower" };
  await publish(goodBody({ items: [goodItem(), second] }));
  const line = (over: Partial<{ line: string }> = {}) => ({
    line: "בואו נספור לאט",
    caption: null,
    next: "replay_prompt_slow",
    highlight: [] as string[],
    audio: new Uint8Array([1, 2, 3]),
    ...over,
  });
  // approved lines for both items, and a line a model made for the first
  const key = (item: string, prompt: string) => `starter/0.2.0/${item}/default/0/A/n/nitzi/${prompt}/v1`;
  store.cache.set(key("count.butterflies.3", "approved"), line());
  store.cache.set(key("pick.red.flower", "approved"), line());
  store.cache.set(key("count.butterflies.3", "p9"), line());

  // 0.3.0: the first item is the same, the second was revised
  const next = await publish(
    goodBody({
      pack_version: "0.3.0",
      manifest_sha256: "b".repeat(64),
      items: [goodItem(), { ...second, revision: 2 }],
    }),
  );
  assert.equal((await next.json()).result, "published");
  const keys = [...store.cache.keys()].sort();
  assert.deepEqual(keys, [key("count.butterflies.3", "approved").replace("0.2.0", "0.3.0")]);
  assert.deepEqual([...store.cache.values()][0].audio, new Uint8Array([1, 2, 3]), "with its voice");
});
