// The real Store: Postgres, connected as the least-privilege `app_gateway` role. The Data API
// cannot see the closed `app` schema, so this direct connection is the only road to it.
// Every statement is parameterised; nothing from a request is ever pasted into SQL text.
import { Buffer } from "node:buffer";
import postgres from "npm:postgres@3.4.9";
import type { DeviceRecord } from "./auth.ts";
import type { Bytes } from "./b64.ts";
import { compareSemver } from "./semver.ts";
import type { DeviceSummary, RevokeReason, Store } from "./store.ts";

const bytes = (v: unknown): Bytes => new Uint8Array(v as ArrayLike<number>) as Bytes;
const buf = (b: Uint8Array) => Buffer.from(b);

class RollbackReason extends Error {
  constructor(readonly reason: "bad_code") {
    super(reason);
  }
}

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

    async consumeChallenge(c) {
      const rows = await sql`
        update app.enroll_challenge set used_at = now()
         where challenge = ${buf(c.challenge)} and purpose = ${c.purpose}
           and used_at is null and expires_at > now() and failed_attempts < 5
           and user_id is not distinct from ${c.userId}
        returning id`;
      return rows.length === 1;
    },

    async devAllowlistHas(secretHash) {
      const rows = await sql`
        select 1 from app.dev_device_allowlist
         where secret_hash = ${buf(secretHash)} and expires_at > now()`;
      return rows.length === 1;
    },

    async enrolParentDevice(e) {
      try {
        return await sql.begin(async (tx) => {
          // One enrolment per user at a time, so two phones cannot create two families.
          await tx`select pg_advisory_xact_lock(hashtextextended(${e.userId}, 1))`;
          let [g] = await tx`select family_id from app.guardian where user_id = ${e.userId}`;
          if (!g) {
            const [f] = await tx`insert into app.family default values returning id`;
            await tx`insert into app.guardian (user_id, family_id) values (${e.userId}, ${f.id})`;
            g = { family_id: f.id };
          }
          const familyId: string = g.family_id;
          if (e.replaceDeviceId) {
            const gone = await tx`
              update app.device set revoked_at = now(), revoked_reason = 'replaced'
               where id = ${e.replaceDeviceId} and family_id = ${familyId} and revoked_at is null
              returning id`;
            if (gone.length !== 1) return { ok: false as const, reason: "no_such_device" as const };
          }
          const [d] = await tx`
            insert into app.device (family_id, role, public_key, platform, attestation_kind, security_level, app_version)
            values (${familyId}, 'parent', ${
            buf(e.publicKey)
          }, ${e.platform}, ${e.attestationKind}, ${e.securityLevel}, ${e.appVersion})
            returning id`;
          return { ok: true as const, deviceId: d.id as string, familyId };
        });
      } catch (err) {
        const code = (err as { code?: string; message?: string }).code;
        const message = (err as { message?: string }).message ?? "";
        if (code === "P0001" && message.includes("device_limit")) {
          return { ok: false as const, reason: "device_limit" as const };
        }
        if (code === "23505") return { ok: false as const, reason: "key_in_use" as const };
        throw err;
      }
    },

    async pairPeek(c) {
      return await sql.begin(async (tx) => {
        const [ch] = await tx`
          select id from app.enroll_challenge
           where challenge = ${buf(c.challenge)} and purpose = 'pair' and used_at is null
             and expires_at > now() and failed_attempts < 5
           for update`;
        if (!ch) return { ok: false as const, reason: "challenge_invalid" as const };
        const [code] = await tx`
          select p.family_id, (select g.user_id from app.guardian g where g.family_id = p.family_id
                                order by g.created_at limit 1) as guardian
            from app.pairing_code p
           where p.code_hash = ${buf(c.codeHash)} and p.used_at is null and p.burned_at is null
             and p.expires_at > now()`;
        if (!code || !code.guardian) {
          await tx`update app.enroll_challenge set failed_attempts = failed_attempts + 1 where id = ${ch.id}`;
          return { ok: false as const, reason: "bad_code" as const };
        }
        return {
          ok: true as const,
          familyId: code.family_id as string,
          guardianUserId: code.guardian as string,
        };
      });
    },

    async pairComplete(c) {
      try {
        return await sql.begin(async (tx) => {
          const [ch] = await tx`
            update app.enroll_challenge set used_at = now()
             where challenge = ${buf(c.challenge)} and purpose = 'pair' and used_at is null
               and expires_at > now() and failed_attempts < 5
            returning id`;
          if (!ch) return { ok: false as const, reason: "challenge_invalid" as const };
          const [code] = await tx`
            update app.pairing_code set used_at = now()
             where code_hash = ${buf(c.codeHash)} and used_at is null and burned_at is null
               and expires_at > now()
            returning id, family_id`;
          if (!code) throw new RollbackReason("bad_code");
          const [d] = await tx`
            insert into app.device (family_id, role, public_key, platform, attestation_kind, security_level, app_version)
            values (${code.family_id}, 'child', ${
            buf(c.publicKey)
          }, ${c.platform}, ${c.attestationKind}, ${c.securityLevel}, ${c.appVersion})
            returning id`;
          await tx`update app.pairing_code set used_by_device = ${d.id} where id = ${code.id}`;
          return { ok: true as const, deviceId: d.id as string, familyId: code.family_id as string };
        });
      } catch (err) {
        if (err instanceof RollbackReason) return { ok: false as const, reason: err.reason };
        const code = (err as { code?: string }).code;
        const message = (err as { message?: string }).message ?? "";
        if (code === "P0001" && message.includes("device_limit")) {
          return { ok: false as const, reason: "device_limit" as const };
        }
        if (code === "23505") return { ok: false as const, reason: "key_in_use" as const };
        throw err;
      }
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

    async publishContent(p) {
      return await sql.begin(async (tx) => {
        // One publish of a pack at a time.
        await tx`select pg_advisory_xact_lock(hashtext(${"content:" + p.packId}))`;
        const have =
          await tx`select pack_version, manifest_sha256 from app.content_pack where pack_id = ${p.packId}`;
        let same = false;
        for (const r of have) {
          const order = compareSemver(p.packVersion, r.pack_version as string);
          if (order === 0) {
            if (r.manifest_sha256 !== p.manifestSha256) return "conflict" as const;
            same = true;
          } else if (order < 0) {
            return "older" as const;
          }
        }
        // The speaking characters are kept up to date whenever their pack is published again (the owner chooses a
        // voice later); a voice already set is never erased by a publish that does not know it.
        for (const c of p.characters) {
          await tx`
            insert into app.family_character (character_id, name_he, gender, voice_id, personal)
            values (${c.characterId}, ${c.nameHe}, ${c.gender}, ${c.voiceId}, ${c.personal})
            on conflict (character_id) do update
              set name_he = excluded.name_he, gender = excluded.gender, personal = excluded.personal,
                  voice_id = coalesce(excluded.voice_id, app.family_character.voice_id), updated_at = now()`;
        }
        if (same) return "unchanged" as const;
        // Only the current version of a pack is kept (its items, misconceptions and cached lines go with it).
        await tx`delete from app.content_pack where pack_id = ${p.packId}`;
        await tx`
          insert into app.content_pack (pack_id, pack_version, manifest_sha256)
          values (${p.packId}, ${p.packVersion}, ${p.manifestSha256})`;
        for (const i of p.items) {
          await tx`
            insert into app.content_item
              (pack_id, pack_version, item_id, revision, template, band, skill_ids, llm_allowed, goal, prompt_text,
               answers, number_set, allowed_actions, hint_threshold, object_ids)
            values (${p.packId}, ${p.packVersion}, ${i.itemId}, ${i.revision}, ${i.template}, ${i.band},
              array(select jsonb_array_elements_text(${JSON.stringify(i.skillIds)}::jsonb)),
              ${i.llmAllowed}, ${i.goal}, ${i.promptText}, ${JSON.stringify(i.answers)}::jsonb,
              array(select (jsonb_array_elements_text(${JSON.stringify(i.numberSet)}::jsonb))::integer),
              array(select jsonb_array_elements_text(${JSON.stringify(i.allowedActions)}::jsonb)),
              ${i.hintThreshold},
              array(select jsonb_array_elements_text(${JSON.stringify(i.objectIds)}::jsonb)))`;
        }
        for (const m of p.misconceptions) {
          await tx`
            insert into app.misconception (pack_id, pack_version, tag, skill_ids, description)
            values (${p.packId}, ${p.packVersion}, ${m.tag},
              array(select jsonb_array_elements_text(${
            JSON.stringify(m.skillIds)
          }::jsonb)), ${m.description})`;
        }
        return "published" as const;
      });
    },
  };
}
