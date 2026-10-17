-- No client policies: only the Edge Function may access these private objects.
-- It authorizes each operation against Firestore using the caller's Firebase JWT.
insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values (
  'boteparroquial-photos', 'boteparroquial-photos', false, 524288,
  array['image/jpeg', 'image/png', 'image/webp']
)
on conflict (id) do nothing;

-- Do not silently override a bucket that was manually configured differently.
do $$
begin
  if not exists (
    select 1 from storage.buckets
    where id = 'boteparroquial-photos'
      and public = false and file_size_limit = 524288
      and allowed_mime_types @> array['image/jpeg', 'image/png', 'image/webp']
      and array_length(allowed_mime_types, 1) = 3
  ) then
    raise exception 'Existing photo bucket differs: review its configuration';
  end if;
end $$;
