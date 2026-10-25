// One wrapper for every function: method check, body cap, authentication, strict body schema,
// error mapping and the redacted log line. A function supplies only its shape and what it does.
import { authenticate, type Authenticated, type Role } from "./auth.ts";
import type { Bytes } from "./b64.ts";
import { isFunctionName } from "./canonical.ts";
import { errorResponse, GatewayError, jsonResponse } from "./errors.ts";
import { log } from "./log.ts";
import { parseJsonObject, readBodyBytes, type Shape, validate } from "./schema.ts";
import type { Secrets, Store } from "./store.ts";

export interface Services {
  nowMs(): number;
  verifyToken(bearer: string): Promise<{ userId: string; issuedAt: number | null } | null>;
  store: Store;
  secrets: Secrets;
  randomBytes(n: number): Bytes;
  /** True only in the local stack: lets emulators enrol through the dev allowlist. */
  allowDevEnrolment: boolean;
  /** Tests only: replaces Google's roots. Always undefined in production. */
  androidRootsPem?: readonly string[];
}

export type Access =
  | { kind: "device"; roles: readonly Role[] }
  /** A valid session token and nothing else (first-device enrolment happens before any device exists). */
  | { kind: "token" }
  /** No session at all (a child device pairing for the first time); callers are limited per IP. */
  | { kind: "public" };

export interface Context {
  svc: Services;
  req: Request;
  body: Record<string, unknown>;
  /** The exact bytes received, for calls that verify their own signature. */
  raw: Bytes;
  requestId: string;
  /** Present when access.kind is "device". */
  auth?: Authenticated;
  /** Present for "device" and "token"; null for "public". */
  userId: string | null;
  issuedAt: number | null;
}

export interface FunctionSpec {
  name: string;
  access: Access;
  shape: Shape;
  run(ctx: Context): Promise<unknown>;
}

function bearer(req: Request): string {
  const m = /^Bearer ([A-Za-z0-9._-]{10,4096})$/.exec(req.headers.get("authorization") ?? "");
  if (!m) throw new GatewayError("unauthorized", "no_token");
  return m[1];
}

export function makeHandler(spec: FunctionSpec, getServices: () => Services) {
  if (!isFunctionName(spec.name)) throw new Error("bad function name");
  return async (req: Request): Promise<Response> => {
    const started = performance.now();
    const requestId = crypto.randomUUID();
    let outcome: "ok" | "refused" | "error" = "ok";
    let reason: string | undefined;
    let res: Response;
    try {
      // No browser origins are served: no CORS headers, and only POST.
      if (req.method !== "POST") throw new GatewayError("bad_request", "method");
      const svc = getServices();
      const raw = await readBodyBytes(req);
      let auth: Authenticated | undefined;
      let userId: string | null = null;
      let issuedAt: number | null = null;
      if (spec.access.kind === "device") {
        auth = await authenticate(req, spec.name, raw, spec.access.roles, {
          nowMs: () => svc.nowMs(),
          verifyToken: (b) => svc.verifyToken(b),
          getDevice: (id) => svc.store.getDevice(id),
          isGuardian: (u, f) => svc.store.isGuardian(u, f),
          recordNonce: (d, n) => svc.store.recordNonce(d, n),
        });
        userId = auth.userId;
        issuedAt = auth.issuedAt;
      } else if (spec.access.kind === "token") {
        const claims = await svc.verifyToken(bearer(req));
        if (!claims) throw new GatewayError("unauthorized", "bad_token");
        userId = claims.userId;
        issuedAt = claims.issuedAt;
      }
      const body = parseJsonObject(raw);
      validate(spec.shape, body);
      const result = await spec.run({ svc, req, body, raw, requestId, auth, userId, issuedAt });
      if (auth) svc.store.touchDevice(auth.device.id).catch(() => {});
      res = jsonResponse(result ?? {});
    } catch (e) {
      if (e instanceof GatewayError) {
        outcome = "refused";
        reason = e.reason;
        res = errorResponse(e);
      } else {
        outcome = "error";
        reason = "internal";
        res = errorResponse(new GatewayError("internal", "internal"));
      }
    }
    res.headers.set("x-request-id", requestId);
    log({ requestId, fn: spec.name, outcome, latencyMs: performance.now() - started, reason });
    return res;
  };
}

/** Rounds a time down to the start of its hour (the window for hourly limits). */
export const hourStart = (ms: number): Date => new Date(Math.floor(ms / 3_600_000) * 3_600_000);
