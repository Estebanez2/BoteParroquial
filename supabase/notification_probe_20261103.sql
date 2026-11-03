-- Two explicitly requested one-off tests, 18:00/20:00 Europe/Madrid.
-- ONLY notifications qngrmxfjckrrfiyioyzl. No credentials copied or new keys.
-- Each job removes itself after submitting its HTTP request. Existing cron intact.
do $setup$
begin
  if exists(select 1 from cron.job where jobname in ('boteparroquial-test-20261103-1','boteparroquial-test-20261103-2')) then
    raise exception 'Test jobs already exist; inspect before changing them';
  end if;
end $setup$;
select cron.schedule('boteparroquial-test-20261103-1','0 17 3 11 *',$job$
do $body$
begin
  if current_timestamp >= timestamptz '2026-11-03 17:00:00+00' and current_timestamp < timestamptz '2026-11-03 17:10:00+00' then
    perform net.http_post(
      url := 'https://qngrmxfjckrrfiyioyzl.supabase.co/functions/v1/notification-probe',
      headers := jsonb_build_object('Content-Type','application/json','x-worker-secret',(select decrypted_secret from vault.decrypted_secrets where name='boteparroquial_worker_secret')),
      body := '{}'::jsonb, timeout_milliseconds := 30000);
  end if;
  perform cron.unschedule('boteparroquial-test-20261103-1');
end $body$;
$job$);
select cron.schedule('boteparroquial-test-20261103-2','0 19 3 11 *',$job$
do $body$
begin
  if current_timestamp >= timestamptz '2026-11-03 19:00:00+00' and current_timestamp < timestamptz '2026-11-03 19:10:00+00' then
    perform net.http_post(
      url := 'https://qngrmxfjckrrfiyioyzl.supabase.co/functions/v1/notification-probe',
      headers := jsonb_build_object('Content-Type','application/json','x-worker-secret',(select decrypted_secret from vault.decrypted_secrets where name='boteparroquial_worker_secret')),
      body := '{}'::jsonb, timeout_milliseconds := 30000);
  end if;
  perform cron.unschedule('boteparroquial-test-20261103-2');
end $body$;
$job$);
