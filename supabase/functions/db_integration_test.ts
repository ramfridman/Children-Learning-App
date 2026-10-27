// Runs the real Postgres store and the real handlers against the local Supabase stack, connected
// as the least-privilege `app_gateway` role. Skipped unless both URLs are set (CI sets them).
import { assert } from "./_shared/testassert.ts";
import { connect, pgStore } from "./_shared/db.ts";
import { b64urlDecode, b64urlEncode } from "./_shared/b64.ts";
import { type FunctionSpec, makeHandler } from "./_shared/handler.ts";
import {
  call,
  callSelfSigned,
  fakeServices,
  FakeStore,
  plainPost,
  type TestDevice,
  tokenFor,
} from "./_shared/testkit.ts";
import { spec as deviceList } from "./device-list/handler.ts";
import { spec as deviceRevoke } from "./device-revoke/handler.ts";
import { spec as deviceEnroll } from "./device-enroll/handler.ts";
import { spec as devicePair } from "./device-pair/handler.ts";
import { spec as enrollChallenge } from "./enroll-challenge/handler.ts";
import { spec as pairingCodeCreate } from "./pairing-code-create/handler.ts";
import { spec as signedPing } from "./signed-ping/handler.ts";

const adminUrl = Deno.env.get("TEST_ADMIN_DB_URL");
const gatewayUrl = Deno.env.get("TEST_GATEWAY_DB_URL");

Deno.test(
  { name: "postgres store and handlers, as app_gateway", ignore: !adminUrl || !gatewayUrl },
  async () => {
    const admin = connect(adminUrl!);
    // Local test stack only: give the gateway role a login. Production sets its own password by hand.
    const password = new URL(gatewayUrl!).password;
    await admin.unsafe(`alter role app_gateway login password '${password.replaceAll("'", "''")}'`);
    const sql = connect(gatewayUrl!);
    const store = pgStore(sql);

    const userA = crypto.randomUUID();
    const userB = crypto.randomUUID();
    const famA = crypto.randomUUID();
    const famB = crypto.randomUUID();
    await admin`insert into auth.users (id, email) values (${userA}, ${
      userA + "@example.test"
    }), (${userB}, ${userB + "@example.test"})`;
    await admin`insert into app.family (id) values (${famA}), (${famB})`;
    await admin`insert into app.guardian (user_id, family_id) values (${userA}, ${famA}), (${userB}, ${famB})`;

    // Build devices by hand so the public key lands in Postgres.
    async function makeDevice(family: string, user: string, role: "parent" | "child"): Promise<TestDevice> {
      const pair = await crypto.subtle.generateKey({ name: "ECDSA", namedCurve: "P-256" }, true, ["sign"]);
      const spki = new Uint8Array(await crypto.subtle.exportKey("spki", pair.publicKey));
      const id = crypto.randomUUID();
      await admin`insert into app.device (id, family_id, role, public_key, platform, attestation_kind, security_level)
                values (${id}, ${family}, ${role}, ${spki as unknown as Uint8Array}, 'android', 'dev_allowlist', 'dev')`;
      return { id, familyId: family, userId: user, priv: pair.privateKey };
    }

    try {
      const svc = { ...fakeServices(new FakeStore(), () => Date.now()), store };
      const h = (s: FunctionSpec) => makeHandler(s, () => svc);
      const token = (u: string) => tokenFor(u, Math.floor(Date.now() / 1000) - 5);
      const send = (
        handler: ReturnType<typeof h>,
        d: TestDevice,
        fn: string,
        body: unknown = {},
        nonce?: string,
      ) => call(handler, d, fn, body, { token: token(d.userId), ts: Date.now(), nonce });

      const parentA = await makeDevice(famA, userA, "parent");
      const childA = await makeDevice(famA, userA, "child");
      const parentB = await makeDevice(famB, userB, "parent");

      // Signed ping through the real tables: device lookup, signature, nonce, guardian, role.
      const ping = h(signedPing);
      const nonce = crypto.randomUUID();
      assert.equal((await send(ping, parentA, "signed-ping", {}, nonce)).status, 200);
      assert.equal(
        (await send(ping, parentA, "signed-ping", {}, nonce)).status,
        401,
        "a repeated nonce is refused",
      );
      // A token for a user who is not a guardian of the device's family is refused.
      const wrongFamily = await call(ping, parentA, "signed-ping", {}, {
        token: token(userB),
        ts: Date.now(),
      });
      assert.equal(wrongFamily.status, 401);

      // Roles and family isolation.
      const list = h(deviceList);
      assert.equal((await send(list, childA, "device-list")).status, 403);
      const listed = await (await send(list, parentA, "device-list")).json();
      assert.equal(listed.devices.length, 2);

      const revoke = h(deviceRevoke);
      assert.equal((await send(revoke, parentA, "device-revoke", { device_id: parentB.id })).status, 404);
      assert.equal((await send(ping, parentB, "signed-ping")).status, 200);
      assert.equal((await send(revoke, parentA, "device-revoke", { device_id: childA.id })).status, 200);
      assert.equal((await send(ping, childA, "signed-ping")).status, 401, "revoked device stops at once");

      // Pairing code: stored as a hash, and the sixth in an hour is refused (atomic counter).
      const create = h(pairingCodeCreate);
      const first = await (await send(create, parentA, "pairing-code-create")).json();
      assert.match(first.code, /^\d{6}$/);
      const rows =
        await admin`select code_hash, expires_at - created_at as life from app.pairing_code where family_id = ${famA}`;
      assert.equal(rows.length, 1);
      assert.equal(rows[0].code_hash.length, 32);
      for (let i = 0; i < 4; i++) {
        assert.equal(
          (await send(create, parentA, "pairing-code-create")).status,
          200,
        );
      }
      assert.equal((await send(create, parentA, "pairing-code-create")).status, 429);

      // Challenges satisfy the database's own lifetime and length rules.
      const ch = h(enrollChallenge);
      const enrolled = await ch(
        plainPost("enroll-challenge", { purpose: "enroll" }, { authorization: `Bearer ${token(userA)}` }),
      );
      assert.equal(enrolled.status, 200);
      assert.equal(b64urlDecode((await enrolled.json()).challenge)!.length, 32);
      const paired = await ch(
        plainPost("enroll-challenge", { purpose: "pair" }, { "x-forwarded-for": "198.51.100.4" }),
      );
      assert.equal(paired.status, 200);
      const [counts] =
        await admin`select count(*)::int as n from app.enroll_challenge where user_id = ${userA} or ip_hash is not null`;
      assert.ok(counts.n >= 2);

      // The rate-limit statement is atomic: 20 simultaneous tries, limit 5, exactly 5 succeed.
      const window = new Date(Math.floor(Date.now() / 3_600_000) * 3_600_000);
      const results = await Promise.all(
        Array.from({ length: 20 }, () => store.rateLimitHit("test_race", "k", window, 5)),
      );
      assert.equal(results.filter(Boolean).length, 5);

      // Config: a missing key is undefined; a stored JSON value comes back as JSON.
      assert.equal(await store.getConfig("tutor_enabled"), undefined);
      await admin`insert into app.config (key, value) values ('tutor_enabled', 'true'::jsonb) on conflict (key) do update set value = excluded.value`;
      assert.equal(await store.getConfig("tutor_enabled"), true);
      await admin`delete from app.config where key = 'tutor_enabled'`;

      // The gateway role really is limited: it cannot read auth.users.
      let blocked = false;
      try {
        await sql`select count(*) from auth.users`;
      } catch {
        blocked = true;
      }
      assert.ok(blocked, "app_gateway must not read auth.users");
    } finally {
      await admin`delete from app.usage_counter where scope in ('test_race', 'pairing_code') or scope like 'challenge_%'`;
      await admin`delete from app.family where id in (${famA}, ${famB})`;
      await admin`delete from auth.users where id in (${userA}, ${userB})`;
      await sql.end();
      await admin.end();
    }
  },
);

