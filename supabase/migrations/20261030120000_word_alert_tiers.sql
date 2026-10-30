-- Word alerts in three tiers (docs/child-safety): `disclosure` is an act (pushed), the new `concern` is a check (in the
-- app only) and `inappropriateWords` is the weekly note of swearing (never pushed). Nothing else changes: a word alert
-- still holds a category, a severity, a count, fixed characters in `detail` (tier, subcategory, row and list version)
-- and the words only while the parent keeps them, for 30 days.
do $$
declare c text;
begin
  for c in
    select conname from pg_constraint
     where conrelid = 'app.alert'::regclass and contype = 'c' and pg_get_constraintdef(oid) like '%pastLimit%'
  loop
    execute format('alter table app.alert drop constraint %I', c);
  end loop;
end $$;

alter table app.alert add constraint alert_category_check check (
  category in ('pastLimit', 'restHours', 'gateAttempts', 'guessing', 'frustration', 'inappropriateWords',
               'disclosure', 'absence', 'ribbonEarned', 'concern')
);
