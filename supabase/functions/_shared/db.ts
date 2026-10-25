// The real Store: Postgres, connected as the least-privilege `app_gateway` role. The Data API
// cannot see the closed `app` schema, so this direct connection is the only road to it.
// Every statement is parameterised; nothing from a request is ever pasted into SQL text.
import { Buffer } from "node:buffer";
import postgres from "postgres";
import type { DeviceRecord } from "./auth.ts";
import type { Bytes } from "./b64.ts";
import type { DeviceSummary, RevokeReason, Store } from "./store.ts";

const bytes = (v: unknown): Bytes => new Uint8Array(v as ArrayLike<number>) as Bytes;
const buf = (b: Uint8Array) => Buffer.from(b);

export type Sql = ReturnType<typeof postgres>;

export function connect(url: string): Sql {
  const local = /@(127\.0\.0\.1|localhost)[:/]/.test(url);
  return postgres(url, {
    max: 3,
    idle_timeout: 20,
    connect_timeout: 3,
    // Poolers in transaction mode do not support prepared statements.
    prepare: false,
    ssl: local ? false : "require",
    onnotice: () => {},
  });
}

export function pgStore(sql: Sql): Store {
  return {
    async getDevice(id): Promise<DeviceRecord | null> {
      const [r] = await sql`
        select id, family_id, role, public_key, revoked_at
          from app.device where id = ${id}`;
      return r
        ? {
          id: r.id,
          familyId: r.family_id,
          role: r.role,
          publicKey: bytes(r.public_key),
          revokedAt: r.revoked_at,
        }
        : null;
    },

    async isGuardian(userId, familyId) {
      const rows = await sql`
        select 1 from app.guardian g join app.family f on f.id = g.family_id
         where g.user_id = ${userId} and g.family_id = ${familyId} and f.deleted_at is null`;
      return rows.length === 1;
    },

    async recordNonce(deviceId, nonce) {
      const rows = await sql`
        insert into app.request_nonce (device_id, nonce) values (${deviceId}, ${nonce})
        on conflict do nothing returning 1`;
      return rows.length === 1;
    },

    async touchDevice(id) {
      await sql`update app.device set last_seen_at = now() where id = ${id}`;
    },

    async getConfig(key) {
      const [r] = await sql`select value from app.config where key = ${key}`;
      return r ? r.value : undefined;
    },

    async rateLimitHit(scope, key, windowStart, limit) {
      // One atomic statement: count this use only while below the limit.
      const rows = await sql`
        insert into app.usage_counter (scope, key, window_start, count)
        values (${scope}, ${key}, ${windowStart}, 1)
        on conflict (scope, key, window_start)
        do update set count = app.usage_counter.count + 1
          where app.usage_counter.count < ${limit}
        returning count`;
      return rows.length === 1;
    },

    async insertChallenge(c) {
      await sql`
        insert into app.enroll_challenge (challenge, purpose, user_id, ip_hash, expires_at)
        values (${buf(c.challenge)}, ${c.purpose}, ${c.userId}, ${
        c.ipHash ? buf(c.ipHash) : null
      }, ${c.expiresAt})`;
    },

    async insertPairingCode(c) {
      const rows = await sql`
        insert into app.pairing_code (family_id, created_by_device, code_hash, expires_at)
        values (${c.familyId}, ${c.byDevice}, ${buf(c.codeHash)}, ${c.expiresAt})
        on conflict (code_hash) where used_at is null and burned_at is null do nothing
        returning id`;
      return rows.length === 1;
    },

    async listActiveDevices(familyId): Promise<DeviceSummary[]> {
      const rows = await sql`
        select id, role, platform, security_level, created_at, last_seen_at
          from app.device where family_id = ${familyId} and revoked_at is null
         order by created_at, id`;
      return rows.map((r) => ({
        id: r.id,
        role: r.role,
        platform: r.platform,
        securityLevel: r.security_level,
        createdAt: r.created_at,
        lastSeenAt: r.last_seen_at,
      }));
    },

    async revokeDevice(familyId, deviceId, reason: RevokeReason) {
      const rows = await sql`
        update app.device set revoked_at = now(), revoked_reason = ${reason}
         where id = ${deviceId} and family_id = ${familyId} and revoked_at is null
        returning id`;
      return rows.length === 1;
    },
  };
}
