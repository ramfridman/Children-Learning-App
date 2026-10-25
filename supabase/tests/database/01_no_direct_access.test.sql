-- No client role can reach the `app` schema, and every table keeps RLS on.
begin;
create extension if not exists pgtap with schema extensions;
select * from no_plan();

-- 1. Nobody but app_gateway has any privilege on the schema.
select ok(not has_schema_privilege('anon', 'app', 'usage'), 'anon has no USAGE on schema app');
select ok(not has_schema_privilege('authenticated', 'app', 'usage'), 'authenticated has no USAGE on schema app');
select ok(not has_schema_privilege('service_role', 'app', 'usage'), 'service_role has no USAGE on schema app');
select ok(not has_schema_privilege('anon', 'app', 'create'), 'anon has no CREATE on schema app');
select ok(not has_schema_privilege('authenticated', 'app', 'create'), 'authenticated has no CREATE on schema app');
select ok(has_schema_privilege('app_gateway', 'app', 'usage'), 'app_gateway has USAGE on schema app');
select ok(not has_schema_privilege('app_gateway', 'app', 'create'), 'app_gateway cannot create objects in schema app');

-- 2. No client role has any privilege on any table, sequence or function in the schema.
select is(
  (select count(*)::int
     from pg_class c
     join pg_namespace n on n.oid = c.relnamespace
     cross join (values ('anon'), ('authenticated'), ('service_role')) as r(rolname)
     cross join (values ('SELECT'), ('INSERT'), ('UPDATE'), ('DELETE'), ('TRUNCATE'), ('REFERENCES'), ('TRIGGER')) as p(priv)
    where n.nspname = 'app' and c.relkind in ('r', 'p', 'v', 'm', 'f')
      and has_table_privilege(r.rolname, c.oid, p.priv)),
  0,
  'anon, authenticated and service_role have no privilege on any app table');

select is(
  (select count(*)::int
     from pg_proc p
     join pg_namespace n on n.oid = p.pronamespace
     cross join (values ('anon'), ('authenticated'), ('service_role')) as r(rolname)
    where n.nspname = 'app' and has_function_privilege(r.rolname, p.oid, 'EXECUTE')),
  0,
  'anon, authenticated and service_role cannot execute any app function');

select is(
  (select count(*)::int
     from pg_proc p
     join pg_namespace n on n.oid = p.pronamespace
    where n.nspname = 'app' and has_function_privilege('public', p.oid, 'EXECUTE')),
  0,
  'PUBLIC cannot execute any app function');

-- 3. Every app table has RLS switched on.
select is(
  (select count(*)::int from pg_class c join pg_namespace n on n.oid = c.relnamespace
    where n.nspname = 'app' and c.relkind = 'r' and not c.relrowsecurity),
  0,
  'row level security is on for every app table');

-- 4. Nothing else is exposed by accident: no tables in the exposed `public` schema.
select is(
  (select count(*)::int from pg_class c join pg_namespace n on n.oid = c.relnamespace
    where n.nspname = 'public' and c.relkind in ('r', 'p', 'v', 'm', 'f')),
  0,
  'the exposed public schema holds no tables or views');

-- 5. The gateway role is not a login-less superuser in disguise and cannot touch auth.
select is(
  (select rolsuper or rolcreaterole or rolcreatedb or rolbypassrls or rolreplication
     from pg_roles where rolname = 'app_gateway'),
  false,
  'app_gateway has no elevated attributes');
select ok(not has_schema_privilege('app_gateway', 'auth', 'usage'), 'app_gateway cannot use schema auth');
select ok(not has_table_privilege('app_gateway', 'app.device', 'delete'), 'app_gateway cannot delete devices directly');

select * from finish();
rollback;
