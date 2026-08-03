# The referral tables, rebuilt

Bolt Pharmacy's referral programme refuses referrals between people who share an address. Two
customers wrote it down in public. One was told his housemate was already a customer, which was
untrue, and the housemate bought from a competitor instead. The other joined because her husband
referred her, then watched her own credit vanish when their accounts merged over a shared home
address. Both referrals happened. Neither was paid.

An address is not an identity. This is the whole thing rebuilt as 6 Postgres tables: a claim that
exists before any account does, one rule held as data, and 19 worked cases with every verdict
decided inside the database and readable without an account.

## The six tables

| table | holds | how it works |
|---|---|---|
| **`patients`** | customer records | The account list. `referrer_id` holds at most one person, set when they convert and never changed after, so who introduced them cannot be rewritten later. `successful_referrals` is counted from released payouts by a trigger, never typed. `address_line` is deliberately not unique: recorded, and it decides nothing. |
| **`claims`** | events | One row per discount link click, written before any account exists, so a closed tab no longer ends a referral. Every claim carries an email or a phone number, and either one finds them later. `expiry_date` is creation plus 6 months, stored in the row rather than run as a job. One referrer can hold many claims, and where several customers claim the same friend the earliest one pays. |
| **`friends`** | onboarded friends | The name, contact and address typed at registration, and the row the four comparisons run against. Held apart from `patients` because at this point they are not one. |
| **`grant_friend_discount`** | verification records | Checks the claimant is not already a patient before the £40 is granted. Each patient is compared as a whole person, never field by field. `manual_verification_needed` is generated from the matrix row rather than set by hand, and `verdict_note` freezes the reason as it read at the time. A constraint blocks release unless the claim is approved and inside its window. UK photo ID carries no number to dedupe on, so genuine conflicts go to a human. |
| **`grant_patient_discount`** | order records | Decides whether the referrer gets their bonus. `first_claim` decides £80 or £40, and `referral_amount` accepts nothing else. A constraint blocks release unless the transaction succeeded, and a unique index refuses a second £80 to the same referrer whatever the code does. |
| **`verification_matrix`** | the rule itself | The 16 rows every verdict is read from. The four booleans are the primary key, so every combination exists exactly once. It has no foreign keys: the answer is copied onto the decision, so editing the rule changes what happens next and not what already happened. |

## The rule, in one line

A shop can only match on an address, because an address is all it holds. A pharmacy holds patient
records, so it can ask the better question: is this the same person? Those two tests disagree
exactly where it hurts, at a couple, a houseshare, a parent and an adult child.

**So: a human looks only when a first name and a last name both match an existing patient.** A
shared address changes nothing. A shared postcode changes nothing. A shared bank card changes
nothing. All three are recorded, shown, and ignored by the verdict.

| first name | last name | address | postcode | verdict | why |
|---|---|---|---|---|---|
| yes | yes | yes | yes | **a human looks** | could be father and son, same name, same address |
| yes | yes | yes | no | **a human looks** | could be the same person, different postcode |
| yes | yes | no | yes | **a human looks** | neighbours with same names |
| yes | yes | no | no | **a human looks** | could be the same person at a different address |
| yes | no | yes | yes | approved | |
| yes | no | yes | no | approved | |
| yes | no | no | yes | approved | neighbours with the same first name |
| yes | no | no | no | approved | |
| no | yes | yes | yes | approved | family members |
| no | yes | yes | no | approved | |
| no | yes | no | yes | approved | |
| no | yes | no | no | approved | |
| no | no | yes | yes | approved | unrelated housemates |
| no | no | yes | no | approved | |
| no | no | no | yes | approved | |
| no | no | no | no | approved | |

