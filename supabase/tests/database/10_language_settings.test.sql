-- L0: the family's settings hold the parents' language settings (a few hundred characters for each of up to 6 children), and
-- deleting a child takes that child's language settings out of the settings and counts the change as a new version.
begin;
create extension if not exists pgtap with schema extensions;
select * from no_plan();

insert into app.family (id) values ('d9d9d9d9-0000-4000-8000-000000000001');
insert into app.child_profile (family_id, id, nickname, avatar_id, address_form, age_band) values
  ('d9d9d9d9-0000-4000-8000-000000000001', 'child-9191-0001', 'נועה', 'avatar-noa', 'f', 1),
  ('d9d9d9d9-0000-4000-8000-000000000001', 'child-9191-0002', 'גלעד', 'avatar-gilad', 'm', 0);

-- ---- room: the largest document the gateway takes for six children fits the table's own limit ------------------------
select lives_ok($$insert into app.family_settings (family_id, rules)
  values ('d9d9d9d9-0000-4000-8000-000000000001',
          jsonb_build_object('languages', (
            select jsonb_object_agg('child-9191-000' || n, jsonb_build_object(
              'eng', jsonb_build_object('on', true, 'voice', true, 'personal', false, 'oralOnly', true, 'band', 2,
                                        'q', jsonb_build_object('knowsLetters', 'some')),
              'heb', jsonb_build_object('on', true, 'voice', true, 'personal', false, 'readCheck', true, 'band', 0),
              'rus', jsonb_build_object('on', true, 'voice', true, 'personal', false, 'lettersBefore5', true,
                                        'stress', 'off', 'route', 'heritage', 'band', 1,
                                        'q', jsonb_build_object('home', 'grandparentsOthers', 'understands', 'most',
                                                                'speaks', 'sentences', 'letters', 'most', 'reads', 'sentences'))))
            from generate_series(1, 6) n),
          'ribbons', (select jsonb_object_agg('trophy:land' || n || ':gold', repeat('א', 60)) from generate_series(1, 30) n)))$$,
  'six children with every language set fit in the settings beside thirty promises');

select throws_ok($$update app.family_settings set rules = jsonb_build_object('x', repeat('a', 13000))$$,
  '23514', null, 'a document over 12 KB is still refused');
select throws_ok($$update app.family_settings set rules = '[1]'::jsonb$$, '23514', null, 'and it is still an object');

-- ---- deleting a child takes the language settings out of the settings ------------------------------------------------
update app.family_settings
   set rules = '{"languages":{"child-9191-0001":{"eng":{"on":true}},"child-9191-0002":{"rus":{"on":true,"route":"new"}}}}'::jsonb,
       version = 5
 where family_id = 'd9d9d9d9-0000-4000-8000-000000000001';
select lives_ok($$select app.delete_child('d9d9d9d9-0000-4000-8000-000000000001', 'child-9191-0001')$$,
  'a child with language settings can be deleted');
select ok(not jsonb_exists((select rules -> 'languages' from app.family_settings where family_id = 'd9d9d9d9-0000-4000-8000-000000000001'), 'child-9191-0001'),
  'the language settings of that child are gone');
select ok(jsonb_exists((select rules -> 'languages' from app.family_settings where family_id = 'd9d9d9d9-0000-4000-8000-000000000001'), 'child-9191-0002'),
  'the language settings of the other child stay');
select is((select version from app.family_settings where family_id = 'd9d9d9d9-0000-4000-8000-000000000001'), 6::bigint,
  'and every phone is told by a new version');

-- a child with no language settings changes nothing in the settings
select lives_ok($$select app.delete_child('d9d9d9d9-0000-4000-8000-000000000001', 'child-9191-0002')$$, 'the other child can be deleted too');
select is((select version from app.family_settings where family_id = 'd9d9d9d9-0000-4000-8000-000000000001'), 7::bigint,
  'one version for the one change');
select is((select rules from app.family_settings where family_id = 'd9d9d9d9-0000-4000-8000-000000000001'), '{"languages":{}}'::jsonb,
  'nothing of either child is left');

select * from finish();
rollback;