Deno.test({
  name: "enrolment against the real tables (dev allowlist path)",
  ignore: !adminUrl || !gatewayUrl,
}, async () => {
  const admin = connect(adminUrl!);
  const sql = connect(gatewayUrl!);
  const store = pgStore(sql);
  const user = crypto.randomUUID();
  const secret = `ci-secret-${crypto.randomUUID()}`;
  await admin`insert into auth.users (id, email) values (${user}, ${user + "@example.test"})`;
  const digest = new Uint8Array(await crypto.subtle.digest("SHA-256", new TextEncoder().encode(secret)));
  await admin`insert into app.dev_device_allowlist (label, secret_hash, expires_at)
              values ('ci', ${digest as unknown as Uint8Array}, now() + interval '1 day')`;
  try {
    const svc = { ...fakeServices(new FakeStore(), () => Date.now()), store, allowDevEnrolment: true };
    const h = (s: FunctionSpec) => makeHandler(s, () => svc);
    const token = () => tokenFor(user, Math.floor(Date.now() / 1000) - 5);
    const enrol = async (extra: Record<string, unknown> = {}, key?: CryptoKeyPair) => {
      const pair = key ??
        await crypto.subtle.generateKey({ name: "ECDSA", namedCurve: "P-256" }, true, ["sign"]);
      const spki = new Uint8Array(await crypto.subtle.exportKey("spki", pair.publicKey));
      const c = await h(enrollChallenge)(
        plainPost("enroll-challenge", { purpose: "enroll" }, { authorization: `Bearer ${token()}` }),
      );
      const challenge = (await c.json()).challenge;
      const r = await callSelfSigned(h(deviceEnroll), pair.privateKey, "device-enroll", {
        challenge,
        public_key: b64urlEncode(spki),
        platform: "android",
        attestation_kind: "dev_allowlist",
        dev_secret: secret,
        ...extra,
      }, { token: token(), ts: Date.now() });
      return { r, pair, challenge };
    };

    const first = await enrol();
    assert.equal(first.r.status, 200);
    const firstId = (await first.r.json()).device_id as string;
    const [fam] = await admin`select count(*)::int as n from app.guardian where user_id = ${user}`;
    assert.equal(fam.n, 1, "a family and guardian were created");

    // The challenge is single use in the real table too.
    const [used] =
      await admin`select used_at from app.enroll_challenge where user_id = ${user} order by created_at limit 1`;
    assert.ok(used.used_at, "challenge marked used");

    const ids = [firstId];
    for (let i = 0; i < 5; i++) {
      const r = await enrol();
      assert.equal(r.r.status, 200);
      ids.push((await r.r.json()).device_id);
    }
    assert.equal((await enrol()).r.status, 409, "the seventh active device hits the database trigger");

    const replaced = await enrol({ replace_device_id: firstId });
    assert.equal(replaced.r.status, 200);
    const [old] = await admin`select revoked_reason from app.device where id = ${firstId}`;
    assert.equal(old.revoked_reason, "replaced");
    assert.equal((await enrol({}, replaced.pair)).r.status, 409, "the same key cannot be registered twice");
    assert.equal((await enrol({ replace_device_id: crypto.randomUUID() })).r.status, 404);
  } finally {
    await admin`delete from app.usage_counter where scope like 'challenge_%'`;
    await admin`delete from app.family where id in (select family_id from app.guardian where user_id = ${user})`;
    await admin`delete from app.dev_device_allowlist where label = 'ci'`;
    await admin`delete from auth.users where id = ${user}`;
    await sql.end();
    await admin.end();
  }
});

