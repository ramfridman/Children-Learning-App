-- M8: rewards (stickers, golden stars, trophies) travel as their own kind of event, so a second phone shows the same ones.
-- The payload is the same small object as for the other events (at most 2 KB); the function allows only a kind and an
-- award key in it, so nothing else about a child can ride along.
do $$
declare c text;
begin
  for c in
    select conname from pg_constraint
     where conrelid = 'app.event'::regclass and contype = 'c' and pg_get_constraintdef(oid) like '%attempt%session%'
  loop
    execute format('alter table app.event drop constraint %I', c);
  end loop;
end $$;

alter table app.event add constraint event_type_check check (type in ('attempt', 'session', 'reward'));
