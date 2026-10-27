-- M7b: the tables of the parent area hold only what they should, their limits hold, deleting a child leaves nothing of
-- that child anywhere, and the clean-up job drops old alerts.
begin;
create extension if not exists pgtap with schema extensions;
select * from no_plan();

create function pg_temp.fake_spki(n int) returns bytea language sql immutable as $$
  select substring(sha256((n::text)::bytea) || sha256(((n + 1000)::text)::bytea) || sha256(((n + 2000)::text)::bytea) from 1 for 91)
$$;

insert into app.family (id) values
  ('d1d1d1d1-0000-4000-8000-000000000001'),
  ('d1d1d1d1-0000-4000-8000-000000000002');
insert into app.device (id, family_id, role, public_key, platform, attestation_kind, security_level) values
  ('d2d2d2d2-0000-4000-8000-000000000001', 'd1d1d1d1-0000-4000-8000-000000000001', 'parent', pg_temp.fake_spki(11), 'android', 'key_attestation', 'tee');

-- ---- children --------------------------------------------------------------------------------
select lives_ok($$insert into app.child_profile (family_id, id, nickname, avatar_id, address_form, age_band)
  values ('d1d1d1d1-0000-4000-8000-000000000001', 'child-aaaa-0001', 'נועה', 'avatar-noa', 'f', 1)$$,
  'a child with a nickname can be saved');
select throws_ok($$insert into app.child_profile (family_id, id, nickname, avatar_id, address_form, age_band)
  values ('d1d1d1d1-0000-4000-8000-000000000001', 'child-aaaa-0002', repeat('א', 25), 'avatar-noa', 'f', 1)$$,
  '23514', null, 'a nickname over 24 characters is refused');
select throws_ok($$insert into app.child_profile (family_id, id, nickname, avatar_id, address_form, age_band)
  values ('d1d1d1d1-0000-4000-8000-000000000001', 'x', 'נועה', 'avatar-noa', 'f', 1)$$,
  '23514', null, 'a child id that is too short is refused');
select throws_ok($$insert into app.child_profile (family_id, id, nickname, avatar_id, address_form, age_band)
  values ('d1d1d1d1-0000-4000-8000-000000000001', 'child-aaaa-0003', 'נועה', 'avatar-noa', 'x', 1)$$,
  '23514', null, 'an address form must be f, m or n');
select throws_ok($$insert into app.child_profile (family_id, id, nickname, avatar_id, address_form, age_band)
  values ('d1d1d1d1-0000-4000-8000-000000000001', 'child-aaaa-0003', 'נועה', 'avatar-noa', 'f', 3)$$,
  '23514', null, 'an age band must be 0, 1 or 2');

-- ---- the log ---------------------------------------------------------------------------------
select lives_ok($$insert into app.event (id, family_id, child_id, device_id, client_at, engine_version, type, payload)
  values ('e1e1e1e1-0000-4000-8000-000000000001', 'd1d1d1d1-0000-4000-8000-000000000001', 'child-aaaa-0001',
          'd2d2d2d2-0000-4000-8000-000000000001', now(), 1, 'attempt', '{"activity_id":"count.butterflies.3"}')$$,
  'an event can be logged');
select throws_ok($$insert into app.event (id, family_id, child_id, device_id, client_at, engine_version, type, payload)
  values ('e1e1e1e1-0000-4000-8000-000000000001', 'd1d1d1d1-0000-4000-8000-000000000001', 'child-aaaa-0001',
          'd2d2d2d2-0000-4000-8000-000000000001', now(), 1, 'attempt', '{}')$$,
  '23505', null, 'the same event twice is refused (a retry is harmless)');
select throws_ok($$insert into app.event (id, family_id, child_id, device_id, client_at, engine_version, type, payload)
  values ('e1e1e1e1-0000-4000-8000-000000000002', 'd1d1d1d1-0000-4000-8000-000000000001', 'child-aaaa-0001',
          'd2d2d2d2-0000-4000-8000-000000000001', now(), 1, 'reward', '{}')$$,
  '23514', null, 'an unknown event type is refused');
select throws_ok($$insert into app.event (id, family_id, child_id, device_id, client_at, engine_version, type, payload)
  values ('e1e1e1e1-0000-4000-8000-000000000003', 'd1d1d1d1-0000-4000-8000-000000000001', 'child-aaaa-0001',
          'd2d2d2d2-0000-4000-8000-000000000001', now(), 1, 'attempt', '[1]')$$,
  '23514', null, 'a payload that is not an object is refused');
