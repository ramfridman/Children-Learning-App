import { assert } from "./testassert.ts";
import { sha256B64url } from "./b64.ts";
import { canonicalString, checkSkew, isUuid, isUuidV4, NIL_DEVICE_ID } from "./canonical.ts";
import { loadVectors, utf8 } from "./testutil.ts";

Deno.test("canonical string matches every shared test vector", async () => {
  for (const v of await loadVectors()) {
    const hash = await sha256B64url(utf8(v.body));
    assert.equal(hash, v.body_sha256_b64url, v.name);
    const got = canonicalString({
      functionName: v.function,
      timestampMs: v.timestamp_ms,
      nonce: v.nonce,
      bodyHashB64url: hash,
      deviceId: v.device_id,
    });
    assert.equal(got, v.canonical, v.name);
    assert.equal(got.split("\n").length, 7);
  }
});

const good = {
  functionName: "signed-ping",
  timestampMs: 1793000000000,
  nonce: "0d6f3a52-1c1e-4f6b-8c55-3b0a5a6f2d11",
  bodyHashB64url: "47DEQpj8HBSa-_TImW-5JCeuQeRkm5NMpJWZG3hSuFU",
  deviceId: NIL_DEVICE_ID,
};

Deno.test("canonical string refuses any field that could shift the line layout", () => {
  canonicalString(good);
  const bads: Record<string, Partial<typeof good>> = {
    newline_in_function: { functionName: "a\nb" },
    slash_in_function: { functionName: "a/b" },
    upper_function: { functionName: "Signed" },
    empty_function: { functionName: "" },
    negative_time: { timestampMs: -1 },
    fractional_time: { timestampMs: 1.5 },
    nan_time: { timestampMs: NaN },
    v1_nonce: { nonce: "0d6f3a52-1c1e-1f6b-8c55-3b0a5a6f2d11" },
    upper_nonce: { nonce: "0D6F3A52-1C1E-4F6B-8C55-3B0A5A6F2D11" },
    newline_nonce: { nonce: "0d6f3a52-1c1e-4f6b-8c55-3b0a5a6f2d11\n" },
    short_hash: { bodyHashB64url: "abc" },
    padded_hash: { bodyHashB64url: "47DEQpj8HBSa-_TImW-5JCeuQeRkm5NMpJWZG3hSuF=" },
    bad_device: { deviceId: "not-a-uuid" },
  };
  for (const [name, patch] of Object.entries(bads)) {
    assert.throws(() => canonicalString({ ...good, ...patch }), name);
  }
});

Deno.test("UUID helpers", () => {
  assert.ok(isUuidV4(good.nonce));
  assert.ok(!isUuidV4(NIL_DEVICE_ID));
  assert.ok(isUuid(NIL_DEVICE_ID));
  assert.ok(!isUuid("0d6f3a52-1c1e-4f6b-8c55-3b0a5a6f2d1"));
});

Deno.test("clock skew: 60 s either way is fine, more is refused with the server time", () => {
  const now = 1_800_000_000_000;
  assert.deepEqual(checkSkew(now, now), { ok: true });
  assert.deepEqual(checkSkew(now - 60_000, now), { ok: true });
  assert.deepEqual(checkSkew(now + 60_000, now), { ok: true });
  assert.deepEqual(checkSkew(now - 60_001, now), { ok: false, serverTimeMs: now });
  assert.deepEqual(checkSkew(now + 60_001, now), { ok: false, serverTimeMs: now });
});
