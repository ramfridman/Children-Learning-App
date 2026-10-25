-- M0: the `app` schema. It is NOT exposed by the Data API (see supabase/config.toml, [api].schemas),
-- and no client role (anon, authenticated, service_role) has any grant on it. Only the gateway role
-- `app_gateway`, used by Edge Functions over a direct Postgres connection, can reach these tables.
-- Row Level Security stays on for every table as a second layer.

create schema if not exists app;

revoke all on schema app from public;
revoke all on schema app from anon, authenticated, service_role;

-- The gateway role. NOLOGIN here; the owner turns it into a login role out of band
-- (a password never goes into Git): see docs/milestones/M0.md, task C-secrets.
do $$
begin
  if not exists (select 1 from pg_roles where rolname = 'app_gateway') then
    create role app_gateway nologin noinherit nosuperuser nocreatedb nocreaterole noreplication;
  end if;
end
$$;
grant app_gateway to postgres;
grant usage on schema app to app_gateway;

-- Nothing created in this schema is reachable by default.
alter default privileges in schema app revoke all on tables from public, anon, authenticated, service_role;
alter default privileges in schema app revoke all on sequences from public, anon, authenticated, service_role;
alter default privileges in schema app revoke all on functions from public, anon, authenticated, service_role;

-- ---------------------------------------------------------------------------------------------
-- Families and guardians
-- ---------------------------------------------------------------------------------------------
create table app.family (
  id uuid primary key default gen_random_uuid(),
  created_at timestamptz not null default now(),
  deleted_at timestamptz
);

-- v1: one family per guardian (user_id is the primary key).
create table app.guardian (
  user_id uuid primary key references auth.users (id) on delete cascade,
  family_id uuid not null references app.family (id) on delete cascade,
  created_at timestamptz not null default now()
);
create index guardian_family_idx on app.guardian (family_id);

-- ---------------------------------------------------------------------------------------------
-- Devices
-- ---------------------------------------------------------------------------------------------
create table app.device (
  id uuid primary key default gen_random_uuid(),
  family_id uuid not null references app.family (id) on delete cascade,
  role text not null check (role in ('parent', 'child')),
  -- P-256 public key as SubjectPublicKeyInfo DER (always 91 bytes).
  public_key bytea not null check (octet_length(public_key) = 91),
  platform text not null check (platform in ('android', 'ios')),
  attestation_kind text not null check (attestation_kind in ('key_attestation', 'app_attest', 'dev_allowlist')),
  -- What the server actually verified, e.g. 'strongbox', 'tee', 'secure_enclave', 'dev'.
  security_level text not null check (security_level in ('strongbox', 'tee', 'secure_enclave', 'dev')),
  app_version text check (app_version is null or char_length(app_version) <= 40),
  created_at timestamptz not null default now(),
  last_seen_at timestamptz,
  revoked_at timestamptz,
  revoked_reason text check (revoked_reason in ('parent', 'replaced', 'inactive', 'family_deleted', 'admin')),
  constraint device_revoked_consistent check ((revoked_at is null) = (revoked_reason is null)),
  constraint device_public_key_unique unique (public_key)
);
create index device_family_active_idx on app.device (family_id) where revoked_at is null;

-- At most 6 active devices per family, enforced in the database so concurrent enrolments cannot
-- slip past a count made in application code.
create function app.enforce_device_limit() returns trigger
language plpgsql
set search_path = pg_catalog, app
as $$
begin
  if new.revoked_at is null and (tg_op = 'INSERT' or old.revoked_at is not null) then
    perform pg_advisory_xact_lock(hashtextextended(new.family_id::text, 0));
    if (select count(*) from app.device
        where family_id = new.family_id and revoked_at is null and id <> new.id) >= 6 then
      raise exception 'device_limit' using errcode = 'P0001';
    end if;
  end if;
  return new;
end
$$;

create trigger device_limit_trg
  before insert or update of revoked_at on app.device
  for each row execute function app.enforce_device_limit();

-- ---------------------------------------------------------------------------------------------
-- Enrolment and pairing (short-lived)
-- ---------------------------------------------------------------------------------------------
create table app.enroll_challenge (
  id uuid primary key default gen_random_uuid(),
  challenge bytea not null unique check (octet_length(challenge) = 32),
  purpose text not null check (purpose in ('enroll', 'pair')),
  -- For first-device enrolment: the signed-in user who asked for it.
  user_id uuid references auth.users (id) on delete cascade,
  -- Keyed hash of the caller's IP address, for rate limiting only. Never the address itself.
  ip_hash bytea,
  -- Wrong pairing-code tries made with this challenge. The challenge dies after 5.
  failed_attempts integer not null default 0 check (failed_attempts >= 0),
  created_at timestamptz not null default now(),
  expires_at timestamptz not null,
  used_at timestamptz,
  constraint challenge_lifetime check (expires_at > created_at and expires_at <= created_at + interval '5 minutes')
);
create index enroll_challenge_expiry_idx on app.enroll_challenge (expires_at);

