// The parent area's sync functions: children with nicknames, the log with its server cursor, and deleting a child.
// Each one is called as a signed device, so the four checks of every function run too.
import { assert } from "./_shared/testassert.ts";
import { UUID_ANY } from "./_shared/canonical.ts";
import { makeHandler } from "./_shared/handler.ts";
import type { Field, Shape } from "./_shared/schema.ts";
import {
  addDevice,
  call,
  fakeServices,
  FakeStore,
  FAMILY_A,
  FAMILY_B,
  NOW,
  USER_A,
  USER_B,
} from "./_shared/testkit.ts";
import { spec as childDelete } from "./child-delete/handler.ts";
import { BAND_OF_STAGE, SCHOOL_STAGES, type SchoolStage, spec as childPut } from "./child-put/handler.ts";
import { PULL_LIMIT, spec as syncPull } from "./sync-pull/handler.ts";
import {
  DATA,
  MAX_EVENTS,
  PUSHES_PER_HOUR_PER_DEVICE,
  REQUIRED,
  spec as syncPush,
} from "./sync-push/handler.ts";
import { OPTION } from "./tutor-turn/handler.ts";

const NOON = 1_790_000_000_000;
const KID = "child-aaaa-0001";
const KID2 = "child-bbbb-0002";

async function setup() {
  const store = new FakeStore();
  const svc = fakeServices(store);
  const h = {
    put: makeHandler(childPut, () => svc),
    del: makeHandler(childDelete, () => svc),
    push: makeHandler(syncPush, () => svc),
    pull: makeHandler(syncPull, () => svc),
  };
  const parent = await addDevice(store, { family: FAMILY_A, user: USER_A, role: "parent" });
  const child = await addDevice(store, { family: FAMILY_A, user: USER_A, role: "child" });
  const other = await addDevice(store, { family: FAMILY_B, user: USER_B, role: "parent" });
  const profile = (id = KID, over: Record<string, unknown> = {}) => ({
    child_id: id,
    nickname: "נועה",
    avatar_id: "avatar-noa",
    address_form: "f",
    age_band: 1,
    ...over,
  });
  const attempt = (over: Record<string, unknown> = {}, id = crypto.randomUUID(), childId = KID) => ({
    id,
    child_id: childId,
    at: NOON,
    engine: 1,
    type: "attempt",
    data: {
      activity_id: "count.butterflies.3",
      activity_revision: 1,
      pack_id: "starter",
      pack_version: "0.2.0",
      template: "count_tap",
      template_version: "1.0",
      skill_id: "NUM-A-03",
      result: "correct",
      attempt_no: 1,
      hint_level: 0,
      duration_ms: 4200,
      input: "tap",
      session_local: 7,
      ...over,
    },
  });
  const session = (id = crypto.randomUUID()) => ({
    id,
    child_id: KID,
    at: NOON,
    engine: 1,
    type: "session",
    data: {
      plan: "lesson:butterflies",
      started_at: NOON,
      session_local: 7,
      end_reason: "finished",
      ended_at: NOON + 60_000,
    },
  });
  const j = async (r: Response) => await r.json();
  return { store, svc, h, parent, child, other, profile, attempt, session, j };
}

Deno.test("child-put: a parent saves a child with a nickname and every device of the family sees it", async () => {
  const { h, parent, child, other, profile, j } = await setup();
  const saved = await call(h.put, parent, "child-put", profile());
  assert.equal(saved.status, 200);
  const pulled = await j(await call(h.pull, child, "sync-pull", { after: 0, limit: 10 }));
  assert.equal(pulled.children.length, 1);
  assert.deepEqual(pulled.children[0], {
    id: KID,
    nickname: "נועה",
    avatar_id: "avatar-noa",
    companion_id: null,
    outfit_id: null,
    address_form: "f",
    age_band: 1,
    school_stage: null,
    birth: null,
  });
  const theirs = await j(await call(h.pull, other, "sync-pull", { after: 0, limit: 10 }));
  assert.equal(theirs.children.length, 0, "another family sees nothing of it");
  await call(h.put, parent, "child-put", profile(KID, { nickname: "נועה כהן", companion_id: "hero-son" }));
  const again = await j(await call(h.pull, child, "sync-pull", { after: 0, limit: 10 }));
  assert.equal(again.children.length, 1, "saving again changes the child, it does not add one");
  assert.equal(again.children[0].nickname, "נועה כהן");
  assert.equal(again.children[0].companion_id, "hero-son");
});

