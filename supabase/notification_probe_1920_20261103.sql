-- Additional explicitly requested test, 19:20 Europe/Madrid, 18:20 UTC.
-- Does not alter the 20:00 test or the regular worker.
select cron.schedule('boteparroquial-test-20261103-1920','20 18 3 11 *',$job$
do $body$
begin
  if current_timestamp >= timestamptz '2026-11-03 18:20:00+00' and current_timestamp < timestamptz '2026-11-03 18:30:00+00' then
    perform net.http_post(
      url := 'https://qngrmxfjckrrfiyioyzl.supabase.co/functions/v1/notification-probe',
      headers := jsonb_build_object('Content-Type','application/json','x-worker-secret',(select decrypted_secret from vault.decrypted_secrets where name='boteparroquial_worker_secret')),
      body := '{}'::jsonb, timeout_milliseconds := 30000);
  end if;
  perform cron.unschedule('boteparroquial-test-20261103-1920');
end $body$;
$job$);
