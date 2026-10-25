import { assert } from "./_shared/testassert.ts";
import { b64urlEncode, type Bytes, sha256 } from "./_shared/b64.ts";
import { type FunctionSpec, makeHandler, type Services } from "./_shared/handler.ts";
import {
  addDevice,
  call,
  callSelfSigned,
  fakeServices,
  FakeStore,
  FAMILY_A,
  NOW,
  plainPost,
  USER_A,
} from "./_shared/testkit.ts";
import {
  ATTEMPTS_PER_HOUR_GLOBAL,
  spec as devicePair,
  TRIES_PER_HOUR_PER_IP,
} from "./device-pair/handler.ts";
import { spec as enrollChallenge } from "./enroll-challenge/handler.ts";
import { spec as pairingCodeCreate } from "./pairing-code-create/handler.ts";
import { spec as signedPing } from "./signed-ping/handler.ts";

const secret = "child-emulator-secret-0123456789";

async function setup() {
  const store = new FakeStore();
  const svc: Services = { ...fakeServices(store), allowDevEnrolment: true };
  store.allowlist.add(b64urlEncode(await sha256(new TextEncoder().encode(secret) as Bytes)));
  const h = (s: FunctionSpec) => makeHandler(s, () => svc);
  const parent = await addDevice(store, { family: FAMILY_A, user: USER_A, role: "parent" });
  return { store, svc, h, parent };
}
type Ctx = Awaited<ReturnType<typeof setup>>;

async function parentCode(c: Ctx) {
  const r = await call(c.h(pairingCodeCreate), c.parent, "pairing-code-create");
  return (await r.json()).code as string;
}
const pairChallenge = async (c: Ctx, ip = "203.0.113.5") =>
  (await (await c.h(enrollChallenge)(
    plainPost("enroll-challenge", { purpose: "pair" }, { "x-forwarded-for": ip }),
  )).json())
    .challenge as string;

async function pair(
  c: Ctx,
  o: { code: string; challenge?: string; ip?: string; extra?: Record<string, unknown>; kp?: CryptoKeyPair },
) {
  const kp = o.kp ?? await crypto.subtle.generateKey({ name: "ECDSA", namedCurve: "P-256" }, true, ["sign"]);
  const spki = new Uint8Array(await crypto.subtle.exportKey("spki", kp.publicKey));
  const challenge = o.challenge ?? await pairChallenge(c, o.ip);
  const body = {
    challenge,
    code: o.code,
    public_key: b64urlEncode(spki),
    platform: "android",
    attestation_kind: "dev_allowlist",
    dev_secret: secret,
    ...(o.extra ?? {}),
  };
  const res = await callSelfSigned(c.h(devicePair), kp.privateKey, "device-pair", body, {
    token: "",
    ts: NOW,
  });
  return { res, kp, challenge };
}
Deno.test("a child device pairs with a live code, gets a one-time sign-in and can then make signed calls", async () => {
  const c = await setup();
  const code = await parentCode(c);
  const { res, kp } = await pair(c, { code });
  assert.equal(res.status, 200);
  const out = await res.json();
  assert.equal(out.role, "child");
  assert.equal(out.token_hash, `hash-for-${USER_A}`);
  assert.equal(c.store.devices.get(out.device_id)!.familyId, FAMILY_A);
  assert.equal(c.store.devices.get(out.device_id)!.role, "child");

  const ping = await call(c.h(signedPing), {
    id: out.device_id,
    familyId: FAMILY_A,
    userId: USER_A,
    priv: kp.privateKey,
  }, "signed-ping");
  assert.equal(ping.status, 200);
  assert.equal((await ping.json()).role, "child");
});

Deno.test("a code works once; a stale, wrong or malformed code does not", async () => {
  const c = await setup();
  const code = await parentCode(c);
  assert.equal((await pair(c, { code })).res.status, 200);
  assert.equal((await pair(c, { code })).res.status, 401, "already used");

  const fresh = await parentCode(c);
  const wrong = fresh === "000000" ? "000001" : "000000";
  assert.equal((await pair(c, { code: wrong })).res.status, 401, "wrong code");
  for (const bad of ["12345", "1234567", "abcdef", "12 456", ""]) {
    assert.equal((await pair(c, { code: bad })).res.status, 400, `malformed ${bad}`);
  }
  c.store.nowMs = NOW + 11 * 60_000; // codes expire
  c.svc.nowMs = () => NOW; // (request clock unchanged so the signature window still holds)
  assert.equal((await pair(c, { code: fresh })).res.status, 401, "expired code");
});

