// Strict request-body checking: at most 16 KB, JSON object only, unknown fields refused.
import { GatewayError } from "./errors.ts";
import { isUuid } from "./canonical.ts";
import { b64urlDecode, type Bytes } from "./b64.ts";

export const MAX_BODY_BYTES = 16 * 1024;

export type Field =
  | { t: "uuid" }
  | { t: "string"; max: number; pattern?: RegExp }
  | { t: "int"; min: number; max: number }
  | { t: "bool" }
  | { t: "enum"; values: readonly string[] }
  | { t: "b64url"; maxBytes: number; minBytes?: number }
  | { t: "array"; of: Field; maxItems: number }
  | { t: "object"; shape: Shape };

export interface Shape {
  [key: string]: Field & { optional?: boolean };
}

const bad = (reason: string) => new GatewayError("bad_request", reason);

/** Reads the raw body with a hard cap, whatever the headers claim. */
export async function readBodyBytes(req: Request, maxBytes = MAX_BODY_BYTES): Promise<Bytes> {
  const declared = req.headers.get("content-length");
  if (declared !== null && (!/^\d+$/.test(declared) || Number(declared) > maxBytes)) {
    throw new GatewayError("too_large", "body_too_large");
  }
  if (!req.body) return new Uint8Array(0) as Bytes;
  const reader = req.body.getReader();
  const chunks: Uint8Array[] = [];
  let total = 0;
  for (;;) {
    const { done, value } = await reader.read();
    if (done) break;
    total += value.length;
    if (total > maxBytes) {
      await reader.cancel();
      throw new GatewayError("too_large", "body_too_large");
    }
    chunks.push(value);
  }
  const out: Bytes = new Uint8Array(total);
  let off = 0;
  for (const c of chunks) {
    out.set(c, off);
    off += c.length;
  }
  return out;
}

export function parseJsonObject(bytes: Uint8Array): Record<string, unknown> {
  let text: string;
  try {
    text = new TextDecoder("utf-8", { fatal: true }).decode(bytes);
  } catch {
    throw bad("body_not_utf8");
  }
  let value: unknown;
  try {
    value = JSON.parse(text);
  } catch {
    throw bad("body_not_json");
  }
  if (value === null || typeof value !== "object" || Array.isArray(value)) throw bad("body_not_object");
  return value as Record<string, unknown>;
}

function checkField(f: Field, v: unknown, path: string): void {
  switch (f.t) {
    case "uuid":
      if (typeof v !== "string" || !isUuid(v)) throw bad(`${path}:uuid`);
      return;
    case "string":
      if (typeof v !== "string" || v.length > f.max || (f.pattern && !f.pattern.test(v))) {
        throw bad(`${path}:string`);
      }
      return;
    case "int":
      if (typeof v !== "number" || !Number.isSafeInteger(v) || v < f.min || v > f.max) {
        throw bad(`${path}:int`);
      }
      return;
    case "bool":
      if (typeof v !== "boolean") throw bad(`${path}:bool`);
      return;
    case "enum":
      if (typeof v !== "string" || !f.values.includes(v)) throw bad(`${path}:enum`);
      return;
    case "b64url": {
      if (typeof v !== "string" || v.length > Math.ceil((f.maxBytes * 4) / 3) + 1) throw bad(`${path}:b64`);
      const bytes = b64urlDecode(v);
      if (!bytes || bytes.length > f.maxBytes || bytes.length < (f.minBytes ?? 0)) throw bad(`${path}:b64`);
      return;
    }
    case "array":
      if (!Array.isArray(v) || v.length > f.maxItems) throw bad(`${path}:array`);
      v.forEach((item, i) => checkField(f.of, item, `${path}[${i}]`));
      return;
    case "object":
      if (v === null || typeof v !== "object" || Array.isArray(v)) throw bad(`${path}:object`);
      checkShape(f.shape, v as Record<string, unknown>, path);
      return;
  }
}

function checkShape(shape: Shape, body: Record<string, unknown>, prefix: string): void {
  const at = (key: string) => (prefix ? `${prefix}.${key}` : key);
  for (const key of Object.keys(body)) {
    if (!Object.hasOwn(shape, key)) throw bad("unknown_field");
  }
  for (const [key, field] of Object.entries(shape)) {
    if (!Object.hasOwn(body, key)) {
      if (field.optional) continue;
      throw bad(`${at(key)}:missing`);
    }
    checkField(field, body[key], at(key));
  }
}

/** Throws `bad_request` on a missing field, a wrong type, or any field the shape does not name. */
export function validate(shape: Shape, body: Record<string, unknown>): void {
  checkShape(shape, body, "");
}
