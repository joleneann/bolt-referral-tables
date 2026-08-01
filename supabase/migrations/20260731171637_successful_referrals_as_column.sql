-- successful_referrals becomes a real column on patients, per the agreed sheet: visible in
-- the Table Editor, maintained by trigger from released payouts, never written by hand.

drop function if exists public.successful_referrals(public.patients);

alter table public.patients
  add column if not exists successful_referrals int not null default 0;

create or replace function public.sync_successful_referrals()
returns trigger language plpgsql security definer set search_path = public as $$
declare
  v_ins uuid; v_del uuid;
begin
  if tg_op in ('INSERT','UPDATE') then v_ins := new.referrer_id; end if;
  if tg_op in ('UPDATE','DELETE') then v_del := old.referrer_id; end if;
  update public.patients p
     set successful_referrals =
       (select count(*) from public.grant_patient_discount g
         where g.referrer_id = p.patient_id and g.release_patient_discount)
   where p.patient_id = any (array[v_ins, v_del]);
  return null;
end $$;

drop trigger if exists trg_sync_successful_referrals on public.grant_patient_discount;
create trigger trg_sync_successful_referrals
after insert or update or delete on public.grant_patient_discount
for each row execute function public.sync_successful_referrals();

revoke execute on function public.sync_successful_referrals() from public, anon;

-- Backfill from the current payout log.
update public.patients p
   set successful_referrals =
     (select count(*) from public.grant_patient_discount g
       where g.referrer_id = p.patient_id and g.release_patient_discount);
