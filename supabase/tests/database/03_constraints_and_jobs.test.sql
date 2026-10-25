-- Device limit, uniqueness, short lifetimes and the clean-up job.
begin;
create extension if not exists pgtap with schema extensions;
select * from no_plan();

create function pg_temp.fake_spki(n int) returns bytea language sql immutable as $$
  select substring(sha256((n::text)::bytea) || sha256(((n + 1000)::text)::bytea) || sha256(((n + 2000)::text)::bytea) from 1 for 91)
$$;

insert into app.family (id) values ('a1a1a1a1-0000-4000-8000-000000000001'), ('b1b1b1b1-0000-4000-8000-000000000001');

-- ---- At most 6 active devices per family ----------------------------------------------------
insert into app.device (family_id, role, public_key, platform, attestation_kind, security_level)
select 'a1a1a1a1-0000-4000-8000-000000000001', case when n = 1 then 'parent' else 'child' end,
       pg_temp.fake_spki(n), 'android', 'key_attestation', 'tee'
from generate_series(1, 6) as n;

select is((select count(*)::int from app.device where family_id = 'a1a1a1a1-0000-4000-8000-000000000001' and revoked_at is null), 6, 'six devices enrol');

select throws_ok($$insert into app.device (family_id, role, public_key, platform, attestation_kind, security_level)
  values ('a1a1a1a1-0000-4000-8000-000000000001', 'child', pg_temp.fake_spki(7), 'android', 'key_attestation', 'tee')$$,
  'P0001', 'device_limit', 'a seventh active device is refused');

select lives_ok($$insert into app.device (family_id, role, public_key, platform, attestation_kind, security_level)
  values ('b1b1b1b1-0000-4000-8000-000000000001', 'parent', pg_temp.fake_spki(8), 'ios', 'app_attest', 'secure_enclave')$$,
  'the limit is per family');

update app.device set revoked_at = now(), revoked_reason = 'replaced'
  where public_key = pg_temp.fake_spki(6);

select lives_ok($$insert into app.device (family_id, role, public_key, platform, attestation_kind, security_level)
  values ('a1a1a1a1-0000-4000-8000-000000000001', 'child', pg_temp.fake_spki(7), 'android', 'key_attestation', 'tee')$$,
  'revoking a device frees a slot (replace this device)');

select throws_ok($$update app.device set revoked_at = null, revoked_reason = null where public_key = pg_temp.fake_spki(6)$$,
  'P0001', 'device_limit', 'un-revoking cannot exceed the limit either');

-- ---- Column rules ---------------------------------------------------------------------------
select throws_ok($$insert into app.device (family_id, role, public_key, platform, attestation_kind, security_level)
  values ('b1b1b1b1-0000-4000-8000-000000000001', 'child', pg_temp.fake_spki(1), 'android', 'key_attestation', 'tee')$$,
  '23505', null, 'a public key cannot be registered twice');
select throws_ok($$insert into app.device (family_id, role, public_key, platform, attestation_kind, security_level)
  values ('b1b1b1b1-0000-4000-8000-000000000001', 'admin', pg_temp.fake_spki(20), 'android', 'key_attestation', 'tee')$$,
  '23514', null, 'only parent and child roles exist');
select throws_ok($$insert into app.device (family_id, role, public_key, platform, attestation_kind, security_level)
  values ('b1b1b1b1-0000-4000-8000-000000000001', 'child', decode('abcd', 'hex'), 'android', 'key_attestation', 'tee')$$,
  '23514', null, 'a public key must be 91 bytes of SPKI');
select throws_ok($$update app.device set revoked_at = now() where public_key = pg_temp.fake_spki(1)$$,
  '23514', null, 'a revoked device must carry a reason');

-- ---- Challenges and pairing codes have short lives -----------------------------------------
select throws_ok($$insert into app.enroll_challenge (challenge, purpose, expires_at)
  values (sha256('long'::bytea), 'enroll', now() + interval '6 minutes')$$, '23514', null, 'a challenge cannot live longer than 5 minutes');