Deno.test({ name: "child pairing against the real tables", ignore: !adminUrl || !gatewayUrl }, async () => {
  const admin = connect(adminUrl!);
  const sql = connect(gatewayUrl!);
  const store = pgStore(sql);
  const user = crypto.randomUUID();
  const family = crypto.randomUUID();
  const secret = `ci-pair-${crypto.randomUUID()}`;
  await admin`insert into auth.users (id, email) values (${user}, ${user + "@example.test"})`;
  await admin`insert into app.family (id) values (${family})`;
  await admin`insert into app.guardian (user_id, family_id) values (${user}, ${family})`;
  const digest = new Uint8Array(await crypto.subtle.digest("SHA-256", new TextEncoder().encode(secret)));
  await admin`insert into app.dev_device_allowlist (label, secret_hash, expires_at)
              values ('ci-pair', ${digest as unknown as Uint8Array}, now() + interval '1 day')`;
  const parentPair = await crypto.subtle.generateKey({ name: "ECDSA", namedCurve: "P-256" }, true, ["sign"]);
  const parentSpki = new Uint8Array(await crypto.subtle.exportKey("spki", parentPair.publicKey));
  const parentId = crypto.randomUUID();
  await admin`insert into app.device (id, family_id, role, public_key, platform, attestation_kind, security_level)
              values (${parentId}, ${family}, 'parent', ${parentSpki as unknown as Uint8Array}, 'android', 'dev_allowlist', 'dev')`;
  const parent: TestDevice = { id: parentId, familyId: family, userId: user, priv: parentPair.privateKey };
  try {
    const svc = { ...fakeServices(new FakeStore(), () => Date.now()), store, allowDevEnrolment: true };
    const h = (s: FunctionSpec) => makeHandler(s, () => svc);
    const makeCode = async () => {
      await admin`delete from app.usage_counter where scope = 'pairing_code'`;
      const r = await call(h(pairingCodeCreate), parent, "pairing-code-create", {}, {
        token: tokenFor(user, Math.floor(Date.now() / 1000) - 5),
        ts: Date.now(),
      });
      return (await r.json()).code as string;
    };
    const pairWith = async (code: string, challenge?: string) => {
      const kp = await crypto.subtle.generateKey({ name: "ECDSA", namedCurve: "P-256" }, true, ["sign"]);
      const spki = new Uint8Array(await crypto.subtle.exportKey("spki", kp.publicKey));
      const ch = challenge ?? (await (await h(enrollChallenge)(
        plainPost("enroll-challenge", { purpose: "pair" }, { "x-forwarded-for": "192.0.2.10" }),
      )).json()).challenge;
      const r = await callSelfSigned(h(devicePair), kp.privateKey, "device-pair", {
        challenge: ch,
        code,
        public_key: b64urlEncode(spki),
        platform: "android",
        attestation_kind: "dev_allowlist",
        dev_secret: secret,
      }, { token: "", ts: Date.now() });
      return { r, challenge: ch as string };
    };

    // Wrong codes add up on the challenge; the fifth kills it even for the right code.
    const code = await makeCode();
    const wrong = code === "000000" ? "000001" : "000000";
    const first = await pairWith(wrong);
    assert.equal(first.r.status, 401);
    for (let i = 0; i < 4; i++) assert.equal((await pairWith(wrong, first.challenge)).r.status, 401);
    const [counted] =
      await admin`select failed_attempts from app.enroll_challenge where used_at is null and purpose = 'pair' and failed_attempts >= 5`;
    assert.ok(counted, "five failed attempts recorded");
    assert.equal(
      (await pairWith(code, first.challenge)).r.status,
      401,
      "dead challenge refuses the right code",
    );

    // The right code on a fresh challenge pairs a child; the code is then spent.
    const ok = await pairWith(code);
    assert.equal(ok.r.status, 200);
    const out = await ok.r.json();
    assert.equal(out.role, "child");
    const [row] = await admin`select role, family_id from app.device where id = ${out.device_id}`;
    assert.equal(row.role, "child");
    assert.equal(row.family_id, family);
    const [spent] =
      await admin`select used_by_device from app.pairing_code where used_by_device = ${out.device_id}`;
    assert.ok(spent, "the code records which device used it");
    assert.equal((await pairWith(code)).r.status, 401, "a spent code does not work twice");

    // Fill the family (parent + 5 children = 6) and the seventh is refused by the trigger.
    for (let i = 0; i < 4; i++) assert.equal((await pairWith(await makeCode())).r.status, 200);
    const last = await makeCode();
    assert.equal((await pairWith(last)).r.status, 409);
    const [stillLive] =
      await admin`select 1 as live from app.pairing_code where used_at is null and family_id = ${family}`;
    assert.ok(stillLive, "a refused join leaves the code unused");
  } finally {
    await admin`delete from app.usage_counter where scope in ('pairing_code', 'pair_try', 'pair_global') or scope like 'challenge_%'`;
    await admin`delete from app.enroll_challenge where purpose = 'pair'`;
    await admin`delete from app.family where id = ${family}`;
    await admin`delete from app.dev_device_allowlist where label = 'ci-pair'`;
    await admin`delete from auth.users where id = ${user}`;
    await sql.end();
    await admin.end();
  }
});

