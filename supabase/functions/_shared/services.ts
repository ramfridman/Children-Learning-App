// Builds the real services from the function's environment. Anything missing means the function
// answers "unavailable" and does nothing, rather than running half-configured.
import { b64urlDecode, type Bytes } from "./b64.ts";
import { anthropicClient } from "./anthropic.ts";
import { authAdminMinter } from "./auth_admin.ts";
import { elevenLabsClient } from "./elevenlabs.ts";
import { fcmClient } from "./fcm.ts";
import { connect, pgStore } from "./db.ts";
import { GatewayError } from "./errors.ts";
import { DEFAULT_TUTOR_BUDGET, type Services } from "./handler.ts";
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
  // The two vendor keys are optional here: without them the tutor answers with the RuleTutor and costs nothing.
  const anthropicKey = Deno.env.get("ANTHROPIC_API_KEY");
  const elevenKey = Deno.env.get("ELEVENLABS_API_KEY");
  // The push is optional too: without the Firebase service account alerts simply wait in the app.
  const fcmAccount = Deno.env.get("FCM_SERVICE_ACCOUNT");
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
    tutor: anthropicKey && elevenKey
      ? {
        model: anthropicClient(anthropicKey),
        voice: elevenLabsClient(elevenKey),
        budget: DEFAULT_TUTOR_BUDGET,
      }
      : undefined,
    push: (fcmAccount ? fcmClient(fcmAccount) : null) ?? undefined,
    randomBytes: (n) => crypto.getRandomValues(new Uint8Array(n)) as Bytes,
  };
  return cached;
}