Deno.test("child-put: a child device cannot save children, and a nickname is plain text of 1 to 24 characters", async () => {
  const { h, parent, child, profile } = await setup();
  assert.equal((await call(h.put, child, "child-put", profile())).status, 403);
  for (
    const bad of [
      { nickname: "" },
      { nickname: "א".repeat(25) },
      { nickname: "<b>נועה</b>" },
      { nickname: "נועה\n" },
      { age_band: 3 },
      { address_form: "x" },
      { child_id: "short" },
      { avatar_id: "Bad Avatar" },
      { companion_id: "Bad Companion" },
      { surname: "כהן" },
    ]
  ) {
    assert.equal(
      (await call(h.put, parent, "child-put", profile(KID, bad))).status,
      400,
      JSON.stringify(bad),
    );
  }
});

Deno.test("child-delete: everything about the child goes, a tombstone is left, and every device learns of it", async () => {
  const { h, parent, child, other, store, profile, attempt, session, j } = await setup();
  await call(h.put, parent, "child-put", profile(KID));
  await call(h.put, parent, "child-put", profile(KID2, { nickname: "גלעד", avatar_id: "avatar-gilad" }));
  await call(h.push, child, "sync-push", {
    events: [attempt(), session(), attempt({}, crypto.randomUUID(), KID2)],
  });
  store.logs.push({ familyId: FAMILY_A, childRef: KID } as never);
  assert.equal(
    (await call(h.del, child, "child-delete", { child_id: KID })).status,
    403,
    "a child device cannot delete",
  );

  assert.equal((await call(h.del, parent, "child-delete", { child_id: KID })).status, 200);
  const pulled = await j(await call(h.pull, child, "sync-pull", { after: 0, limit: 100 }));
  assert.deepEqual(pulled.tombstones, [KID]);
  assert.deepEqual(pulled.children.map((c: { id: string }) => c.id), [KID2], "the other child stays");
  assert.ok(
    pulled.events.every((e: { child_id: string }) => e.child_id === KID2),
    "no event of the deleted child is left",
  );
  assert.equal(pulled.events.length, 1);
  assert.equal(store.logs.filter((l) => l.childRef === KID).length, 0, "nor a tutor log line");

  assert.equal(
    (await call(h.del, parent, "child-delete", { child_id: KID })).status,
    200,
    "deleting again is harmless",
  );
  const theirs = await j(await call(h.pull, other, "sync-pull", { after: 0, limit: 10 }));
  assert.deepEqual(theirs.tombstones, [], "another family sees no tombstone");
  assert.equal((await call(h.del, other, "child-delete", { child_id: KID2 })).status, 200);
  const stillThere = await j(await call(h.pull, child, "sync-pull", { after: 0, limit: 10 }));
  assert.equal(stillThere.children.length, 1, "another family cannot delete a child that is not theirs");
});

Deno.test("child-put: a deleted child can never come back, and the events of one are refused", async () => {
  const { h, parent, child, profile, attempt, j } = await setup();
  await call(h.put, parent, "child-put", profile());
  await call(h.del, parent, "child-delete", { child_id: KID });
  const again = await call(h.put, parent, "child-put", profile());
  assert.equal(again.status, 400);
  const e = attempt();
  const pushed = await j(await call(h.push, child, "sync-push", { events: [e] }));
  assert.deepEqual(pushed, { accepted: 0, duplicates: 0, refused: [e.id] });
});

