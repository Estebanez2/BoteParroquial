-- Run ONLY on the notifications project after setting the private Vault values.
-- No Firebase credential, worker secret or token is stored in this source file.
-- Required Vault names: boteparroquial_worker_url, boteparroquial_worker_secret.
create extension if not exists pg_cron;
create extension if not exists pg_net with schema extensions;

do $$
begin
  if (select count(*) from vault.decrypted_secrets
      where name in ('boteparroquial_worker_url', 'boteparroquial_worker_secret')) <> 2 then
    raise exception 'Configure the two private worker Vault values first';
  end if;
end $$;

-- Replace only our job, never other schedules.
select cron.unschedule(jobid) from cron.job where jobname = 'boteparroquial-notifications';
select cron.schedule('boteparroquial-notifications', '*/15 * * * *', $job$
  select net.http_post(
    url := (select decrypted_secret from vault.decrypted_secrets where name = 'boteparroquial_worker_url'),
    headers := jsonb_build_object('Content-Type', 'application/json',
      'x-worker-secret', (select decrypted_secret from vault.decrypted_secrets where name = 'boteparroquial_worker_secret')),
    body := '{}'::jsonb,
    timeout_milliseconds := 120000
  );
$job$);
