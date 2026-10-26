-- M6: the server side of the AI tutor. Same rules as M0: every table lives in the closed `app` schema,
-- nobody but app_gateway has any privilege, RLS is on, and only the gateway functions touch the rows.

-- ---------------------------------------------------------------------------------------------
-- Published content: what the prompt is built from (never audio, never anything a device sends)
-- ---------------------------------------------------------------------------------------------
create table app.content_pack (
  pack_id text not null check (pack_id ~ '^[a-z0-9-]{3,41}$'),
  pack_version text not null check (pack_version ~ '^[0-9]{1,4}[.][0-9]{1,4}[.][0-9]{1,4}$'),
  manifest_sha256 text not null check (manifest_sha256 ~ '^[0-9a-f]{64}$'),
  published_at timestamptz not null default now(),
  primary key (pack_id, pack_version)
);

create table app.content_item (
  pack_id text not null,
  pack_version text not null,
  item_id text not null check (item_id ~ '^[a-z0-9][a-z0-9._-]{0,63}$'),
  revision integer not null check (revision between 1 and 9999),
  template text not null check (template ~ '^[a-z][a-z0-9_]{1,31}$'),
  band text not null check (band in ('A', 'B', 'C')),
  skill_ids text[] not null check (cardinality(skill_ids) between 1 and 10),
  llm_allowed boolean not null,
  -- What the child is meant to do, in the author's words (English), for the prompt.
  goal text not null check (char_length(goal) between 1 and 300),
  -- The authored question the child heard, with niqqud.
  prompt_text text not null check (char_length(prompt_text) between 1 and 400),
  -- [{id, value?, label?, misconception?, correct}]: the answer forms of the item.
  answers jsonb not null check (jsonb_typeof(answers) = 'array' and jsonb_array_length(answers) between 1 and 8),
  number_set integer[] not null default '{}' check (cardinality(number_set) <= 40),
  allowed_actions text[] not null default '{}' check (cardinality(allowed_actions) <= 12),
  -- The hint level before which the correct answer must not be revealed (1 to 3).
  hint_threshold smallint not null check (hint_threshold between 1 and 3),
  object_ids text[] not null default '{}' check (cardinality(object_ids) <= 40),
  primary key (pack_id, pack_version, item_id),
  foreign key (pack_id, pack_version) references app.content_pack (pack_id, pack_version) on delete cascade
);

create table app.misconception (
  pack_id text not null,
  pack_version text not null,
  tag text not null check (tag ~ '^M-[A-Z]{2,5}-[A-Z0-9]{2,12}$'),
  skill_ids text[] not null check (cardinality(skill_ids) between 1 and 10),
  -- What the child is probably thinking, in the author's words, for the prompt and the parent.
  description text not null check (char_length(description) between 1 and 300),
  primary key (pack_id, pack_version, tag),
  foreign key (pack_id, pack_version) references app.content_pack (pack_id, pack_version) on delete cascade
);

-- The characters that can speak: Nitzi and the family characters. `voice_id` stays null until the owner has chosen it.
create table app.family_character (
  character_id text primary key check (character_id ~ '^[a-z0-9-]{2,40}$'),
  name_he text not null check (char_length(name_he) between 1 and 40 and name_he ~ '^[א-תְ-ׇ ]+$'),
  gender text not null check (gender in ('m', 'f')),
  voice_id text check (voice_id ~ '^[A-Za-z0-9]{10,40}$'),
  personal boolean not null default true,
  updated_at timestamptz not null default now()
);

-- ---------------------------------------------------------------------------------------------
-- What the tutor said (30 days) and the lines already made (so they are never made twice)
-- ---------------------------------------------------------------------------------------------
create table app.tutor_log (
  id uuid primary key default gen_random_uuid(),
  created_at timestamptz not null default now(),
  family_id uuid not null references app.family (id) on delete cascade,
  child_ref text not null check (char_length(child_ref) between 1 and 64),
  session_ref text not null check (char_length(session_ref) between 1 and 64),
  pack_id text not null,
  pack_version text not null,
  item_id text not null,
  character_id text not null,
  -- live: made on the spot; cache: served from tutor_cache; prefetch: made ahead; rule: the server chose RuleTutor
  source text not null check (source in ('live', 'cache', 'prefetch', 'rule')),
  -- ok: a line was returned; the rest are the fixed reasons for RuleTutor
  outcome text not null check (outcome ~ '^[a-z_]{2,40}$'),
  line text check (char_length(line) <= 400),
  validator_ok boolean,
  validator_failures text[] not null default '{}',
  prompt_version text not null,
  total_ms integer check (total_ms >= 0),
  model_ms integer check (model_ms >= 0),
  voice_ms integer check (voice_ms >= 0),
  eleven_request_id text check (char_length(eleven_request_id) <= 80)
);
create index tutor_log_family_time on app.tutor_log (family_id, created_at desc);

