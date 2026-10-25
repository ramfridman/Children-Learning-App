// Short, quiet error codes. The client sees `code` only; `reason` goes to the (redacted) log.
// Several different internal reasons share one public code on purpose, so a caller cannot tell
// "unknown device" from "revoked device" from "bad signature" from "replayed nonce".

export type PublicCode =
  | "bad_request"
  | "unauthorized"
  | "clock_skew"
  | "forbidden"
  | "not_found"
  | "too_large"
  | "rate_limited"
  | "device_limit"
  | "unavailable"
  | "internal";

const STATUS: Record<PublicCode, number> = {
  bad_request: 400,
  unauthorized: 401,
  clock_skew: 401,
  forbidden: 403,
  not_found: 404,
  too_large: 413,
  rate_limited: 429,
  device_limit: 409,
  unavailable: 503,
  internal: 500,
};

export class GatewayError extends Error {
  readonly code: PublicCode;
  readonly status: number;
  /** Internal, log-safe label such as `bad_signature`. Never contains user data. */
  readonly reason: string;
  readonly serverTimeMs?: number;

  constructor(code: PublicCode, reason: string, extra: { serverTimeMs?: number } = {}) {
    super(reason);
    this.code = code;
    this.status = STATUS[code];
    this.reason = reason;
    this.serverTimeMs = extra.serverTimeMs;
  }
}

export function jsonResponse(body: unknown, status = 200): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: {
      "content-type": "application/json; charset=utf-8",
      "cache-control": "no-store",
      "x-content-type-options": "nosniff",
    },
  });
}

export function errorResponse(e: GatewayError): Response {
  const body: Record<string, unknown> = { error: e.code };
  if (e.serverTimeMs !== undefined) body.server_time = e.serverTimeMs;
  return jsonResponse(body, e.status);
}