[Read those 16 rows straight out of the live database.](https://doiyvwwvddgokurwyvvb.supabase.co/rest/v1/verification_matrix?select=first_name_match,last_name_match,address_match,postcode_match,approved,note&order=first_name_match.desc,last_name_match.desc,address_match.desc,postcode_match.desc&apikey=sb_publishable__nHann-Y9PXbsuaJVmcAxg__f8Y0Rvy)

Manual review is 4 of the 16 combinations. Each patient is compared as a whole person, never field
by field, so two strangers who happen to share a first name and a surname between them never
trigger it.

## The complaint, re-run

A customer wrote publicly that Bolt refused him because a housemate at his address was already a
customer. Case 6 in the seed data is that exact situation, two different people at one address, run
through the rebuilt check. This is what the database recorded:

| first name | last name | address | postcode | goes to a human | verdict |
|---|---|---|---|---|---|
| no | no | yes | yes | no | **approved** |

The address matched and the postcode matched. Both were recorded, and neither decided anything.
Reason stored at the time: **unrelated housemates**.

## 19 cases, decided inside the database

Six went to a human, and every one of them turned on a full name. Three matched an address or a
postcode without matching both names, and none of the three was refused. Four end with nobody paid,
each for a different reason: the contact already belongs to a patient, an existing patient claiming
under a fresh email, a friend claimed twice where the earlier claim keeps it, and a referrer
refused a second £80 by the database itself.

**[`results.md`](results.md) is all 19 in full**: every comparison made, every verdict, and the
reason stored at the time. It is written by a script that reads the live tables, so it cannot drift
from what the system actually does.

## Two promises the database keeps by itself

```sql
create unique index one_first_claim_per_referrer
  on grant_patient_discount (referrer_id) where referral_amount = 80;

create unique index one_release_per_friend
  on grant_friend_discount (friend_patient_id) where release_friend_discount;
```

A referrer is paid £80 once, ever. A friend is released once, ever, however many people claimed
them. Neither is application code that could race. [`seed-cases.sql`](seed-cases.sql) attempts a
second £80 on purpose and fails loudly if the database ever accepts it.

## Read it live

No account, no terminal. The key in these links is the publishable one, which is meant to be public.

- [Every claim, with both verdicts and the stored reason](https://doiyvwwvddgokurwyvvb.supabase.co/rest/v1/claims?select=friend_email,friend_phone,claim_status,grant_friend_discount(manual_verification_needed,approved,verdict_note,release_friend_discount),grant_patient_discount(first_claim,referral_amount,release_patient_discount)&order=creation_date&apikey=sb_publishable__nHann-Y9PXbsuaJVmcAxg__f8Y0Rvy)
- [The patients, with successful_referrals counted from released payouts](https://doiyvwwvddgokurwyvvb.supabase.co/rest/v1/patients?select=first_name,last_name,address_line,postcode,successful_referrals,customer_since&order=customer_since&apikey=sb_publishable__nHann-Y9PXbsuaJVmcAxg__f8Y0Rvy)
- [Every verification, with the four comparisons](https://doiyvwwvddgokurwyvvb.supabase.co/rest/v1/grant_friend_discount?select=first_name_match,last_name_match,address_match,postcode_match,manual_verification_needed,manual_approved,approved,verdict_note,release_friend_discount&apikey=sb_publishable__nHann-Y9PXbsuaJVmcAxg__f8Y0Rvy)
- [Every payout decision](https://doiyvwwvddgokurwyvvb.supabase.co/rest/v1/grant_patient_discount?select=transaction_success,first_claim,referral_amount,release_patient_discount&apikey=sb_publishable__nHann-Y9PXbsuaJVmcAxg__f8Y0Rvy)

Filtering works: add `&approved=eq.false` to the verifications, or `&referral_amount=eq.80` to the
payouts. Writing does not. Select is the only privilege granted to anonymous readers, so an insert
returns 42501.

## Scope

It starts at the claim and stops at the payout. It does not decide who gets asked to refer, or
when, and it does not touch the share moment or the message. Getting more people to refer is a
different job from paying correctly the ones who already did.

It also puts nothing in public. Sharing stays inside private 1 to 1 channels, because public posts
naming prescription medicines are advertising, and the regulator ruled against four UK brands for
exactly that in February 2026.

## Files

The schema is in [`supabase/migrations/`](supabase/migrations/), applied by Supabase's GitHub
integration: a push to `main` runs any migration not yet run. Then the data is seeded by hand and
both files are safe to re-run: [`seed-matrix.sql`](seed-matrix.sql) is the 16 rows of the rule,
[`seed-cases.sql`](seed-cases.sql) is the 19 cases as data. `node render-tables.mjs` reads the live
tables and writes [`results.md`](results.md) and [`data/*.csv`](data/), which GitHub renders as
sortable grids. [`tables.md`](tables.md) is the design, written before the SQL.

## What is real and what is not

The tables, the rule, both indexes and both decision functions are real. Every verdict was computed
in Postgres, not typed.

The people are invented and the phone numbers come from Ofcom's test range.

The £80 and £40 are Bolt's own published amounts, captured from their live referral page on
2026-07-23.

The old rule is inferred from what customers described in public, and labelled as inference
wherever it appears. Bolt has never published how their check works.

Concept work by Jolene Fernandes. Not affiliated with Bolt Pharmacy.
