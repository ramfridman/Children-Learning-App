import { assert } from "./_shared/testassert.ts";
import { b64urlDecode, b64urlEncode } from "./_shared/b64.ts";
import { type FunctionSpec, makeHandler } from "./_shared/handler.ts";
import { hashPairingCode } from "./_shared/keyed.ts";
import {
  addDevice,
  call,
  fakeServices,
  FakeStore,
  FAMILY_A,
  FAMILY_B,
  NOW,
  plainPost,
  tokenFor,
  USER_A,
  USER_B,
} from "./_shared/testkit.ts";
import { spec as appConfig } from "./app-config/handler.ts";
import { spec as deviceList } from "./device-list/handler.ts";
import { spec as deviceRevoke } from "./device-revoke/handler.ts";
import { CHALLENGE_SECONDS, spec as enrollChallenge } from "./enroll-challenge/handler.ts";
import { CODE_SECONDS, spec as pairingCodeCreate } from "./pairing-code-create/handler.ts";
import { spec as signedPing } from "./signed-ping/handler.ts";

async function setup() {
  const store = new FakeStore();
  const svc = fakeServices(store);
  const h = (spec: FunctionSpec) => makeHandler(spec, () => svc);
  const parentA = await addDevice(store, { family: FAMILY_A, user: USER_A, role: "parent" });
  const childA = await addDevice(store, { family: FAMILY_A, user: USER_A, role: "child" });
  const parentB = await addDevice(store, { family: FAMILY_B, user: USER_B, role: "parent" });
  return { store, svc, h, parentA, childA, parentB };
}
const json = async (r: Response) => await r.json();

Deno.test("signed-ping: parent and child pass, answers with role and server time, touches the device", async () => {
  const { h, parentA, childA, store } = await setup();
  const ping = h(signedPing);
  const r = await call(ping, parentA, "signed-ping");
  assert.equal(r.status, 200);
  assert.deepEqual(await json(r), { ok: true, role: "parent", server_time: NOW });
  assert.equal((await json(await call(ping, childA, "signed-ping"))).role, "child");
  assert.ok(r.headers.get("x-request-id"));
  assert.equal(r.headers.get("access-control-allow-origin"), null, "no browser origins are served");
  assert.deepEqual(store.touched, [parentA.id, childA.id]);
});

Deno.test("every function refuses GET, OPTIONS and a missing signature", async () => {
  const { h, parentA } = await setup();
  for (const spec of [signedPing, appConfig, deviceList, deviceRevoke, pairingCodeCreate]) {
    const handler = h(spec);
    for (const method of ["GET", "OPTIONS", "PUT"]) {
      const r = await handler(new Request("https://x.test/f", { method }));
      assert.equal(r.status, 400, `${spec.name} ${method}`);
      assert.equal(r.headers.get("access-control-allow-origin"), null);
    }
    const unsigned = await handler(
      plainPost(spec.name, {}, { authorization: `Bearer ${tokenFor(parentA.userId)}` }),
    );
    assert.equal(unsigned.status, 401, `${spec.name} unsigned`);
    assert.deepEqual(await json(unsigned), { error: "unauthorized" });
  }
});

Deno.test("a body over 16 KB, an unknown field and a non-object body are refused after authentication", async () => {
  const { h, parentA } = await setup();
  const revoke = h(deviceRevoke);
  assert.equal((await call(revoke, parentA, "device-revoke", { pad: "x".repeat(20_000) })).status, 413);
  const unknown = await call(revoke, parentA, "device-revoke", { device_id: parentA.id, extra: 1 });
  assert.equal(unknown.status, 400);
  assert.equal((await call(revoke, parentA, "device-revoke", [])).status, 400);
  assert.equal((await call(revoke, parentA, "device-revoke", {})).status, 400);
});

Deno.test("app-config: kill switches are off unless explicitly true", async () => {
  const { h, parentA, childA, store } = await setup();
  const cfg = h(appConfig);
  assert.deepEqual(await json(await call(cfg, childA, "app-config")), {
    server_time: NOW,
    tutor_enabled: false,
    voice_enabled: false,
  });
  store.config.set("tutor_enabled", true);
  store.config.set("voice_enabled", "true"); // a string is not "true": still off
  const r = await json(await call(cfg, parentA, "app-config"));
  assert.equal(r.tutor_enabled, true);
  assert.equal(r.voice_enabled, false);
});

Deno.test("device-list: parents see their own family only; children are refused", async () => {
  const { h, parentA, childA, parentB } = await setup();
  const list = h(deviceList);
  const a = await json(await call(list, parentA, "device-list"));
  assert.equal(a.devices.length, 2);
  assert.deepEqual(a.devices.map((d: { this_device: boolean }) => d.this_device), [true, false]);
  assert.ok(a.devices.every((d: Record<string, unknown>) => !("public_key" in d) && !("family_id" in d)));
  const b = await json(await call(list, parentB, "device-list"));
  assert.equal(b.devices.length, 1);
  const child = await call(list, childA, "device-list");
  assert.equal(child.status, 403);
  assert.deepEqual(await json(child), { error: "forbidden" });
});

