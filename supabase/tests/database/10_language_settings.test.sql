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

-- SEC-L0-3, rebuilt for L7 (SEC-L7-2): the worst document the gateway accepts (settings-put MAX_RULES_BYTES = 10000) is 10,000 UTF-8
-- bytes: six children with UUID ids and every language field at its maximum (placement in all three courses, the English and Hebrew
-- questions of L7, the five Russian answers, `lettersWithWords` in English and Russian (L7-8), B-29's look of each child), twelve UUID time limits, three windows on seven days, the
-- thirty promises of 3-byte characters (the last ones cut until the whole is accepted). It must fit the table's own limit of 12288 bytes
-- (pg_column_size), so the gateway's bound can never let through a document the table refuses, and it must leave 512 bytes to spare,
-- so that a field added to the settings is noticed here before the table refuses a parent's save. Built from the gateway's own tables by
-- the same code that checks it (checkRules, supabase/functions/alerts_test.ts reads this file and checks the document is accepted and
-- that it is still the largest: no more than 300 bytes under the limit).
create temp table worst_rules on commit drop as select $doc${"limitByBand":{"A":180,"B":180,"C":180},"limitByChild":{"d9d9d9d9-0000-4000-8000-000000000100":180,"d9d9d9d9-0000-4000-8000-000000000101":180,"d9d9d9d9-0000-4000-8000-000000000102":180,"d9d9d9d9-0000-4000-8000-000000000103":180,"d9d9d9d9-0000-4000-8000-000000000104":180,"d9d9d9d9-0000-4000-8000-000000000105":180,"d9d9d9d9-0000-4000-8000-000000000106":180,"d9d9d9d9-0000-4000-8000-000000000107":180,"d9d9d9d9-0000-4000-8000-000000000108":180,"d9d9d9d9-0000-4000-8000-000000000109":180,"d9d9d9d9-0000-4000-8000-000000000110":180,"d9d9d9d9-0000-4000-8000-000000000111":180},"restOn":true,"lockWhenDone":true,"keepWords":true,"aiHelper":true,"ceremonies":true,"restStartMinute":1439,"restEndMinute":1439,"schedule":{"1":[[1000,1100],[1200,1300],[1400,1439]],"2":[[1000,1100],[1200,1300],[1400,1439]],"3":[[1000,1100],[1200,1300],[1400,1439]],"4":[[1000,1100],[1200,1300],[1400,1439]],"5":[[1000,1100],[1200,1300],[1400,1439]],"6":[[1000,1100],[1200,1300],[1400,1439]],"7":[[1000,1100],[1200,1300],[1400,1439]]},"languages":{"d9d9d9d9-0000-4000-8000-000000000100":{"eng":{"on":true,"voice":true,"personal":true,"placement":true,"band":2,"oralOnly":true,"q":{"understands":"most","knowsLetters":"some"},"lettersWithWords":true},"heb":{"on":true,"voice":true,"personal":true,"placement":true,"band":2,"readCheck":true,"q":{"knowsLetters":"reads"}},"rus":{"on":true,"voice":true,"personal":true,"placement":true,"band":2,"lettersBefore5":true,"stress":"off","route":"reader","q":{"home":"grandparentsOthers","understands":"most","speaks":"sentences","letters":"most","reads":"sentences"},"lettersWithWords":true}},"d9d9d9d9-0000-4000-8000-000000000101":{"eng":{"on":true,"voice":true,"personal":true,"placement":true,"band":2,"oralOnly":true,"q":{"understands":"most","knowsLetters":"some"},"lettersWithWords":true},"heb":{"on":true,"voice":true,"personal":true,"placement":true,"band":2,"readCheck":true,"q":{"knowsLetters":"reads"}},"rus":{"on":true,"voice":true,"personal":true,"placement":true,"band":2,"lettersBefore5":true,"stress":"off","route":"reader","q":{"home":"grandparentsOthers","understands":"most","speaks":"sentences","letters":"most","reads":"sentences"},"lettersWithWords":true}},"d9d9d9d9-0000-4000-8000-000000000102":{"eng":{"on":true,"voice":true,"personal":true,"placement":true,"band":2,"oralOnly":true,"q":{"understands":"most","knowsLetters":"some"},"lettersWithWords":true},"heb":{"on":true,"voice":true,"personal":true,"placement":true,"band":2,"readCheck":true,"q":{"knowsLetters":"reads"}},"rus":{"on":true,"voice":true,"personal":true,"placement":true,"band":2,"lettersBefore5":true,"stress":"off","route":"reader","q":{"home":"grandparentsOthers","understands":"most","speaks":"sentences","letters":"most","reads":"sentences"},"lettersWithWords":true}},"d9d9d9d9-0000-4000-8000-000000000103":{"eng":{"on":true,"voice":true,"personal":true,"placement":true,"band":2,"oralOnly":true,"q":{"understands":"most","knowsLetters":"some"},"lettersWithWords":true},"heb":{"on":true,"voice":true,"personal":true,"placement":true,"band":2,"readCheck":true,"q":{"knowsLetters":"reads"}},"rus":{"on":true,"voice":true,"personal":true,"placement":true,"band":2,"lettersBefore5":true,"stress":"off","route":"reader","q":{"home":"grandparentsOthers","understands":"most","speaks":"sentences","letters":"most","reads":"sentences"},"lettersWithWords":true}},"d9d9d9d9-0000-4000-8000-000000000104":{"eng":{"on":true,"voice":true,"personal":true,"placement":true,"band":2,"oralOnly":true,"q":{"understands":"most","knowsLetters":"some"},"lettersWithWords":true},"heb":{"on":true,"voice":true,"personal":true,"placement":true,"band":2,"readCheck":true,"q":{"knowsLetters":"reads"}},"rus":{"on":true,"voice":true,"personal":true,"placement":true,"band":2,"lettersBefore5":true,"stress":"off","route":"reader","q":{"home":"grandparentsOthers","understands":"most","speaks":"sentences","letters":"most","reads":"sentences"},"lettersWithWords":true}},"d9d9d9d9-0000-4000-8000-000000000105":{"eng":{"on":true,"voice":true,"personal":true,"placement":true,"band":2,"oralOnly":true,"q":{"understands":"most","knowsLetters":"some"},"lettersWithWords":true},"heb":{"on":true,"voice":true,"personal":true,"placement":true,"band":2,"readCheck":true,"q":{"knowsLetters":"reads"}},"rus":{"on":true,"voice":true,"personal":true,"placement":true,"band":2,"lettersBefore5":true,"stress":"off","route":"reader","q":{"home":"grandparentsOthers","understands":"most","speaks":"sentences","letters":"most","reads":"sentences"},"lettersWithWords":true}}},"looks":{"d9d9d9d9-0000-4000-8000-000000000100":"C","d9d9d9d9-0000-4000-8000-000000000101":"C","d9d9d9d9-0000-4000-8000-000000000102":"C","d9d9d9d9-0000-4000-8000-000000000103":"C","d9d9d9d9-0000-4000-8000-000000000104":"C","d9d9d9d9-0000-4000-8000-000000000105":"C"},"ribbons":{"d9d9d9d9-0000-4000-8000-000000000100":{"trophy:landa:bronze":"€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€","trophy:landa:silver":"€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€","trophy:landa:gold":"€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€","trophy:landb:bronze":"€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€","trophy:landb:silver":"€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€","trophy:landb:gold":"€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€","trophy:landc:bronze":"€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€","trophy:landc:silver":"€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€","trophy:landc:gold":"€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€","trophy:landd:bronze":"€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€","trophy:landd:silver":"€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€","trophy:landd:gold":"€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€","trophy:lande:bronze":"€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€","trophy:lande:silver":"€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€","trophy:lande:gold":"€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€","trophy:landf:bronze":"€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€","trophy:landf:silver":"€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€","trophy:landf:gold":"€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€"},"d9d9d9d9-0000-4000-8000-000000000101":{"trophy:landa:bronze":"€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€","trophy:landa:silver":"€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€","trophy:landa:gold":"€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€","trophy:landb:bronze":"€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€","trophy:landb:silver":"€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€","trophy:landb:gold":"€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€","trophy:landc:bronze":"€€€€€€€€€€€","trophy:landc:silver":"€","trophy:landc:gold":"€","trophy:landd:bronze":"€","trophy:landd:silver":"€","trophy:landd:gold":"€"}}}$doc$::jsonb as rules;
select lives_ok($$update app.family_settings set rules = (select rules from worst_rules)
  where family_id = 'd9d9d9d9-0000-4000-8000-000000000001'$$,
  'the largest document the gateway accepts (10,000 bytes, 3-byte characters, L7 fields and looks) fits the table');
select is((select count(*) from jsonb_object_keys((select rules -> 'languages' from app.family_settings
  where family_id = 'd9d9d9d9-0000-4000-8000-000000000001'))), 6::bigint, 'and all six children are stored');
select is((select count(*) from jsonb_object_keys((select rules -> 'looks' from app.family_settings
  where family_id = 'd9d9d9d9-0000-4000-8000-000000000001'))), 6::bigint, 'with the look of each');
-- The size the table's own check sees is that of the jsonb as it is built in memory (before it is compressed): text to jsonb again.
select ok(pg_column_size((select rules::text::jsonb from worst_rules)) <= 12288 - 512,
  'the largest document takes at most 11,776 of the 12,288 bytes of the table');

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
