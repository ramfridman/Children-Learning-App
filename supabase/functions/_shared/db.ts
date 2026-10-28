// The real Store: Postgres, connected as the least-privilege `app_gateway` role. The Data API
// cannot see the closed `app` schema, so this direct connection is the only road to it.
// Every statement is parameterised; nothing from a request is ever pasted into SQL text.
import { Buffer } from "node:buffer";
import postgres from "npm:postgres@3.4.9";
import type { DeviceRecord } from "./auth.ts";
import type { Bytes } from "./b64.ts";
import { compareSemver } from "./semver.ts";
import type {
  AlertIn,
  AlertOut,
  CachedLine,
  ChildProfile,
  DeviceSummary,
  EventIn,
  EventOut,
  RevokeReason,
  Store,
  TakeResult,
  TutorContext,
  TutorLogEntry,
} from "./store.ts";

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

    async getConfigs(keys) {
      const rows = await sql`select key, value from app.config where key = any(${keys as string[]})`;
      return Object.fromEntries(rows.map((r) => [r.key as string, r.value]));
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
              array(select jsonb_array_elements_text(${JSON.stringify(i.skillIds)}::text::jsonb)),
              ${i.llmAllowed}, ${i.goal}, ${i.promptText}, ${JSON.stringify(i.answers)}::text::jsonb,
              array(select (jsonb_array_elements_text(${JSON.stringify(i.numberSet)}::text::jsonb))::integer),
              array(select jsonb_array_elements_text(${JSON.stringify(i.allowedActions)}::text::jsonb)),
              ${i.hintThreshold},
              array(select jsonb_array_elements_text(${JSON.stringify(i.objectIds)}::text::jsonb)))`;
        }
        for (const m of p.misconceptions) {
          await tx`
            insert into app.misconception (pack_id, pack_version, tag, skill_ids, description)
            values (${p.packId}, ${p.packVersion}, ${m.tag},
              array(select jsonb_array_elements_text(${
            JSON.stringify(m.skillIds)
          }::text::jsonb)), ${m.description})`;
        }
        return "published" as const;
      });
    },

    async tutorContext(packId, packVersion, itemId, characterId): Promise<TutorContext | null> {
      const [i] = await sql`
        select item_id, band, llm_allowed, goal, prompt_text, number_set, allowed_actions, hint_threshold,
               object_ids, answers
          from app.content_item
         where pack_id = ${packId} and pack_version = ${packVersion} and item_id = ${itemId}`;
      if (!i) return null;
      const ms = await sql`
        select tag, description from app.misconception where pack_id = ${packId} and pack_version = ${packVersion}`;
      const [c] = await sql`
        select name_he, gender, voice_id from app.family_character where character_id = ${characterId}`;
      return {
        itemId: i.item_id,
        band: i.band,
        llmAllowed: i.llm_allowed,
        goal: i.goal,
        promptText: i.prompt_text,
        numberSet: i.number_set,
        allowedActions: i.allowed_actions,
        hintThreshold: i.hint_threshold,
        objectIds: i.object_ids,
        answers: i.answers,
        descriptions: Object.fromEntries(ms.map((m) => [m.tag as string, m.description as string])),
        character: c ? { nameHe: c.name_he, gender: c.gender, voiceId: c.voice_id } : null,
      };
    },

    async tutorItemIds(packId, packVersion) {
      const rows = await sql`
        select item_id from app.content_item
         where pack_id = ${packId} and pack_version = ${packVersion} and llm_allowed order by item_id`;
      return rows.map((r) => r.item_id as string);
    },

    async cacheGet(k): Promise<CachedLine | null> {
      const [r] = await sql`
        select line, caption, next_action, highlight_targets, audio from app.tutor_cache
         where pack_id = ${k.packId} and pack_version = ${k.packVersion} and item_id = ${k.itemId}
           and mistake = ${k.mistake} and hint_level = ${k.hintLevel} and band = ${k.band}
           and address_form = ${k.addressForm} and character_id = ${k.characterId}
           and prompt_version = ${k.promptVersion} and validator_version = ${k.validatorVersion}`;
      return r
        ? {
          line: r.line,
          caption: r.caption,
          next: r.next_action,
          highlight: r.highlight_targets,
          audio: r.audio ? bytes(r.audio) : null,
        }
        : null;
    },

    async cachePut(k, v, replace = false) {
      await sql`
        insert into app.tutor_cache
          (pack_id, pack_version, item_id, mistake, hint_level, band, address_form, character_id, prompt_version,
           validator_version, line, caption, next_action, highlight_targets, audio, audio_mime)
        values (${k.packId}, ${k.packVersion}, ${k.itemId}, ${k.mistake}, ${k.hintLevel}, ${k.band}, ${k.addressForm},
          ${k.characterId}, ${k.promptVersion}, ${k.validatorVersion}, ${v.line}, ${v.caption}, ${v.next},
          array(select jsonb_array_elements_text(${JSON.stringify(v.highlight)}::text::jsonb)),
          ${v.audio ? buf(v.audio) : null}, ${v.audio ? "audio/mpeg" : null})
        on conflict (pack_id, pack_version, item_id, mistake, hint_level, band, address_form, character_id,
                     prompt_version, validator_version)
        do update set line = excluded.line, caption = excluded.caption, next_action = excluded.next_action,
          highlight_targets = excluded.highlight_targets, audio = excluded.audio, audio_mime = excluded.audio_mime,
          created_at = now()
        where ${replace}::boolean`;
    },

    async carryLines(packId, fromVersion, toVersion, promptVersion) {
      const rows = await sql`
        insert into app.tutor_cache
          (pack_id, pack_version, item_id, mistake, hint_level, band, address_form, character_id, prompt_version,
           validator_version, line, caption, next_action, highlight_targets, audio, audio_mime)
        select c.pack_id, ${toVersion}, c.item_id, c.mistake, c.hint_level, c.band, c.address_form, c.character_id,
               c.prompt_version, c.validator_version, c.line, c.caption, c.next_action, c.highlight_targets, c.audio,
               c.audio_mime
          from app.tutor_cache c
          join app.content_item o on o.pack_id = c.pack_id and o.pack_version = c.pack_version and o.item_id = c.item_id
          join app.content_item n on n.pack_id = c.pack_id and n.pack_version = ${toVersion} and n.item_id = c.item_id
                                 and n.revision = o.revision
         where c.pack_id = ${packId} and c.pack_version = ${fromVersion} and c.prompt_version = ${promptVersion}
        on conflict do nothing
        returning 1`;
      return rows.length;
    },

    async tutorTake(p): Promise<TakeResult> {
      const [r] = await sql`
        select app.tutor_take(${p.familyId}, ${p.childRef}, ${p.sessionRef}, ${p.kind}, ${p.sessionCap},
          ${p.dayCap}, ${p.prefetchCap}, ${p.costCapMicro}, ${new Date(p.nowMs)}) as result`;
      return r.result as TakeResult;
    },

    async tutorCostAdd(familyId, micro, nowMs) {
      await sql`select app.tutor_cost_add(${familyId}, ${Math.round(micro)}, ${new Date(nowMs)})`;
    },

    async logTutor(r) {
      await sql`
        insert into app.tutor_log
          (family_id, child_ref, session_ref, pack_id, pack_version, item_id, character_id, source, outcome, line,
           validator_ok, validator_failures, prompt_version, total_ms, model_ms, voice_ms, eleven_request_id)
        values (${r.familyId}, ${r.childRef}, ${r.sessionRef}, ${r.packId}, ${r.packVersion}, ${r.itemId},
          ${r.characterId}, ${r.source}, ${r.outcome}, ${r.line}, ${r.validatorOk},
          array(select jsonb_array_elements_text(${JSON.stringify(r.validatorFailures)}::text::jsonb)),
          ${r.promptVersion}, ${Math.round(r.totalMs)}, ${r.modelMs === null ? null : Math.round(r.modelMs)},
          ${r.voiceMs === null ? null : Math.round(r.voiceMs)}, ${r.elevenRequestId})`;
    },

    async upsertChild(familyId, c) {
      const [gone] =
        await sql`select 1 from app.deleted_child where family_id = ${familyId} and child_id = ${c.id}`;
      if (gone) return "deleted";
      await sql`
        insert into app.child_profile (family_id, id, nickname, avatar_id, companion_id, outfit_id, address_form, age_band)
        values (${familyId}, ${c.id}, ${c.nickname}, ${c.avatarId}, ${c.companionId}, ${
        c.outfitId ?? null
      }, ${c.addressForm}, ${c.ageBand})
        on conflict (family_id, id) do update set nickname = excluded.nickname, avatar_id = excluded.avatar_id,
          companion_id = excluded.companion_id, outfit_id = excluded.outfit_id, address_form = excluded.address_form,
          age_band = excluded.age_band, updated_at = now()`;
      return "saved";
    },

    async listChildren(familyId) {
      const rows = await sql`
        select id, nickname, avatar_id, companion_id, outfit_id, address_form, age_band
          from app.child_profile where family_id = ${familyId} order by created_at, id`;
      return rows.map((r): ChildProfile => ({
        id: r.id,
        nickname: r.nickname,
        avatarId: r.avatar_id,
        companionId: r.companion_id,
        outfitId: r.outfit_id,
        addressForm: r.address_form,
        ageBand: r.age_band,
      }));
    },

    async listTombstones(familyId) {
      const rows =
        await sql`select child_id from app.deleted_child where family_id = ${familyId} order by deleted_at`;
      return rows.map((r) => r.child_id as string);
    },

    async deleteChild(familyId, childId) {
      await sql`select app.delete_child(${familyId}, ${childId})`;
    },

    async insertEvents(familyId, deviceId, events: readonly EventIn[]) {
      if (events.length === 0) return { accepted: 0, duplicates: 0, refused: [] };
      const ids = [...new Set(events.map((e) => e.childId))];
      const known =
        await sql`select id from app.child_profile where family_id = ${familyId} and id = any(${ids})`;
      const have = new Set(known.map((r) => r.id as string));
      let accepted = 0;
      let duplicates = 0;
      const refused: string[] = [];
      await sql.begin(async (tx) => {
        for (const e of events) {
          if (!have.has(e.childId)) {
            refused.push(e.id);
            continue;
          }
          const rows = await tx`
            insert into app.event (id, family_id, child_id, device_id, client_at, engine_version, type, payload)
            values (${e.id}, ${familyId}, ${e.childId}, ${deviceId}, ${new Date(
            e.clientAtMs,
          )}, ${e.engineVersion},
              ${e.type}, ${JSON.stringify(e.payload)}::text::jsonb)
            on conflict (family_id, id) do nothing
            returning seq`;
          if (rows.length === 1) accepted++;
          else duplicates++;
        }
      });
      return { accepted, duplicates, refused };
    },

    async pullEvents(familyId, after, limit) {
      const rows = await sql`
        select seq, id, child_id, device_id, client_at, engine_version, type, payload
          from app.event where family_id = ${familyId} and seq > ${after}
         order by seq limit ${limit + 1}`;
      const more = rows.length > limit;
      return {
        more,
        events: rows.slice(0, limit).map((r): EventOut => ({
          seq: Number(r.seq),
          id: r.id,
          childId: r.child_id,
          deviceId: r.device_id,
          clientAtMs: (r.client_at as Date).getTime(),
          engineVersion: r.engine_version,
          type: r.type,
          payload: r.payload as Record<string, unknown>,
        })),
      };
    },

    async insertAlert(familyId, deviceId, a: AlertIn) {
      if (a.childId !== null) {
        const [have] =
          await sql`select 1 from app.child_profile where family_id = ${familyId} and id = ${a.childId}`;
        if (!have) return "refused";
      }
      const rows = await sql`
        insert into app.alert (family_id, child_id, device_id, category, severity, count, detail, words, dedupe_key,
          client_at)
        values (${familyId}, ${a.childId}, ${deviceId}, ${a.category}, ${a.severity}, ${a.count}, ${a.detail},
          ${a.words}, ${a.key}, ${new Date(a.clientAtMs)})
        on conflict (family_id, dedupe_key) do nothing
        returning id`;
      return rows.length === 1 ? "new" : "duplicate";
    },

    async listAlerts(familyId, sinceMs) {
      const rows = await sql`
        select id, child_id, device_id, category, severity, count, detail, words, dedupe_key, client_at, read_at
          from app.alert where family_id = ${familyId} and client_at >= ${new Date(sinceMs)}
         order by client_at desc, id limit 200`;
      return rows.map((r): AlertOut => ({
        id: r.id,
        childId: r.child_id,
        deviceId: r.device_id,
        category: r.category,
        severity: r.severity,
        count: r.count,
        detail: r.detail,
        words: r.words,
        key: r.dedupe_key,
        clientAtMs: (r.client_at as Date).getTime(),
        readAtMs: r.read_at ? (r.read_at as Date).getTime() : null,
      }));
    },

    async markAlertsRead(familyId, nowMs) {
      const rows = await sql`
        update app.alert set read_at = ${new Date(nowMs)}
         where family_id = ${familyId} and read_at is null returning id`;
      return rows.length;
    },

    async upsertPushToken(familyId, deviceId, token, platform) {
      await sql`
        insert into app.push_token (device_id, family_id, token, platform)
        values (${deviceId}, ${familyId}, ${token}, ${platform})
        on conflict (device_id) do update set token = excluded.token, platform = excluded.platform,
          family_id = excluded.family_id, updated_at = now()`;
    },

    async removePushToken(deviceId) {
      await sql`delete from app.push_token where device_id = ${deviceId}`;
    },

    async pushTokens(familyId) {
      const rows =
        await sql`select device_id, token, platform from app.push_token where family_id = ${familyId}`;
      return rows.map((r) => ({
        deviceId: r.device_id as string,
        token: r.token as string,
        platform: r.platform,
      }));
    },

    async getSettings(familyId) {
      const [r] = await sql`select rules, version from app.family_settings where family_id = ${familyId}`;
      return r ? { rules: r.rules as Record<string, unknown>, version: Number(r.version) } : null;
    },

    async putSettings(familyId, rules) {
      const [r] = await sql`
        insert into app.family_settings (family_id, rules)
        values (${familyId}, ${JSON.stringify(rules)}::text::jsonb)
        on conflict (family_id) do update set rules = excluded.rules, version = app.family_settings.version + 1,
          updated_at = now()
        returning version`;
      return Number(r.version);
    },

    async tutorLogOf(familyId, sinceMs, limit) {
      const rows = await sql`
        select created_at, child_ref, item_id, character_id, source, outcome, line
          from app.tutor_log where family_id = ${familyId} and created_at >= ${new Date(sinceMs)}
         order by created_at desc limit ${limit}`;
      return rows.map((r): TutorLogEntry => ({
        atMs: (r.created_at as Date).getTime(),
        childRef: r.child_ref,
        itemId: r.item_id,
        characterId: r.character_id,
        source: r.source,
        outcome: r.outcome,
        line: r.line,
      }));
    },
  };
}
