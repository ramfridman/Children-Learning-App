-- M7b: the weekly backup logs in as `backup_reader`, which can only read the `app` schema. It has no password here: a
-- password is set outside Git by tools/make-backup-login.ps1, and until then the role cannot log in at all. It reads
-- through row-level security (a dump must see every row) but cannot change anything: sessions are read-only.
do $$
begin
  if not exists (select 1 from pg_roles where rolname = 'backup_reader') then
    create role backup_reader login bypassrls noinherit nosuperuser nocreatedb nocreaterole noreplication connection limit 2;
  end if;
end $$;

alter role backup_reader set default_transaction_read_only = on;
alter role backup_reader set statement_timeout = '10min';

grant usage on schema app to backup_reader;
grant select on all tables in schema app to backup_reader;
grant select on all sequences in schema app to backup_reader;
alter default privileges in schema app grant select on tables to backup_reader;
alter default privileges in schema app grant select on sequences to backup_reader;
