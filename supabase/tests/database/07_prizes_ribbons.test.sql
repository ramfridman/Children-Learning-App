-- M8b: a child's prize is an id and nothing else, the ribbon alert is a known category, and the family's settings have room
-- for the parents' promises but not for anything large.
begin;
create extension if not exists pgtap with schema extensions;
select * from no_plan();

insert into app.family (id) values ('d7d7d7d7-0000-4000-8000-000000000001');
insert into app.device (id, family_id, role, public_key, platform, attestation_kind, security_level) values
  ('d8d8d8d8-0000-4000-8000-000000000001', 'd7d7d7d7-0000-4000-8000-000000000001', 'parent',
   substring(sha256('7'::bytea) || sha256('1007'::bytea) || sha256('2007'::bytea) from 1 for 91), 'android', 'key_attestation', 'tee');

select lives_ok($$insert into app.child_profile (family_id, id, nickname, avatar_id, outfit_id, address_form, age_band)
  values ('d7d7d7d7-0000-4000-8000-000000000001', 'child-7777-0001', 'נועה', 'avatar-noa', 'sky', 'f', 1)$$,
  'a child can wear a prize');
select lives_ok($$insert into app.child_profile (family_id, id, nickname, avatar_id, address_form, age_band)
  values ('d7d7d7d7-0000-4000-8000-000000000001', 'child-7777-0002', 'דני', 'avatar-dani', 'm', 0)$$,
  'a child may wear none');
select throws_ok($$update app.child_profile set outfit_id = 'Has Spaces And Capitals' where id = 'child-7777-0001'$$,
  '23514', null, 'a prize is an id, not free text');
select throws_ok($$update app.child_profile set outfit_id = 'x' where id = 'child-7777-0001'$$,
  '23514', null, 'an id of one character is refused');

select lives_ok($$insert into app.alert (family_id, child_id, device_id, category, severity, detail, dedupe_key, client_at)
  values ('d7d7d7d7-0000-4000-8000-000000000001', 'child-7777-0001', 'd8d8d8d8-0000-4000-8000-000000000001',
          'ribbonEarned', 'info', 'trophy:counting:silver', 'ribbon:child-7777-0001:trophy:counting:silver', now())$$,
  'the alert that a trophy with a promise was earned carries only the trophy key');
select throws_ok($$insert into app.alert (family_id, child_id, device_id, category, severity, detail, dedupe_key, client_at)
  values ('d7d7d7d7-0000-4000-8000-000000000001', 'child-7777-0001', 'd8d8d8d8-0000-4000-8000-000000000001',
          'ribbonEarned', 'info', 'We go for ice cream', 'ribbon:2', now())$$,
  '23514', null, 'a promise cannot ride in the alert: the detail is fixed characters only');
select throws_ok($$insert into app.alert (family_id, child_id, device_id, category, severity, dedupe_key, client_at)
  values ('d7d7d7d7-0000-4000-8000-000000000001', 'child-7777-0001', 'd8d8d8d8-0000-4000-8000-000000000001',
          'ribbonsEarned', 'info', 'ribbon:3', now())$$,
  '23514', null, 'an unknown category is still refused');

select lives_ok($$insert into app.family_settings (family_id, rules)
  values ('d7d7d7d7-0000-4000-8000-000000000001',
          jsonb_build_object('ribbons', (select jsonb_object_agg('trophy:land' || n || ':gold', repeat('א', 60)) from generate_series(1, 30) n)))$$,
  'thirty promises of sixty letters fit in the settings');
select throws_ok($$update app.family_settings set rules = jsonb_build_object('x', repeat('a', 9000))$$,
  '23514', null, 'a large document is still refused');

select * from finish();
rollback;
