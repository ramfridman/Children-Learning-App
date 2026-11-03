-- B-42: how a child's name is said. The column is additive (existing children have none), holds only the narrow rule of
-- testvectors/name-spoken.json, and goes with the child when the child is deleted.
begin;
create extension if not exists pgtap with schema extensions;
select * from no_plan();

insert into app.family (id) values ('e1e1e1e1-0000-4000-8000-000000000001');

select lives_ok($$insert into app.child_profile (family_id, id, nickname, avatar_id, address_form, age_band)
  values ('e1e1e1e1-0000-4000-8000-000000000001', 'child-9999-0001', 'נועה', 'avatar-noa', 'f', 1)$$,
  'a child can be saved with no spelling (every child saved before)');
select is((select name_spoken from app.child_profile where id = 'child-9999-0001'), null, 'and has none');

select lives_ok($$update app.child_profile set name_spoken = 'נועה' where id = 'child-9999-0001'$$,
  'Hebrew letters');
select lives_ok($$update app.child_profile set name_spoken = E'נ\u05B9ע\u05B8ה' where id = 'child-9999-0001'$$,
  'with nikud');
select lives_ok($$update app.child_profile set name_spoken = E'ש\u05BC\u05C1\u05B8' where id = 'child-9999-0001'$$,
  'a shin with a dagesh, a shin dot and a vowel: three marks in a row');
select lives_ok($$update app.child_profile set name_spoken = 'בן-ציון' where id = 'child-9999-0001'$$, 'a hyphen');
select lives_ok($$update app.child_profile set name_spoken = E'בן\u05BEציון' where id = 'child-9999-0001'$$,
  'a maqaf');
select lives_ok($$update app.child_profile set name_spoken = E'ג''ורג''' where id = 'child-9999-0001'$$,
  'an apostrophe as a geresh');
select lives_ok($$update app.child_profile set name_spoken = E'ג׳ורג׳' where id = 'child-9999-0001'$$,
  'a geresh');
select lives_ok($$update app.child_profile set name_spoken = 'נועה כהן' where id = 'child-9999-0001'$$, 'a space inside');
select lives_ok($$update app.child_profile set name_spoken = 'אבגדהוזחטיכלמנסעפצקרשתאב' where id = 'child-9999-0001'$$,
  'twenty-four characters');
select lives_ok($$update app.child_profile set name_spoken = null where id = 'child-9999-0001'$$, 'and it can be cleared');

select throws_ok($$update app.child_profile set name_spoken = '' where id = 'child-9999-0001'$$, '23514', null, 'empty');
select throws_ok($$update app.child_profile set name_spoken = 'אבגדהוזחטיכלמנסעפצקרשתאבג' where id = 'child-9999-0001'$$,
  '23514', null, 'twenty-five characters');
select throws_ok($$update app.child_profile set name_spoken = 'Noa' where id = 'child-9999-0001'$$, '23514', null, 'Latin letters');
select throws_ok($$update app.child_profile set name_spoken = 'נועה1' where id = 'child-9999-0001'$$, '23514', null, 'a digit');
select throws_ok($$update app.child_profile set name_spoken = 'נועה!' where id = 'child-9999-0001'$$, '23514', null, 'an exclamation mark');
select throws_ok($$update app.child_profile set name_spoken = 'נועה,' where id = 'child-9999-0001'$$, '23514', null, 'a comma');
select throws_ok($$update app.child_profile set name_spoken = '<b>נועה' where id = 'child-9999-0001'$$, '23514', null, 'markup');
select throws_ok($$update app.child_profile set name_spoken = '{child}' where id = 'child-9999-0001'$$, '23514', null, 'a placeholder');
select throws_ok($$update app.child_profile set name_spoken = ' נועה' where id = 'child-9999-0001'$$, '23514', null, 'a leading space');
select throws_ok($$update app.child_profile set name_spoken = 'נועה ' where id = 'child-9999-0001'$$, '23514', null, 'a trailing space');
select throws_ok($$update app.child_profile set name_spoken = 'נועה  כהן' where id = 'child-9999-0001'$$, '23514', null, 'two spaces');
select throws_ok($$update app.child_profile set name_spoken = '-' where id = 'child-9999-0001'$$, '23514', null, 'no letter');
select throws_ok($$update app.child_profile set name_spoken = E'נו\tעה' where id = 'child-9999-0001'$$,
  '23514', null, 'a tab');
select throws_ok($$update app.child_profile set name_spoken = E'נו\u200Dעה' where id = 'child-9999-0001'$$,
  '23514', null, 'a zero-width joiner');
select throws_ok($$update app.child_profile set name_spoken = E'נו\u200Fעה' where id = 'child-9999-0001'$$,
  '23514', null, 'a direction mark');
select throws_ok($$update app.child_profile set name_spoken = E'\u05B0נועה' where id = 'child-9999-0001'$$,
  '23514', null, 'a mark at the start');
select throws_ok($$update app.child_profile set name_spoken = E'נועה \u05B0כהן' where id = 'child-9999-0001'$$,
  '23514', null, 'a mark after a space');
select throws_ok($$update app.child_profile set name_spoken = E'נ\u05B0\u05B1\u05B2\u05B4' where id = 'child-9999-0001'$$,
  '23514', null, 'four marks in a row');
select throws_ok($$update app.child_profile set name_spoken = E'נ\u05B3ועה' where id = 'child-9999-0001'$$,
  '23514', null, 'hataf qamats is never sent to the voice');
select throws_ok($$update app.child_profile set name_spoken = E'כ\u05C7ל' where id = 'child-9999-0001'$$,
  '23514', null, 'qamats qatan is never sent to the voice');
select throws_ok($$update app.child_profile set name_spoken = E'נ\u0591ועה' where id = 'child-9999-0001'$$,
  '23514', null, 'a cantillation mark');

-- ---- the spelling goes with the child ---------------------------------------------------------------------------
update app.child_profile set name_spoken = 'נועה' where id = 'child-9999-0001';
select lives_ok($$select app.delete_child('e1e1e1e1-0000-4000-8000-000000000001', 'child-9999-0001')$$, 'the child is deleted');
select is((select count(*)::int from app.child_profile where id = 'child-9999-0001'), 0, 'and the spelling is gone with it');

-- ---- the gateway reads and writes it, nobody else -----------------------------------------------------------------
select ok(has_column_privilege('app_gateway', 'app.child_profile', 'name_spoken', 'select'), 'the gateway reads it');
select ok(has_column_privilege('app_gateway', 'app.child_profile', 'name_spoken', 'update'), 'and writes it');
select ok(not has_column_privilege('anon', 'app.child_profile', 'name_spoken', 'select'), 'anon cannot read it');
select ok(not has_column_privilege('authenticated', 'app.child_profile', 'name_spoken', 'select'), 'nor a signed-in user');

select * from finish();
rollback;