Deno.test("sync-push: events are numbered by the server, a retry changes nothing, an unknown child is refused by id", async () => {
  const { h, parent, child, profile, attempt, session, j } = await setup();
  await call(h.put, parent, "child-put", profile());
  const a = attempt();
  const s = session();
  const stranger = attempt({}, crypto.randomUUID(), "child-zzzz-0009");
  const first = await j(await call(h.push, child, "sync-push", { events: [a, s, stranger] }));
  assert.deepEqual(first, { accepted: 2, duplicates: 0, refused: [stranger.id] });
  const retry = await j(await call(h.push, child, "sync-push", { events: [a, s] }));
  assert.deepEqual(retry, { accepted: 0, duplicates: 2, refused: [] });
  const pulled = await j(await call(h.pull, parent, "sync-pull", { after: 0, limit: 10 }));
  assert.equal(pulled.events.length, 2);
  assert.deepEqual(pulled.events.map((e: { seq: number }) => e.seq), [1, 2]);
  assert.equal(pulled.events[0].id, a.id);
  assert.equal(pulled.events[0].data.result, "correct");
  assert.equal(pulled.events[0].type, "attempt");
  assert.equal(pulled.events[1].type, "session");
});

Deno.test("sync-push: an answer of a language course carries its course, a dotted skill id and a language tag, and nothing else about it", async () => {
  const { h, parent, child, profile, attempt, j } = await setup();
  await call(h.put, parent, "child-put", profile());
  const english = attempt({
    pack_id: "lang-eng",
    skill_id: "ENG-B-19.G1",
    course: "eng",
    misconception_tag: "eng.ph.dir",
    result: "incorrect",
  });
  const plainCore = attempt({ course: "core" });
  const noCourse = attempt({ pack_id: "lang-heb", skill_id: "HEB-B-14.S10", misconception_tag: "" });
  const pushed = await j(await call(h.push, child, "sync-push", { events: [english, plainCore, noCourse] }));
  assert.equal(pushed.accepted, 3, "the course is optional; the lands send none");
  const pulled = await j(await call(h.pull, parent, "sync-pull", { after: 0, limit: 10 }));
  assert.equal(pulled.events[0].data.course, "eng");
  assert.equal(pulled.events[0].data.skill_id, "ENG-B-19.G1");
  for (
    const bad of [
      { course: "fra" },
      { course: "ENG" },
      { skill_id: "ENG-B-19.g1" },
      { skill_id: "ENG-B-19.G123" },
      { skill_id: "ENG-B-19.G1.G2" },
      { misconception_tag: "eng.ph.Dir" },
      { misconception_tag: "eng.ph" },
      { misconception_tag: "english.ph.dir" },
      { misconception_tag: "eng.ph." + "x".repeat(25) },
    ]
  ) {
    assert.equal(
      (await call(h.push, child, "sync-push", { events: [attempt(bad)] })).status,
      400,
      JSON.stringify(bad),
    );
  }
  const star = { kind: "star", key: "star:HEB-B-14.S1" };
  const reward = {
    id: crypto.randomUUID(),
    child_id: KID,
    at: NOON,
    engine: 1,
    type: "reward",
    data: star,
  };
  assert.equal((await call(h.push, child, "sync-push", { events: [reward] })).status, 200);
});

