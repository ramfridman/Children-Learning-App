-- Cross-family and signed-out access. Even if a table were granted by mistake, RLS must still
-- keep family A out of family B's rows. Everything runs in one transaction that is rolled back.
begin;
create extension if not exists pgtap with schema extensions;
select * from no_plan();

-- Counts the rows a statement changes, run with the caller's privileges (so RLS applies).
-- It is created inside this transaction and disappears on rollback.
create function public.test_rows_changed(q text) returns int language plpgsql as $$
declare n int;
begin execute q; get diagnostics n = row_count; return n; end
$$;

-- ---- Fixtures (as the table owner) ---------------------------------------------------------
create function pg_temp.fake_spki(n int) returns bytea language sql immutable as $$
  select substring(sha256((n::text)::bytea) || sha256(((n + 1000)::text)::bytea) || sha256(((n + 2000)::text)::bytea) from 1 for 91)
$$;

insert into auth.users (id, email) values
  ('aaaaaaaa-0000-4000-8000-000000000001', 'a@example.test'),
  ('bbbbbbbb-0000-4000-8000-000000000001', 'b@example.test');

insert into app.family (id) values
  ('a1a1a1a1-0000-4000-8000-000000000001'),
  ('b1b1b1b1-0000-4000-8000-000000000001');

insert into app.guardian (user_id, family_id) values
  ('aaaaaaaa-0000-4000-8000-000000000001', 'a1a1a1a1-0000-4000-8000-000000000001'),
  ('bbbbbbbb-0000-4000-8000-000000000001', 'b1b1b1b1-0000-4000-8000-000000000001');

insert into app.device (id, family_id, role, public_key, platform, attestation_kind, security_level) values
  ('a2a2a2a2-0000-4000-8000-000000000001', 'a1a1a1a1-0000-4000-8000-000000000001', 'parent', pg_temp.fake_spki(1), 'android', 'key_attestation', 'tee'),
  ('a2a2a2a2-0000-4000-8000-000000000002', 'a1a1a1a1-0000-4000-8000-000000000001', 'child',  pg_temp.fake_spki(2), 'android', 'key_attestation', 'tee'),
  ('b2b2b2b2-0000-4000-8000-000000000001', 'b1b1b1b1-0000-4000-8000-000000000001', 'parent', pg_temp.fake_spki(3), 'ios', 'app_attest', 'secure_enclave');

insert into app.enroll_challenge (challenge, purpose, user_id, expires_at) values
  (sha256('c1'::bytea), 'enroll', 'aaaaaaaa-0000-4000-8000-000000000001', now() + interval '5 minutes'),
  (sha256('c2'::bytea), 'enroll', 'bbbbbbbb-0000-4000-8000-000000000001', now() + interval '5 minutes');
insert into app.pairing_code (family_id, created_by_device, code_hash, expires_at) values
  ('a1a1a1a1-0000-4000-8000-000000000001', 'a2a2a2a2-0000-4000-8000-000000000001', sha256('p1'::bytea), now() + interval '10 minutes'),
  ('b1b1b1b1-0000-4000-8000-000000000001', 'b2b2b2b2-0000-4000-8000-000000000001', sha256('p2'::bytea), now() + interval '10 minutes');
insert into app.request_nonce (device_id, nonce) values
  ('a2a2a2a2-0000-4000-8000-000000000001', 'cccccccc-0000-4000-8000-000000000001'),
  ('b2b2b2b2-0000-4000-8000-000000000001', 'cccccccc-0000-4000-8000-000000000002');
insert into app.dev_device_allowlist (label, secret_hash, expires_at) values ('emulator', sha256('d1'::bytea), now() + interval '1 day');
insert into app.config (key, value) values ('tutor_enabled', 'true');
insert into app.usage_counter (scope, key, window_start, count) values ('enroll_challenge', 'family-a', date_trunc('hour', now()), 1);

-- Deliberately grant everything to the client roles. RLS is the only thing left in the way.
grant usage on schema app to anon, authenticated;
grant select, insert, update, delete on all tables in schema app to anon, authenticated;

-- ---- Signed in as guardian A ----------------------------------------------------------------
set local role authenticated;
set local request.jwt.claims = '{"sub": "aaaaaaaa-0000-4000-8000-000000000001", "role": "authenticated"}';

select is((select count(*)::int from app.family), 1, 'guardian A sees exactly one family');
select is((select count(*)::int from app.family where id = 'b1b1b1b1-0000-4000-8000-000000000001'), 0, 'guardian A cannot read family B');
select is((select count(*)::int from app.guardian), 1, 'guardian A sees only their own guardian row');
select is((select count(*)::int from app.device), 2, 'guardian A sees only family A devices');
select is((select count(*)::int from app.device where family_id = 'b1b1b1b1-0000-4000-8000-000000000001'), 0, 'guardian A cannot read family B devices');

select is((select count(*)::int from app.enroll_challenge), 0, 'enroll_challenge is invisible to guardians');
select is((select count(*)::int from app.pairing_code), 0, 'pairing_code is invisible to guardians');
select is((select count(*)::int from app.request_nonce), 0, 'request_nonce is invisible to guardians');
select is((select count(*)::int from app.dev_device_allowlist), 0, 'dev_device_allowlist is invisible to guardians');
select is((select count(*)::int from app.config), 0, 'config is invisible to guardians');
select is((select count(*)::int from app.usage_counter), 0, 'usage_counter is invisible to guardians');

