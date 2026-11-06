-- B-29 step 3: a child's school stage is one of six words or null, nothing else; no client role can reach the column; deleting a
-- child takes its look letter out of the family's settings and counts a new version; and nothing that looks like a birth is
-- anywhere in the child's table.
begin;
create extension if not exists pgtap with schema extensions;
select * from no_plan();

insert into app.family (id) values ('dbdbdbdb-0000-4000-8000-000000000001');

-- ---- the column: six words or null --------------------------------------------------------------------------------------
select has_column('app', 'child_profile', 'school_stage', 'the child has a school stage');
select col_is_null('app', 'child_profile', 'school_stage', 'and it may be empty (a child nobody has placed)');
select col_type_is('app', 'child_profile', 'school_stage', 'text', 'it is a word, not a date');

select lives_ok($$insert into app.child_profile (family_id, id, nickname, avatar_id, address_form, age_band) values
  ('dbdbdbdb-0000-4000-8000-000000000001', 'child-dbdb-0000', 'ללא', 'avatar-noa', 'n', 1)$$,
  'a child saved before B-29, with no stage, is still valid');
select is((select school_stage from app.child_profile where id = 'child-dbdb-0000'), null, 'and has none');

select lives_ok(format($$insert into app.child_profile (family_id, id, nickname, avatar_id, address_form, age_band, school_stage) values
  ('dbdbdbdb-0000-4000-8000-000000000001', 'child-dbdb-%s', 'נועה', 'avatar-noa', 'f', 1, %L)$$, i, s),
  format('%s is accepted', s))
  from (values (1, 'gan3'), (2, 'gan4'), (3, 'gan5'), (4, 'grade1'), (5, 'grade2'), (6, 'grade3')) as t(i, s);

select throws_ok(format($$update app.child_profile set school_stage = %L where id = 'child-dbdb-0000'$$, s), '23514', null,
  format('%L is refused', s))
  from (values ('grade4'), ('Gan3'), (''), ('2020-05'), ('2020'), ('gan3 '), ('grade 1'), ('kita-a'), ('12')) as t(s);

-- ---- no client role has any privilege on the column or the table --------------------------------------------------------
select ok(not has_column_privilege('anon', 'app.child_profile', 'school_stage', 'select'), 'anon cannot read the stage');
select ok(not has_column_privilege('authenticated', 'app.child_profile', 'school_stage', 'select'), 'authenticated cannot read the stage');
select ok(not has_column_privilege('anon', 'app.child_profile', 'school_stage', 'update'), 'anon cannot write the stage');
select ok(not has_column_privilege('authenticated', 'app.child_profile', 'school_stage', 'update'), 'authenticated cannot write the stage');
select ok(has_column_privilege('app_gateway', 'app.child_profile', 'school_stage', 'select'), 'the gateway reads it');
select ok(has_column_privilege('app_gateway', 'app.child_profile', 'school_stage', 'update'), 'and writes it');
select ok((select relrowsecurity from pg_class where oid = 'app.child_profile'::regclass), 'row level security stays on for the table');

-- ---- the table holds no date of birth, month of birth or age in months ----------------------------------------------------
select is(
  (select count(*)::int from information_schema.columns
    where table_schema = 'app' and table_name = 'child_profile'
      and (column_name ~* '(birth|born|dob|month|year|age_months|presentation|look)' or data_type in ('date', 'interval'))),
  0, 'no column of the child table can hold a birth, a month, a year, a look or a date');

-- ---- deleting a child takes its look letter out of the family's settings ------------------------------------------------------
insert into app.family_settings (family_id, rules, version)
values ('dbdbdbdb-0000-4000-8000-000000000001',
        '{"looks":{"child-dbdb-1":"A","child-dbdb-2":"C"},"ceremonies":true}'::jsonb, 3);
select lives_ok($$select app.delete_child('dbdbdbdb-0000-4000-8000-000000000001', 'child-dbdb-1')$$, 'a child with a look can be deleted');
select ok(not jsonb_exists((select rules -> 'looks' from app.family_settings where family_id = 'dbdbdbdb-0000-4000-8000-000000000001'), 'child-dbdb-1'),
  'its look letter is gone');
select is((select rules -> 'looks' ->> 'child-dbdb-2' from app.family_settings where family_id = 'dbdbdbdb-0000-4000-8000-000000000001'), 'C',
  'the other child keeps its letter');
select is((select version from app.family_settings where family_id = 'dbdbdbdb-0000-4000-8000-000000000001'), 4::bigint,
  'and every phone is told by one new version');
select is((select rules -> 'ceremonies' from app.family_settings where family_id = 'dbdbdbdb-0000-4000-8000-000000000001'), 'true'::jsonb,
  'nothing else in the rules is touched');

-- a family with no looks changes nothing in its settings
select lives_ok($$select app.delete_child('dbdbdbdb-0000-4000-8000-000000000001', 'child-dbdb-0000')$$, 'a child with no look can be deleted');
select is((select version from app.family_settings where family_id = 'dbdbdbdb-0000-4000-8000-000000000001'), 4::bigint,
  'and the version does not move');

select * from finish();
rollback;