Deno.test("sync-push: a reward is a kind and an award key and nothing else; a parent's phone pulls it", async () => {
  const { h, parent, child, profile, j } = await setup();
  await call(h.put, parent, "child-put", profile());
  const reward = (data: Record<string, unknown>, id = crypto.randomUUID()) => ({
    id,
    child_id: KID,
    at: NOON,
    engine: 1,
    type: "reward",
    data,
  });
  const good = reward({ kind: "trophy", key: "trophy:counting:silver" });
  const pushed = await j(await call(h.push, child, "sync-push", { events: [good] }));
  assert.equal(pushed.accepted, 1);
  const pulled = await j(await call(h.pull, parent, "sync-pull", { after: 0, limit: 100 }));
  assert.equal(pulled.events[0].type, "reward");
  assert.deepEqual(pulled.events[0].data, { kind: "trophy", key: "trophy:counting:silver" });
  for (
    const key of [
      "sticker:butterflies:3",
      "star:NUM-A-01",
      "trophy:colors:gold",
      "medal:asks-questions",
      "deco:10",
    ]
  ) {
    const r = await call(h.push, child, "sync-push", { events: [reward({ kind: "star", key })] });
    assert.equal(r.status, 200, key);
  }
  const bad: Array<[string, Record<string, unknown>]> = [
    ["a key that is free text", { kind: "trophy", key: "gold for being quick" }],
    ["a promise typed by a parent", { kind: "trophy", key: "trophy:counting:gold", ribbon: "glida" }],
    ["a kind that is not a kind", { kind: "coupon", key: "star:NUM-A-01" }],
    ["a tier that does not exist", { kind: "trophy", key: "trophy:counting:platinum" }],
    ["no key", { kind: "star" }],
    ["no kind", { key: "star:NUM-A-01" }],
  ];
  for (const [why, data] of bad) {
    assert.equal((await call(h.push, child, "sync-push", { events: [reward(data)] })).status, 400, why);
  }
});

Deno.test("sync-push: only ids, numbers and fixed words get in: no free text, no name, no unknown field, nothing missing", async () => {
  const { h, parent, child, profile, attempt, j } = await setup();
  await call(h.put, parent, "child-put", profile());
  const bad: Array<[string, Record<string, unknown>]> = [
    ["a result that is not one of the three", { result: "wrong" }],
    ["a name in the data", { name: "נועה" }],
    ["a transcript", { transcript: "אני לא רוצה" }],
    ["an activity id with spaces", { activity_id: "count butterflies" }],
    ["a response with free text", { response: "I think it is four" }],
    ["a hint level of 9", { hint_level: 9 }],
    ["a duration of a day", { duration_ms: 86_400_000 }],
    ["a misconception tag that is not a tag", { misconception_tag: "he skipped one" }],
    ["an input that is not tap or voice", { input: "audio" }],
  ];
  for (const [why, over] of bad) {
    const r = await call(h.push, child, "sync-push", { events: [attempt(over)] });
    assert.equal(r.status, 400, why);
  }
  const missing = attempt();
  delete (missing.data as Record<string, unknown>).skill_id;
  assert.equal(
    (await call(h.push, child, "sync-push", { events: [missing] })).status,
    400,
    "a field the type needs",
  );
  const notUuid = { ...attempt(), id: "not-a-uuid" };
  assert.equal((await call(h.push, child, "sync-push", { events: [notUuid] })).status, 400);
  const tooMany = Array.from({ length: 41 }, () => attempt());
  assert.equal(
    (await call(h.push, child, "sync-push", { events: tooMany })).status,
    400,
    "more than 40 at once",
  );
  const ancient = { ...attempt(), at: 1000 };
  assert.equal(
    (await call(h.push, child, "sync-push", { events: [ancient] })).status,
    400,
    "a time before 2017",
  );
  assert.equal(
    (await j(await call(h.pull, parent, "sync-pull", { after: 0, limit: 10 }))).events.length,
    0,
    "none got in",
  );
});

/** A field of the gateway's schema as `testvectors/wire-patterns.json` writes it. */
function described(f: Field): Record<string, unknown> {
  switch (f.t) {
    case "uuid":
      return { t: f.t, pattern: UUID_ANY.source };
    case "string":
      return f.pattern ? { t: f.t, pattern: f.pattern.source, max: f.max } : { t: f.t, max: f.max };
    case "int":
      return { t: f.t, min: f.min, max: f.max };
    case "enum":
      return { t: f.t, values: [...f.values] };
    default:
      return { t: f.t };
  }
}

