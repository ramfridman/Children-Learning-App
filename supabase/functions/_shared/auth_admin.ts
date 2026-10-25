// The only place the project's powerful Auth admin key is used: to give a freshly paired child
// device a one-time sign-in for the family's guardian account. The key comes from our own secret
// named AUTH_ADMIN_KEY (set with `supabase secrets set`), never from the platform's defaults, and
// it is used for exactly two Auth admin calls.
import { GatewayError } from "./errors.ts";

const UUID = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/;

export function authAdminMinter(supabaseUrl: string, adminKey: string, fetchFn: typeof fetch = fetch) {
  const base = new URL(supabaseUrl).origin;
  const headers = {
    apikey: adminKey,
    authorization: `Bearer ${adminKey}`,
    "content-type": "application/json",
  };
  const unavailable = () => new GatewayError("unavailable", "session_mint_failed");

  return async (guardianUserId: string): Promise<{ tokenHash: string }> => {
    if (!UUID.test(guardianUserId)) throw unavailable();
    const signal = () => AbortSignal.timeout(3000);
    const u = await fetchFn(`${base}/auth/v1/admin/users/${guardianUserId}`, { headers, signal: signal() });
    if (!u.ok) throw unavailable();
    const email = (await u.json())?.email;
    if (typeof email !== "string" || email.length === 0 || email.length > 254) throw unavailable();
    const g = await fetchFn(`${base}/auth/v1/admin/generate_link`, {
      method: "POST",
      headers,
      body: JSON.stringify({ type: "magiclink", email }),
      signal: signal(),
    });
    if (!g.ok) throw unavailable();
    const hashed = (await g.json())?.hashed_token;
    if (typeof hashed !== "string" || !/^[A-Za-z0-9_-]{10,200}$/.test(hashed)) throw unavailable();
    return { tokenHash: hashed };
  };
}
