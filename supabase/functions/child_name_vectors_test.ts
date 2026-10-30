// Board B-28: the app and child-put take the same child's names (testvectors/child-name.json). The app is tested
// against the same file (app/test/child_name_test.dart); this side proves what the server takes and refuses.
import { assert } from "./_shared/testassert.ts";
import { type Shape, validate } from "./_shared/schema.ts";
import { NICKNAME, spec as childPut } from "./child-put/handler.ts";

interface Vector {
  name: string;
  value: string;
  units: number;
  reason?: string;
  appOnly?: boolean;
}

const v = JSON.parse(
  await Deno.readTextFile(new URL("../../testvectors/child-name.json", import.meta.url)),
) as {
  max_utf16_units: number;
  server_pattern: string;
  accept: Vector[];
  reject: Vector[];
  clientOnly: Vector[];
};

/** Only the nickname of child-put's schema: the field's own length limit and pattern, as a request meets them. */
const nicknameOnly: Shape = { nickname: childPut.shape.nickname };

function takes(value: string): boolean {
  try {
    validate(nicknameOnly, { nickname: value });
  } catch {
    return false;
  }
  return NICKNAME.test(value);
}

Deno.test("child name: child-put's pattern and limit are the ones in testvectors/child-name.json", () => {
  assert.equal(NICKNAME.source, v.server_pattern);
  assert.equal(NICKNAME.flags, "", "no u flag: the pattern counts UTF-16 units, as the app does");
  const field = childPut.shape.nickname as { t: string; max: number };
  assert.equal(field.max, v.max_utf16_units);
});

Deno.test("child name: every vector is as long as it says, in UTF-16 units", () => {
  for (const x of [...v.accept, ...v.reject, ...v.clientOnly]) assert.equal(x.value.length, x.units, x.name);
});

Deno.test("child name: child-put takes every accepted name", () => {
  assert.ok(v.accept.length >= 7);
  for (const x of v.accept) assert.ok(takes(x.value), x.name);
});

Deno.test("child name: child-put refuses every rejected name except the ones only the app refuses", () => {
  const server = v.reject.filter((x) => !x.appOnly);
  assert.ok(server.length >= 8);
  for (const x of server) assert.ok(!takes(x.value), x.name);
});

Deno.test("child name: the app-only and client-only names still get past the server today (the app is their guard)", () => {
  // When the server's pattern grows to the app's set (a security decision; the gateway changes first), this test fails:
  // drop `appOnly` from those vectors then.
  for (const x of [...v.reject.filter((r) => r.appOnly), ...v.clientOnly]) assert.ok(takes(x.value), x.name);
});