select throws_ok($$insert into app.enroll_challenge (challenge, purpose, expires_at)
  values (decode('abcd', 'hex'), 'enroll', now() + interval '1 minute')$$, '23514', null, 'a challenge must be exactly 32 bytes');
select lives_ok($$insert into app.enroll_challenge (challenge, purpose, expires_at)
  values (sha256('ok'::bytea), 'pair', now() + interval '5 minutes')$$, 'a 5-minute challenge is accepted');
select throws_ok($$insert into app.enroll_challenge (challenge, purpose, expires_at)
  values (sha256('ok'::bytea), 'pair', now() + interval '5 minutes')$$, '23505', null, 'a challenge value cannot repeat');

select lives_ok($$insert into app.pairing_code (family_id, created_by_device, code_hash, expires_at)
  select family_id, id, sha256('code1'::bytea), now() + interval '10 minutes' from app.device where public_key = pg_temp.fake_spki(1)$$,
  'a 10-minute pairing code is accepted');
select throws_ok($$insert into app.pairing_code (family_id, created_by_device, code_hash, expires_at)
  select family_id, id, sha256('code1'::bytea), now() + interval '10 minutes' from app.device where public_key = pg_temp.fake_spki(2)$$,
  '23505', null, 'two live pairing codes cannot share a hash');
select throws_ok($$insert into app.pairing_code (family_id, created_by_device, code_hash, expires_at)
  select family_id, id, sha256('code2'::bytea), now() + interval '11 minutes' from app.device where public_key = pg_temp.fake_spki(1)$$,
  '23514', null, 'a pairing code cannot live longer than 10 minutes');

update app.pairing_code set used_at = now() where code_hash = sha256('code1'::bytea);
select lives_ok($$insert into app.pairing_code (family_id, created_by_device, code_hash, expires_at)
  select family_id, id, sha256('code1'::bytea), now() + interval '10 minutes' from app.device where public_key = pg_temp.fake_spki(2)$$,
  'a used code hash can be issued again later');

-- ---- Nonces: unique per device ------------------------------------------------------------
insert into app.request_nonce (device_id, nonce)
  select id, 'cccccccc-0000-4000-8000-000000000001' from app.device where public_key = pg_temp.fake_spki(1);
select throws_ok($$insert into app.request_nonce (device_id, nonce)
  select id, 'cccccccc-0000-4000-8000-000000000001' from app.device where public_key = pg_temp.fake_spki(1)$$,
  '23505', null, 'a repeated nonce for the same device is refused');
select lives_ok($$insert into app.request_nonce (device_id, nonce)
  select id, 'cccccccc-0000-4000-8000-000000000001' from app.device where public_key = pg_temp.fake_spki(2)$$,
  'the same nonce on another device is a different row');

-- ---- The clean-up job ------------------------------------------------------------------------
update app.request_nonce set seen_at = now() - interval '11 minutes'
  where device_id = (select id from app.device where public_key = pg_temp.fake_spki(1));
update app.device set last_seen_at = now() - interval '91 days' where public_key = pg_temp.fake_spki(3);
update app.device set created_at = now() - interval '200 days', revoked_at = now() - interval '100 days', revoked_reason = 'parent'
  where public_key = pg_temp.fake_spki(4);

select app.purge_expired();

select is((select count(*)::int from app.request_nonce), 1, 'nonces older than 10 minutes are purged');
select is((select revoked_reason from app.device where public_key = pg_temp.fake_spki(3)), 'inactive', 'a device unseen for 90 days is revoked');
select is((select count(*)::int from app.device where public_key = pg_temp.fake_spki(4)), 0, 'devices revoked more than 90 days ago are deleted');
select ok(exists (select 1 from cron.job where jobname = 'app-purge-expired'), 'the clean-up job is scheduled');

select * from finish();
rollback;
