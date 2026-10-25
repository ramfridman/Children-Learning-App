// Session-token verification, done inside the function against the project's published signing
// keys (JWKS). We never trust the platform's own gate alone, and we accept only asymmetric
// algorithms, so an attacker cannot present an HMAC token "signed" with a public key.
import { createRemoteJWKSet, jwtVerify, type JWTVerifyGetKey } from "jose";

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

/** Returns the user id, or null for any token that is not completely valid. Never throws. */
export async function verifyAccessToken(
  bearer: string,
  cfg: TokenConfig,
): Promise<{ userId: string; issuedAt: number | null } | null> {
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
    return { userId: payload.sub, issuedAt: typeof payload.iat === "number" ? payload.iat : null };
  } catch {
    return null;
  }
}
