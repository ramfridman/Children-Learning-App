-- The release-signing migration: the prod package is allowed with the release key's fingerprint, the dev entry stays, the
-- migration can run twice, and a missing row is created. The migration's statement is copied below (pg_prove cannot include files) and run against stand-in rows;
-- keep the copy equal to supabase/migrations/20261108120000_android_prod_app.sql.
begin;
create extension if not exists pgtap with schema extensions;
select * from no_plan();

-- SEC-RS-1: the migration as applied (not the copy below) left the prod package with the release key's fingerprint.
select is((select e -> 'cert_sha256' ->> 0 from app.config, jsonb_array_elements(value) e
           where key = 'android_allowed_apps' and e ->> 'package_name' = 'app.nitznutz.nitznutz'),
  'fbf648da2461d4488f94e45562c21ca98b1cdf28d5531b11b7ba778253c7cc6f', 'the applied migration trusts the prod package with the release key');


-- Stand-in for the live row: the dev package with a debug-key fingerprint, and an old prod entry with a wrong fingerprint.
delete from app.config where key = 'android_allowed_apps';
insert into app.config (key, value) values ('android_allowed_apps',
  '[{"package_name": "app.nitznutz.nitznutz.dev", "cert_sha256": ["3d5b8c4ab4722dfcf736ce16bdb9a6297bf216307efcf2b5fd5d2a3e1b25ffb9"]},
    {"package_name": "app.nitznutz.nitznutz", "cert_sha256": ["0000000000000000000000000000000000000000000000000000000000000000"]}]'::jsonb);

insert into app.config (key, value)
values (
  'android_allowed_apps',
  jsonb_build_array(jsonb_build_object(
    'package_name', 'app.nitznutz.nitznutz',
    'cert_sha256', jsonb_build_array('fbf648da2461d4488f94e45562c21ca98b1cdf28d5531b11b7ba778253c7cc6f')))
)
on conflict (key) do update
set value = coalesce(
      (select jsonb_agg(e) from jsonb_array_elements(
         case when jsonb_typeof(app.config.value) = 'array' then app.config.value else '[]'::jsonb end) as t(e)
       where e ->> 'package_name' is distinct from 'app.nitznutz.nitznutz'),
      '[]'::jsonb) || excluded.value,
    updated_at = now();

select is(jsonb_array_length(value), 2, 'two apps: dev and prod') from app.config where key = 'android_allowed_apps';
select is((select e -> 'cert_sha256' ->> 0 from app.config, jsonb_array_elements(value) e
           where key = 'android_allowed_apps' and e ->> 'package_name' = 'app.nitznutz.nitznutz'),
  'fbf648da2461d4488f94e45562c21ca98b1cdf28d5531b11b7ba778253c7cc6f', 'prod has the release key fingerprint, the old one is gone');
select is((select e -> 'cert_sha256' ->> 0 from app.config, jsonb_array_elements(value) e
           where key = 'android_allowed_apps' and e ->> 'package_name' = 'app.nitznutz.nitznutz.dev'),
  '3d5b8c4ab4722dfcf736ce16bdb9a6297bf216307efcf2b5fd5d2a3e1b25ffb9', 'the dev entry is untouched');

insert into app.config (key, value)
values (
  'android_allowed_apps',
  jsonb_build_array(jsonb_build_object(
    'package_name', 'app.nitznutz.nitznutz',
    'cert_sha256', jsonb_build_array('fbf648da2461d4488f94e45562c21ca98b1cdf28d5531b11b7ba778253c7cc6f')))
)
on conflict (key) do update
set value = coalesce(
      (select jsonb_agg(e) from jsonb_array_elements(
         case when jsonb_typeof(app.config.value) = 'array' then app.config.value else '[]'::jsonb end) as t(e)
       where e ->> 'package_name' is distinct from 'app.nitznutz.nitznutz'),
      '[]'::jsonb) || excluded.value,
    updated_at = now();
select is(jsonb_array_length(value), 2, 'running it again adds nothing') from app.config where key = 'android_allowed_apps';

-- Every entry has the shape the server demands (enrol.ts androidPolicy).
select ok(bool_and(e ->> 'package_name' is not null and jsonb_typeof(e -> 'cert_sha256') = 'array'
                   and e -> 'cert_sha256' ->> 0 ~ '^[0-9a-f]{64}$'), 'each entry has a package and 64 lower-case hex digits')
  from app.config, jsonb_array_elements(value) e where key = 'android_allowed_apps';

-- A project with no row gets one entry.
delete from app.config where key = 'android_allowed_apps';
insert into app.config (key, value)
values (
  'android_allowed_apps',
  jsonb_build_array(jsonb_build_object(
    'package_name', 'app.nitznutz.nitznutz',
    'cert_sha256', jsonb_build_array('fbf648da2461d4488f94e45562c21ca98b1cdf28d5531b11b7ba778253c7cc6f')))
)
on conflict (key) do update
set value = coalesce(
      (select jsonb_agg(e) from jsonb_array_elements(
         case when jsonb_typeof(app.config.value) = 'array' then app.config.value else '[]'::jsonb end) as t(e)
       where e ->> 'package_name' is distinct from 'app.nitznutz.nitznutz'),
      '[]'::jsonb) || excluded.value,
    updated_at = now();
select is(jsonb_array_length(value), 1, 'with no row before, the prod entry is created') from app.config where key = 'android_allowed_apps';

select * from finish();
rollback;
