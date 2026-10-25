import { assert } from "./testassert.ts";
import { GatewayError } from "./errors.ts";
import { MAX_BODY_BYTES, parseJsonObject, readBodyBytes, type Shape, validate } from "./schema.ts";
import { utf8 } from "./testutil.ts";

const code = (f: () => unknown) => {
  try {
    f();
  } catch (e) {
    if (e instanceof GatewayError) return `${e.code}/${e.reason}`;
    throw e;
  }
  return "ok";
};
const post = (body: BodyInit | null, headers: Record<string, string> = {}) =>
  new Request("https://x.test/f", { method: "POST", body, headers });

Deno.test("the body is capped at 16 KB however it is sent", async () => {
  assert.equal((await readBodyBytes(post("a".repeat(MAX_BODY_BYTES)))).length, MAX_BODY_BYTES);
  await assert.rejects(readBodyBytes(post("a".repeat(MAX_BODY_BYTES + 1))), { code: "too_large" });
  // A lying or missing Content-Length cannot sneak extra bytes past the cap.
  const stream = new ReadableStream<Uint8Array>({
    start(c) {
      for (let i = 0; i < 40; i++) c.enqueue(new Uint8Array(1024));
      c.close();
    },
  });
  await assert.rejects(
    readBodyBytes(
      new Request("https://x.test/f", { method: "POST", body: stream, duplex: "half" } as RequestInit),
    ),
    {
      code: "too_large",
    },
  );
  await assert.rejects(readBodyBytes(post("{}", { "content-length": "99999999" })), { code: "too_large" });
  assert.equal((await readBodyBytes(post(null))).length, 0);
});

Deno.test("only a JSON object is accepted", () => {
  assert.equal(code(() => parseJsonObject(utf8("{}"))), "ok");
  assert.equal(code(() => parseJsonObject(utf8("[]"))), "bad_request/body_not_object");
  assert.equal(code(() => parseJsonObject(utf8("null"))), "bad_request/body_not_object");
  assert.equal(code(() => parseJsonObject(utf8('"x"'))), "bad_request/body_not_object");
  assert.equal(code(() => parseJsonObject(utf8("{"))), "bad_request/body_not_json");
  assert.equal(code(() => parseJsonObject(utf8(""))), "bad_request/body_not_json");
  assert.equal(code(() => parseJsonObject(Uint8Array.from([0x7b, 0xff, 0x7d]))), "bad_request/body_not_utf8");
});

const shape: Shape = {
  id: { t: "uuid" },
  platform: { t: "enum", values: ["android", "ios"] },
  n: { t: "int", min: 0, max: 10 },
  key: { t: "b64url", maxBytes: 91, minBytes: 91 },
  tags: { t: "array", of: { t: "string", max: 3, pattern: /^[a-z]+$/ }, maxItems: 2 },
  flag: { t: "bool", optional: true },
};
const ok = {
  id: "0d6f3a52-1c1e-4f6b-8c55-3b0a5a6f2d11",
  platform: "ios",
  n: 3,
  key: "",
  tags: ["ab"],
};

Deno.test("unknown fields, missing fields and wrong types are refused", () => {
  const key90 = "A".repeat(120); // decodes to 90 bytes, one short of an SPKI key
  assert.equal(code(() => validate(shape, { ...ok, key: key90 })), "bad_request/key:b64");
  const key91 = btoa(String.fromCharCode(...new Uint8Array(91))).replaceAll("+", "-").replaceAll("/", "_")
    .replace(/=+$/, "");
  const base = { ...ok, key: key91 };
  assert.equal(code(() => validate(shape, base)), "ok");
  assert.equal(code(() => validate(shape, { ...base, flag: true })), "ok");
  assert.equal(code(() => validate(shape, { ...base, extra: 1 })), "bad_request/unknown_field");
  assert.equal(code(() => validate(shape, { ...base, __proto__x: 1 })), "bad_request/unknown_field");
  assert.equal(code(() => validate(shape, JSON.parse('{"__proto__": {}}'))), "bad_request/unknown_field");
  const { n: _n, ...noN } = base;
  assert.equal(code(() => validate(shape, noN)), "bad_request/n:missing");
  assert.equal(code(() => validate(shape, { ...base, id: "nope" })), "bad_request/id:uuid");
  assert.equal(code(() => validate(shape, { ...base, platform: "web" })), "bad_request/platform:enum");
  assert.equal(code(() => validate(shape, { ...base, n: 11 })), "bad_request/n:int");
  assert.equal(code(() => validate(shape, { ...base, n: 1.5 })), "bad_request/n:int");
  assert.equal(code(() => validate(shape, { ...base, n: "1" })), "bad_request/n:int");
  assert.equal(code(() => validate(shape, { ...base, tags: ["a", "b", "c"] })), "bad_request/tags:array");
  assert.equal(code(() => validate(shape, { ...base, tags: ["ABC"] })), "bad_request/tags[0]:string");
  assert.equal(code(() => validate(shape, { ...base, flag: "yes" })), "bad_request/flag:bool");
  assert.equal(code(() => validate(shape, { ...base, key: key91 + "=" })), "bad_request/key:b64");
  assert.equal(code(() => validate({}, {})), "ok");
  assert.equal(code(() => validate({}, { a: 1 })), "bad_request/unknown_field");
});
