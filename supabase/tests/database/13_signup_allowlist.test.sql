-- SEC-SU-1: the "Before User Created" hook lets only the owner's approved addresses sign up; the list, the schema and the
-- function are closed to every client role, and every refusal carries a message.
begin;
create extension if not exists pgtap with schema extensions;
select * from no_plan();

-- A tester asks the hook as GoTrue does: an event with the new user's address (or none).
create function pg_temp.hook_for(p_email text) returns jsonb language sql as $$
  select signup_gate.before_user_created(jsonb_build_object('user', jsonb_build_object('email', p_email)))
$$;
create function pg_temp.refused(p jsonb) returns boolean language sql as $$
  select coalesce(length(p #>> '{error,message}'), 0) > 0 and (p #>> '{error,http_code}')::int = 403
$$;

insert into signup_gate.approved_email (email) values
  ('invited@example.test'),
  ('kate@example.test'),
  (signup_gate.normalise_email(E'  Typed.Badly@Example.TEST\n'));

-- ---- who is on the list: one normalised form ---------------------------------------------------------------------------
select is(signup_gate.normalise_email(E'  MiXed@Example.Test \t\r\n'), 'mixed@example.test', 'normalising trims and lower-cases');
select is(signup_gate.normalise_email('name+alias@example.test'), 'name+alias@example.test', 'a plus-alias is kept as written');
select is(signup_gate.normalise_email('k' || chr(8490) || '@example.test'), 'k' || chr(8490) || '@example.test',
  'a lookalike letter (the Kelvin sign) does not fold into an ASCII one');
select ok(exists (select 1 from signup_gate.approved_email where email = 'typed.badly@example.test'),
  'the owner''s helper stores a badly typed address in the one form');
select throws_ok($$insert into signup_gate.approved_email (email) values ('Upper@example.test')$$, '23514', null,
  'a row with a capital letter is refused');
select throws_ok($$insert into signup_gate.approved_email (email) values (' padded@example.test')$$, '23514', null,
  'a row with a leading space is refused');
select throws_ok($$insert into signup_gate.approved_email (email) values ('no-at-sign')$$, '23514', null, 'a row with no @ is refused');
select throws_ok($$insert into signup_gate.approved_email (email) values ('a@b')$$, '23514', null, 'a row with no domain dot is refused');
select throws_ok($$insert into signup_gate.approved_email (email) values ('')$$, '23514', null, 'an empty row is refused');
select throws_ok($$insert into signup_gate.approved_email (email) values ('two@@example.test')$$, '23514', null, 'a double @ is refused');
select throws_ok($$insert into signup_gate.approved_email (email) values ('Ünï@example.test')$$, '23514', null, 'a non-ASCII row is refused');

-- ---- the hook: allowed ------------------------------------------------------------------------------------------------
select is(pg_temp.hook_for('invited@example.test'), '{}'::jsonb, 'a listed address is allowed (an empty object)');
select is(pg_temp.hook_for('INVITED@Example.Test'), '{}'::jsonb, 'upper case is allowed');
select is(pg_temp.hook_for(E'  invited@example.test \n'), '{}'::jsonb, 'surrounding spaces are allowed');
select is(pg_temp.hook_for('Typed.Badly@example.test'), '{}'::jsonb, 'an address the owner typed badly still matches');

-- ---- the hook: refused, always with a message and a 403 ---------------------------------------------------------------
select ok(pg_temp.refused(pg_temp.hook_for('stranger@example.test')), 'an address not on the list is refused with a message');
select is(pg_temp.hook_for('stranger@example.test') #>> '{error,message}', 'This address is not invited yet.',
  'the message says only that it is not invited yet');
select is(position('stranger' in (pg_temp.hook_for('stranger@example.test')::text)), 0, 'and does not repeat the address');
select ok(pg_temp.refused(pg_temp.hook_for('invited+friend@example.test')), 'a plus-alias of a listed address is another address');
select ok(pg_temp.refused(pg_temp.hook_for('xinvited@example.test')), 'a longer local part is refused');
select ok(pg_temp.refused(pg_temp.hook_for('invited@example.test.evil.test')), 'a longer domain is refused');
select ok(pg_temp.refused(pg_temp.hook_for('invited@example.testx')), 'a domain with a letter more is refused');
select ok(pg_temp.refused(pg_temp.hook_for('inv_ted@example.test')), 'an underscore is not a wildcard');
select ok(pg_temp.refused(pg_temp.hook_for('%@example.test')), 'a percent sign is not a wildcard');
select ok(pg_temp.refused(pg_temp.hook_for('k' || chr(8490) || 'ate@example.test')), 'a lookalike letter does not match a listed address');
select ok(pg_temp.refused(pg_temp.hook_for('')), 'an empty address is refused');
select ok(pg_temp.refused(pg_temp.hook_for(null)), 'a null address is refused');
select ok(pg_temp.refused(signup_gate.before_user_created('{}'::jsonb)), 'an event with no user is refused');
select ok(pg_temp.refused(signup_gate.before_user_created('{"user":{}}'::jsonb)), 'a user with no address is refused');
select ok(pg_temp.refused(signup_gate.before_user_created('{"user":{"email":5}}'::jsonb)), 'a number for an address is refused');
select ok(pg_temp.refused(signup_gate.before_user_created('[]'::jsonb)), 'an event that is not an object is refused');
select ok(pg_temp.refused(signup_gate.before_user_created('null'::jsonb)), 'a JSON null event is refused');
select ok(pg_temp.refused(signup_gate.before_user_created(null)), 'no event at all is refused');

-- ---- who can reach what -----------------------------------------------------------------------------------------------
select ok(has_schema_privilege('supabase_auth_admin', 'signup_gate', 'usage'), 'supabase_auth_admin can use the schema');
select ok(has_function_privilege('supabase_auth_admin', 'signup_gate.before_user_created(jsonb)', 'execute'),
  'supabase_auth_admin can run the hook');
select ok(not has_function_privilege('supabase_auth_admin', 'signup_gate.normalise_email(text)', 'execute'),
  'but not the helper');
select is(
  (select count(*)::int
     from pg_class c
     cross join (values ('SELECT'), ('INSERT'), ('UPDATE'), ('DELETE'), ('TRUNCATE'), ('REFERENCES'), ('TRIGGER')) as p(priv)
    where c.oid = 'signup_gate.approved_email'::regclass and has_table_privilege('supabase_auth_admin', c.oid, p.priv)),
  0, 'supabase_auth_admin has no right on the list itself (the hook reads it as its owner)');

select is(
  (select count(*)::int
     from (values ('public'), ('anon'), ('authenticated'), ('service_role'), ('app_gateway'), ('backup_reader')) as r(rolname)
     cross join (values ('usage'), ('create')) as p(priv)
    where has_schema_privilege(r.rolname, 'signup_gate', p.priv)),
  0, 'no other role has any right on the schema');
select is(
  (select count(*)::int
     from (values ('public'), ('anon'), ('authenticated'), ('service_role'), ('app_gateway'), ('backup_reader')) as r(rolname)
     cross join (values ('SELECT'), ('INSERT'), ('UPDATE'), ('DELETE'), ('TRUNCATE'), ('REFERENCES'), ('TRIGGER')) as p(priv)
    where has_table_privilege(r.rolname, 'signup_gate.approved_email', p.priv)),
  0, 'no other role has any right on the list');
select is(
  (select count(*)::int
     from pg_proc f
     join pg_namespace n on n.oid = f.pronamespace
     cross join (values ('public'), ('anon'), ('authenticated'), ('service_role'), ('app_gateway'), ('backup_reader')) as r(rolname)
    where n.nspname = 'signup_gate' and has_function_privilege(r.rolname, f.oid, 'execute')),
  0, 'no other role can run any function in the schema');
select ok((select relrowsecurity from pg_class where oid = 'signup_gate.approved_email'::regclass), 'row level security is on for the list');
select is((select count(*)::int from pg_policies where schemaname = 'signup_gate'), 0, 'and there is no policy that opens it');
select ok((select prosecdef from pg_proc where oid = 'signup_gate.before_user_created(jsonb)'::regprocedure), 'the hook runs as its owner');
select ok((select proconfig from pg_proc where oid = 'signup_gate.before_user_created(jsonb)'::regprocedure) @> array['search_path=pg_catalog'],
  'with a fixed search path');
select ok(not exists (select 1 from pg_class c join pg_namespace n on n.oid = c.relnamespace
                       where n.nspname = 'public' and c.relkind in ('r', 'p', 'v', 'm', 'f')),
  'the exposed public schema still holds no table or view');

-- ---- the client roles cannot call the hook or read the list, even with a session -----------------------------------------
set local role authenticated;
select throws_ok($$select signup_gate.before_user_created('{}'::jsonb)$$, '42501', null, 'a signed-in user cannot call the hook');
select throws_ok($$select count(*) from signup_gate.approved_email$$, '42501', null, 'a signed-in user cannot read the list');
reset role;
set local role anon;
select throws_ok($$select signup_gate.before_user_created('{}'::jsonb)$$, '42501', null, 'anon cannot call the hook');
select throws_ok($$select count(*) from signup_gate.approved_email$$, '42501', null, 'anon cannot read the list');
reset role;
set local role service_role;
select throws_ok($$select count(*) from signup_gate.approved_email$$, '42501', null, 'service_role cannot read the list');
reset role;

select * from finish();
rollback;