create table app.pairing_code (
  id uuid primary key default gen_random_uuid(),
  family_id uuid not null references app.family (id) on delete cascade,
  created_by_device uuid not null references app.device (id) on delete cascade,
  -- Keyed hash (HMAC with a server secret) of the 6-digit code.
  code_hash bytea not null check (octet_length(code_hash) = 32),
  created_at timestamptz not null default now(),
  expires_at timestamptz not null,
  used_at timestamptz,
  used_by_device uuid references app.device (id) on delete set null,
  burned_at timestamptz,
  constraint pairing_code_lifetime check (expires_at > created_at and expires_at <= created_at + interval '10 minutes')
);
-- A code can be looked up globally by the child device, so live codes must be unique.
create unique index pairing_code_live_hash_idx on app.pairing_code (code_hash)
  where used_at is null and burned_at is null;
create index pairing_code_family_idx on app.pairing_code (family_id);

create table app.request_nonce (
  device_id uuid not null references app.device (id) on delete cascade,
  nonce uuid not null,
  seen_at timestamptz not null default now(),
  primary key (device_id, nonce)
);
create index request_nonce_seen_idx on app.request_nonce (seen_at);

-- Emulators and simulators enrol only through this list, and only when the function setting
-- ALLOW_DEV_ENROLMENT is true (on in the local stack, off in the cloud project).
create table app.dev_device_allowlist (
  id uuid primary key default gen_random_uuid(),
  label text not null check (char_length(label) between 1 and 60),
  secret_hash bytea not null unique check (octet_length(secret_hash) = 32),
  created_at timestamptz not null default now(),
  expires_at timestamptz not null
);

-- ---------------------------------------------------------------------------------------------
-- Settings and counters
-- ---------------------------------------------------------------------------------------------
create table app.config (
  key text primary key check (key ~ '^[a-z0-9_.]{1,60}$'),
  value jsonb not null,
  updated_at timestamptz not null default now()
);

-- Rate limits and caps. `window_start` generalises the plan's `day` so hourly and per-minute
-- limits can share the table. Keys for IP-based limits are keyed hashes, never raw addresses.
create table app.usage_counter (
  scope text not null check (scope ~ '^[a-z0-9_.:-]{1,60}$'),
  key text not null check (char_length(key) between 1 and 120),
  window_start timestamptz not null,
  count integer not null default 0 check (count >= 0),
  cost_micro_usd bigint not null default 0 check (cost_micro_usd >= 0),
  primary key (scope, key, window_start)
);

-- ---------------------------------------------------------------------------------------------
-- Privileges: nobody but app_gateway
-- ---------------------------------------------------------------------------------------------
revoke all on all tables in schema app from public, anon, authenticated, service_role;
revoke all on all sequences in schema app from public, anon, authenticated, service_role;
revoke all on all functions in schema app from public, anon, authenticated, service_role;

grant select, insert, update on app.family to app_gateway;
grant select, insert on app.guardian to app_gateway;
grant select, insert, update on app.device to app_gateway;
grant select, insert, update, delete on app.enroll_challenge to app_gateway;
grant select, insert, update, delete on app.pairing_code to app_gateway;
grant select, insert, delete on app.request_nonce to app_gateway;
grant select on app.dev_device_allowlist to app_gateway;
grant select on app.config to app_gateway;
grant select, insert, update, delete on app.usage_counter to app_gateway;

-- ---------------------------------------------------------------------------------------------
-- Row Level Security: on for every table (second layer)
-- ---------------------------------------------------------------------------------------------
alter table app.family enable row level security;
alter table app.guardian enable row level security;
alter table app.device enable row level security;
alter table app.enroll_challenge enable row level security;
alter table app.pairing_code enable row level security;
alter table app.request_nonce enable row level security;
alter table app.dev_device_allowlist enable row level security;
alter table app.config enable row level security;
alter table app.usage_counter enable row level security;

-- The gateway role is trusted code that filters every query by the family id taken from the
-- verified token and device, so it is allowed through RLS.
create policy gateway_all on app.family for all to app_gateway using (true) with check (true);
create policy gateway_all on app.guardian for all to app_gateway using (true) with check (true);
create policy gateway_all on app.device for all to app_gateway using (true) with check (true);
create policy gateway_all on app.enroll_challenge for all to app_gateway using (true) with check (true);
create policy gateway_all on app.pairing_code for all to app_gateway using (true) with check (true);
create policy gateway_all on app.request_nonce for all to app_gateway using (true) with check (true);
create policy gateway_all on app.dev_device_allowlist for all to app_gateway using (true) with check (true);
create policy gateway_all on app.config for all to app_gateway using (true) with check (true);
create policy gateway_all on app.usage_counter for all to app_gateway using (true) with check (true);

-- Second layer for signed-in users, in case a table is ever exposed or granted by mistake:
-- a guardian can read only their own family's rows, and cannot write anything.
-- Tables without a policy for `authenticated` are invisible to it.
create policy guardian_reads_own_family on app.family for select to authenticated
  using (id in (select g.family_id from app.guardian g where g.user_id = auth.uid()));
create policy guardian_reads_own_row on app.guardian for select to authenticated
  using (user_id = auth.uid());
create policy guardian_reads_family_devices on app.device for select to authenticated
  using (family_id in (select g.family_id from app.guardian g where g.user_id = auth.uid()));
