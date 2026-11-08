-- Release signing: the server trusts the family build (`app.nitznutz.nitznutz`, flavour prod) signed with the owner's release key,
-- next to whatever is already in the list (the dev package with the debug-key fingerprint). The fingerprint is public (the
-- SHA-256 of the signing certificate, lower case, no colons); the key itself never leaves the owner's PC. Re-running changes
-- nothing: an older entry for the same package is replaced, every other entry is kept, and a missing row is created.
insert into app.config (key, value)
values (
  'android_allowed_apps',
  jsonb_build_array(jsonb_build_object(
    'package_name', 'app.nitznutz.nitznutz',
    'cert_sha256', jsonb_build_array('fbf648da2461d4488f94e45562c21ca98b1cdf28d5531b11b7ba778253c7cc6f')))
)
on conflict (key) do update
set value = coalesce(
      (select jsonb_agg(e) from jsonb_array_elements(
         case when jsonb_typeof(app.config.value) = 'array' then app.config.value else '[]'::jsonb end) as t(e)
       where e ->> 'package_name' is distinct from 'app.nitznutz.nitznutz'),
      '[]'::jsonb) || excluded.value,
    updated_at = now();