Deno.test("sync-push: every key, value and range it takes is the one in testvectors/wire-patterns.json", async () => {
  // The app is tested against the same file (app/test/wire_format_test.dart, response_contract_test.dart, and the fake
  // server of the sync tests, which refuses what this function would): a new key, value or range cannot reach a device
  // before this test and the file change with the gateway (SEC-12).
  const v = JSON.parse(
    await Deno.readTextFile(new URL("../../testvectors/wire-patterns.json", import.meta.url)),
  ) as {
    max_events: number;
    event_fields: Record<string, Record<string, unknown>>;
    data_fields: Record<string, Record<string, unknown>>;
    required: Record<string, string[]>;
  };
  const events = syncPush.shape.events as { t: "array"; maxItems: number; of: { t: "object"; shape: Shape } };
  assert.equal(events.maxItems, v.max_events);
  assert.equal(MAX_EVENTS, v.max_events);
  const compare = (shape: Shape, file: Record<string, Record<string, unknown>>, what: string) => {
    assert.deepEqual(Object.keys(shape).sort(), Object.keys(file).sort(), `${what}: the same keys`);
    for (const [key, f] of Object.entries(shape)) assert.deepEqual(described(f), file[key], `${what}.${key}`);
  };
  compare(events.of.shape, v.event_fields, "event");
  compare(DATA as unknown as Shape, v.data_fields, "data");
  for (const [key, f] of Object.entries(DATA)) {
    assert.ok(f.optional, `data.${key} is optional; each type's are below`);
  }
  assert.deepEqual(REQUIRED, v.required);
  assert.deepEqual(Object.keys(REQUIRED), (events.of.shape.type as { values: readonly string[] }).values);
});

Deno.test("sync-push: the app's answer codes fit (testvectors/wire-patterns.json), and the codes that stopped a sync do not", async () => {
  // The app is tested against the same file (app/test/response_contract_test.dart, the fake server of the sync tests).
  const v = JSON.parse(
    await Deno.readTextFile(new URL("../../testvectors/wire-patterns.json", import.meta.url)),
  ) as {
    tutor_option: string;
    examples: Record<string, string>;
  };
  assert.equal(OPTION.source, v.tutor_option);

  const { h, parent, child, profile, attempt, j } = await setup();
  await call(h.put, parent, "child-put", profile());
  const events = Object.values(v.examples).map((response) => attempt({ response }));
  const pushed = await j(await call(h.push, child, "sync-push", { events }));
  assert.equal(pushed.accepted, events.length, "every template's longest code gets in");
  // What the M9 templates wrote before SEC-1: each one refused the whole batch it was in.
  for (
    const old of [
      "3:30",
      "i1>b2",
      "b1=3,b2=3",
      "up,up,right",
      "asset:shape_x>s1",
      "a=x,b=y",
      "ball_red,ball_blue",
    ]
  ) {
    assert.equal(
      (await call(h.push, child, "sync-push", { events: [attempt({ response: old })] })).status,
      400,
      old,
    );
  }
});

Deno.test("sync-push: a device can only send a limited number of times an hour", async () => {
  const { h, parent, child, profile, attempt, store } = await setup();
  await call(h.put, parent, "child-put", profile());
  const hour = Math.floor(NOW / 3_600_000) * 3_600_000;
  store.counters.set(`sync_push/${child.id}/${hour}`, PUSHES_PER_HOUR_PER_DEVICE);
  const r = await call(h.push, child, "sync-push", { events: [attempt()] });
  assert.equal(r.status, 429);
});

