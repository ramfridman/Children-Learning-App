import { assert } from "./testassert.ts";
import {
  type AuthDeps,
  authenticate,
  authenticatePreEnrolment,
  type DeviceRecord,
  type Role,
} from "./auth.ts";
import { b64urlEncode, type Bytes, sha256B64url } from "./b64.ts";
import { canonicalString, NIL_DEVICE_ID } from "./canonical.ts";
import { GatewayError } from "./errors.ts";
import { rawToDer, utf8 } from "./testutil.ts";

const NOW = 1_800_000_000_000;
const USER = "aaaaaaaa-0000-4000-8000-000000000001";
const FAMILY = "a1a1a1a1-0000-4000-8000-000000000001";
const DEVICE = "a2a2a2a2-0000-4000-8000-000000000001";

async function keypair() {
  const kp = await crypto.subtle.generateKey({ name: "ECDSA", namedCurve: "P-256" }, true, ["sign"]);
  const spki = new Uint8Array(await crypto.subtle.exportKey("spki", kp.publicKey)) as Bytes;
  return { spki, priv: kp.privateKey };
}

interface World {
  deps: AuthDeps;
  device: DeviceRecord;
  nonces: Set<string>;
  priv: CryptoKey;
}

async function world(over: { role?: Role; revoked?: boolean; guardian?: boolean; tokenOk?: boolean } = {}) {
  const { spki, priv } = await keypair();
  const device: DeviceRecord = {
    id: DEVICE,
    familyId: FAMILY,
    role: over.role ?? "parent",
    publicKey: spki,
    revokedAt: over.revoked ? new Date(NOW - 1000) : null,
  };
  const nonces = new Set<string>();
  const deps: AuthDeps = {
    nowMs: () => NOW,
    verifyToken: (b) =>
      Promise.resolve(
        over.tokenOk === false || b === "invalidtoken00" ? null : { userId: USER, issuedAt: NOW - 5 },
      ),
    getDevice: (id) => Promise.resolve(id === DEVICE ? device : null),
    isGuardian: (u, f) => Promise.resolve((over.guardian ?? true) && u === USER && f === FAMILY),
    recordNonce: (d, n) => {
      const k = `${d}/${n}`;
      if (nonces.has(k)) return Promise.resolve(false);
      nonces.add(k);
      return Promise.resolve(true);
    },
  } satisfies AuthDeps;
  return { deps, device, nonces, priv } as World;
}

async function signed(
  w: World,
  o: {
    fn?: string;
    body?: string;
    ts?: number;
    nonce?: string;
    deviceId?: string;
    token?: string;
    signBody?: string;
  } = {},
) {
  const fn = o.fn ?? "signed-ping";
  const body = o.body ?? "{}";
  const nonce = o.nonce ?? crypto.randomUUID();
  const ts = o.ts ?? NOW;
  const deviceId = o.deviceId ?? DEVICE;
  const canonical = canonicalString({
    functionName: fn,
    timestampMs: ts,
    nonce,
    bodyHashB64url: await sha256B64url(utf8(o.signBody ?? body)),
    deviceId,
  });
  const raw = new Uint8Array(
    await crypto.subtle.sign({ name: "ECDSA", hash: "SHA-256" }, w.priv, utf8(canonical)),
  );
  const req = new Request(`https://x.test/${fn}`, {
    method: "POST",
    body,
    headers: {
      authorization: `Bearer ${o.token ?? "validtoken-0123456789"}`,
      "x-device-id": deviceId,
      "x-timestamp": String(ts),
      "x-nonce": nonce,
      "x-signature": b64urlEncode(rawToDer(raw)),
    },
  });
  return { req, body: utf8(body), nonce };
}

const reasonOf = async (p: Promise<unknown>) => {
  try {
    await p;
  } catch (e) {
    if (e instanceof GatewayError) return `${e.code}/${e.reason}`;
    throw e;
  }
  return "ok";
};
const run = (
  w: World,
  s: { req: Request; body: Bytes },
  roles: readonly Role[] = ["parent", "child"],
  fn = "signed-ping",
) => reasonOf(authenticate(s.req, fn, s.body, roles, w.deps));

Deno.test("a correct request from an active parent device passes", async () => {
  const w = await world();
  const s = await signed(w);
  const r = await authenticate(s.req, "signed-ping", s.body, ["parent"], w.deps);
  assert.equal(r.userId, USER);
  assert.equal(r.device.id, DEVICE);
});

Deno.test("token refusals: missing, malformed, wrong key", async () => {
  const w = await world();
  const s = await signed(w);
  s.req.headers.delete("authorization");
  assert.equal(await run(w, s), "unauthorized/no_token");
  const s2 = await signed(w);
  s2.req.headers.set("authorization", "Basic abcdefghijkl");
  assert.equal(await run(w, s2), "unauthorized/no_token");
  assert.equal(await run(w, await signed(w, { token: "invalidtoken00" })), "unauthorized/bad_token");
  assert.equal(await run(await world({ tokenOk: false }), await signed(w)), "unauthorized/bad_token");
});