Deno.test("device-revoke: own family only, never self, and the revoked device stops working at once", async () => {
  const { h, parentA, childA, parentB } = await setup();
  const revoke = h(deviceRevoke);
  const ping = h(signedPing);
  assert.equal((await call(ping, childA, "signed-ping")).status, 200);

  assert.equal(
    (await call(revoke, childA, "device-revoke", { device_id: parentA.id })).status,
    403,
    "child cannot revoke",
  );
  const other = await call(revoke, parentA, "device-revoke", { device_id: parentB.id });
  assert.equal(other.status, 404, "another family's device looks like it does not exist");
  assert.equal((await call(ping, parentB, "signed-ping")).status, 200, "and it was not revoked");
  const self = await call(revoke, parentA, "device-revoke", { device_id: parentA.id });
  assert.equal(self.status, 400);

  assert.deepEqual(await json(await call(revoke, parentA, "device-revoke", { device_id: childA.id })), {
    revoked: true,
  });
  const after = await call(ping, childA, "signed-ping");
  assert.equal(after.status, 401);
  assert.deepEqual(await json(after), { error: "unauthorized" });
  assert.equal(
    (await call(revoke, parentA, "device-revoke", { device_id: childA.id })).status,
    404,
    "already revoked",
  );
});

Deno.test("pairing-code-create: parent only, 6 digits, stored as a keyed hash, 5 an hour per family", async () => {
  const { h, parentA, childA, parentB, store, svc } = await setup();
  const create = h(pairingCodeCreate);
  assert.equal((await call(create, childA, "pairing-code-create")).status, 403);

  const r = await json(await call(create, parentA, "pairing-code-create"));
  assert.match(r.code, /^\d{6}$/);
  assert.equal(r.expires_at, NOW + CODE_SECONDS * 1000);
  assert.ok(CODE_SECONDS <= 600);
  assert.equal(store.codes.length, 1);
  assert.equal(store.codes[0].familyId, FAMILY_A);
  assert.equal(store.codes[0].byDevice, parentA.id);
  assert.deepEqual(store.codes[0].codeHash, await hashPairingCode(svc.secrets.pairingCodeKey, r.code));
  assert.ok(!JSON.stringify([...store.codes[0].codeHash]).includes(r.code), "the code itself is not stored");

  for (let i = 0; i < 4; i++) assert.equal((await call(create, parentA, "pairing-code-create")).status, 200);
  const sixth = await call(create, parentA, "pairing-code-create");
  assert.equal(sixth.status, 429);
  assert.deepEqual(await json(sixth), { error: "rate_limited" });
  assert.equal((await call(create, parentB, "pairing-code-create")).status, 200, "limit is per family");
});

Deno.test("enroll-challenge (enroll): needs a fresh sign-in, gives 32 random bytes valid under 5 minutes", async () => {
  const { h, store } = await setup();
  const ch = h(enrollChallenge);
  const post = (token: string | null, purpose = "enroll") =>
    ch(plainPost("enroll-challenge", { purpose }, token ? { authorization: `Bearer ${token}` } : {}));

  assert.equal((await post(null)).status, 401, "no token");
  assert.equal((await post("junk-token-value")).status, 401, "bad token");
  const stale = await post(tokenFor(USER_A, NOW / 1000 - 601));
  assert.equal(stale.status, 401, "signed in more than 10 minutes ago");
  assert.equal((await post(tokenFor(USER_A, NOW / 1000 - 599))).status, 200);

  const r = await json(await post(tokenFor(USER_A)));
  const bytes = b64urlDecode(r.challenge)!;
  assert.equal(bytes.length, 32);
  assert.equal(r.expires_at, NOW + CHALLENGE_SECONDS * 1000);
  assert.ok(CHALLENGE_SECONDS <= 300);
  const row = store.challenges.at(-1)!;
  assert.equal(row.purpose, "enroll");
  assert.equal(row.userId, USER_A);
  assert.equal(row.ipHash, null);
  const all = new Set(store.challenges.map((c) => b64urlEncode(c.challenge)));
  assert.equal(all.size, store.challenges.length, "every challenge is different");

  assert.equal((await post(tokenFor(USER_A), "other")).status, 400);
});

Deno.test("enroll-challenge: 10 an hour per user; pairing challenges are limited per IP and keep no raw address", async () => {
  const { h, store } = await setup();
  const ch = h(enrollChallenge);
  const enroll = () =>
    ch(plainPost("enroll-challenge", { purpose: "enroll" }, { authorization: `Bearer ${tokenFor(USER_A)}` }));
  for (let i = 0; i < 10; i++) assert.equal((await enroll()).status, 200);
  assert.equal((await enroll()).status, 429);

  const pair = (ip: string) =>
    ch(plainPost("enroll-challenge", { purpose: "pair" }, { "x-forwarded-for": `${ip}, 10.0.0.1` }));
  for (let i = 0; i < 20; i++) assert.equal((await pair("203.0.113.7")).status, 200);
  assert.equal((await pair("203.0.113.7")).status, 429);
  assert.equal((await pair("203.0.113.8")).status, 200, "another address has its own allowance");

  const row = store.challenges.find((c) => c.purpose === "pair")!;
  assert.equal(row.userId, null);
  assert.equal(row.ipHash!.length, 32);
  assert.ok(![...store.counters.keys()].some((k) => k.includes("203.0.113")), "no raw IP in the counters");
});
