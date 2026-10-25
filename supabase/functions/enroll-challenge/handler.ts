// Hands out a single-use 32-byte challenge for enrolment (first device, signed-in guardian) or
// pairing (a child device with no session yet, limited per IP address).
import { b64urlEncode } from "../_shared/b64.ts";
import { GatewayError } from "../_shared/errors.ts";
import { type FunctionSpec, hourStart } from "../_shared/handler.ts";
import { ipKey } from "../_shared/keyed.ts";

/** The database caps a challenge at 5 minutes; we ask for 4 so clock drift cannot break the insert. */
export const CHALLENGE_SECONDS = 240;
export const FRESH_SIGN_IN_SECONDS = 600;
export const ENROLL_LIMIT_PER_HOUR = 10;
export const PAIR_LIMIT_PER_HOUR_PER_IP = 20;

export const spec: FunctionSpec = {
  name: "enroll-challenge",
  // The caller decides by `purpose`; the handler below enforces what each purpose needs.
  access: { kind: "public" },
  shape: { purpose: { t: "enum", values: ["enroll", "pair"] } },
  run: async (ctx) => {
    const now = ctx.svc.nowMs();
    const purpose = ctx.body.purpose as "enroll" | "pair";
    let userId: string | null = null;
    let ipHash = null;
    let limitKey: string;
    let limit: number;

    if (purpose === "enroll") {
      const m = /^Bearer ([A-Za-z0-9._-]{10,4096})$/.exec(ctx.req.headers.get("authorization") ?? "");
      const claims = m ? await ctx.svc.verifyToken(m[1]) : null;
      if (!claims) throw new GatewayError("unauthorized", "bad_token");
      // The first device may only be enrolled right after a sign-in, so a stolen old token is not enough.
      if (claims.issuedAt === null || now - claims.issuedAt * 1000 > FRESH_SIGN_IN_SECONDS * 1000) {
        throw new GatewayError("unauthorized", "stale_sign_in");
      }
      userId = claims.userId;
      limitKey = claims.userId;
      limit = ENROLL_LIMIT_PER_HOUR;
    } else {
      const ip = await ipKey(ctx.req, ctx.svc.secrets.ipHashKey);
      ipHash = ip.hash;
      limitKey = ip.text;
      limit = PAIR_LIMIT_PER_HOUR_PER_IP;
    }

    if (!(await ctx.svc.store.rateLimitHit(`challenge_${purpose}`, limitKey, hourStart(now), limit))) {
      throw new GatewayError("rate_limited", "challenge_rate");
    }
    const challenge = ctx.svc.randomBytes(32);
    const expiresAt = new Date(now + CHALLENGE_SECONDS * 1000);
    await ctx.svc.store.insertChallenge({ challenge, purpose, userId, ipHash, expiresAt });
    return { challenge: b64urlEncode(challenge), expires_at: expiresAt.getTime() };
  },
};
