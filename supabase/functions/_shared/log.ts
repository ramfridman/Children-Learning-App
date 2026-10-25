// Log lines carry a request id, the function, how long it took and the outcome. Nothing else:
// no headers, no body, no token, no key, no device id. Fields are rebuilt from a fixed allowlist,
// so even a careless caller cannot add something to a line.

const FUNCTION_NAME = /^[a-z][a-z0-9-]{0,63}$/;
const REASON = /^[a-z0-9_:\[\]]{1,48}$/;
const OUTCOMES = ["ok", "refused", "error"] as const;
export type Outcome = (typeof OUTCOMES)[number];

export interface LogEntry {
  requestId: string;
  fn: string;
  outcome: Outcome;
  latencyMs: number;
  reason?: string;
}

export function redactedLine(e: LogEntry): string {
  const safe = {
    request_id: /^[0-9a-f-]{36}$/.test(e.requestId) ? e.requestId : "invalid",
    fn: FUNCTION_NAME.test(e.fn) ? e.fn : "invalid",
    outcome: (OUTCOMES as readonly string[]).includes(e.outcome) ? e.outcome : "error",
    latency_ms: Number.isFinite(e.latencyMs) ? Math.max(0, Math.round(e.latencyMs)) : -1,
    ...(e.reason !== undefined ? { reason: REASON.test(e.reason) ? e.reason : "invalid" } : {}),
  };
  return JSON.stringify(safe);
}

export function log(e: LogEntry): void {
  console.log(redactedLine(e));
}

/**
 * The reason label for an unexpected error: only its short machine code (for example a Postgres
 * SQLSTATE such as `28p01`, or a network code such as `connect_timeout`), or its class name. Never
 * the message, which can name a host, a user or a value. Lets the owner tell "wrong database
 * password" from "pooler refused the user" in the function log without exposing anything.
 */
export function internalReason(e: unknown): string {
  const o = (e ?? {}) as { code?: unknown; name?: unknown };
  const raw = typeof o.code === "string" ? o.code : typeof o.name === "string" ? o.name : "";
  const s = raw.toLowerCase().replace(/[^a-z0-9_]/g, "_").slice(0, 30);
  return s ? `internal:${s}` : "internal";
}