Deno.test("sync-pull: a long log comes in pages of the server's own numbers and nothing is sent twice", async () => {
  const { h, parent, child, profile, attempt, j } = await setup();
  await call(h.put, parent, "child-put", profile());
  const events = Array.from({ length: 5 }, () => attempt());
  await call(h.push, child, "sync-push", { events });
  const seen: string[] = [];
  let after = 0;
  let pages = 0;
  for (;;) {
    const page = await j(await call(h.pull, parent, "sync-pull", { after, limit: 2 }));
    pages++;
    for (const e of page.events) seen.push(e.id);
    assert.ok(page.next >= after, "the cursor never goes back");
    after = page.next;
    if (!page.more) break;
    assert.ok(pages < 10, "it ends");
  }
  assert.equal(pages, 3);
  assert.deepEqual(seen, events.map((e) => e.id), "every event once, in the order the server received them");
  const end = await j(await call(h.pull, parent, "sync-pull", { after, limit: 2 }));
  assert.deepEqual(end.events, []);
  assert.equal(end.next, after, "an empty page keeps the cursor");
  assert.equal((await call(h.pull, parent, "sync-pull", { after: 0, limit: PULL_LIMIT + 1 })).status, 400);
  assert.equal((await call(h.pull, parent, "sync-pull", { after: -1, limit: 5 })).status, 400);
});

Deno.test("sync: events of one family are never seen by another, and the other family cannot push into it", async () => {
  const { h, parent, child, other, profile, attempt, j } = await setup();
  await call(h.put, parent, "child-put", profile());
  await call(h.push, child, "sync-push", { events: [attempt()] });
  const theirs = await j(await call(h.pull, other, "sync-pull", { after: 0, limit: 10 }));
  assert.deepEqual(theirs.events, []);
  const e = attempt();
  const pushed = await j(await call(h.push, other, "sync-push", { events: [e] }));
  assert.deepEqual(pushed.refused, [e.id], "their family has no such child");
  const mine = await j(await call(h.pull, parent, "sync-pull", { after: 0, limit: 10 }));
  assert.equal(mine.events.length, 1);
});

Deno.test("child-put: the prize the companion wears is an id, goes to every device, and nothing else fits there", async () => {
  const { h, parent, child, profile, j } = await setup();
  assert.equal((await call(h.put, parent, "child-put", profile(KID, { outfit_id: "sky" }))).status, 200);
  const first = await j(await call(h.pull, child, "sync-pull", { after: 0, limit: 10 }));
  assert.equal(first.children[0].outfit_id, "sky");
  // "none" is a choice too, and saving without a prize clears it.
  await call(h.put, parent, "child-put", profile(KID, { outfit_id: "none" }));
  assert.equal(
    (await j(await call(h.pull, child, "sync-pull", { after: 0, limit: 10 }))).children[0].outfit_id,
    "none",
  );
  for (const bad of ["Sky Scarf", "x", "a".repeat(21), "scarf!"]) {
    assert.equal(
      (await call(h.put, parent, "child-put", profile(KID, { outfit_id: bad }))).status,
      400,
      bad,
    );
  }
});

const PROFILE_VECTORS = JSON.parse(
  await Deno.readTextFile(new URL("../../testvectors/profile-sync.json", import.meta.url)),
) as {
  school_stages: string[];
  band_of_stage: Record<string, number>;
  refused_keys_of_child_put: string[];
  birth_examples: Array<{ year: number; month: number }>;
  birth_refused: unknown[];
};

Deno.test("child-put: the school stage is the six words of testvectors/profile-sync.json and each one has its band", () => {
  assert.deepEqual([...SCHOOL_STAGES], PROFILE_VECTORS.school_stages);
  assert.deepEqual(BAND_OF_STAGE, PROFILE_VECTORS.band_of_stage);
});

Deno.test("child-put: the school stage is saved, every device gets it, and a child without one has null", async () => {
  const { h, parent, child, other, profile, j } = await setup();
  const pull = async (who: typeof child) =>
    (await j(await call(h.pull, who, "sync-pull", { after: 0, limit: 10 }))).children;
  for (const stage of PROFILE_VECTORS.school_stages) {
    const band = PROFILE_VECTORS.band_of_stage[stage];
    const r = await call(h.put, parent, "child-put", profile(KID, { school_stage: stage, age_band: band }));
    assert.equal(r.status, 200, stage);
    const kids = await pull(child);
    assert.equal(kids[0].school_stage, stage);
    assert.equal(kids[0].age_band, band);
  }
  assert.deepEqual(await pull(other), [], "another family sees nothing of it");
  const none = await call(h.put, parent, "child-put", profile(KID2, { nickname: "גלעד", age_band: 0 }));
  assert.equal(none.status, 200);
  assert.equal((await pull(child)).find((c: { id: string }) => c.id === KID2).school_stage, null);
});

