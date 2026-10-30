-- The child's words in alerts (SEC-28, SEC-29), additive only:
-- - the words hold only the characters alert-create takes (a second layer under the gateway's pattern); NOT VALID, so
--   rows already saved through that same pattern are not re-read at deploy;
-- - the gateway may change only the count (a word alert said again), the read time and the words (emptied when the
--   family turns "keep the words" off), never anything else of an alert;
-- - an alert goes 30 days after the earlier of its device time and its server time, so a phone whose clock runs ahead
--   cannot keep it, or its words, any longer.
-- Deploy order: this migration, then the functions (alert-create, alert-list, settings-put), then the app.
alter table app.alert add constraint alert_words_charset_check
  check (words ~ '^[֐-׿A-Za-z0-9 .,?!''"-]*$') not valid;

revoke update on app.alert from app_gateway;
grant update (count, read_at, words) on app.alert to app_gateway;

create or replace function app.purge_expired() returns void
language plpgsql
security definer
set search_path = pg_catalog, app
as $$
begin
  delete from app.request_nonce where seen_at < now() - interval '10 minutes';

  delete from app.enroll_challenge
    where expires_at < now() - interval '1 hour' or used_at < now() - interval '1 hour';
  delete from app.pairing_code
    where expires_at < now() - interval '1 hour'
       or used_at < now() - interval '1 hour'
       or burned_at < now() - interval '1 hour';

  delete from app.dev_device_allowlist where expires_at < now();
  delete from app.usage_counter where window_start < now() - interval '90 days';

  update app.device
    set revoked_at = now(), revoked_reason = 'inactive'
    where revoked_at is null and coalesce(last_seen_at, created_at) < now() - interval '90 days';
  delete from app.device where revoked_at < now() - interval '90 days';

  delete from app.tutor_log where created_at < now() - interval '30 days';
  delete from app.tutor_cache where created_at < now() - interval '90 days';

  -- Alerts (and the words in them) are kept 30 days from the earlier of the device's time and the server's.
  delete from app.alert where least(client_at, created_at) < now() - interval '30 days';
  delete from app.deleted_child where deleted_at < now() - interval '365 days';
end
$$;

revoke all on function app.purge_expired() from public, anon, authenticated, service_role;
