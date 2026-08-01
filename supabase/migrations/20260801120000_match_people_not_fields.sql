-- Three fixes to the verification, all found by review rather than by the seed data.
--
-- 1. The four comparisons ran independently across the whole patient list, so they answered
--    "does anyone share this first name" and "does anyone share this last name", never "is
--    there one person who is both". A friend called Arthur Nash matched Arthur Bell on one
--    and Derek Nash on the other, and went to a human, though no Arthur Nash exists. Rare at
--    19 patients. At 50,000 it sends nearly every claim to review, which is the opposite of
--    the design. Now each patient is compared as a person, and the strictest verdict the
--    matrix returns for any one of them is the verdict.
--
-- 2. manual_verification_needed was a generated column hardcoding (first_name and last_name),
--    so editing verification_matrix could not change who goes to review. The rule was in two
--    places and only one of them was the table. It is now written from the matrix.
--
-- 3. A missing matrix row left the lookup null, which fell through to approved: fail-open on
--    a payout. It now raises.

alter table public.grant_friend_discount
  drop column manual_verification_needed;

alter table public.grant_friend_discount
  add column manual_verification_needed boolean;

create or replace function public.decide_friend(p_claim_id uuid,
                                                p_manual_approved boolean default null)
returns void language plpgsql security definer set search_path = public as $$
declare
  v_claim    public.claims;
  v_friend   public.friends;
  v_resolved public.patients;
  v_fn boolean; v_ln boolean; v_ad boolean; v_pc boolean;
  v_verdict text; v_rule_note text;
  v_approved boolean; v_note text; v_window boolean; v_release boolean;
begin
  delete from public.grant_friend_discount where claim_id = p_claim_id;
  select * into v_claim from public.claims where claim_id = p_claim_id;
  select * into v_friend from public.friends where claim_id = p_claim_id;
  v_window := now() < v_claim.expiry_date;

  if v_claim.friend_patient_id is not null then
    select * into v_resolved from public.patients
     where patient_id = v_claim.friend_patient_id;
  end if;

  if v_resolved.patient_id is not null
     and v_resolved.customer_since < v_claim.creation_date then
    insert into public.grant_friend_discount
      (claim_id, approved, verdict_note, within_window,
       release_friend_discount, friend_patient_id)
    values
      (p_claim_id, false,
       'the claimed contact already belongs to an account opened before the claim',
       v_window, false, v_claim.friend_patient_id);
    return;
  end if;

  if v_friend.claim_id is null and v_resolved.patient_id is null then
    insert into public.grant_friend_discount
      (claim_id, approved, verdict_note, within_window, release_friend_discount)
    values
      (p_claim_id, null, 'no account yet, so there is nothing to check', v_window, false);
    return;
  end if;

  if v_friend.claim_id is null then
    v_friend.first_name   := v_resolved.first_name;
    v_friend.last_name    := v_resolved.last_name;
    v_friend.address_line := v_resolved.address_line;
    v_friend.postcode     := v_resolved.postcode;
  end if;

  -- One patient at a time. Each is a person, compared on all four fields at once, and looked
  -- up in the matrix as that person. The strictest answer any single patient produces wins,
  -- and the four booleans stored are that patient's, not a mixture of several people's.
  select m.approved, m.note, x.fn, x.ln, x.ad, x.pc
    into v_verdict, v_rule_note, v_fn, v_ln, v_ad, v_pc
    from (
      select p.first_name = v_friend.first_name as fn,
             p.last_name  = v_friend.last_name  as ln,
             coalesce(p.address_line = v_friend.address_line, false) as ad,
             coalesce(p.postcode     = v_friend.postcode,     false) as pc
        from public.patients p
       where p.patient_id is distinct from v_claim.friend_patient_id
    ) x
    join public.verification_matrix m
      on m.first_name_match = x.fn and m.last_name_match = x.ln
     and m.address_match    = x.ad and m.postcode_match  = x.pc
   order by (m.approved = 'manual') desc,
            (x.fn::int + x.ln::int + x.ad::int + x.pc::int) desc
   limit 1;

  -- Nobody else on the list at all: the all-false row is the answer.
  if v_verdict is null then
    v_fn := false; v_ln := false; v_ad := false; v_pc := false;
    select approved, note into v_verdict, v_rule_note from public.verification_matrix
     where not first_name_match and not last_name_match
       and not address_match and not postcode_match;
  end if;

  -- Fail closed. A missing rule is a broken rule, not an approval.
  if v_verdict is null then
    raise exception 'verification_matrix has no row for %/%/%/%: refusing to decide',
      v_fn, v_ln, v_ad, v_pc;
  end if;

  if v_verdict = 'manual' then
    v_approved := p_manual_approved;
    v_note := coalesce(v_rule_note, 'both names match an existing patient')
              || case when p_manual_approved is null
                        then '. awaiting manual photo ID check'
                      when p_manual_approved
                        then '. photo ID checked: a distinct person'
                      else '. photo ID checked: an existing patient' end;
  else
    v_approved := true;
    v_note := coalesce(v_rule_note,
                       'nothing here identifies this person as an existing patient');
  end if;

  v_release := coalesce(v_approved, false) and v_window;
  if v_release and v_claim.friend_patient_id is not null
     and exists (select 1 from public.grant_friend_discount g
                  where g.friend_patient_id = v_claim.friend_patient_id
                    and g.release_friend_discount and g.claim_id <> p_claim_id) then
    v_release := false;
    v_note := v_note || '. an earlier claim already released for this person; '
                     || 'the successful claim keeps it';
  end if;

  insert into public.grant_friend_discount
    (claim_id, first_name_match, last_name_match, address_match, postcode_match,
     manual_verification_needed, manual_approved, approved, verdict_note, within_window,
     release_friend_discount, transaction_status, friend_patient_id)
  values
    (p_claim_id, v_fn, v_ln, v_ad, v_pc,
     v_verdict = 'manual', p_manual_approved, v_approved, v_note, v_window,
     v_release,
     case v_claim.claim_status when 'transaction_paid' then 'paid'
                               when 'transaction_delivered' then 'delivered'
                               when 'transaction_success' then 'success' end,
     v_claim.friend_patient_id);
end $$;

revoke execute on function public.decide_friend(uuid, boolean) from public, anon, authenticated;
