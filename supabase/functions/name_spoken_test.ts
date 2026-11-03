// B-42: how a child's name is said. The gateway, the database check and the app take the same spellings
// (testvectors/name-spoken.json). The app is tested against the same file (app/test/name_spoken_test.dart); this side proves
// what the shared validator, child-put and the migration's check take and refuse.
import { assert } from "./_shared/testassert.ts";
import { spellingHash } from "./_shared/name_voice.ts";
import { isSpokenName, NAME_SPOKEN, NAME_SPOKEN_MAX } from "./_shared/name_spoken.ts";
import { type Shape, validate } from "./_shared/schema.ts";
import { addDevice, call, fakeServices, FakeStore, FAMILY_A, USER_A } from "./_shared/testkit.ts";
import { makeHandler } from "./_shared/handler.ts";
import { spec as childPut } from "./child-put/handler.ts";
import { spec as syncPull } from "./sync-pull/handler.ts";

interface Vector {
  name: string;
  value: string;
  units: number;
}

const v = JSON.parse(
  await Deno.readTextFile(new URL("../../testvectors/name-spoken.json", import.meta.url)),
) as {
  max_utf16_units: number;
  server_pattern: string;
  accept: Vector[];
  reject: Vector[];
  hash_examples: Array<{ value: string; hash: string }>;
};

Deno.test("name spoken: the validator's pattern and limit are the ones in testvectors/name-spoken.json", () => {
  assert.equal(NAME_SPOKEN.source, v.server_pattern);
  assert.equal(
    NAME_SPOKEN.flags,
    "",
    "no u flag: the pattern counts UTF-16 units, as the app and the database do",
  );
  assert.equal(NAME_SPOKEN_MAX, v.max_utf16_units);
});

Deno.test("name spoken: every vector is as long as it says, in UTF-16 units", () => {
  for (const x of [...v.accept, ...v.reject]) assert.equal(x.value.length, x.units, x.name);
});

Deno.test("name spoken: the validator takes every accepted spelling and refuses every rejected one", () => {
  assert.ok(v.accept.length >= 10 && v.reject.length >= 25);
  for (const x of v.accept) assert.ok(isSpokenName(x.value), x.name);
  for (const x of v.reject) assert.ok(!isSpokenName(x.value), x.name);
  for (const x of [null, undefined, 5, {}, []]) assert.ok(!isSpokenName(x));
});

Deno.test("name spoken: the database check is the same rule (its patterns, run here on every vector)", async () => {
  const sql = await Deno.readTextFile(
    new URL("../migrations/20261103120000_name_spoken.sql", import.meta.url),
  );
  const check = sql.slice(sql.indexOf("add constraint child_profile_name_spoken_check"));
  const patterns = [...check.matchAll(/name_spoken (!?)~ '((?:[^']|'')*)'/g)].map((m) => ({
    negated: m[1] === "!",
    re: new RegExp(m[2].replaceAll("''", "'")),
  }));
  assert.equal(patterns.length, 5, "the five patterns of the check");
  const length = check.match(/char_length\(name_spoken\) between (\d+) and (\d+)/)!;
  assert.deepEqual([Number(length[1]), Number(length[2])], [1, v.max_utf16_units]);
  const takes = (s: string) =>
    s.length >= Number(length[1]) && s.length <= Number(length[2]) &&
    patterns.every((p) => p.re.test(s) !== p.negated);
  for (const x of v.accept) assert.ok(takes(x.value), `takes ${x.name}`);
  for (const x of v.reject) assert.ok(!takes(x.value), `refuses ${x.name}`);
});

Deno.test("name spoken: child-put's schema takes and refuses the same, and the field is optional", () => {
  const only: Shape = { name_spoken: childPut.shape.name_spoken };
  const takes = (s: string) => {
    try {
      validate(only, { name_spoken: s });
      return true;
    } catch {
      return false;
    }
  };
  for (const x of v.accept) assert.ok(takes(x.value), x.name);
  for (const x of v.reject) assert.ok(!takes(x.value), x.name);
  assert.ok(childPut.shape.name_spoken.optional === true);
});

async function setup() {
  const store = new FakeStore();
  const svc = fakeServices(store);
  const h = { put: makeHandler(childPut, () => svc), pull: makeHandler(syncPull, () => svc) };
  const parent = await addDevice(store, { family: FAMILY_A, user: USER_A, role: "parent" });
  const child = await addDevice(store, { family: FAMILY_A, user: USER_A, role: "child" });
  const profile = (over: Record<string, unknown> = {}) => ({
    child_id: "child-aaaa-0001",
    nickname: "נועה",
    avatar_id: "avatar-noa",
    address_form: "f",
    age_band: 1,
    ...over,
  });
  return { store, h, parent, child, profile };
}

Deno.test("child-put: the spelling is saved with the child and every device sees it; absent keeps it, null clears it", async () => {
  const { h, parent, child, profile } = await setup();
  assert.equal((await call(h.put, parent, "child-put", profile({ name_spoken: "נֹעָה" }))).status, 200);
  const first = await (await call(h.pull, child, "sync-pull", { after: 0, limit: 10 })).json();
  assert.equal(first.children[0].name_spoken, "נֹעָה");
  assert.equal(first.children[0].nickname, "נועה", "the nickname is its own text");
  // A phone from before B-42 saves the child without the field: the spelling stays (O2).
  assert.equal((await call(h.put, parent, "child-put", profile({ nickname: "נועה כהן" }))).status, 200);
  const kept = await (await call(h.pull, child, "sync-pull", { after: 0, limit: 10 })).json();
  assert.equal(kept.children[0].name_spoken, "נֹעָה", "absent leaves it");
  assert.equal(kept.children[0].nickname, "נועה כהן", "the rest of the child did change");
  assert.equal((await call(h.put, parent, "child-put", profile({ name_spoken: null }))).status, 200);
  const cleared = await (await call(h.pull, child, "sync-pull", { after: 0, limit: 10 })).json();
  assert.equal(cleared.children[0].name_spoken, null, "an explicit null clears it");
});

Deno.test("child-put: a spelling the voice must not read is refused, and a child device cannot set one", async () => {
  const { h, parent, child, profile, store } = await setup();
  for (const bad of ["Noa", "נועה!", " נועה", "<b>", "x".repeat(25), ""]) {
    assert.equal((await call(h.put, parent, "child-put", profile({ name_spoken: bad }))).status, 400, bad);
  }
  assert.equal((await call(h.put, child, "child-put", profile({ name_spoken: "נועה" }))).status, 403);
  assert.equal(store.children.size, 0, "nothing was saved");
});

Deno.test("name spoken: the hash a clip is keyed by is the shared one (the phone checks the same examples)", async () => {
  assert.ok(v.hash_examples.length >= 3);
  for (const x of v.hash_examples) assert.equal(await spellingHash(x.value), x.hash, x.value);
});
