-- B-29 step 5a (owner, 2026-11-08): a child's month and year of birth (never the day) are two small numbers on the child's row.
-- Both or neither; a real month; a year in range; no date, no day, no age in months; no client role can reach them; the row's
-- deletion takes them; and the grants of the table are exactly as before.
begin;
create extension if not exists pgtap with schema extensions;
select * from no_plan();

insert into app.family (id) values ('dbdbdbdb-0000-4000-8000-000000000012');

-- ---- the columns -----------------------------------------------------------------------------------------------------------
select has_column('app', 'child_profile', 'birth_year', 'the child has a year of birth');
select has_column('app', 'child_profile', 'birth_month', 'and a month of birth');
select col_is_null('app', 'child_profile', 'birth_year', 'the year may be empty (a child nobody gave a birth)');
select col_is_null('app', 'child_profile', 'birth_month', 'and so may the month');
select col_type_is('app', 'child_profile', 'birth_year', 'smallint', 'the year is a small number, not a date');
select col_type_is('app', 'child_profile', 'birth_month', 'smallint', 'and so is the month');
select is(
  (select count(*)::int from information_schema.columns
    where table_schema = 'app' and table_name = 'child_profile'
      and (column_name ~* '(dob|day|age_months|presentation)' or data_type in ('date', 'interval'))),
  0, 'there is still no date, day or age in months on the child table');

-- ---- a child with no birth is still valid, and so is one with a month and year -------------------------------------------
select lives_ok($$insert into app.child_profile (family_id, id, nickname, avatar_id, address_form, age_band) values
  ('dbdbdbdb-0000-4000-8000-000000000012', 'child-bb12-0000', 'ללא', 'avatar-noa', 'n', 1)$$,
  'a child saved before this change has no birth and is valid');
select lives_ok(format($$insert into app.child_profile (family_id, id, nickname, avatar_id, address_form, age_band, birth_year, birth_month) values
  ('dbdbdbdb-0000-4000-8000-000000000012', 'child-bb12-%s', 'נועה', 'avatar-noa', 'f', 1, %s, %s)$$, i, y, m),
  format('%s-%s is accepted', y, m))
  from (values (1, 2010, 1), (2, 2021, 5), (3, 2023, 12), (4, 2100, 12)) as t(i, y, m);

-- ---- both or neither -------------------------------------------------------------------------------------------------------
select throws_ok($$update app.child_profile set birth_year = 2021, birth_month = null where id = 'child-bb12-0000'$$, '23514', null,
  'a year with no month is refused');
select throws_ok($$update app.child_profile set birth_year = null, birth_month = 5 where id = 'child-bb12-0000'$$, '23514', null,
  'a month with no year is refused');
select lives_ok($$update app.child_profile set birth_year = null, birth_month = null where id = 'child-bb12-2'$$,
  'both can be cleared together');
select is((select birth_year from app.child_profile where id = 'child-bb12-2'), null, 'and then there is none');
select ok(exists (select 1 from pg_constraint where conrelid = 'app.child_profile'::regclass and conname = 'child_profile_birth_both' and contype = 'c'),
  'a check says both or neither');

-- ---- a real month, a year in range ---------------------------------------------------------------------------------------------
select throws_ok(format($$update app.child_profile set birth_year = 2021, birth_month = %s where id = 'child-bb12-0000'$$, m), '23514', null,
  format('month %s is refused', m))
  from (values (0), (13), (-1), (99), (32767)) as t(m);
select throws_ok(format($$update app.child_profile set birth_year = %s, birth_month = 5 where id = 'child-bb12-0000'$$, y), '23514', null,
  format('year %s is refused', y))
  from (values (0), (1999), (2009), (2101), (9999)) as t(y);
select throws_ok($$update app.child_profile set birth_year = 99999, birth_month = 5 where id = 'child-bb12-0000'$$, '22003', null,
  'a year that does not fit a small number is refused');

-- ---- no client role has any privilege on the columns or the table; the gateway does ---------------------------------------------
select ok(not has_column_privilege('anon', 'app.child_profile', 'birth_year', 'select'), 'anon cannot read the year');
select ok(not has_column_privilege('anon', 'app.child_profile', 'birth_month', 'select'), 'anon cannot read the month');
select ok(not has_column_privilege('authenticated', 'app.child_profile', 'birth_year', 'select'), 'authenticated cannot read the year');
select ok(not has_column_privilege('authenticated', 'app.child_profile', 'birth_month', 'select'), 'authenticated cannot read the month');
select ok(not has_column_privilege('anon', 'app.child_profile', 'birth_year', 'update'), 'anon cannot write the year');
select ok(not has_column_privilege('authenticated', 'app.child_profile', 'birth_month', 'update'), 'authenticated cannot write the month');
select ok(not has_table_privilege('anon', 'app.child_profile', 'select'), 'anon has nothing on the table');
select ok(not has_table_privilege('authenticated', 'app.child_profile', 'select'), 'authenticated has nothing on the table');
select ok(has_column_privilege('app_gateway', 'app.child_profile', 'birth_year', 'select'), 'the gateway reads the year');
select ok(has_column_privilege('app_gateway', 'app.child_profile', 'birth_month', 'update'), 'and writes the month');
select ok((select relrowsecurity from pg_class where oid = 'app.child_profile'::regclass), 'row level security stays on');
select ok(not has_schema_privilege('anon', 'app', 'usage'), 'the app schema stays closed to anon');
select ok(not has_schema_privilege('authenticated', 'app', 'usage'), 'and to authenticated');

-- ---- deleting a child takes its birth with the row, and nothing else of it is left ------------------------------------------------
select lives_ok($$select app.delete_child('dbdbdbdb-0000-4000-8000-000000000012', 'child-bb12-3')$$, 'a child with a birth can be deleted');
select is((select count(*)::int from app.child_profile where id = 'child-bb12-3'), 0, 'the row, and so the birth, is gone');
select is((select count(*)::int from app.deleted_child where child_id = 'child-bb12-3'), 1, 'and only the tombstone, a bare id, is left');

select * from finish();
rollback;
