-- M7b: the backup login can read every table of the `app` schema and do nothing else.
begin;
create extension if not exists pgtap with schema extensions;
select * from no_plan();

select ok((select rolcanlogin from pg_roles where rolname = 'backup_reader'), 'backup_reader is a login role');
select ok((select rolbypassrls from pg_roles where rolname = 'backup_reader'), 'it reads through row-level security, as a dump must');
select ok(
  (select not rolsuper and not rolcreaterole and not rolcreatedb and not rolreplication and not rolinherit
     from pg_roles where rolname = 'backup_reader'),
  'it is not a superuser and cannot create roles or databases');
select ok(
  exists (select 1 from pg_db_role_setting s join pg_roles r on r.oid = s.setrole
           where r.rolname = 'backup_reader' and 'default_transaction_read_only=on' = any (s.setconfig)),
  'its sessions are read-only');

select ok(has_schema_privilege('backup_reader', 'app', 'usage'), 'it can use schema app');
select ok(not has_schema_privilege('backup_reader', 'app', 'create'), 'it cannot create objects there');

select is(
  (select count(*)::int
     from pg_class c join pg_namespace n on n.oid = c.relnamespace
    where n.nspname = 'app' and c.relkind in ('r', 'p') and not has_table_privilege('backup_reader', c.oid, 'SELECT')),
  0, 'it can read every table of the app schema');

select is(
  (select count(*)::int
     from pg_class c join pg_namespace n on n.oid = c.relnamespace
     cross join (values ('INSERT'), ('UPDATE'), ('DELETE'), ('TRUNCATE'), ('REFERENCES'), ('TRIGGER')) as p(priv)
    where n.nspname = 'app' and c.relkind in ('r', 'p') and has_table_privilege('backup_reader', c.oid, p.priv)),
  0, 'it can change nothing in the app schema');

select is(
  (select count(*)::int
     from pg_class c join pg_namespace n on n.oid = c.relnamespace
    where n.nspname = 'app' and c.relkind = 'S'
      and not (case when c.relkind = 'S' then has_sequence_privilege('backup_reader', c.oid, 'SELECT') end)),
  0, 'it can read every sequence');

select ok(not has_schema_privilege('backup_reader', 'auth', 'usage'), 'it cannot reach the auth schema');
select ok(not has_function_privilege('backup_reader', 'app.delete_child(uuid, text)', 'execute'), 'it cannot run the functions of the app schema');

select * from finish();
rollback;