Deno.test(
  { name: "publishing and the tutor caps against the real tables", ignore: !adminUrl || !gatewayUrl },
  async () => {
    const admin = connect(adminUrl!);
    const password = new URL(gatewayUrl!).password;
    await admin.unsafe(`alter role app_gateway login password '${password.replaceAll("'", "''")}'`);
    const sql = connect(gatewayUrl!);
    const store = pgStore(sql);
    const family = crypto.randomUUID();
    await admin`insert into app.family (id) values (${family})`;
    const item = (id: string) => ({
      itemId: id,
      revision: 1,
      template: "count_tap",
      band: "A" as const,
      skillIds: ["NUM-A-03"],
      llmAllowed: true,
      goal: "touch each butterfly once",
      promptText: "כַּמָּה פַּרְפָּרִים?",
      answers: [
        { id: "o1", value: 2, misconception: "M-CNT-SKIP", correct: false },
        { id: "o2", value: 3, correct: true },
      ],
      numberSet: [2, 3],
      allowedActions: ["show_fingers"],
      hintThreshold: 3,
      objectIds: ["o1", "o2"],
    });
    const pack = (version: string, sha: string, ids: string[]) => ({
      packId: "ci-pack",
      packVersion: version,
      manifestSha256: sha,
      items: ids.map(item),
      misconceptions: [{ tag: "M-CNT-SKIP", skillIds: ["NUM-A-03"], description: "skips an object" }],
      characters: [{
        characterId: "ci-char",
        nameHe: "נִיצִי",
        gender: "f" as const,
        voiceId: null,
        personal: false,
      }],
    });
    try {
      assert.equal(await store.publishContent(pack("0.1.0", "a".repeat(64), ["a.1", "a.2"])), "published");
      assert.equal(await store.publishContent(pack("0.1.0", "a".repeat(64), ["a.1", "a.2"])), "unchanged");
      assert.equal(await store.publishContent(pack("0.1.0", "b".repeat(64), ["a.1"])), "conflict");
      assert.equal(await store.publishContent(pack("0.0.9", "c".repeat(64), ["a.1"])), "older");
      const items =
        await admin`select item_id, answers, number_set, skill_ids from app.content_item where pack_id = 'ci-pack' order by item_id`;
      assert.equal(items.length, 2);
      assert.equal(items[0].number_set.join(","), "2,3");
      assert.equal(items[0].skill_ids[0], "NUM-A-03");
      assert.equal(items[0].answers[1].correct, true);
      assert.equal(await store.publishContent(pack("0.2.0", "d".repeat(64), ["a.1"])), "published");
      const after =
        await admin`select pack_version, count(*)::int as n from app.content_item where pack_id = 'ci-pack' group by 1`;
      assert.equal(after.length, 1, "only the current version is kept");
      assert.equal(after[0].pack_version, "0.2.0");
      await admin`update app.family_character set voice_id = 'abcDEF0123456789' where character_id = 'ci-char'`;
      await store.publishContent(pack("0.3.0", "e".repeat(64), ["a.1"]));
      const [ch] = await admin`select voice_id from app.family_character where character_id = 'ci-char'`;
      assert.equal(ch.voice_id, "abcDEF0123456789", "a publish does not erase a chosen voice");

      // The caps: 30 requests at once against a limit of 20 let exactly 20 through.
      const now = new Date();
      const results = await Promise.all(
        Array.from(
          { length: 30 },
          () =>
            sql`select app.tutor_take(${family}, 'ci-child', 'ci-session', 'turn', 20, 60, 40, 500000, ${now}) as r`,
        ),
      );
      const ok = results.filter((r) => r[0].r === "ok").length;
      assert.equal(ok, 20, "exactly 20 turns are allowed in a session, even in parallel");
      assert.equal(results.filter((r) => r[0].r === "session_cap").length, 10);
      const [day] =
        await admin`select count from app.usage_counter where scope = 'tutor_day' and key = 'ci-child'`;
      assert.equal(day.count, 20, "refused turns gave their slot back");
    } finally {
      await admin`delete from app.content_pack where pack_id = 'ci-pack'`;
      await admin`delete from app.family_character where character_id = 'ci-char'`;
      await admin`delete from app.usage_counter where key in ('ci-child', 'ci-session')`;
      await admin`delete from app.family where id = ${family}`;
      await sql.end();
      await admin.end();
    }
  },
);