Deno.test("child-put: a save without a school stage keeps the stored one, so an older app cannot wipe it", async () => {
  const { h, parent, child, profile, j } = await setup();
  await call(h.put, parent, "child-put", profile(KID, { school_stage: "grade1", age_band: 1 }));
  assert.equal((await call(h.put, parent, "child-put", profile(KID, { nickname: "נועה כהן" }))).status, 200);
  const kid = (await j(await call(h.pull, child, "sync-pull", { after: 0, limit: 10 }))).children[0];
  assert.equal(kid.nickname, "נועה כהן");
  assert.equal(kid.school_stage, "grade1");
});

Deno.test("child-put: a save with another band and no stage never leaves a stage against the band (SEC-B29-1)", async () => {
  const { h, parent, child, profile, j } = await setup();
  await call(h.put, parent, "child-put", profile(KID, { school_stage: "grade2", age_band: 2 }));
  assert.equal((await call(h.put, parent, "child-put", profile(KID, { age_band: 1 }))).status, 200);
  const kid = (await j(await call(h.pull, child, "sync-pull", { after: 0, limit: 10 }))).children[0];
  assert.ok(kid.school_stage === null || BAND_OF_STAGE[kid.school_stage as SchoolStage] === kid.age_band);
});

Deno.test("child-put: a school stage that is not one of the six, in another type, or against the band is refused", async () => {
  const { h, parent, profile } = await setup();
  const bad: Array<Record<string, unknown>> = [
    { school_stage: "grade4" },
    { school_stage: "Grade1" },
    { school_stage: "" },
    { school_stage: null },
    { school_stage: 1 },
    { school_stage: ["gan3"] },
    { school_stage: "gan3", age_band: 1 },
    { school_stage: "grade2", age_band: 1 },
    { school_stage: "gan5", age_band: 0 },
  ];
  for (const over of bad) {
    assert.equal(
      (await call(h.put, parent, "child-put", profile(KID, over))).status,
      400,
      JSON.stringify(over),
    );
  }
});

Deno.test("child-put: no other key about a birth, an age in months or a look can be sent", async () => {
  const { h, parent, profile } = await setup();
  for (const key of PROFILE_VECTORS.refused_keys_of_child_put) {
    for (const value of [2020, 5, "2020-05", "2020-05-17", "A"]) {
      assert.equal(
        (await call(h.put, parent, "child-put", profile(KID, { [key]: value }))).status,
        400,
        `${key}=${value}`,
      );
    }
  }
});

Deno.test("child-put: the birth month and year are saved, every device of the family gets them, another family does not", async () => {
  const { h, parent, child, other, profile, j } = await setup();
  const pull = async (who: typeof child) =>
    (await j(await call(h.pull, who, "sync-pull", { after: 0, limit: 10 }))).children;
  for (const birth of PROFILE_VECTORS.birth_examples) {
    const r = await call(h.put, parent, "child-put", profile(KID, { birth }));
    assert.equal(r.status, 200, JSON.stringify(birth));
    assert.deepEqual((await pull(child))[0].birth, birth);
  }
  assert.deepEqual(await pull(other), [], "another family sees nothing of it");
  await call(h.put, parent, "child-put", profile(KID2, { nickname: "גלעד", age_band: 0 }));
  assert.equal(
    (await pull(child)).find((c: { id: string }) => c.id === KID2).birth,
    null,
    "a child with none has null",
  );
});