select throws_ok($$insert into app.event (id, family_id, child_id, device_id, client_at, engine_version, type, payload)
  values ('e1e1e1e1-0000-4000-8000-000000000004', 'd1d1d1d1-0000-4000-8000-000000000001', 'child-aaaa-0001',
          'd2d2d2d2-0000-4000-8000-000000000001', now(), 1, 'attempt', jsonb_build_object('x', repeat('a', 3000)))$$,
  '23514', null, 'a payload over 2 KB is refused');
select lives_ok($$insert into app.event (id, family_id, child_id, device_id, client_at, engine_version, type, payload)
  values ('e1e1e1e1-0000-4000-8000-000000000005', 'd1d1d1d1-0000-4000-8000-000000000001', 'child-aaaa-0001',
          'd2d2d2d2-0000-4000-8000-000000000001', now(), 1, 'session', '{"plan":"lesson:butterflies"}')$$,
  'a session event can be logged');
select ok((select max(seq) from app.event) > (select min(seq) from app.event), 'the server numbers events in order');

-- ---- alerts and push tokens --------------------------------------------------------------------
select lives_ok($$insert into app.alert (family_id, child_id, device_id, category, severity, count, detail, words, dedupe_key, client_at)
  values ('d1d1d1d1-0000-4000-8000-000000000001', 'child-aaaa-0001', 'd2d2d2d2-0000-4000-8000-000000000001',
          'inappropriateWords', 'attention', 0, '', 'חרא', 'words:child-aaaa-0001:1', now())$$,
  'an alert can be saved, with the words the parent chose to keep');
select throws_ok($$insert into app.alert (family_id, child_id, device_id, category, severity, dedupe_key, client_at)
  values ('d1d1d1d1-0000-4000-8000-000000000001', 'child-aaaa-0001', 'd2d2d2d2-0000-4000-8000-000000000001',
          'inappropriateWords', 'attention', 'words:child-aaaa-0001:1', now())$$,
  '23505', null, 'the same alert twice is refused');
select throws_ok($$insert into app.alert (family_id, child_id, device_id, category, severity, dedupe_key, client_at)
  values ('d1d1d1d1-0000-4000-8000-000000000001', 'child-aaaa-0001', 'd2d2d2d2-0000-4000-8000-000000000001',
          'shouting', 'attention', 'k2', now())$$,
  '23514', null, 'an unknown category is refused');
select throws_ok($$insert into app.alert (family_id, child_id, device_id, category, severity, detail, dedupe_key, client_at)
  values ('d1d1d1d1-0000-4000-8000-000000000001', 'child-aaaa-0001', 'd2d2d2d2-0000-4000-8000-000000000001',
          'guessing', 'attention', 'free text with spaces', 'k3', now())$$,
  '23514', null, 'the detail is fixed words only: no spaces, no free text');
select lives_ok($$insert into app.alert (family_id, device_id, category, severity, count, dedupe_key, client_at)
  values ('d1d1d1d1-0000-4000-8000-000000000001', 'd2d2d2d2-0000-4000-8000-000000000001',
          'gateAttempts', 'attention', 3, 'gate:1', now())$$,
  'an alert about the device has no child');
select lives_ok($$insert into app.push_token (device_id, family_id, token, platform)
  values ('d2d2d2d2-0000-4000-8000-000000000001', 'd1d1d1d1-0000-4000-8000-000000000001', repeat('a', 40), 'android')$$,
  'a parent phone can register a push token');
select throws_ok($$update app.push_token set token = 'has spaces in it, which no token has'$$,
  '23514', null, 'a token is plain characters only');

-- ---- settings ----------------------------------------------------------------------------------
select lives_ok($$insert into app.family_settings (family_id, rules)
  values ('d1d1d1d1-0000-4000-8000-000000000001', '{"restOn":true}')$$, 'a family has one settings document');
select throws_ok($$insert into app.family_settings (family_id, rules)
  values ('d1d1d1d1-0000-4000-8000-000000000002', '[1]')$$, '23514', null, 'settings are an object');

-- ---- deleting a child leaves nothing of that child --------------------------------------------
insert into app.child_profile (family_id, id, nickname, avatar_id, address_form, age_band)
values ('d1d1d1d1-0000-4000-8000-000000000001', 'child-bbbb-0002', 'דני', 'avatar-dani', 'm', 0);
insert into app.event (id, family_id, child_id, device_id, client_at, engine_version, type, payload)
values ('e1e1e1e1-0000-4000-8000-000000000011', 'd1d1d1d1-0000-4000-8000-000000000001', 'child-bbbb-0002',
        'd2d2d2d2-0000-4000-8000-000000000001', now(), 1, 'attempt', '{"activity_id":"x"}');
