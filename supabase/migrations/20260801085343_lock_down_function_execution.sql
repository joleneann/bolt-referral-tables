-- Nothing that writes should be reachable over the API by anyone, signed in or not.
-- The decide functions are called by the seed file and by a maintainer, never by a visitor.
-- Revoking from `authenticated` as well as `anon` matters because Supabase Auth is on by
-- default, so a stranger can sign themselves up and become `authenticated`.

create or replace function public.is_first_claim(p_referrer_id uuid)
returns boolean language sql stable security invoker set search_path = public as $$
  select not exists (select 1 from public.grant_patient_discount g
                      where g.referrer_id = p_referrer_id and g.release_patient_discount);
$$;

revoke execute on function public.decide_friend(uuid, boolean) from public, anon, authenticated;
revoke execute on function public.decide_patient(uuid) from public, anon, authenticated;
revoke execute on function public.sync_successful_referrals() from public, anon, authenticated;

-- Read-only helper stays readable.
grant execute on function public.is_first_claim(uuid) to anon, authenticated;
