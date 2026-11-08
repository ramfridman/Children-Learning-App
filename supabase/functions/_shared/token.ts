// Session-token verification, done inside the function against the project's published signing
// keys (JWKS). We never trust the platform's own gate alone, and we accept only asymmetric
// algorithms, so an attacker cannot present an HMAC token "signed" with a public key.
import { createRemoteJWKSet, jwtVerify, type JWTVerifyGetKey } from "npm:jose@6.2.13";

export const ACCEPTED_ALGORITHMS = ["ES256", "RS256"];

export interface TokenConfig {
  /** Same value as the `iss` claim, e.g. https://<ref>.supabase.co/auth/v1 */
  issuer: string;
  keys: JWTVerifyGetKey;
  nowSeconds(): number;
}

export function remoteTokenConfig(supabaseUrl: string): TokenConfig {
  const base = new URL(supabaseUrl);
  if (base.protocol !== "https:" && base.hostname !== "127.0.0.1" && base.hostname !== "localhost") {
    throw new Error("SUPABASE_URL must be https");
  }
  const issuer = `${base.origin}/auth/v1`;
  return {
    issuer,
    keys: createRemoteJWKSet(new URL(`${issuer}/.well-known/jwks.json`), {
      cooldownDuration: 30_000,
      cacheMaxAge: 600_000,
      timeoutDuration: 3_000,
    }),
    nowSeconds: () => Math.floor(Date.now() / 1000),
  };
}

const UUID = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/;

/** One way the session was signed in: Supabase's `amr` entry, `timestamp` in seconds since 1970. */
export interface AuthMethod {
  method: string;
  timestamp: number;
}

export interface TokenClaims {
  userId: string;
  /** Empty when the token has no usable `amr` claim (then no sign-in counts as fresh). */
  amr: AuthMethod[];
}

/**
 * The `amr` claim as Supabase documents it: objects `{method, timestamp}`. A plain string list (RFC 8176) has
 * no times, so it yields nothing; so does any entry of another shape.
 */
function authMethods(amr: unknown): AuthMethod[] {
  if (!Array.isArray(amr)) return [];
  const out: AuthMethod[] = [];
  for (const e of amr) {
    if (e && typeof e === "object" && typeof e.method === "string" && Number.isFinite(e.timestamp)) {
      out.push({ method: e.method, timestamp: e.timestamp });
    }
  }
  return out;
}

/** Returns the claims we use, or null for any token that is not completely valid. Never throws. */
export async function verifyAccessToken(bearer: string, cfg: TokenConfig): Promise<TokenClaims | null> {
  try {
    const { payload } = await jwtVerify(bearer, cfg.keys, {
      issuer: cfg.issuer,
      audience: "authenticated",
      algorithms: ACCEPTED_ALGORITHMS,
      currentDate: new Date(cfg.nowSeconds() * 1000),
      clockTolerance: 5,
      requiredClaims: ["exp", "sub"],
    });
    if (payload.role !== "authenticated") return null;
    if (typeof payload.sub !== "string" || !UUID.test(payload.sub)) return null;
    if (payload.is_anonymous === true) return null;
    return { userId: payload.sub, amr: authMethods(payload.amr) };
  } catch {
    return null;
  }
}

/** Enrolment must follow a sign-in by emailed code within this many seconds. */
export const FRESH_SIGN_IN_SECONDS = 600;

/**
 * True when the session was signed in by an emailed code (`otp`) within the last 10 minutes. Only the code
 * counts: a password sign-in can be made by whoever registered the address first, and a refresh keeps the
 * original sign-in time in `amr`, so neither passes. A time in the future (beyond 5 s of clock drift) fails.
 */
export function signedInByCodeRecently(amr: readonly AuthMethod[], nowMs: number): boolean {
  return amr.some((a) => {
    const age = nowMs - a.timestamp * 1000;
    return a.method === "otp" && age <= FRESH_SIGN_IN_SECONDS * 1000 && age >= -5000;
  });
}
