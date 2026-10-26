-- M6: the tutor's tables are as closed as the rest, their limits hold, and the caps count exactly.
begin;
create extension if not exists pgtap with schema extensions;
select * from no_plan();

insert into app.family (id) values ('c1c1c1c1-0000-4000-8000-000000000001');

-- ---- published content ------------------------------------------------------------------------
insert into app.content_pack (pack_id, pack_version, manifest_sha256)
values ('starter', '0.2.0', repeat('a', 64));

select lives_ok($$insert into app.content_item
  (pack_id, pack_version, item_id, revision, template, band, skill_ids, llm_allowed, goal, prompt_text, answers,
   number_set, allowed_actions, hint_threshold, object_ids)
  values ('starter', '0.2.0', 'count.butterflies.3', 1, 'count_tap', 'A', '{NUM-A-03}', true,
          'touch each butterfly once', 'כמה פרפרים?',
          '[{"id":"o1","value":2,"correct":false},{"id":"o2","value":3,"correct":true}]'::jsonb,
          '{2,3}', '{show_fingers}', 3, '{o1,o2}')$$, 'an item can be published');

select throws_ok($$insert into app.content_item
  (pack_id, pack_version, item_id, revision, template, band, skill_ids, llm_allowed, goal, prompt_text, answers, hint_threshold)
  values ('starter', '0.2.0', 'bad item!', 1, 'count_tap', 'A', '{NUM-A-03}', true, 'g', 'p', '[{"id":"o1"}]'::jsonb, 3)$$,
  '23514', null, 'an item id with odd characters is refused');

select throws_ok($$insert into app.content_item
  (pack_id, pack_version, item_id, revision, template, band, skill_ids, llm_allowed, goal, prompt_text, answers, hint_threshold)
  values ('starter', '0.2.0', 'x', 1, 'count_tap', 'A', '{NUM-A-03}', true, 'g', 'p', '[{"id":"o1"}]'::jsonb, 4)$$,
  '23514', null, 'a hint threshold above 3 is refused');

select throws_ok($$insert into app.content_item
  (pack_id, pack_version, item_id, revision, template, band, skill_ids, llm_allowed, goal, prompt_text, answers, hint_threshold)
  values ('other', '1.0.0', 'x', 1, 'count_tap', 'A', '{NUM-A-03}', true, 'g', 'p', '[{"id":"o1"}]'::jsonb, 3)$$,
  '23503', null, 'an item needs its pack');

select lives_ok($$insert into app.family_character (character_id, name_he, gender, voice_id)
  values ('nitzi', 'נִיצִי', 'f', null)$$, 'a character can wait for its voice');
select throws_ok($$insert into app.family_character (character_id, name_he, gender, voice_id)
  values ('evil', 'Nitzi', 'f', null)$$, '23514', null, 'a character name is Hebrew letters only');
select throws_ok($$insert into app.family_character (character_id, name_he, gender, voice_id)
  values ('evil2', 'נִיצִי', 'f', 'bad id!')$$, '23514', null, 'a voice id is letters and digits only');

-- ---- the cache is tied to the item and to its versions ------------------------------------------
select lives_ok($$insert into app.tutor_cache
  (pack_id, pack_version, item_id, mistake, hint_level, band, address_form, character_id, prompt_version,
   validator_version, line, next_action, audio, audio_mime)
  values ('starter', '0.2.0', 'count.butterflies.3', 'M-CNT-DOUBLE', 1, 'A', 'n', 'nitzi', 'p1', 'v1',
          'בואו נספור לאט', 'replay_prompt_slow', '\x00ff'::bytea, 'audio/mpeg')$$, 'a validated line can be kept');
select throws_ok($$insert into app.tutor_cache
  (pack_id, pack_version, item_id, mistake, hint_level, band, address_form, character_id, prompt_version,
   validator_version, line, next_action, audio, audio_mime)
  values ('starter', '0.2.0', 'count.butterflies.3', 'not-a-tag', 1, 'A', 'n', 'nitzi', 'p1', 'v1',
          'x', 'none', null, null)$$, '23514', null, 'the mistake must be a tag or default');
select throws_ok($$insert into app.tutor_cache
  (pack_id, pack_version, item_id, mistake, hint_level, band, address_form, character_id, prompt_version,
   validator_version, line, next_action, audio, audio_mime)
  values ('starter', '0.2.0', 'count.butterflies.3', 'default', 1, 'A', 'n', 'nitzi', 'p1', 'v1',
          'x', 'none', decode(repeat('00', 70000), 'hex'), 'audio/mpeg')$$, '23514', null, 'a clip over 64 KB is refused');
