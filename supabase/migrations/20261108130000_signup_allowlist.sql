-- SEC-SU-1: sign-up by invitation. A Supabase Auth "Before User Created" hook (a Postgres function) lets a new account
-- be made only for an address the owner approved. The list and the hook live in a schema of their own, `signup_gate`,
-- which the Data API never exposes (supabase/config.toml, [api].schemas lists only `public`; the live dashboard's
-- "Exposed schemas" must not list it either: docs/setup/open-signup.md). Only the Auth service role, `supabase_auth_admin`,
-- can run the hook. Nobody else, client roles included, can reach the schema, the list or the function.
--
-- What the hook knows: a fixed refusal ("this address is not invited yet") with a non-empty message (GoTrue reads an error
-- object with an empty message as no error), and no echo of the address. An address that already has an account is not
-- created again, so the hook is not asked: parents who exist keep signing in.
--
-- Adding and removing testers is plain SQL run by the owner's tool (tools/signup-allowlist.ps1); the addresses are data in
-- the live database only, never in this repository.

create schema if not exists signup_gate;

revoke all on schema signup_gate from public, anon, authenticated, service_role;
alter default privileges in schema signup_gate revoke all on tables from public, anon, authenticated, service_role;
alter default privileges in schema signup_gate revoke all on sequences from public, anon, authenticated, service_role;
alter default privileges in schema signup_gate revoke all on functions from public, anon, authenticated, service_role;

-- One form for every address: ASCII letters folded to lower case (by an explicit map, not by locale, so no lookalike letter
-- such as the Kelvin sign can fold into one), spaces, tabs and line ends trimmed from both ends. A plus-alias is a different
-- address, as written.
create function signup_gate.normalise_email(p_email text) returns text
language sql
immutable
strict
parallel safe
set search_path = pg_catalog
as $$
  select btrim(
    translate(p_email, 'ABCDEFGHIJKLMNOPQRSTUVWXYZ', 'abcdefghijklmnopqrstuvwxyz'),
    E' \t\r\n');
$$;

-- The owner's list. The table refuses a row that is not already in the one form and ASCII-shaped, so a typed capital letter
-- or a stray space can never sit in it unmatched.
create table signup_gate.approved_email (
  email text primary key,
  added_at timestamptz not null default now(),
  constraint approved_email_form check (
    email = signup_gate.normalise_email(email)
    and length(email) <= 254
    and email ~ '^[a-z0-9._%+-]{1,64}@[a-z0-9-]+(\.[a-z0-9-]+)+$'
  )
);
alter table signup_gate.approved_email enable row level security;
-- No policy on purpose: only the owner of the table (through the function below, which runs as that owner) reads it.

-- The hook. Runs as its owner, so `supabase_auth_admin` needs no right on the table at all, only the right to call this.
-- It ends in an explicit allow for a listed address and an explicit refusal for anything else (also an event without an
-- address, a malformed event, or no event).
create function signup_gate.before_user_created(event jsonb) returns jsonb
language plpgsql
stable
security definer
set search_path = pg_catalog
as $$
declare
  v_email text := signup_gate.normalise_email(event #>> '{user,email}');
begin
  if v_email is not null and exists (select 1 from signup_gate.approved_email a where a.email = v_email) then
    return '{}'::jsonb;
  end if;
  return jsonb_build_object(
    'error', jsonb_build_object('message', 'This address is not invited yet.', 'http_code', 403));
end;
$$;

revoke all on function signup_gate.normalise_email(text) from public, anon, authenticated, service_role;
revoke all on function signup_gate.before_user_created(jsonb) from public, anon, authenticated, service_role;

grant usage on schema signup_gate to supabase_auth_admin;
grant execute on function signup_gate.before_user_created(jsonb) to supabase_auth_admin;
