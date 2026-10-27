-- M7b: the children a family has, the log of what they did (with a server cursor), the alerts parents get, the tokens of
-- the parents' phones, the family's settings, and the record of children who were deleted. Everything is filtered by the
-- family id the gateway takes from the verified token and device; no client role can read any of it directly.

-- ---------------------------------------------------------------------------------------------
-- Children (the one personal text on the server is the nickname the parent chose)
-- ---------------------------------------------------------------------------------------------
create table app.child_profile (
  family_id uuid not null references app.family (id) on delete cascade,
  -- Random id made on the device (the same id the device and the tutor use for the child).
  id text not null check (id ~ '^[A-Za-z0-9-]{8,64}$'),
  nickname text not null check (char_length(nickname) between 1 and 24),
  avatar_id text not null check (avatar_id ~ '^[a-z0-9_-]{2,40}$'),
  companion_id text check (companion_id is null or companion_id ~ '^[a-z0-9-]{2,40}$'),
  address_form text not null check (address_form in ('f', 'm', 'n')),
  age_band smallint not null check (age_band between 0 and 2),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  primary key (family_id, id)
);

-- A child that was deleted: devices that pull this delete their local data, and the id can never come back.
create table app.deleted_child (
  family_id uuid not null references app.family (id) on delete cascade,
  child_id text not null check (child_id ~ '^[A-Za-z0-9-]{8,64}$'),
  deleted_at timestamptz not null default now(),
  primary key (family_id, child_id)
);

-- ---------------------------------------------------------------------------------------------
-- The log: what children did, in the order the server received it
-- ---------------------------------------------------------------------------------------------
create table app.event (
  -- The cursor: devices ask for everything after the last `seq` they saw. Device clocks never decide it.
  seq bigint generated always as identity primary key,
  id uuid not null,
  family_id uuid not null references app.family (id) on delete cascade,
  child_id text not null check (child_id ~ '^[A-Za-z0-9-]{8,64}$'),
  device_id uuid not null,
  client_at timestamptz not null,
  engine_version smallint not null check (engine_version between 1 and 1000),
  type text not null check (type in ('attempt', 'session')),
  -- Ids, numbers and fixed words only: never a name, audio or free text.
  payload jsonb not null check (jsonb_typeof(payload) = 'object' and pg_column_size(payload) <= 2048),
  received_at timestamptz not null default now(),
  constraint event_family_id_unique unique (family_id, id)
);
create index event_family_seq_idx on app.event (family_id, seq);
create index event_family_child_idx on app.event (family_id, child_id);

-- ---------------------------------------------------------------------------------------------
-- Alerts for the parents (30 days) and the tokens of the parents' phones
-- ---------------------------------------------------------------------------------------------
create table app.alert (
  id uuid primary key default gen_random_uuid(),
  family_id uuid not null references app.family (id) on delete cascade,
  -- Null for an alert about the device (someone at the parent gate).
  child_id text check (child_id is null or child_id ~ '^[A-Za-z0-9-]{8,64}$'),
  device_id uuid not null,
  category text not null check (
    category in ('pastLimit', 'restHours', 'gateAttempts', 'guessing', 'frustration', 'inappropriateWords',
                 'disclosure', 'absence')
  ),
  severity text not null check (severity in ('info', 'attention', 'important')),
  count integer not null default 0 check (count between 0 and 100000),
  detail text not null default '' check (char_length(detail) <= 80 and detail ~ '^[A-Za-z0-9._:=-]*$'),
  -- What the child said, only while the parent keeps the words (never more than 30 days with the alert).
  words text not null default '' check (char_length(words) <= 200),
  dedupe_key text not null check (char_length(dedupe_key) between 1 and 120),
  client_at timestamptz not null,
  created_at timestamptz not null default now(),
  read_at timestamptz,
  constraint alert_family_key_unique unique (family_id, dedupe_key)
);
create index alert_family_time_idx on app.alert (family_id, client_at desc);

