import { createLocalJWKSet, exportJWK, generateKeyPair, SignJWT } from "npm:jose@6.2.13";
import { assert } from "./testassert.ts";
import { signedInByCodeRecently, type TokenConfig, verifyAccessToken } from "./token.ts";

const NOW = 1_800_000_000;
const ISS = "https://example-ref.supabase.co/auth/v1";
const USER = "aaaaaaaa-0000-4000-8000-000000000001";

const es = await generateKeyPair("ES256", { extractable: true });
const rs = await generateKeyPair("RS256", { extractable: true });
const evil = await generateKeyPair("ES256", { extractable: true });
const jwks = {
  keys: [
    { ...(await exportJWK(es.publicKey)), kid: "es1", alg: "ES256", use: "sig" },
    { ...(await exportJWK(rs.publicKey)), kid: "rs1", alg: "RS256", use: "sig" },
  ],
};
const cfg: TokenConfig = { issuer: ISS, keys: createLocalJWKSet(jwks), nowSeconds: () => NOW };

function token(
  o: {
    claims?: Record<string, unknown>;
    key?: CryptoKey;
    alg?: string;
    kid?: string;
    iss?: string;
    aud?: string;
    exp?: number;
  } = {},
) {
  const jwt = new SignJWT({ role: "authenticated", ...(o.claims ?? {}) })
    .setProtectedHeader({ alg: o.alg ?? "ES256", kid: o.kid ?? "es1" })
    .setSubject(USER)
    .setIssuer(o.iss ?? ISS)
    .setAudience(o.aud ?? "authenticated")
    .setIssuedAt(NOW - 10)
    .setExpirationTime(o.exp ?? NOW + 600);
  return jwt.sign(o.key ?? es.privateKey);
}

Deno.test("a valid ES256 or RS256 token yields the user id and how it was signed in", async () => {
  const amr = [{ method: "otp", timestamp: NOW - 10 }];
  assert.deepEqual(await verifyAccessToken(await token({ claims: { amr } }), cfg), { userId: USER, amr });
  const t = await token({ alg: "RS256", kid: "rs1", key: rs.privateKey, claims: { amr } });
  assert.deepEqual(await verifyAccessToken(t, cfg), { userId: USER, amr });
});

Deno.test("amr: objects with a method and a time are kept; anything else yields no sign-in method", async () => {
  const amr = (a: unknown) => token({ claims: { amr: a } }).then((t) => verifyAccessToken(t, cfg));
  const two = [{ method: "password", timestamp: NOW - 900 }, { method: "otp", timestamp: NOW - 20 }];
  assert.deepEqual((await amr(two))!.amr, two);
  assert.deepEqual((await amr([{ method: "otp", timestamp: NOW - 5, extra: 1 }]))!.amr, [{
    method: "otp",
    timestamp: NOW - 5,
  }]);
  assert.deepEqual((await amr(["password", "otp"]))!.amr, [], "a plain list of names has no times");
  assert.deepEqual((await amr([{ method: "otp" }]))!.amr, [], "no time");
  assert.deepEqual(
    (await amr([{ method: "otp", timestamp: "now" }]))!.amr,
    [],
    "a time that is not a number",
  );
  assert.deepEqual((await amr([{ method: 5, timestamp: NOW }, null, 7, []]))!.amr, [], "junk entries");
  assert.deepEqual((await amr("otp"))!.amr, [], "not a list");
  assert.deepEqual((await amr({ method: "otp", timestamp: NOW }))!.amr, [], "an object, not a list");
  assert.deepEqual((await verifyAccessToken(await token(), cfg))!.amr, [], "no claim");
});

