// Runs the real Postgres store and the real handlers against the local Supabase stack, connected
// as the least-privilege `app_gateway` role. Skipped unless both URLs are set (CI sets them).
import { assert } from "./_shared/testassert.ts";
import { connect, pgStore } from "./_shared/db.ts";
import { b64urlDecode } from "./_shared/b64.ts";
import { type FunctionSpec, makeHandler } from "./_shared/handler.ts";
import { call, fakeServices, FakeStore, plainPost, type TestDevice, tokenFor } from "./_shared/testkit.ts";
import { spec as deviceList } from "./device-list/handler.ts";
import { spec as deviceRevoke } from "./device-revoke/handler.ts";
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
