// Sends the one push of the app: a parent's phone is told that there is a new alert, and nothing else. The text is a
// fixed phrase; no child, no alert and no family data are ever in it. Firebase Cloud Messaging HTTP v1, with plain fetch;
// the service account is a Supabase secret and never leaves the gateway.
import { b64urlEncode } from "./b64.ts";

/** What every push says (PLAN: "there's a new alert"). The details open behind the parent gate. */
export const PUSH_TEXT = "יש התראה חדשה";

export type PushResult = "ok" | "invalid_token" | "failed";

export interface PushClient {
  send(token: string, platform: "android" | "ios"): Promise<PushResult>;
}

interface ServiceAccount {
  project_id: string;
  client_email: string;
  private_key: string;
}

const TOKEN_URL = "https://oauth2.googleapis.com/token";
const SCOPE = "https://www.googleapis.com/auth/firebase.messaging";

function pemToDer(pem: string): Uint8Array<ArrayBuffer> {
  const body = pem.replace(/-----[A-Z ]+-----/g, "").replace(/\s+/g, "");
  const bin = atob(body);
  const out = new Uint8Array(bin.length);
  for (let i = 0; i < bin.length; i++) out[i] = bin.charCodeAt(i);
  return out;
}

const textBytes = (s: string) => new TextEncoder().encode(s);

/** Parses the secret; null if it is not a usable service account (the push is then simply not available). */
export function parseServiceAccount(json: string): ServiceAccount | null {
  try {
    const a = JSON.parse(json) as Partial<ServiceAccount>;
    if (
      typeof a.project_id === "string" && /^[a-z0-9-]{4,60}$/.test(a.project_id) &&
      typeof a.client_email === "string" && /^[A-Za-z0-9._@-]{10,200}$/.test(a.client_email) &&
      typeof a.private_key === "string" && a.private_key.includes("BEGIN PRIVATE KEY")
    ) return { project_id: a.project_id, client_email: a.client_email, private_key: a.private_key };
  } catch {
    // fall through
  }
  return null;
}

export function fcmClient(
  serviceAccountJson: string,
  o: { fetchFn?: typeof fetch; nowMs?: () => number; timeoutMs?: number } = {},
): PushClient | null {
  const account = parseServiceAccount(serviceAccountJson);
  if (!account) return null;
  const fetchFn = o.fetchFn ?? fetch;
  const now = o.nowMs ?? (() => Date.now());
  const timeoutMs = o.timeoutMs ?? 2000;
  let cached: { token: string; expiresAtMs: number } | undefined;
  let key: CryptoKey | undefined;

  async function accessToken(): Promise<string | null> {
    if (cached && cached.expiresAtMs - 60_000 > now()) return cached.token;
    key ??= await crypto.subtle.importKey(
      "pkcs8",
      pemToDer(account!.private_key),
      { name: "RSASSA-PKCS1-v1_5", hash: "SHA-256" },
      false,
      ["sign"],
    );
    const iat = Math.floor(now() / 1000);
    const head = b64urlEncode(textBytes(JSON.stringify({ alg: "RS256", typ: "JWT" })));
    const claims = b64urlEncode(
      textBytes(
        JSON.stringify({ iss: account!.client_email, scope: SCOPE, aud: TOKEN_URL, iat, exp: iat + 3600 }),
      ),
    );
    const sig = new Uint8Array(
      await crypto.subtle.sign("RSASSA-PKCS1-v1_5", key, textBytes(`${head}.${claims}`)),
    );
    const res = await fetchFn(TOKEN_URL, {
      method: "POST",
      headers: { "content-type": "application/x-www-form-urlencoded" },
      body: new URLSearchParams({
        grant_type: "urn:ietf:params:oauth:grant-type:jwt-bearer",
        assertion: `${head}.${claims}.${b64urlEncode(sig)}`,
      }),
      signal: AbortSignal.timeout(timeoutMs),
    });
    if (!res.ok) return null;
    const j = await res.json() as { access_token?: unknown; expires_in?: unknown };
    if (typeof j.access_token !== "string") return null;
    cached = {
      token: j.access_token,
      expiresAtMs: now() + (typeof j.expires_in === "number" ? j.expires_in : 3600) * 1000,
    };
    return cached.token;
  }

  return {
    async send(token, platform) {
      // Android first: iOS push waits for the iOS gate (APNs).
      if (platform !== "android") return "failed";
      try {
        const bearer = await accessToken();
        if (!bearer) return "failed";
        const res = await fetchFn(
          `https://fcm.googleapis.com/v1/projects/${account.project_id}/messages:send`,
          {
            method: "POST",
            headers: { authorization: `Bearer ${bearer}`, "content-type": "application/json" },
            // The whole message: a token, the fixed phrase and a channel. Nothing else, ever.
            body: JSON.stringify({
              message: {
                token,
                notification: { body: PUSH_TEXT },
                android: { priority: "HIGH", notification: { channel_id: "alerts" } },
              },
            }),
            signal: AbortSignal.timeout(timeoutMs),
          },
        );
        if (res.ok) {
          await res.body?.cancel();
          return "ok";
        }
        // 404 UNREGISTERED and 400 INVALID_ARGUMENT mean this token is dead; anything else is a passing failure.
        const dead = res.status === 404 || res.status === 400;
        await res.body?.cancel();
        return dead ? "invalid_token" : "failed";
      } catch {
        return "failed";
      }
    },
  };
}

/**
 * Tells the family's parent phones (but not the one that raised the alert) that there is a new alert. Never throws,
 * never waits long, and removes a token that is dead.
 */
export async function notifyParents(
  push: PushClient | undefined,
  store: {
    pushTokens(
      familyId: string,
    ): Promise<Array<{ deviceId: string; token: string; platform: "android" | "ios" }>>;
    removePushToken(deviceId: string): Promise<void>;
  },
  familyId: string,
  exceptDeviceId: string,
  waitMs = 2500,
): Promise<number> {
  if (!push) return 0;
  try {
    const targets = (await store.pushTokens(familyId)).filter((t) => t.deviceId !== exceptDeviceId);
    let sent = 0;
    const work = Promise.all(targets.map(async (t) => {
      const r = await push.send(t.token, t.platform);
      if (r === "ok") sent++;
      else if (r === "invalid_token") await store.removePushToken(t.deviceId);
    }));
    await Promise.race([work, new Promise((r) => setTimeout(r, waitMs))]);
    return sent;
  } catch {
    return 0;
  }
}
