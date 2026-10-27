// The content publish secret: one value that lives on the owner's computer and as a Supabase secret.
// It is compared in constant time, wrong tries are counted per caller address, and it is never logged.
import { GatewayError } from "./errors.ts";
import type { Services } from "./handler.ts";
import { ipKey } from "./keyed.ts";

export const PUBLISH_FAILS_PER_HOUR_PER_IP = 10;

const utf8 = (s: string) => new TextEncoder().encode(s);

async function digest(s: string): Promise<Uint8Array> {
  return new Uint8Array(await crypto.subtle.digest("SHA-256", utf8(s)));
}

/** True when the strings are equal, in time that does not depend on where they differ. */
export async function sameSecret(a: string, b: string): Promise<boolean> {
  const [x, y] = await Promise.all([digest(a), digest(b)]);
  let diff = 0;
  for (let i = 0; i < x.length; i++) diff |= x[i] ^ y[i];
  return diff === 0;
}

export async function verifyPublishSecret(svc: Services, req: Request): Promise<void> {
  const secret = svc.secrets.publishSecret;
  if (!secret || secret.length < 24) throw new GatewayError("unavailable", "no_publish_secret");
  const sent = req.headers.get("x-publish-secret") ?? "";
  if (sent.length <= 200 && await sameSecret(sent, secret)) return;
  // A wrong secret counts against the caller's address; past the limit the answer changes to "slow down".
  const ip = await ipKey(req, svc.secrets.ipHashKey);
  const hour = new Date(Math.floor(svc.nowMs() / 3_600_000) * 3_600_000);
  const room = await svc.store.rateLimitHit("publish_fail", ip.text, hour, PUBLISH_FAILS_PER_HOUR_PER_IP);
  throw room
    ? new GatewayError("unauthorized", "bad_publish_secret")
    : new GatewayError("rate_limited", "publish_fail_limit");
}
