import { assert } from "./_shared/testassert.ts";
import { b64urlEncode, type Bytes, sha256 } from "./_shared/b64.ts";
import { buildChain, GOOD_DIGEST } from "./_shared/attest/android_fixture.ts";
import { type FunctionSpec, makeHandler, type Services } from "./_shared/handler.ts";
import {
  call,
  callSelfSigned,
  fakeServices,
  FakeStore,
  NOW,
  plainPost,
  tokenFor,
  USER_A,
  USER_B,
} from "./_shared/testkit.ts";
import { spec as deviceEnroll } from "./device-enroll/handler.ts";
import { spec as enrollChallenge } from "./enroll-challenge/handler.ts";
import { spec as signedPing } from "./signed-ping/handler.ts";

const hex = (b: Uint8Array) => [...b].map((x) => x.toString(16).padStart(2, "0")).join("");

async function setup(o: { dev?: boolean } = {}) {
  const store = new FakeStore();
  const built = await buildChain();
  const svc: Services = {
    ...fakeServices(store),
    allowDevEnrolment: o.dev ?? false,
    androidRootsPem: [built.rootPem],
  };
  store.config.set("android_allowed_apps", [{
    package_name: "com.example.nitznutz",
    cert_sha256: [hex(GOOD_DIGEST)],
  }]);
  const h = (s: FunctionSpec) => makeHandler(s, () => svc);
  return { store, svc, h };
}

type Harness = (s: FunctionSpec) => (req: Request) => Promise<Response>;

async function newChallenge(
  h: Harness,
  user = USER_A,
  iat = NOW / 1000 - 5,
) {
  const r = await h(enrollChallenge)(
    plainPost("enroll-challenge", { purpose: "enroll" }, { authorization: `Bearer ${tokenFor(user, iat)}` }),
  );
  return (await r.json()).challenge as string;
}

async function phone() {
  const kp = await crypto.subtle.generateKey({ name: "ECDSA", namedCurve: "P-256" }, true, ["sign"]);
  return {
    priv: kp.privateKey,
    spki: new Uint8Array(await crypto.subtle.exportKey("spki", kp.publicKey)) as Bytes,
  };
}

const devSecret = "emulator-secret-0123456789";

Deno.test("android: a valid attestation enrols the first device and creates the family", async () => {
  const { store, h, svc } = await setup();
  const challenge = await newChallenge(h);
  const challengeBytes = Uint8Array.from(
    atob(challenge.replaceAll("-", "+").replaceAll("_", "/") + "="),
    (c) => c.charCodeAt(0),
  );
  const chain = await buildChain({ challenge: challengeBytes });
  svc.androidRootsPem = [chain.rootPem];
  const r = await callSelfSigned(h(deviceEnroll), chain.devicePrivateKey, "device-enroll", {
    challenge,
    public_key: b64urlEncode(chain.deviceSpki),
    platform: "android",
    attestation_kind: "key_attestation",
    chain: chain.chainDer.map(b64urlEncode),
    app_version: "0.1.0",
  });
  assert.equal(r.status, 200);
  const out = await r.json();
  assert.equal(out.role, "parent");
  assert.equal(out.security_level, "tee");
  const device = store.devices.get(out.device_id)!;
  assert.equal(device.role, "parent");
  assert.ok(store.families.has(USER_A));

  // The new device can now make signed calls (the family and guardian exist).
  const ping = await call(
    h(signedPing),
    { id: out.device_id, familyId: device.familyId, userId: USER_A, priv: chain.devicePrivateKey },
    "signed-ping",
  );
  assert.equal(ping.status, 200);

  // The same challenge cannot be used twice.
  const again = await callSelfSigned(h(deviceEnroll), chain.devicePrivateKey, "device-enroll", {
    challenge,
    public_key: b64urlEncode(chain.deviceSpki),
    platform: "android",
    attestation_kind: "key_attestation",
    chain: chain.chainDer.map(b64urlEncode),
  });
  assert.equal(again.status, 401);
});

async function enrolBody(
  h: Harness,
  svc: Services,
  knobs: Parameters<typeof buildChain>[0] = {},
) {
  const challenge = await newChallenge(h);
  const challengeBytes = Uint8Array.from(
    atob(challenge.replaceAll("-", "+").replaceAll("_", "/") + "="),
    (c) => c.charCodeAt(0),
  );
  const chain = await buildChain({ challenge: challengeBytes, ...knobs });
  svc.androidRootsPem = [chain.rootPem];
  return {
    chain,
    body: {
      challenge,
      public_key: b64urlEncode(chain.deviceSpki),
      platform: "android",
      attestation_kind: "key_attestation",
      chain: chain.chainDer.map(b64urlEncode),
    } as Record<string, unknown>,
  };
}

Deno.test("android: bad attestations are forbidden and the challenge is spent", async () => {
  for (
    const knobs of [{ packages: ["com.evil"] }, { locked: false }, { attestationLevel: 0 }, { origin: 2 }, {
      digests: [new Uint8Array(32)],
    }]
  ) {
    const { store, h, svc } = await setup();
    const { chain, body } = await enrolBody(h, svc, knobs);
    const r = await callSelfSigned(h(deviceEnroll), chain.devicePrivateKey, "device-enroll", body);
    assert.equal(r.status, 403, JSON.stringify(knobs));
    assert.deepEqual(await r.json(), { error: "forbidden" });
    assert.equal(store.devices.size, 0);
    const retry = await callSelfSigned(h(deviceEnroll), chain.devicePrivateKey, "device-enroll", body);
    assert.equal(retry.status, 401, "the failed attempt used up the challenge");
  }
});