create table app.tutor_cache (
  pack_id text not null,
  pack_version text not null,
  item_id text not null,
  -- The mistake: a misconception tag, or `default` for a wrong answer that has none.
  mistake text not null check (mistake ~ '^(default|M-[A-Z]{2,5}-[A-Z0-9]{2,12})$'),
  hint_level smallint not null check (hint_level between 0 and 3),
  band text not null check (band in ('A', 'B', 'C')),
  address_form text not null check (address_form in ('f', 'm', 'n')),
  character_id text not null,
  -- A new prompt or a new validator makes every older line unreachable.
  prompt_version text not null check (char_length(prompt_version) between 1 and 20),
  validator_version text not null check (char_length(validator_version) between 1 and 20),
  line text not null check (char_length(line) between 1 and 400),
  caption text check (char_length(caption) <= 400),
  next_action text not null check (next_action ~ '^[a-z_]{2,40}$'),
  highlight_targets text[] not null default '{}' check (cardinality(highlight_targets) <= 6),
  audio bytea check (octet_length(audio) <= 65536),
  audio_mime text check (audio_mime in ('audio/mpeg')),
  created_at timestamptz not null default now(),
  primary key (pack_id, pack_version, item_id, mistake, hint_level, band, address_form, character_id,
               prompt_version, validator_version),
  foreign key (pack_id, pack_version, item_id) references app.content_item (pack_id, pack_version, item_id)
    on delete cascade
);

-- ---------------------------------------------------------------------------------------------
-- Caps: one atomic call counts what a tutor request may use, in one round trip.
-- ---------------------------------------------------------------------------------------------
-- p_kind `turn` is a line the child will meet; `prefetch` is a line made ahead. Returns `ok`, or the name of the
-- first limit that is already reached (and then nothing is counted).
create function app.tutor_take(
  p_family uuid,
  p_child text,
  p_session text,
  p_kind text,
  p_session_cap integer,
  p_day_cap integer,
  p_prefetch_cap integer,
  p_cost_cap_micro bigint,
  p_now timestamptz
) returns text
language plpgsql
set search_path = pg_catalog, app
as $$
declare
  v_day timestamptz := date_trunc('day', p_now at time zone 'UTC') at time zone 'UTC';
  v_spent bigint;
  v_n integer;
begin
  if p_kind not in ('turn', 'prefetch') then
    raise exception 'bad kind';
  end if;

  select coalesce(sum(cost_micro_usd), 0) into v_spent
    from app.usage_counter
   where scope = 'tutor_cost' and key = p_family::text and window_start = v_day;
  if v_spent >= p_cost_cap_micro then
    return 'cost_cap';
  end if;

  if p_kind = 'prefetch' then
    insert into app.usage_counter (scope, key, window_start, count)
    values ('tutor_prefetch', left(p_session, 100), v_day, 1)
    on conflict (scope, key, window_start)
    do update set count = app.usage_counter.count + 1 where app.usage_counter.count < p_prefetch_cap
    returning count into v_n;
    if v_n is null then
      return 'prefetch_cap';
    end if;
    return 'ok';
  end if;

  insert into app.usage_counter (scope, key, window_start, count)
  values ('tutor_day', left(p_child, 100), v_day, 1)
  on conflict (scope, key, window_start)
  do update set count = app.usage_counter.count + 1 where app.usage_counter.count < p_day_cap
  returning count into v_n;
  if v_n is null then
    return 'day_cap';
  end if;

  v_n := null;
  insert into app.usage_counter (scope, key, window_start, count)
  values ('tutor_session', left(p_session, 100), v_day, 1)
  on conflict (scope, key, window_start)
  do update set count = app.usage_counter.count + 1 where app.usage_counter.count < p_session_cap
  returning count into v_n;
  if v_n is null then
    -- Give the day's slot back: a refused turn costs nothing.
    update app.usage_counter set count = count - 1
     where scope = 'tutor_day' and key = left(p_child, 100) and window_start = v_day;
    return 'session_cap';
  end if;
  return 'ok';