Deno.test("clock refusals carry the server time; 60 s is still fine", async () => {
  const w = await world();
  for (const ts of [NOW - 61_000, NOW + 61_000]) {
    try {
      await authenticate((await signed(w, { ts })).req, "signed-ping", utf8("{}"), ["parent"], w.deps);
      assert.ok(false, "should have thrown");
    } catch (e) {
      assert.equal((e as GatewayError).code, "clock_skew");
      assert.equal((e as GatewayError).serverTimeMs, NOW);
    }
  }
  assert.equal(await run(w, await signed(w, { ts: NOW - 60_000 })), "ok");
});

Deno.test("signature refusals: wrong function, tampered body, wrong key, malformed headers", async () => {
  const w = await world();
  assert.equal(
    await run(w, await signed(w, { fn: "device-list" }), ["parent"], "signed-ping"),
    "unauthorized/bad_signature",
  );
  assert.equal(
    await run(w, await signed(w, { body: '{"a":1}', signBody: "{}" })),
    "unauthorized/bad_signature",
  );
  const other = await world();
  assert.equal(await run(w, await signed(other)), "unauthorized/bad_signature");

  for (
    const [h, why] of [
      ["x-device-id", "bad_device_header"],
      ["x-timestamp", "bad_time_header"],
      ["x-nonce", "bad_nonce_header"],
      ["x-signature", "bad_signature_header"],
    ]
  ) {
    const s = await signed(w);
    s.req.headers.set(h, "nope!");
    assert.equal(await run(w, s), `unauthorized/${why}`, h);
    const t = await signed(w);
    t.req.headers.delete(h);
    assert.equal(await run(w, t), `unauthorized/${why}`, `${h} missing`);
  }
});

Deno.test("a repeated nonce is refused, a failed signature does not use one up", async () => {
  const w = await world();
  const s = await signed(w);
  assert.equal(await run(w, s), "ok");
  const replay = new Request(s.req.url, { method: "POST", body: "{}", headers: s.req.headers });
  assert.equal(await run(w, { req: replay, body: s.body }), "unauthorized/replayed_nonce");

  const nonce = crypto.randomUUID();
  const forged = await signed(await world(), { nonce });
  assert.equal(await run(w, forged), "unauthorized/bad_signature");
  assert.equal(w.nonces.has(`${DEVICE}/${nonce}`), false, "nonce not stored for a bad signature");
});

Deno.test("device refusals: unknown, revoked, other family, nil id", async () => {
  const w = await world();
  const unknown = "a2a2a2a2-0000-4000-8000-0000000000ff";
  assert.equal(await run(w, await signed(w, { deviceId: unknown })), "unauthorized/unknown_device");
  assert.equal(await run(w, await signed(w, { deviceId: NIL_DEVICE_ID })), "unauthorized/nil_device");
  assert.equal(
    await run(await world({ revoked: true }), await signed(await world({ revoked: true }))),
    "unauthorized/bad_signature",
  );
  const rev = await world({ revoked: true });
  assert.equal(await run(rev, await signed(rev)), "unauthorized/revoked_device");
  const stranger = await world({ guardian: false });
  assert.equal(await run(stranger, await signed(stranger)), "unauthorized/wrong_family");
});

Deno.test("role refusals: a child device cannot call a parent-only function", async () => {
  const child = await world({ role: "child" });
  assert.equal(await run(child, await signed(child), ["parent"]), "forbidden/role_not_allowed");
  assert.equal(
    await run(child, await signed(await world({ role: "child" })), ["parent", "child"]),
    "unauthorized/bad_signature",
  );
  const c2 = await world({ role: "child" });
  assert.equal(await run(c2, await signed(c2), ["parent", "child"]), "ok");
});

Deno.test("every refusal that reveals nothing shares one public code", async () => {
  const codes = new Set<string>();
  const rev = await world({ revoked: true });
  const w = await world();
  for (
    const p of [
      run(rev, await signed(rev)),
      run(w, await signed(w, { deviceId: "a2a2a2a2-0000-4000-8000-0000000000ff" })),
      run(w, await signed(await world())),
    ]
  ) codes.add((await p).split("/")[0]);
  assert.deepEqual([...codes], ["unauthorized"]);
});

Deno.test("pre-enrolment calls: signed with the new key and the nil device id", async () => {
  const { spki, priv } = await keypair();
  const w = { priv } as World;
  const deps = { nowMs: () => NOW };
  const ok = await signed(w, { fn: "device-enroll", deviceId: NIL_DEVICE_ID, body: '{"k":1}' });
  assert.equal(
    (await authenticatePreEnrolment(ok.req, "device-enroll", ok.body, spki, deps)).nonce,
    ok.nonce,
  );

  const other = (await keypair()).spki;
  const bad = await signed(w, { fn: "device-enroll", deviceId: NIL_DEVICE_ID });
  assert.equal(
    await reasonOf(authenticatePreEnrolment(bad.req, "device-enroll", bad.body, other, deps)),
    "unauthorized/bad_signature",
  );

  const real = await signed(w, { fn: "device-enroll", deviceId: DEVICE });
  assert.equal(
    await reasonOf(authenticatePreEnrolment(real.req, "device-enroll", real.body, spki, deps)),
    "unauthorized/expected_nil_device",
  );

  const late = await signed(w, { fn: "device-enroll", deviceId: NIL_DEVICE_ID, ts: NOW - 90_000 });
  assert.equal(
    await reasonOf(authenticatePreEnrolment(late.req, "device-enroll", late.body, spki, deps)),
    "clock_skew/clock_skew",
  );
});