Deno.test("five wrong codes kill the challenge, even if the sixth try is right", async () => {
  const c = await setup();
  const code = await parentCode(c);
  const wrong = code === "000000" ? "000001" : "000000";
  const challenge = await pairChallenge(c);
  for (let i = 0; i < 5; i++) assert.equal((await pair(c, { code: wrong, challenge })).res.status, 401);
  assert.equal((await pair(c, { code, challenge })).res.status, 401, "challenge is dead");
  assert.equal((await pair(c, { code })).res.status, 200, "a new challenge with the right code works");
});

Deno.test("the attestation is checked before anything is burned", async () => {
  const c = await setup();
  const code = await parentCode(c);
  const bad = await pair(c, { code, extra: { dev_secret: "not-the-secret-0123456789" } });
  assert.equal(bad.res.status, 403);
  assert.equal(c.store.usedCodes.size, 0, "the code was not burned");
  assert.equal((await pair(c, { code })).res.status, 200, "the same code still works afterwards");

  const off = await setup();
  off.svc.allowDevEnrolment = false;
  const code2 = await parentCode(off);
  assert.equal((await pair(off, { code: code2 })).res.status, 403, "dev allowlist is off");
});

Deno.test("a signature by another key, a missing signature and the family limit are refused", async () => {
  const c = await setup();
  const code = await parentCode(c);
  const kp = await crypto.subtle.generateKey({ name: "ECDSA", namedCurve: "P-256" }, true, ["sign"]);
  const challenge = await pairChallenge(c);
  const other = await crypto.subtle.generateKey({ name: "ECDSA", namedCurve: "P-256" }, true, ["sign"]);
  const body = {
    challenge,
    code,
    public_key: b64urlEncode(new Uint8Array(await crypto.subtle.exportKey("spki", kp.publicKey))),
    platform: "android",
    attestation_kind: "dev_allowlist",
    dev_secret: secret,
  };
  const forged = await callSelfSigned(c.h(devicePair), other.privateKey, "device-pair", body, { token: "" });
  assert.equal(forged.status, 401);
  const unsigned = await callSelfSigned(c.h(devicePair), kp.privateKey, "device-pair", body, {
    token: "",
    unsigned: true,
  });
  assert.equal(unsigned.status, 401);

  // Fill the family: parent + 5 children = 6; the next child is refused and the code survives.
  for (let i = 0; i < 5; i++) {
    assert.equal((await pair(c, { code: await parentCodeFresh(c) })).res.status, 200);
  }
  const lastCode = await parentCodeFresh(c);
  assert.equal((await pair(c, { code: lastCode })).res.status, 409);
});
async function parentCodeFresh(c: Ctx) {
  // Reset the per-family hourly code limit so the test can fill a family.
  c.store.counters.clear();
  return await parentCode(c);
}

Deno.test("rate limits: 20 tries an hour per address, and a budget for the whole service", async () => {
  const c = await setup();
  const code = await parentCode(c);
  const wrong = code === "000000" ? "000001" : "000000";
  // Challenges come from many addresses, so only the device-pair limits are in play. Every
  // device-pair call here has no forwarding header, so they share one address bucket.
  const statuses: number[] = [];
  for (let i = 0; i < 22; i++) {
    statuses.push((await pair(c, { code: wrong, ip: `198.51.100.${i + 1}` })).res.status);
  }
  assert.deepEqual(statuses.slice(0, TRIES_PER_HOUR_PER_IP), Array(TRIES_PER_HOUR_PER_IP).fill(401));
  assert.deepEqual(statuses.slice(TRIES_PER_HOUR_PER_IP), [429, 429]);

  // The service-wide budget: reached through different addresses.
  const d = await setup();
  const goodCode = await parentCode(d);
  d.store.counters.set(
    `pair_global/all/${Math.floor(NOW / 3_600_000) * 3_600_000}`,
    ATTEMPTS_PER_HOUR_GLOBAL,
  );
  const blocked = await pair(d, { code: goodCode });
  assert.equal(blocked.res.status, 429, "even the right code is refused once the budget is spent");
});
