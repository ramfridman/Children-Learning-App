// A tiny assertion helper for tests, so the tests need no package (not even @types/node).
// Test code only; never imported by a function.

function same(a: unknown, b: unknown): boolean {
  if (Object.is(a, b)) return true;
  if (typeof a !== "object" || typeof b !== "object" || a === null || b === null) return false;
  if (Array.isArray(a) !== Array.isArray(b)) return false;
  if (ArrayBuffer.isView(a) !== ArrayBuffer.isView(b)) return false;
  const ka = Object.keys(a);
  const kb = Object.keys(b);
  if (ka.length !== kb.length) return false;
  return ka.every((k) => Object.hasOwn(b, k) && same((a as never)[k], (b as never)[k]));
}

const show = (v: unknown) => {
  try {
    return v instanceof Uint8Array ? `Uint8Array(${v.length})` : JSON.stringify(v);
  } catch {
    return String(v);
  }
};
const fail = (msg: string | undefined, detail: string): never => {
  throw new Error(msg ? `${msg}: ${detail}` : detail);
};

function matches(error: unknown, expected?: Record<string, unknown>): boolean {
  return !expected || Object.entries(expected).every(([k, v]) => (error as never)?.[k] === v);
}

export const assert = {
  ok(v: unknown, msg?: string) {
    if (!v) fail(msg, `expected truthy, got ${show(v)}`);
  },
  equal(a: unknown, b: unknown, msg?: string) {
    if (!Object.is(a, b)) fail(msg, `expected ${show(b)}, got ${show(a)}`);
  },
  deepEqual(a: unknown, b: unknown, msg?: string) {
    if (!same(a, b)) fail(msg, `expected ${show(b)}, got ${show(a)}`);
  },
  match(s: string, re: RegExp, msg?: string) {
    if (!re.test(s)) fail(msg, `${show(s)} does not match ${re}`);
  },
  throws(fn: () => unknown, msg?: string) {
    try {
      fn();
    } catch {
      return;
    }
    fail(msg, "expected a throw");
  },
  async rejects(p: Promise<unknown>, expected?: Record<string, unknown>, msg?: string) {
    try {
      await p;
    } catch (e) {
      if (!matches(e, expected)) fail(msg, `rejected with ${show(e)}, expected ${show(expected)}`);
      return;
    }
    fail(msg, "expected a rejection");
  },
};