Deno.test("android: a missing app list fails closed", async () => {
  const { store, h, svc } = await setup();
  store.config.delete("android_allowed_apps");
  const { chain, body } = await enrolBody(h, svc);
  const r = await callSelfSigned(h(deviceEnroll), chain.devicePrivateKey, "device-enroll", body);
  assert.equal(r.status, 503);
});

Deno.test("enrolment checks: self-signature, fresh sign-in, challenge owner, shape", async () => {
  const { store, h, svc } = await setup();
  const { chain, body } = await enrolBody(h, svc);
  const enroll = h(deviceEnroll);

  assert.equal(
    (await callSelfSigned(enroll, chain.devicePrivateKey, "device-enroll", body, { unsigned: true })).status,
    401,
    "no signature",
  );
  const stranger = await phone();
  assert.equal(
    (await callSelfSigned(enroll, stranger.priv, "device-enroll", body)).status,
    401,
    "signed with another key",
  );
  assert.equal(
    (await callSelfSigned(enroll, chain.devicePrivateKey, "device-enroll", body, { token: "" })).status,
    401,
    "no token",
  );
  assert.equal(
    (await callSelfSigned(enroll, chain.devicePrivateKey, "device-enroll", body, { ts: NOW - 120_000 }))
      .status,
    401,
    "clock",
  );
  assert.equal(
    (await callSelfSigned(enroll, chain.devicePrivateKey, "device-enroll", body, {
      token: tokenFor(USER_A, NOW / 1000 - 700),
    })).status,
    401,
    "signed in too long ago",
  );
  assert.equal(
    (await callSelfSigned(enroll, chain.devicePrivateKey, "device-enroll", body, { token: tokenFor(USER_B) }))
      .status,
    401,
    "a challenge issued to someone else",
  );
  assert.equal(store.devices.size, 0);

  const extra = await callSelfSigned(enroll, chain.devicePrivateKey, "device-enroll", {
    ...body,
    role: "parent",
  });
  assert.equal(extra.status, 400, "unknown field");
  const shortKey = await callSelfSigned(enroll, chain.devicePrivateKey, "device-enroll", {
    ...body,
    public_key: "AAAA",
  });
  assert.equal(shortKey.status, 400);
  const longChain = await callSelfSigned(enroll, chain.devicePrivateKey, "device-enroll", {
    ...body,
    chain: Array(7).fill(body.chain![0 as never]),
  });
  assert.equal(longChain.status, 400);

  // After all those refusals the honest request still works: nothing consumed the challenge.
  assert.equal((await callSelfSigned(enroll, chain.devicePrivateKey, "device-enroll", body)).status, 200);
});

Deno.test("dev allowlist: only when switched on, and only with a known secret", async () => {
  const off = await setup({ dev: false });
  const on = await setup({ dev: true });
  on.store.allowlist.add(b64urlEncode(await sha256(new TextEncoder().encode(devSecret) as Bytes)));
  for (const w of [off, on]) {
    w.store.allowlist.add(b64urlEncode(await sha256(new TextEncoder().encode(devSecret) as Bytes)));
  }

  const attempt = async (w: typeof on, secret?: string) => {
    const p = await phone();
    const challenge = await newChallenge(w.h);
    return callSelfSigned(w.h(deviceEnroll), p.priv, "device-enroll", {
      challenge,
      public_key: b64urlEncode(p.spki),
      platform: "android",
      attestation_kind: "dev_allowlist",
      ...(secret ? { dev_secret: secret } : {}),
    });
  };
  assert.equal((await attempt(off, devSecret)).status, 403, "switched off (the cloud setting)");
  assert.equal((await attempt(on, "wrong-secret-0123456789")).status, 403, "unknown secret");
  assert.equal((await attempt(on)).status, 400, "no secret");
  const ok = await attempt(on, devSecret);
  assert.equal(ok.status, 200);
  assert.equal((await ok.json()).security_level, "dev");
});

Deno.test("replace-this-device revokes the old device; the sixth device is the last; a key cannot be reused", async () => {
  const { store, h, svc } = await setup({ dev: true });
  svc.allowDevEnrolment = true;
  store.allowlist.add(b64urlEncode(await sha256(new TextEncoder().encode(devSecret) as Bytes)));
  const enrol = async (extra: Record<string, unknown> = {}, key?: Awaited<ReturnType<typeof phone>>) => {
    const p = key ?? await phone();
    const challenge = await newChallenge(h);
    const r = await callSelfSigned(h(deviceEnroll), p.priv, "device-enroll", {
      challenge,
      public_key: b64urlEncode(p.spki),
      platform: "android",
      attestation_kind: "dev_allowlist",
      dev_secret: devSecret,
      ...extra,
    });
    return { r, p };
  };
  const ids: string[] = [];
  for (let i = 0; i < 6; i++) {
    const { r } = await enrol();
    assert.equal(r.status, 200);
    ids.push((await r.json()).device_id);
  }
  const seventh = await enrol();
  assert.equal(seventh.r.status, 409, "a seventh active device is refused");

  const replaced = await enrol({ replace_device_id: ids[0] });
  assert.equal(replaced.r.status, 200);
  assert.ok(store.devices.get(ids[0])!.revokedAt, "the old device was revoked");

  const reuse = await enrol({}, replaced.p);
  // Key is already registered (and the family is full again anyway).
  assert.equal(reuse.r.status, 409);
  const unknownOld = await enrol({ replace_device_id: crypto.randomUUID() });
  assert.equal(unknownOld.r.status, 404);
});