-- Writes: no policy allows any, so every write fails or touches no row.
select is(public.test_rows_changed($q$update app.device set last_seen_at = now() where family_id = 'b1b1b1b1-0000-4000-8000-000000000001'$q$), 0, 'guardian A cannot update family B devices');
select is(public.test_rows_changed($q$update app.device set last_seen_at = now() where family_id = 'a1a1a1a1-0000-4000-8000-000000000001'$q$), 0, 'guardian A cannot update even their own family devices');
select is(public.test_rows_changed($q$delete from app.device where family_id = 'b1b1b1b1-0000-4000-8000-000000000001'$q$), 0, 'guardian A cannot delete family B devices');
select is(public.test_rows_changed($q$delete from app.device where family_id = 'a1a1a1a1-0000-4000-8000-000000000001'$q$), 0, 'guardian A cannot delete their own family devices');
select is(public.test_rows_changed($q$update app.family set deleted_at = now()$q$), 0, 'guardian A cannot update families');
select is(public.test_rows_changed($q$delete from app.guardian$q$), 0, 'guardian A cannot delete guardian rows');
select throws_ok($$insert into app.device (family_id, role, public_key, platform, attestation_kind, security_level)
  values ('b1b1b1b1-0000-4000-8000-000000000001', 'parent', decode(repeat('ab', 91), 'hex'), 'android', 'key_attestation', 'tee')$$,
  '42501', null, 'guardian A cannot add a device to family B');
select throws_ok($$insert into app.device (family_id, role, public_key, platform, attestation_kind, security_level)
  values ('a1a1a1a1-0000-4000-8000-000000000001', 'parent', decode(repeat('cd', 91), 'hex'), 'android', 'key_attestation', 'tee')$$,
  '42501', null, 'guardian A cannot add a device even to their own family');
select throws_ok($$insert into app.family (id) values (gen_random_uuid())$$, '42501', null, 'guardian A cannot create families');
select throws_ok($$insert into app.guardian (user_id, family_id) values ('aaaaaaaa-0000-4000-8000-000000000001', 'b1b1b1b1-0000-4000-8000-000000000001')$$,
  '42501', null, 'guardian A cannot make themselves a guardian of family B');
select throws_ok($$insert into app.config (key, value) values ('x', '1')$$, '42501', null, 'guardian A cannot write config');
select throws_ok($$insert into app.usage_counter (scope, key, window_start) values ('x', 'y', now())$$, '42501', null, 'guardian A cannot write usage counters');
select throws_ok($$insert into app.pairing_code (family_id, created_by_device, code_hash, expires_at)
  values ('a1a1a1a1-0000-4000-8000-000000000001', 'a2a2a2a2-0000-4000-8000-000000000001', sha256('x'::bytea), now() + interval '1 minute')$$,
  '42501', null, 'guardian A cannot create pairing codes directly');

-- ---- Signed in as guardian B (mirror check) -------------------------------------------------
set local request.jwt.claims = '{"sub": "bbbbbbbb-0000-4000-8000-000000000001", "role": "authenticated"}';
select is((select count(*)::int from app.device where family_id = 'a1a1a1a1-0000-4000-8000-000000000001'), 0, 'guardian B cannot read family A devices');
select is((select count(*)::int from app.device), 1, 'guardian B sees only their own device');

-- ---- A signed-in user who is not a guardian of anything ---------------------------------------
set local request.jwt.claims = '{"sub": "dddddddd-0000-4000-8000-000000000001", "role": "authenticated"}';
select is((select count(*)::int from app.family), 0, 'a stranger sees no families');
select is((select count(*)::int from app.device), 0, 'a stranger sees no devices');

-- ---- Signed out (anon) ------------------------------------------------------------------------
reset role;
set local role anon;
set local request.jwt.claims = '{}';
select is((select count(*)::int from app.family), 0, 'anon sees no families');
select is((select count(*)::int from app.guardian), 0, 'anon sees no guardians');
select is((select count(*)::int from app.device), 0, 'anon sees no devices');
select is((select count(*)::int from app.enroll_challenge), 0, 'anon sees no challenges');
select is((select count(*)::int from app.pairing_code), 0, 'anon sees no pairing codes');
select is((select count(*)::int from app.request_nonce), 0, 'anon sees no nonces');
select is((select count(*)::int from app.dev_device_allowlist), 0, 'anon sees no allowlist');
select is((select count(*)::int from app.config), 0, 'anon sees no config');
select is((select count(*)::int from app.usage_counter), 0, 'anon sees no usage counters');
select is(public.test_rows_changed($q$update app.device set last_seen_at = now()$q$), 0, 'anon cannot update devices');
select is(public.test_rows_changed($q$delete from app.family$q$), 0, 'anon cannot delete families');
select throws_ok($$insert into app.family (id) values (gen_random_uuid())$$, '42501', null, 'anon cannot create families');
select throws_ok($$insert into app.enroll_challenge (challenge, purpose, expires_at) values (sha256('z'::bytea), 'pair', now() + interval '1 minute')$$,
  '42501', null, 'anon cannot create challenges');

-- ---- The gateway role works, within its grants ------------------------------------------------
reset role;
-- Test-only: let the gateway role call pgTAP helpers. The real gateway needs neither.
grant usage on schema extensions to app_gateway;
set local search_path = public, extensions;
set local role app_gateway;
select is((select count(*)::int from app.device), 3, 'app_gateway can read devices across families (it filters in code)');
select lives_ok($$update app.device set last_seen_at = now() where id = 'a2a2a2a2-0000-4000-8000-000000000001'$$, 'app_gateway can update last_seen_at');
select throws_ok($$delete from app.device where id = 'a2a2a2a2-0000-4000-8000-000000000001'$$, '42501', null, 'app_gateway cannot delete devices');
select throws_ok($$insert into app.config (key, value) values ('y', '1')$$, '42501', null, 'app_gateway cannot write config');
select throws_ok($$select count(*) from auth.users$$, '42501', null, 'app_gateway cannot read auth.users');

reset role;
select * from finish();
rollback;