Deno.test({
  name: "the tutor's context, cache, caps and log against the real tables",
  ignore: !adminUrl || !gatewayUrl,
}, async () => {
  const admin = connect(adminUrl!);
  const password = new URL(gatewayUrl!).password;
  await admin.unsafe(`alter role app_gateway login password '${password.replaceAll("'", "''")}'`);
  const sql = connect(gatewayUrl!);
  const store = pgStore(sql);
  const family = crypto.randomUUID();
  await admin`insert into app.family (id) values (${family})`;
  try {
    await store.publishContent({
      packId: "ci-tutor",
      packVersion: "0.1.0",
      manifestSha256: "f".repeat(64),
      items: [{
        itemId: "t.1",
        revision: 1,
        template: "count_tap",
        band: "A",
        skillIds: ["NUM-A-03"],
        llmAllowed: true,
        goal: "touch each once",
        promptText: "כַּמָּה?",
        answers: [{ id: "o1", value: 2, misconception: "M-CNT-SKIP", correct: false }, {
          id: "o2",
          value: 3,
          correct: true,
        }],
        numberSet: [2, 3],
        allowedActions: ["show_fingers"],
        hintThreshold: 3,
        objectIds: ["o1", "o2"],
      }],
      misconceptions: [{ tag: "M-CNT-SKIP", skillIds: ["NUM-A-03"], description: "skips one" }],
      characters: [{
        characterId: "ci-tutor-char",
        nameHe: "נִיצִי",
        gender: "f",
        voiceId: "abcDEF0123456789",
        personal: false,
      }],
    });
    const ctx = await store.tutorContext("ci-tutor", "0.1.0", "t.1", "ci-tutor-char");
    assert.ok(ctx);
    assert.equal(ctx!.hintThreshold, 3);
    assert.equal(ctx!.answers[1].correct, true);
    assert.equal(ctx!.descriptions["M-CNT-SKIP"], "skips one");
    assert.deepEqual(ctx!.character, { nameHe: "נִיצִי", gender: "f", voiceId: "abcDEF0123456789" });
    assert.equal(await store.tutorContext("ci-tutor", "0.1.0", "nope", "ci-tutor-char"), null);
    assert.equal(await store.tutorContext("ci-tutor", "9.9.9", "t.1", "ci-tutor-char"), null);
    assert.deepEqual(await store.tutorItemIds("ci-tutor", "0.1.0"), ["t.1"]);
    assert.deepEqual(await store.tutorItemIds("ci-tutor", "9.9.9"), []);

    const key = {
      packId: "ci-tutor",
      packVersion: "0.1.0",
      itemId: "t.1",
      mistake: "M-CNT-SKIP",
      hintLevel: 0,
      band: "A" as const,
      addressForm: "n" as const,
      characterId: "ci-tutor-char",
      promptVersion: "p1",
      validatorVersion: "v1",
    };
    assert.equal(await store.cacheGet(key), null);
    const audio = new Uint8Array([1, 2, 3, 250, 251]);
    await store.cachePut(key, {
      line: "בּוֹאוּ",
      caption: null,
      next: "show_fingers",
      highlight: ["o1"],
      audio,
    });
    await store.cachePut(key, { line: "other", caption: null, next: "none", highlight: [], audio: null });
    const got = await store.cacheGet(key);
    assert.equal(got!.line, "בּוֹאוּ", "the first line stays");
    assert.deepEqual([...got!.audio!], [1, 2, 3, 250, 251]);
    assert.deepEqual(got!.highlight, ["o1"]);
    assert.equal(
      await store.cacheGet({ ...key, promptVersion: "p2" }),
      null,
      "a new prompt version finds nothing",
    );
    // A reviewed line that was edited replaces the old one; without the flag the first line stays.
    const approvedKey = { ...key, promptVersion: "approved" };
    await store.cachePut(approvedKey, {
      line: "one",
      caption: null,
      next: "none",
      highlight: [],
      audio: audio,
    }, true);
    await store.cachePut(approvedKey, {
      line: "kept",
      caption: null,
      next: "none",
      highlight: [],
      audio: null,
    });
    assert.equal((await store.cacheGet(approvedKey))!.line, "one");
    await store.cachePut(approvedKey, {
      line: "edited",
      caption: null,
      next: "none",
      highlight: [],
      audio: null,
    }, true);
    assert.equal((await store.cacheGet(approvedKey))!.line, "edited");
    assert.equal(
      (await store.cacheGet(key))!.line,
      "בּוֹאוּ",
      "the model's line under its own version is untouched",
    );

    const now = Date.now();
    const take = (kind: "turn" | "prefetch", session: string) =>
      store.tutorTake({
        familyId: family,
        childRef: "ci-kid",
        sessionRef: session,
        kind,
        sessionCap: 2,
        dayCap: 3,
        prefetchCap: 1,
        costCapMicro: 1000,
        nowMs: now,
      });
    assert.equal(await take("turn", "cs1"), "ok");
    assert.equal(await take("turn", "cs1"), "ok");
    assert.equal(await take("turn", "cs1"), "session_cap");
    assert.equal(await take("turn", "cs2"), "ok");
    assert.equal(await take("turn", "cs3"), "day_cap");
    assert.equal(await take("prefetch", "cp1"), "ok");
    assert.equal(await take("prefetch", "cp1"), "prefetch_cap");
    await store.tutorCostAdd(family, 1500, now);
    assert.equal(await take("prefetch", "cp2"), "cost_cap");

    await store.logTutor({
      familyId: family,
      childRef: "ci-kid",
      sessionRef: "cs1",
      packId: "ci-tutor",
      packVersion: "0.1.0",
      itemId: "t.1",
      characterId: "ci-tutor-char",
      source: "live",
      outcome: "ok",
      line: "בואו",
      validatorOk: true,
      validatorFailures: [],
      promptVersion: "p1",
      totalMs: 812.4,
      modelMs: 500.2,
      voiceMs: 250,
      elevenRequestId: "req123",
    });
    const [row] =
      await admin`select line, total_ms, validator_failures from app.tutor_log where family_id = ${family}`;
    assert.equal(row.line, "בואו");
    assert.equal(row.total_ms, 812);
    assert.equal(row.validator_failures.length, 0);
    const configs = await store.getConfigs(["tutor_enabled", "no_such_key_ci"]);
    assert.equal(configs["no_such_key_ci"], undefined);
  } finally {
    await admin`delete from app.content_pack where pack_id = 'ci-tutor'`;
    await admin`delete from app.family_character where character_id = 'ci-tutor-char'`;
    await admin`delete from app.usage_counter where key in ('ci-kid', 'cs1', 'cs2', 'cs3', 'cp1', 'cp2') or key = ${family}`;
    await admin`delete from app.family where id = ${family}`;
    await sql.end();
    await admin.end();
  }
});

