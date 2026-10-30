-- Word alerts in three tiers: the check (`concern`) is a known category and may carry the kept words, its detail is
-- fixed characters only, and the categories that were there stay.
begin;
create extension if not exists pgtap with schema extensions;
select * from no_plan();

insert into app.family (id) values ('d9d9d9d9-0000-4000-8000-000000000001');
insert into app.device (id, family_id, role, public_key, platform, attestation_kind, security_level) values
  ('dadadada-0000-4000-8000-000000000001', 'd9d9d9d9-0000-4000-8000-000000000001', 'child',
   substring(sha256('8'::bytea) || sha256('1008'::bytea) || sha256('2008'::bytea) from 1 for 91), 'android', 'key_attestation', 'tee');
insert into app.child_profile (family_id, id, nickname, avatar_id, address_form, age_band)
  values ('d9d9d9d9-0000-4000-8000-000000000001', 'child-9999-0001', 'נועה', 'avatar-noa', 'f', 1);

select lives_ok($$insert into app.alert (family_id, child_id, device_id, category, severity, count, detail, words, dedupe_key, client_at)
  values ('d9d9d9d9-0000-4000-8000-000000000001', 'child-9999-0001', 'dadadada-0000-4000-8000-000000000001',
          'concern', 'attention', 1, '2:FEAR:W-21:2026-10-29.1', 'מפחידים אותי', 'words:child-9999-0001:1', now())$$,
  'a check is a known category and carries the kept words');
select lives_ok($$insert into app.alert (family_id, child_id, device_id, category, severity, count, detail, dedupe_key, client_at)
  values ('d9d9d9d9-0000-4000-8000-000000000001', 'child-9999-0001', 'dadadada-0000-4000-8000-000000000001',
          'inappropriateWords', 'info', 3, '3:SWEAR:S-01:2026-10-29.1', 'note:child-9999-0001:SWEAR:2026-11-15', now())$$,
  'the weekly note of swearing, with its count');
select lives_ok($$insert into app.alert (family_id, child_id, device_id, category, severity, count, detail, dedupe_key, client_at)
  values ('d9d9d9d9-0000-4000-8000-000000000001', 'child-9999-0001', 'dadadada-0000-4000-8000-000000000001',
          'disclosure', 'important', 1, '1:PHYS:W-01:2026-10-29.1:often:repeat', 'words:child-9999-0001:2', now())$$,
  'an act with its flags');
select throws_ok($$insert into app.alert (family_id, child_id, device_id, category, severity, detail, dedupe_key, client_at)
  values ('d9d9d9d9-0000-4000-8000-000000000001', 'child-9999-0001', 'dadadada-0000-4000-8000-000000000001',
          'concern', 'attention', '2:FEAR:W-21:he said scary things', 'words:child-9999-0001:3', now())$$,
  '23514', null, 'the detail of a check is fixed characters only, never the child''s words');
select throws_ok($$insert into app.alert (family_id, child_id, device_id, category, severity, dedupe_key, client_at)
  values ('d9d9d9d9-0000-4000-8000-000000000001', 'child-9999-0001', 'dadadada-0000-4000-8000-000000000001',
          'worry', 'attention', 'words:child-9999-0001:4', now())$$,
  '23514', null, 'an unknown category is still refused');
select lives_ok($$insert into app.alert (family_id, child_id, device_id, category, severity, detail, dedupe_key, client_at)
  values ('d9d9d9d9-0000-4000-8000-000000000001', 'child-9999-0001', 'dadadada-0000-4000-8000-000000000001',
          'ribbonEarned', 'info', 'trophy:counting:gold', 'ribbon:child-9999-0001:trophy:counting:gold', now())$$,
  'the categories that were there stay');

select * from finish();
rollback;