Deno.test("child-put: a save without a birth keeps the stored one, null clears it, a new one replaces it", async () => {
  const { h, parent, child, profile, j } = await setup();
  const birth = async () =>
    (await j(await call(h.pull, child, "sync-pull", { after: 0, limit: 10 }))).children[0].birth;
  await call(h.put, parent, "child-put", profile(KID, { birth: { year: 2021, month: 5 } }));
  assert.equal((await call(h.put, parent, "child-put", profile(KID, { nickname: "נועה כהן" }))).status, 200);
  assert.deepEqual(await birth(), { year: 2021, month: 5 }, "absent keeps (an older app cannot wipe it)");
  await call(h.put, parent, "child-put", profile(KID, { birth: { year: 2020, month: 12 } }));
  assert.deepEqual(await birth(), { year: 2020, month: 12 });
  assert.equal((await call(h.put, parent, "child-put", profile(KID, { birth: null }))).status, 200);
  assert.equal(await birth(), null, "null clears it");
  assert.equal((await call(h.put, parent, "child-put", profile(KID, { age_band: 1 }))).status, 200);
  assert.equal(await birth(), null, "and a save without one does not bring it back");
});

Deno.test("child-put: a birth that is not exactly a month 1 to 12 and a year 2010 to 2100 is refused", async () => {
  const { h, parent, profile } = await setup();
  for (const birth of PROFILE_VECTORS.birth_refused) {
    assert.equal(
      (await call(h.put, parent, "child-put", profile(KID, { birth }))).status,
      400,
      JSON.stringify(birth),
    );
  }
});

Deno.test("child-put: a deleted child's birth goes with the child and cannot be sent again", async () => {
  const { h, parent, child, profile, j } = await setup();
  await call(h.put, parent, "child-put", profile(KID, { birth: { year: 2021, month: 5 } }));
  await call(h.del, parent, "child-delete", { child_id: KID });
  const pulled = await j(await call(h.pull, child, "sync-pull", { after: 0, limit: 10 }));
  assert.deepEqual(pulled.children, []);
  assert.equal(
    (await call(h.put, parent, "child-put", profile(KID, { birth: { year: 2021, month: 5 } }))).status,
    400,
  );
});

Deno.test("sync-pull: the birth is in the response of sync-pull and in no other function's response", async () => {
  const { h, parent, child, profile, j } = await setup();
  await call(h.put, parent, "child-put", profile(KID, { birth: { year: 2021, month: 5 } }));
  const put = await j(
    await call(h.put, parent, "child-put", profile(KID, { birth: { year: 2021, month: 5 } })),
  );
  assert.deepEqual(put, { ok: true }, "child-put answers with nothing about it");
  const push = await j(await call(h.push, parent, "sync-push", { events: [] }));
  assert.ok(!JSON.stringify(push).includes("2021"));
  const pulled = await j(await call(h.pull, child, "sync-pull", { after: 0, limit: 10 }));
  assert.deepEqual(pulled.children[0].birth, { year: 2021, month: 5 });
});

Deno.test("no log line of child-put, sync-pull or a refused birth holds the month or the year", async () => {
  const { h, parent, child, profile } = await setup();
  const lines: string[] = [];
  const old = console.log;
  console.log = (...a: unknown[]) => void lines.push(a.map(String).join(" "));
  try {
    await call(h.put, parent, "child-put", profile(KID, { birth: { year: 2013, month: 7 } }));
    await call(h.pull, child, "sync-pull", { after: 0, limit: 10 });
    await call(h.put, parent, "child-put", profile(KID, { birth: { year: 1999, month: 14 } }));
    await call(h.put, parent, "child-put", profile(KID, { birth: "2013-07" }));
  } finally {
    console.log = old;
  }
  assert.ok(lines.length >= 4, "the calls did log");
  // A refusal names the field (like `school_stage:enum`), never what was in it.
  for (const l of lines) {
    assert.ok(!/2013|1999|-07|"month"|"year"/.test(l), l);
  }
});