Deno.test({
  name: "children, the event log with its cursor, and deleting a child against the real tables",
  ignore: !adminUrl || !gatewayUrl,
}, async () => {
  const admin = connect(adminUrl!);
  const password = new URL(gatewayUrl!).password;
  await admin.unsafe(`alter role app_gateway login password '${password.replaceAll("'", "''")}'`);
  const sql = connect(gatewayUrl!);
  const store = pgStore(sql);
  const family = crypto.randomUUID();
  const other = crypto.randomUUID();
  await admin`insert into app.family (id) values (${family}), (${other})`;
  const kid = "ci-child-0001";
  const kid2 = "ci-child-0002";
  const device = crypto.randomUUID();
  const ev = (id: string, childId: string, at: number) => ({
    id,
    childId,
    clientAtMs: at,
    engineVersion: 1,
    type: "attempt" as const,
    payload: { activity_id: "count.butterflies.3", result: "correct", attempt_no: 1, duration_ms: 3100 },
  });
  try {
    const profile = {
      id: kid,
      nickname: "נועה",
      avatarId: "avatar-noa",
      companionId: null,
      addressForm: "f" as const,
      ageBand: 1 as const,
    };
    assert.equal(await store.upsertChild(family, profile), "saved");
    assert.equal(
      await store.upsertChild(family, { ...profile, nickname: "נועה כהן", companionId: "hero-son" }),
      "saved",
    );
    assert.equal(await store.upsertChild(family, { ...profile, id: kid2, nickname: "דני" }), "saved");
    const kids = await store.listChildren(family);
    assert.equal(kids.length, 2);
    assert.equal(kids[0].nickname, "נועה כהן", "saving again changed the child, it did not add one");
    assert.equal(kids[0].companionId, "hero-son");
    assert.deepEqual(await store.listChildren(other), [], "another family sees none");

    const [a, b, c] = [crypto.randomUUID(), crypto.randomUUID(), crypto.randomUUID()];
    const first = await store.insertEvents(family, device, [
      ev(a, kid, 1_790_000_000_000),
      ev(b, kid2, 1_790_000_001_000),
      ev(c, "ci-child-9999", 1_790_000_002_000),
    ]);
    assert.deepEqual(first, { accepted: 2, duplicates: 0, refused: [c] });
    const retry = await store.insertEvents(family, device, [ev(a, kid, 1_790_000_000_000)]);
    assert.deepEqual(retry, { accepted: 0, duplicates: 1, refused: [] });
    const page = await store.pullEvents(family, 0, 1);
    assert.equal(page.events.length, 1);
    assert.equal(page.more, true);
    assert.equal(page.events[0].id, a);
    assert.equal(typeof page.events[0].payload, "object", "the payload is an object, not a string");
    assert.equal(page.events[0].payload.duration_ms, 3100);
    assert.equal(page.events[0].clientAtMs, 1_790_000_000_000);
    const rest = await store.pullEvents(family, page.events[0].seq, 10);
    assert.deepEqual(rest.events.map((e) => e.id), [b]);
    assert.equal(rest.more, false);
    assert.deepEqual((await store.pullEvents(other, 0, 10)).events, [], "another family sees none");

    // The gateway role cannot rewrite or remove the log itself.
    let refused = false;
    try {
      await sql`delete from app.event where family_id = ${family}`;
    } catch {
      refused = true;
    }
    assert.equal(refused, true);

    // Deleting a child removes every trace of that child and leaves a tombstone.
    await admin`insert into app.tutor_log (family_id, child_ref, session_ref, pack_id, pack_version, item_id,
      character_id, source, outcome, prompt_version) values (${family}, ${kid}, 'ci-session-1', 'starter', '0.2.0', 'x',
      'nitzi', 'live', 'ok', 'p4')`;
    await admin`insert into app.alert (family_id, child_id, device_id, category, severity, dedupe_key, client_at)
      values (${family}, ${kid}, ${device}, 'frustration', 'attention', 'ci-upset', now())`;
    await store.deleteChild(family, kid);
    await store.deleteChild(family, kid);
    assert.deepEqual((await store.listChildren(family)).map((k) => k.id), [kid2]);
    assert.deepEqual(await store.listTombstones(family), [kid]);
    assert.equal((await admin`select count(*)::int as n from app.event where child_id = ${kid}`)[0].n, 0);
    assert.equal((await admin`select count(*)::int as n from app.alert where child_id = ${kid}`)[0].n, 0);
    assert.equal(
      (await admin`select count(*)::int as n from app.tutor_log where child_ref = ${kid}`)[0].n,
      0,
    );
    assert.equal(
      (await store.pullEvents(family, 0, 10)).events.length,
      1,
      "the other child keeps its events",
    );
    assert.equal(await store.upsertChild(family, profile), "deleted", "a deleted child cannot come back");
    const after = await store.insertEvents(family, device, [ev(crypto.randomUUID(), kid, 1_790_000_003_000)]);
    assert.equal(after.refused.length, 1);
    assert.deepEqual(await store.listTombstones(other), []);
  } finally {
    await admin`delete from app.family where id in (${family}, ${other})`;
    await sql.end();
    await admin.end();
  }
});

