# The Bolt referral tables

A referral programme's duplicate check, rebuilt as six Postgres tables on Supabase. Bolt
Pharmacy's programme refuses referrals between people who share an address; two named public
reviews document it. A pharmacy already knows who its patients are, so this build checks names
instead of addresses, sends genuine conflicts to a human with a photo ID, and lets a shared
household through.

Concept work by Jolene Fernandes. Not affiliated with Bolt Pharmacy. Everyone in the data is
invented; phone numbers come from Ofcom's test range.

## The flow

1. A friend clicks a customer's link. A `claims` row exists from that second, so a closed tab
   no longer ends the referral.
2. The friend registers. Their details land in `friends`, and four comparisons run against the
   patient list: first name, last name, address, postcode.
3. `verification_matrix` turns the four answers into a verdict. One rule: both names matching
   sends the case to a human with a photo ID. Everything else auto-approves, shared household
   included.
4. The order completes and the friend becomes a patient. `grant_friend_discount` releases their
   discount once per human, ever: a partial unique index refuses a second release.
5. `grant_patient_discount` prices the referrer's bonus: 80 for their first successful
   referral, 40 after, and a second 80 is refused by the database itself.

## The rule, readable by anyone

The matrix is data, not code. [All 16 combinations with their explanations](https://doiyvwwvddgokurwyvvb.supabase.co/rest/v1/verification_matrix?select=*&order=first_name_match.desc,last_name_match.desc,address_match.desc,postcode_match.desc&apikey=sb_publishable__nHann-Y9PXbsuaJVmcAxg__f8Y0Rvy)
returns straight from Postgres in a browser. No account, no terminal; the key is the
publishable one, which is meant to be public.

More live reads:

- [The 20 claims with both verdicts](https://doiyvwwvddgokurwyvvb.supabase.co/rest/v1/claims?select=friend_email,friend_phone,claim_channel,claim_status,grant_friend_discount(approved,verdict_note,release_friend_discount),grant_patient_discount(first_claim,referral_amount,release_patient_discount)&order=creation_date&apikey=sb_publishable__nHann-Y9PXbsuaJVmcAxg__f8Y0Rvy)
- [The patients, with successful_referrals counted live](https://doiyvwwvddgokurwyvvb.supabase.co/rest/v1/patients?select=first_name,last_name,address_line,postcode,customer_since,successful_referrals&order=customer_since&apikey=sb_publishable__nHann-Y9PXbsuaJVmcAxg__f8Y0Rvy)
- [Every friend-side decision with its stored reason](https://doiyvwwvddgokurwyvvb.supabase.co/rest/v1/grant_friend_discount?select=first_name_match,last_name_match,address_match,postcode_match,manual_verification_needed,manual_approved,approved,verdict_note,release_friend_discount&apikey=sb_publishable__nHann-Y9PXbsuaJVmcAxg__f8Y0Rvy)
- [Every payout decision](https://doiyvwwvddgokurwyvvb.supabase.co/rest/v1/grant_patient_discount?select=transaction_status,transaction_success,first_claim,referral_amount,release_patient_discount&apikey=sb_publishable__nHann-Y9PXbsuaJVmcAxg__f8Y0Rvy)

Filtering works: add `&approved=eq.false` to the decisions, or `&referral_amount=eq.80` to the
payouts. Writing does not: select is the only privilege granted, so an insert returns 42501.

## What the data shows

Nineteen cases. Cases 1 to 4 are the four name-match combinations that go to a human; 5 to 8
the auto-approvals the old rule would have blocked or guessed at; 9 to 11 the dedupe catches
(already a customer, an existing patient on a fresh email, two customers claiming the same
friend); 12 to 14 the payout tiers, including a second 80 the database throws out; 15 to 18
the lifecycle states; 19 a claim made by phone and recovered by email.

Which claim is which case is written in [`seed-cases.sql`](seed-cases.sql) and nowhere else,
on purpose: a row records what happened, never which scenario it was written for.

## Two guarantees the database makes itself

```sql
create unique index one_release_per_friend
  on grant_friend_discount (friend_patient_id) where release_friend_discount;

create unique index one_first_claim_per_referrer
  on grant_patient_discount (referrer_id) where referral_amount = 80;
```

A friend is released once, ever. A referrer's 80 happens once, ever. Code can race or lie;
these cannot. `seed-cases.sql` attempts the second 80 on purpose and prints the refusal.

## Files

- [`tables.md`](tables.md): the specification, transcribed from the design sheet with every
  cell note.
- [`schema.sql`](schema.sql): the six tables, the two indexes, the two decide functions,
  RLS and read-only grants.
- [`seed-matrix.sql`](seed-matrix.sql): the 16 matrix rows.
- [`seed-cases.sql`](seed-cases.sql): the 19 cases. Verdicts, notes, amounts and releases are
  computed by the decide functions at seed time, never typed in.
- [`cases.html`](cases.html): the nineteen cases, situation and solution, grouped.

Run order: schema, matrix, cases. All three are safe to re-run.

## What is real and what is not

The tables, the matrix, the two indexes and both decide functions are real: every verdict in
the live links was computed inside Postgres by the code in this repository. The people are
staged. The 80 and 40 are the proposed tiers from the build spec, not Bolt's published
amounts. The old rule ("refused on a shared address") is inferred from named public reviews
and labelled as inference everywhere it appears; Bolt has never published theirs.
