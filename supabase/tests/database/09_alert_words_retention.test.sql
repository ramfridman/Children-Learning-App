-- The child's words in alerts (SEC-28, SEC-29): only the characters alert-create takes, the gateway may change only
-- the count, the read time and the words, and an alert goes 30 days after the earlier of its two times.
begin;
create extension if not exists pgtap with schema extensions;
select * from no_plan();

insert into app.family (id) values ('dbdbdbdb-0000-4000-8000-000000000001');
insert into app.device (id, family_id, role, public_key, platform, attestation_kind, security_level) values
  ('dcdcdcdc-0000-4000-8000-000000000001', 'dbdbdbdb-0000-4000-8000-000000000001', 'child',
   substring(sha256('9'::bytea) || sha256('1009'::bytea) || sha256('2009'::bytea) from 1 for 91), 'android', 'key_attestation', 'tee');
insert into app.child_profile (family_id, id, nickname, avatar_id, address_form, age_band)
  values ('dbdbdbdb-0000-4000-8000-000000000001', 'child-9090-0001', 'נועה', 'avatar-noa', 'f', 1);

select lives_ok($$insert into app.alert (family_id, child_id, device_id, category, severity, words, dedupe_key, client_at)
  values ('dbdbdbdb-0000-4000-8000-000000000001', 'child-9090-0001', 'dcdcdcdc-0000-4000-8000-000000000001',
          'disclosure', 'important', 'מכים אותי, "כל יום"! fuck-it?', 'w:1', now())$$,
  'Hebrew, Latin, digits and the punctuation alert-create takes');
select throws_ok($$insert into app.alert (family_id, child_id, device_id, category, severity, words, dedupe_key, client_at)
  values ('dbdbdbdb-0000-4000-8000-000000000001', 'child-9090-0001', 'dcdcdcdc-0000-4000-8000-000000000001',
          'disclosure', 'important', 'מכים <b>אותי</b>', 'w:2', now())$$,
  '23514', null, 'an angle bracket is refused');
select throws_ok($$insert into app.alert (family_id, child_id, device_id, category, severity, words, dedupe_key, client_at)
  values ('dbdbdbdb-0000-4000-8000-000000000001', 'child-9090-0001', 'dcdcdcdc-0000-4000-8000-000000000001',
          'disclosure', 'important', 'מכים ' || chr(8238) || 'אותי', 'w:3', now())$$,
  '23514', null, 'a direction control is refused');

-- ---- what the gateway may change ----------------------------------------------------------------------------
select ok(has_column_privilege('app_gateway', 'app.alert', 'count', 'UPDATE'), 'the count (said again)');
select ok(has_column_privilege('app_gateway', 'app.alert', 'read_at', 'UPDATE'), 'the read time');
select ok(has_column_privilege('app_gateway', 'app.alert', 'words', 'UPDATE'), 'the words (emptied when not kept)');
select ok(not has_column_privilege('app_gateway', 'app.alert', 'category', 'UPDATE'), 'never the category');
select ok(not has_column_privilege('app_gateway', 'app.alert', 'detail', 'UPDATE'), 'nor the detail');
select ok(not has_column_privilege('app_gateway', 'app.alert', 'client_at', 'UPDATE'), 'nor the time');
select ok(not has_column_privilege('app_gateway', 'app.alert', 'family_id', 'UPDATE'), 'nor the family');
select ok(not has_table_privilege('app_gateway', 'app.alert', 'delete'), 'and it still deletes nothing');

-- ---- 30 days from the earlier time ---------------------------------------------------------------------------
insert into app.alert (family_id, child_id, device_id, category, severity, dedupe_key, client_at, created_at) values
  ('dbdbdbdb-0000-4000-8000-000000000001', 'child-9090-0001', 'dcdcdcdc-0000-4000-8000-000000000001',
   'disclosure', 'important', 'ahead:1', now() + interval '300 days', now() - interval '31 days'),
  ('dbdbdbdb-0000-4000-8000-000000000001', 'child-9090-0001', 'dcdcdcdc-0000-4000-8000-000000000001',
   'disclosure', 'important', 'behind:1', now() - interval '31 days', now()),
  ('dbdbdbdb-0000-4000-8000-000000000001', 'child-9090-0001', 'dcdcdcdc-0000-4000-8000-000000000001',
   'disclosure', 'important', 'fresh:1', now() - interval '1 day', now() - interval '1 day');
select lives_ok($$select app.purge_expired()$$, 'the clean-up job runs');
select is((select count(*)::int from app.alert where dedupe_key = 'ahead:1'), 0,
  'a phone clock far ahead does not keep an alert past 30 days of the server');
select is((select count(*)::int from app.alert where dedupe_key = 'behind:1'), 0, 'an old device time goes as before');
select is((select count(*)::int from app.alert where dedupe_key = 'fresh:1'), 1, 'a recent alert stays');

select * from finish();
rollback;