Deno.test({
  name: "alerts, push tokens, settings and the tutor log against the real tables",
  ignore: !adminUrl || !gatewayUrl,
}, async () => {
  const admin = connect(adminUrl!);
  const password = new URL(gatewayUrl!).password;
  await admin.unsafe(`alter role app_gateway login password '${password.replaceAll("'", "''")}'`);
  const sql = connect(gatewayUrl!);
  const store = pgStore(sql);
  const family = crypto.randomUUID();
  const other = crypto.randomUUID();
  const user = crypto.randomUUID();
  await admin`insert into auth.users (id, email) values (${user}, ${user + "@example.test"})`;
  await admin`insert into app.family (id) values (${family}), (${other})`;
  await admin`insert into app.guardian (user_id, family_id) values (${user}, ${family})`;
  const spki = new Uint8Array(91).fill(5);
  const [dev] =
    await admin`insert into app.device (family_id, role, public_key, platform, attestation_kind, security_level)
    values (${family}, 'parent', ${spki as unknown as Uint8Array}, 'android', 'dev_allowlist', 'dev') returning id`;
  const kid = "ci-child-0001";
  try {
    await store.upsertChild(family, {
      id: kid,
      nickname: "נועה",
      avatarId: "avatar-noa",
      companionId: null,
      addressForm: "f",
      ageBand: 1,
    });
    const alert = (key: string, over: Partial<Parameters<typeof store.insertAlert>[2]> = {}) => ({
      childId: kid,
      category: "inappropriateWords",
      severity: "attention",
      count: 0,
      detail: "",
      words: "חרא",
      key,
      clientAtMs: Date.now() - 1000,
      ...over,
    });
    assert.equal(await store.insertAlert(family, dev.id, alert("a1")), "new");
    assert.equal(await store.insertAlert(family, dev.id, alert("a1")), "duplicate");
    assert.equal(
      await store.insertAlert(family, dev.id, alert("a2", { childId: "ci-child-9999" })),
      "refused",
    );
    assert.equal(
      await store.insertAlert(
        family,
        dev.id,
        alert("g1", { childId: null, category: "gateAttempts", words: "", count: 3 }),
      ),
      "new",
    );
    await store.insertAlert(family, dev.id, alert("old", { clientAtMs: Date.now() - 40 * 86_400_000 }));
    const listed = await store.listAlerts(family, Date.now() - 30 * 86_400_000);
    assert.deepEqual(listed.map((a) => a.key).sort(), ["a1", "g1"], "30 days only");
    assert.equal(listed.find((a) => a.key === "a1")!.words, "חרא");
    assert.equal(listed.every((a) => a.readAtMs === null), true);
    assert.equal(await store.markAlertsRead(family, Date.now()), 3, "every unread one, including the old");
    assert.equal(await store.markAlertsRead(family, Date.now()), 0);
    assert.deepEqual(await store.listAlerts(other, 0), [], "another family sees none");

    const token = "ci-token-" + "a".repeat(40);
    await store.upsertPushToken(family, dev.id, token, "android");
    await store.upsertPushToken(family, dev.id, token + "2", "android");
    const tokens = await store.pushTokens(family);
    assert.equal(tokens.length, 1);
    assert.equal(tokens[0].token, token + "2");
    assert.deepEqual(await store.pushTokens(other), []);
    await store.removePushToken(dev.id);
    assert.deepEqual(await store.pushTokens(family), []);

    assert.equal(await store.getSettings(family), null);
    assert.equal(await store.putSettings(family, { restOn: true, limitByBand: { A: 15 } }), 1);
    assert.equal(await store.putSettings(family, { restOn: false }), 2);
    const got = await store.getSettings(family);
    assert.deepEqual(got, { rules: { restOn: false }, version: 2 });
    assert.equal(await store.getSettings(other), null);

    await admin`insert into app.tutor_log (family_id, child_ref, session_ref, pack_id, pack_version, item_id,
      character_id, source, outcome, line, prompt_version) values (${family}, ${kid}, 'ci-session-2', 'starter', '0.2.0',
      'count.butterflies.3', 'hero-son', 'cache', 'ok', 'בּוֹאוּ נִסְפֹּר', 'approved')`;
    const log = await store.tutorLogOf(family, Date.now() - 30 * 86_400_000, 100);
    assert.equal(log.length, 1);
    assert.equal(log[0].line, "בּוֹאוּ נִסְפֹּר");
    assert.equal(log[0].childRef, kid);
    assert.deepEqual(await store.tutorLogOf(other, 0, 100), []);
  } finally {
    await admin`delete from app.family where id in (${family}, ${other})`;
    await admin`delete from auth.users where id = ${user}`;
    await sql.end();
    await admin.end();
  }
});