select throws_ok($$insert into app.tutor_cache
  (pack_id, pack_version, item_id, mistake, hint_level, band, address_form, character_id, prompt_version,
   validator_version, line, next_action)
  values ('starter', '0.2.0', 'count.butterflies.3', 'M-CNT-DOUBLE', 1, 'A', 'n', 'nitzi', 'p1', 'v1', 'again', 'none')$$,
  '23505', null, 'the same line is never kept twice');
select lives_ok($$insert into app.tutor_cache
  (pack_id, pack_version, item_id, mistake, hint_level, band, address_form, character_id, prompt_version,
   validator_version, line, next_action)
  values ('starter', '0.2.0', 'count.butterflies.3', 'M-CNT-DOUBLE', 1, 'A', 'n', 'nitzi', 'p2', 'v1', 'again', 'none')$$,
  'a new prompt version makes a new entry');

-- ---- the caps count exactly -----------------------------------------------------------------------
create function pg_temp.take(p_kind text, p_child text, p_session text, p_cost bigint default 500000) returns text
language sql as $$
  select app.tutor_take('c1c1c1c1-0000-4000-8000-000000000001', p_child, p_session, p_kind, 3, 5, 2, p_cost, now())
$$;

select is(pg_temp.take('turn', 'kid1', 's1'), 'ok', 'turn 1 of a session is allowed');
select is(pg_temp.take('turn', 'kid1', 's1'), 'ok', 'turn 2');
select is(pg_temp.take('turn', 'kid1', 's1'), 'ok', 'turn 3');
select is(pg_temp.take('turn', 'kid1', 's1'), 'session_cap', 'turn 4 of a session is refused');
select is((select count from app.usage_counter where scope = 'tutor_day' and key = 'kid1'), 3,
  'a refused turn does not use up a slot of the day');
select is(pg_temp.take('turn', 'kid1', 's2'), 'ok', 'a new session starts again');
select is(pg_temp.take('turn', 'kid1', 's2'), 'ok', 'day turn 5');
select is(pg_temp.take('turn', 'kid1', 's3'), 'day_cap', 'the 6th turn of the day is refused for the child');
select is(pg_temp.take('turn', 'kid2', 's9'), 'ok', 'another child has their own day');

select is(pg_temp.take('prefetch', 'kid1', 'p1'), 'ok', 'prefetch 1');
select is(pg_temp.take('prefetch', 'kid1', 'p1'), 'ok', 'prefetch 2');
select is(pg_temp.take('prefetch', 'kid1', 'p1'), 'prefetch_cap', 'prefetch 3 is refused');
select is(pg_temp.take('prefetch', 'kid1', 'p1b'), 'ok', 'prefetch is counted per session');

select throws_ok($$select pg_temp.take('speak', 'kid1', 's1')$$, 'P0001', 'bad kind', 'an unknown kind is refused');

select app.tutor_cost_add('c1c1c1c1-0000-4000-8000-000000000001', 400000, now());
select is(pg_temp.take('turn', 'kid3', 's20'), 'ok', 'below the cost cap');
select app.tutor_cost_add('c1c1c1c1-0000-4000-8000-000000000001', 100000, now());
select is(pg_temp.take('turn', 'kid3', 's20'), 'cost_cap', 'at the cost cap nothing more is made, turn or prefetch');
select is(pg_temp.take('prefetch', 'kid3', 'p20'), 'cost_cap', 'the cost cap stops prefetch too');
select is((select count from app.usage_counter where scope = 'tutor_day' and key = 'kid3'), 1,
  'a refused call counts nothing');

-- ---- the log: closed to clients, cleaned after 30 days ----------------------------------------------
insert into app.tutor_log (family_id, child_ref, session_ref, pack_id, pack_version, item_id, character_id, source,
  outcome, line, validator_ok, prompt_version, total_ms)
values ('c1c1c1c1-0000-4000-8000-000000000001', 'kid1', 's1', 'starter', '0.2.0', 'count.butterflies.3', 'nitzi',
  'live', 'ok', 'בואו נספור לאט', true, 'p1', 900);
insert into app.tutor_log (family_id, child_ref, session_ref, pack_id, pack_version, item_id, character_id, source,
  outcome, prompt_version, created_at)
values ('c1c1c1c1-0000-4000-8000-000000000001', 'kid1', 's0', 'starter', '0.2.0', 'count.butterflies.3', 'nitzi',
  'rule', 'timeout', 'p1', now() - interval '31 days');
select app.purge_expired();
select is((select count(*)::int from app.tutor_log), 1, 'the tutor log older than 30 days is purged');
select ok(not has_table_privilege('app_gateway', 'app.tutor_log', 'delete'), 'the gateway cannot delete log rows itself');
select ok(not has_table_privilege('app_gateway', 'app.tutor_log', 'update'), 'the gateway cannot change log rows');

select * from finish();
rollback;
