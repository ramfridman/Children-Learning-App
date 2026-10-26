// Builds the real services from the function's environment. Anything missing means the function
// answers "unavailable" and does nothing, rather than running half-configured.
import { b64urlDecode, type Bytes } from "./b64.ts";
import { authAdminMinter } from "./auth_admin.ts";
import { connect, pgStore } from "./db.ts";
import { GatewayError } from "./errors.ts";
import type { Services } from "./handler.ts";
import { remoteTokenConfig, verifyAccessToken } from "./token.ts";

function need(name: string): string {
  const v = Deno.env.get(name);
  if (!v) throw new GatewayError("unavailable", `missing_${name.toLowerCase()}`);
  return v;
}

function key32(name: string): Bytes {
  const k = b64urlDecode(need(name));
  if (!k || k.length < 32) throw new GatewayError("unavailable", `bad_${name.toLowerCase()}`);
  return k;
}

let cached: Services | undefined;

export function realServices(): Services {
  if (cached) return cached;
  // The project URL is set by the platform. The database login is our own limited role; the
  // platform's own database URL and its all-powerful key are deliberately never read here.
  const tokenCfg = remoteTokenConfig(need("SUPABASE_URL"));
  cached = {
    nowMs: () => Date.now(),
    verifyToken: (bearer) => verifyAccessToken(bearer, tokenCfg),
    store: pgStore(connect(need("APP_GATEWAY_DB_URL"))),
    secrets: {
      pairingCodeKey: key32("PAIRING_CODE_KEY"),
      ipHashKey: key32("IP_HASH_KEY"),
      publishSecret: Deno.env.get("CONTENT_PUBLISH_SECRET") || undefined,
    },
    mintSession: (id) => authAdminMinter(need("SUPABASE_URL"), need("AUTH_ADMIN_KEY"))(id),
    allowDevEnrolment: Deno.env.get("ALLOW_DEV_ENROLMENT") === "true",
    randomBytes: (n) => crypto.getRandomValues(new Uint8Array(n)) as Bytes,
  };
  return cached;
}