end
$$;

-- Adds what a generated line cost (millionths of a dollar) to the family's day.
create function app.tutor_cost_add(p_family uuid, p_micro bigint, p_now timestamptz) returns void
language sql
set search_path = pg_catalog, app
as $$
  insert into app.usage_counter (scope, key, window_start, cost_micro_usd)
  values ('tutor_cost', p_family::text, date_trunc('day', p_now at time zone 'UTC') at time zone 'UTC', greatest(p_micro, 0))
  on conflict (scope, key, window_start)
  do update set cost_micro_usd = app.usage_counter.cost_micro_usd + greatest(p_micro, 0)
$$;

-- ---------------------------------------------------------------------------------------------
-- Privileges, RLS, retention
-- ---------------------------------------------------------------------------------------------
revoke all on app.content_pack, app.content_item, app.misconception, app.family_character,
  app.tutor_log, app.tutor_cache from public, anon, authenticated, service_role;
revoke all on function app.tutor_take(uuid, text, text, text, integer, integer, integer, bigint, timestamptz)
  from public, anon, authenticated, service_role;
revoke all on function app.tutor_cost_add(uuid, bigint, timestamptz) from public, anon, authenticated, service_role;

grant select, insert, update, delete on app.content_pack, app.content_item, app.misconception to app_gateway;
grant select, insert, update on app.family_character to app_gateway;
grant select, insert on app.tutor_log to app_gateway;
grant select, insert, update, delete on app.tutor_cache to app_gateway;
grant execute on function app.tutor_take(uuid, text, text, text, integer, integer, integer, bigint, timestamptz)
  to app_gateway;
grant execute on function app.tutor_cost_add(uuid, bigint, timestamptz) to app_gateway;

alter table app.content_pack enable row level security;
alter table app.content_item enable row level security;
alter table app.misconception enable row level security;
alter table app.family_character enable row level security;
alter table app.tutor_log enable row level security;
alter table app.tutor_cache enable row level security;

create policy gateway_all on app.content_pack for all to app_gateway using (true) with check (true);
create policy gateway_all on app.content_item for all to app_gateway using (true) with check (true);
create policy gateway_all on app.misconception for all to app_gateway using (true) with check (true);
create policy gateway_all on app.family_character for all to app_gateway using (true) with check (true);
create policy gateway_all on app.tutor_log for all to app_gateway using (true) with check (true);
create policy gateway_all on app.tutor_cache for all to app_gateway using (true) with check (true);

-- A guardian may read their own family's tutor log (the parent screen of M7 reads it through a function; this is the
-- second layer, as for the other tables). Nothing else is readable by a signed-in user.
create policy guardian_reads_tutor_log on app.tutor_log for select to authenticated
  using (family_id in (select g.family_id from app.guardian g where g.user_id = auth.uid()));

-- The 30-day retention of the tutor log joins the clean-up job.
create or replace function app.purge_expired() returns void
language plpgsql
security definer
set search_path = pg_catalog, app
as $$
begin
  delete from app.request_nonce where seen_at < now() - interval '10 minutes';

  delete from app.enroll_challenge
    where expires_at < now() - interval '1 hour' or used_at < now() - interval '1 hour';
  delete from app.pairing_code
    where expires_at < now() - interval '1 hour'
       or used_at < now() - interval '1 hour'
       or burned_at < now() - interval '1 hour';

  delete from app.dev_device_allowlist where expires_at < now();
  delete from app.usage_counter where window_start < now() - interval '90 days';

  update app.device
    set revoked_at = now(), revoked_reason = 'inactive'
    where revoked_at is null and coalesce(last_seen_at, created_at) < now() - interval '90 days';
  delete from app.device where revoked_at < now() - interval '90 days';

  -- M6: what the tutor said is kept 30 days; lines already made are kept 90 days since last made.
  delete from app.tutor_log where created_at < now() - interval '30 days';
  delete from app.tutor_cache where created_at < now() - interval '90 days';
end
$$;

revoke all on function app.purge_expired() from public, anon, authenticated, service_role;