create table app.push_token (
  device_id uuid primary key references app.device (id) on delete cascade,
  family_id uuid not null references app.family (id) on delete cascade,
  token text not null check (char_length(token) between 20 and 4096 and token ~ '^[A-Za-z0-9_:.-]+$'),
  platform text not null check (platform in ('android', 'ios')),
  updated_at timestamptz not null default now()
);
create index push_token_family_idx on app.push_token (family_id);

-- ---------------------------------------------------------------------------------------------
-- The family's settings: one document, the last write wins by this version (a server counter)
-- ---------------------------------------------------------------------------------------------
create table app.family_settings (
  family_id uuid primary key references app.family (id) on delete cascade,
  rules jsonb not null check (jsonb_typeof(rules) = 'object' and pg_column_size(rules) <= 4096),
  version bigint not null default 1,
  updated_at timestamptz not null default now()
);

-- ---------------------------------------------------------------------------------------------
-- Deleting a child: one transaction, every table, and a tombstone. Called only by the gateway.
-- ---------------------------------------------------------------------------------------------
create function app.delete_child(p_family uuid, p_child text) returns void
language plpgsql
security definer
set search_path = pg_catalog, app
as $$
begin
  delete from app.event where family_id = p_family and child_id = p_child;
  delete from app.alert where family_id = p_family and child_id = p_child;
  delete from app.tutor_log where family_id = p_family and child_ref = p_child;
  -- The tutor's daily count for this child (the key is the child's id).
  delete from app.usage_counter where scope = 'tutor_day' and key = left(p_child, 100);
  delete from app.child_profile where family_id = p_family and id = p_child;
  insert into app.deleted_child (family_id, child_id) values (p_family, p_child)
  on conflict (family_id, child_id) do nothing;
end
$$;

-- ---------------------------------------------------------------------------------------------
-- Privileges, RLS, retention
-- ---------------------------------------------------------------------------------------------
revoke all on app.child_profile, app.deleted_child, app.event, app.alert, app.push_token, app.family_settings
  from public, anon, authenticated, service_role;
revoke all on function app.delete_child(uuid, text) from public, anon, authenticated, service_role;

grant select, insert, update on app.child_profile to app_gateway;
grant select, insert on app.deleted_child to app_gateway;
grant select, insert on app.event to app_gateway;
grant select, insert, update on app.alert to app_gateway;
grant select, insert, update, delete on app.push_token to app_gateway;
grant select, insert, update on app.family_settings to app_gateway;
grant execute on function app.delete_child(uuid, text) to app_gateway;

alter table app.child_profile enable row level security;
alter table app.deleted_child enable row level security;
alter table app.event enable row level security;
alter table app.alert enable row level security;
alter table app.push_token enable row level security;
alter table app.family_settings enable row level security;

create policy gateway_all on app.child_profile for all to app_gateway using (true) with check (true);
create policy gateway_all on app.deleted_child for all to app_gateway using (true) with check (true);
create policy gateway_all on app.event for all to app_gateway using (true) with check (true);
create policy gateway_all on app.alert for all to app_gateway using (true) with check (true);
create policy gateway_all on app.push_token for all to app_gateway using (true) with check (true);
create policy gateway_all on app.family_settings for all to app_gateway using (true) with check (true);

-- Retention joins the clean-up job: alerts 30 days, tombstones a year (an id only).
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

  delete from app.tutor_log where created_at < now() - interval '30 days';
  delete from app.tutor_cache where created_at < now() - interval '90 days';

  -- M7: alerts (and the words in them) are kept 30 days; a tombstone is only an id and is kept a year.
  delete from app.alert where client_at < now() - interval '30 days';
  delete from app.deleted_child where deleted_at < now() - interval '365 days';
end
$$;

revoke all on function app.purge_expired() from public, anon, authenticated, service_role;