insert into app.alert (family_id, child_id, device_id, category, severity, dedupe_key, client_at)
values ('d1d1d1d1-0000-4000-8000-000000000001', 'child-bbbb-0002', 'd2d2d2d2-0000-4000-8000-000000000001',
        'frustration', 'attention', 'upset:2', now());
insert into app.tutor_log (family_id, child_ref, session_ref, pack_id, pack_version, item_id, character_id, source,
  outcome, prompt_version)
values ('d1d1d1d1-0000-4000-8000-000000000001', 'child-bbbb-0002', 'sess-0000-0001', 'starter', '0.2.0', 'x', 'nitzi',
        'live', 'ok', 'p4');
insert into app.usage_counter (scope, key, window_start, count)
values ('tutor_day', 'child-bbbb-0002', date_trunc('day', now()), 3);

select lives_ok($$select app.delete_child('d1d1d1d1-0000-4000-8000-000000000001', 'child-bbbb-0002')$$, 'a child can be deleted');
select is((select count(*)::int from app.child_profile where id = 'child-bbbb-0002'), 0, 'no profile is left');
select is((select count(*)::int from app.event where child_id = 'child-bbbb-0002'), 0, 'no events are left');
select is((select count(*)::int from app.alert where child_id = 'child-bbbb-0002'), 0, 'no alerts are left');
select is((select count(*)::int from app.tutor_log where child_ref = 'child-bbbb-0002'), 0, 'no tutor log is left');
select is((select count(*)::int from app.usage_counter where key = 'child-bbbb-0002'), 0, 'no counters are left');
select is((select count(*)::int from app.deleted_child where child_id = 'child-bbbb-0002'), 1, 'one tombstone says it was deleted');
select is((select count(*)::int from app.event where child_id = 'child-aaaa-0001'), 2, 'the other child keeps everything');
select is((select count(*)::int from app.child_profile where id = 'child-aaaa-0001'), 1, 'and the profile');
select lives_ok($$select app.delete_child('d1d1d1d1-0000-4000-8000-000000000001', 'child-bbbb-0002')$$, 'deleting twice is harmless');
select is((select count(*)::int from app.deleted_child where child_id = 'child-bbbb-0002'), 1, 'and still one tombstone');

-- ---- who may touch what -----------------------------------------------------------------------
select ok(not has_table_privilege('app_gateway', 'app.event', 'update'), 'the gateway cannot rewrite the log');
select ok(not has_table_privilege('app_gateway', 'app.event', 'delete'), 'nor delete from it (only app.delete_child does)');
select ok(not has_table_privilege('app_gateway', 'app.alert', 'delete'), 'nor delete alerts itself');
select ok(not has_table_privilege('authenticated', 'app.event', 'select'), 'a signed-in user cannot read the log');
select ok(not has_table_privilege('authenticated', 'app.child_profile', 'select'), 'nor the children');
select ok(not has_table_privilege('anon', 'app.alert', 'select'), 'nor can an anonymous caller read alerts');
select ok(not has_function_privilege('authenticated', 'app.delete_child(uuid, text)', 'execute'), 'nobody but the gateway deletes a child');
select ok(has_function_privilege('app_gateway', 'app.delete_child(uuid, text)', 'execute'), 'the gateway can');

-- ---- retention --------------------------------------------------------------------------------
insert into app.alert (family_id, child_id, device_id, category, severity, dedupe_key, client_at)
values ('d1d1d1d1-0000-4000-8000-000000000001', 'child-aaaa-0001', 'd2d2d2d2-0000-4000-8000-000000000001',
        'absence', 'info', 'old:1', now() - interval '31 days');
insert into app.deleted_child (family_id, child_id, deleted_at)
values ('d1d1d1d1-0000-4000-8000-000000000001', 'child-cccc-0003', now() - interval '400 days');
select lives_ok($$select app.purge_expired()$$, 'the clean-up job runs');
select is((select count(*)::int from app.alert where dedupe_key = 'old:1'), 0, 'an alert older than 30 days is purged');
select is((select count(*)::int from app.alert where dedupe_key = 'gate:1'), 1, 'a recent alert stays');
select is((select count(*)::int from app.deleted_child where child_id = 'child-cccc-0003'), 0, 'a tombstone is purged after a year');
select is((select count(*)::int from app.deleted_child where child_id = 'child-bbbb-0002'), 1, 'a recent tombstone stays');

select * from finish();
rollback;
