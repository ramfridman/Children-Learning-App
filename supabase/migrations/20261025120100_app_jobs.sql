-- M0: scheduled clean-up. Runs inside the database with pg_cron.
-- Note: pg_cron jobs do not run while a free project is paused; they catch up on resume.

create function app.purge_expired() returns void
language plpgsql
security definer
set search_path = pg_catalog, app
as $$
begin
  -- Nonces are only needed for the 60-second clock window; keep 10 minutes.
  delete from app.request_nonce where seen_at < now() - interval '10 minutes';

  -- Challenges, pairing codes: gone one hour after they expire or are used.
  delete from app.enroll_challenge
    where expires_at < now() - interval '1 hour' or used_at < now() - interval '1 hour';
  delete from app.pairing_code
    where expires_at < now() - interval '1 hour'
       or used_at < now() - interval '1 hour'
       or burned_at < now() - interval '1 hour';

  delete from app.dev_device_allowlist where expires_at < now();
  delete from app.usage_counter where window_start < now() - interval '90 days';

  -- Devices unseen for 90 days are revoked automatically; revoked rows are kept 90 days.
  update app.device
    set revoked_at = now(), revoked_reason = 'inactive'
    where revoked_at is null and coalesce(last_seen_at, created_at) < now() - interval '90 days';
  delete from app.device where revoked_at < now() - interval '90 days';
end
$$;

revoke all on function app.purge_expired() from public, anon, authenticated, service_role;

create extension if not exists pg_cron with schema pg_catalog;

select cron.schedule('app-purge-expired', '* * * * *', $$select app.purge_expired()$$);