Deno.test("signedInByCodeRecently: only an emailed code within 10 minutes counts", () => {
  const nowMs = NOW * 1000;
  const otp = (ago: number) => [{ method: "otp", timestamp: NOW - ago }];
  assert.equal(signedInByCodeRecently(otp(0), nowMs), true);
  assert.equal(signedInByCodeRecently(otp(60), nowMs), true);
  assert.equal(signedInByCodeRecently(otp(600), nowMs), true, "exactly 10 minutes");
  assert.equal(signedInByCodeRecently(otp(601), nowMs), false, "just over");
  assert.equal(signedInByCodeRecently(otp(7200), nowMs), false);
  assert.equal(signedInByCodeRecently(otp(-5), nowMs), true, "a little clock drift");
  assert.equal(signedInByCodeRecently(otp(-60), nowMs), false, "a time in the future");
  assert.equal(
    signedInByCodeRecently([{ method: "password", timestamp: NOW }], nowMs),
    false,
    "a password never counts",
  );
  assert.equal(signedInByCodeRecently([{ method: "token_refresh", timestamp: NOW }], nowMs), false);
  assert.equal(signedInByCodeRecently([], nowMs), false, "no entries");
  const mixed = [{ method: "password", timestamp: NOW - 5 }, { method: "otp", timestamp: NOW - 7200 }];
  assert.equal(signedInByCodeRecently(mixed, nowMs), false, "a fresh password beside a stale code");
  assert.equal(signedInByCodeRecently([...mixed, ...otp(30)], nowMs), true, "any one fresh code is enough");
});

Deno.test("expired, wrong issuer, wrong audience, wrong key, unknown kid: all refused", async () => {
  assert.equal(await verifyAccessToken(await token({ exp: NOW - 60 }), cfg), null, "expired");
  assert.equal(
    await verifyAccessToken(await token({ iss: "https://evil.example/auth/v1" }), cfg),
    null,
    "issuer",
  );
  assert.equal(await verifyAccessToken(await token({ aud: "other" }), cfg), null, "audience");
  assert.equal(
    await verifyAccessToken(await token({ key: evil.privateKey }), cfg),
    null,
    "signed by another key",
  );
  assert.equal(await verifyAccessToken(await token({ kid: "nope" }), cfg), null, "unknown kid");
});

Deno.test("role and subject rules", async () => {
  assert.equal(await verifyAccessToken(await token({ claims: { role: "anon" } }), cfg), null, "anon role");
  assert.equal(
    await verifyAccessToken(await token({ claims: { role: "service_role" } }), cfg),
    null,
    "service role",
  );
  assert.equal(
    await verifyAccessToken(await token({ claims: { is_anonymous: true } }), cfg),
    null,
    "anonymous user",
  );
  const noSub = await new SignJWT({ role: "authenticated" })
    .setProtectedHeader({ alg: "ES256", kid: "es1" })
    .setIssuer(ISS).setAudience("authenticated").setExpirationTime(NOW + 600)
    .sign(es.privateKey);
  assert.equal(await verifyAccessToken(noSub, cfg), null, "no subject");
  const badSub = await new SignJWT({ role: "authenticated" })
    .setProtectedHeader({ alg: "ES256", kid: "es1" })
    .setSubject("not-a-uuid").setIssuer(ISS).setAudience("authenticated").setExpirationTime(NOW + 600)
    .sign(es.privateKey);
  assert.equal(await verifyAccessToken(badSub, cfg), null, "bad subject");
  const noExp = await new SignJWT({ role: "authenticated" })
    .setProtectedHeader({ alg: "ES256", kid: "es1" })
    .setSubject(USER).setIssuer(ISS).setAudience("authenticated")
    .sign(es.privateKey);
  assert.equal(await verifyAccessToken(noExp, cfg), null, "no expiry");
});

Deno.test("algorithm tricks: none, HS256 with the public key as secret, and junk", async () => {
  const b64 = (o: unknown) =>
    btoa(JSON.stringify(o)).replaceAll("=", "").replaceAll("+", "-").replaceAll("/", "_");
  const payload = { sub: USER, iss: ISS, aud: "authenticated", role: "authenticated", exp: NOW + 600 };
  const none = `${b64({ alg: "none", typ: "JWT" })}.${b64(payload)}.`;
  assert.equal(await verifyAccessToken(none, cfg), null, "alg none");

  const secret = new TextEncoder().encode(JSON.stringify(jwks.keys[0]));
  const hs = await new SignJWT(payload).setProtectedHeader({ alg: "HS256", kid: "es1" }).sign(secret);
  assert.equal(await verifyAccessToken(hs, cfg), null, "HS256 confusion");

  for (const junk of ["", "a.b.c", "x".repeat(5000), "..", "Bearer abc"]) {
    assert.equal(await verifyAccessToken(junk, cfg), null, junk.slice(0, 12));
  }
});

Deno.test("a key set that cannot be fetched means refusal, not an error", async () => {
  const broken: TokenConfig = { ...cfg, keys: () => Promise.reject(new Error("network down")) };
  assert.equal(await verifyAccessToken(await token(), broken), null);
});
