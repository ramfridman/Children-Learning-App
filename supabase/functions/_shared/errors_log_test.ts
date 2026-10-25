import { assert } from "./testassert.ts";
import { errorResponse, GatewayError } from "./errors.ts";
import { redactedLine } from "./log.ts";

Deno.test("error responses carry a short code and nothing else (plus server time for skew)", async () => {
  const r = errorResponse(new GatewayError("unauthorized", "bad_signature"));
  assert.equal(r.status, 401);
  assert.deepEqual(await r.json(), { error: "unauthorized" });
  assert.equal(r.headers.get("cache-control"), "no-store");

  const s = errorResponse(new GatewayError("clock_skew", "skew", { serverTimeMs: 1234 }));
  assert.deepEqual(await s.json(), { error: "clock_skew", server_time: 1234 });

  const codes = [
    "bad_request",
    "unauthorized",
    "forbidden",
    "not_found",
    "too_large",
    "rate_limited",
    "device_limit",
    "unavailable",
    "internal",
  ] as const;
  const statuses = codes.map((c) => new GatewayError(c, "x").status);
  assert.deepEqual(statuses, [400, 401, 403, 404, 413, 429, 409, 503, 500]);
});

Deno.test("log lines hold only the allowed fields, and secrets passed by mistake never appear", () => {
  const secret = "sk-ant-api03-SHOULD-NEVER-APPEAR";
  const line = redactedLine({
    requestId: "0d6f3a52-1c1e-4f6b-8c55-3b0a5a6f2d11",
    fn: "signed-ping",
    outcome: "refused",
    latencyMs: 12.7,
    reason: "bad_signature",
    // Extra fields a careless caller might add:
    ...({ authorization: `Bearer ${secret}`, body: secret, device_id: secret } as object),
  } as never);
  assert.deepEqual(JSON.parse(line), {
    request_id: "0d6f3a52-1c1e-4f6b-8c55-3b0a5a6f2d11",
    fn: "signed-ping",
    outcome: "refused",
    latency_ms: 13,
    reason: "bad_signature",
  });
  assert.ok(!line.includes(secret));
});

Deno.test("free text in the id, function, outcome or reason is replaced, not logged", () => {
  const secret = "Bearer eyJhbGciOi.SECRET";
  const line = redactedLine({
    requestId: secret,
    fn: secret,
    outcome: secret as never,
    latencyMs: NaN,
    reason: secret,
  });
  assert.ok(!line.includes("SECRET"));
  assert.deepEqual(JSON.parse(line), {
    request_id: "invalid",
    fn: "invalid",
    outcome: "error",
    latency_ms: -1,
    reason: "invalid",
  });
});
