// The parent area's sync functions: children with nicknames, the log with its server cursor, and deleting a child.
// Each one is called as a signed device, so the four checks of every function run too.
import { assert } from "./_shared/testassert.ts";
import { makeHandler } from "./_shared/handler.ts";
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
import { spec as childPut } from "./child-put/handler.ts";
import { PULL_LIMIT, spec as syncPull } from "./sync-pull/handler.ts";
import { PUSHES_PER_HOUR_PER_DEVICE, spec as syncPush } from "./sync-push/handler.ts";

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
    address_form: "f",
    age_band: 1,
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
  await call(h.put, parent, "child-put", profile(KID2, { nickname: "דני", avatar_id: "avatar-dani" }));
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
