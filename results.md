# The nineteen cases, as the database answered them

Read back out of Postgres by `render-tables.mjs`, not typed. Re-run the script and this
page rewrites itself, so it cannot quietly drift away from what the system does.

31 people, 20 claims, 20 verification decisions, 20 payout decisions.

Which claim belongs to which case is the one hand-written thing here. A row records what
happened, never which scenario it was written for, so the labels come from the comments in
`seed-cases.sql`.

## Situation, and what happened

| # | Situation | What happened |
|---|---|---|
| | **Goes to a human** | |
| 1 | Same full name, same address, same postcode | photo ID checked, approved: could be father and son, same name, same address |
| 2 | Same full name, same address, different postcode | photo ID checked, approved: could be the same person, sending to a different... |
| 3 | Same full name, same postcode, different address | photo ID checked, approved: neighbours with same names |
| 4 | Same full name, nothing else matches | photo ID checked, approved: could be the same person sending to a different a... |
| 10 | An existing patient claims again under a new email | photo ID checked, refused |
| 18 | The photo ID check is still pending | nothing releases until a human decides |
| | **The payout** | |
| 12 | The referrer's first successful claim | approved, referrer paid 80 |
| 13 | The same referrer, second successful claim | approved, referrer paid 40 |
| 14 | A second 80 is attempted for the same referrer | the database refuses the write, so nothing is paid |
| | **Approved without a human** | |
| 5 | Same surname, address, postcode and bank card | approved, referrer paid 80 |
| 6 | Same address and postcode only | approved, referrer paid 80 |
| 7 | Same first name, same postcode | approved, referrer paid 80 |
| 8 | Nothing matches anyone | approved, referrer paid 80 |
| 11a | Two customers claim the same friend: the earlier claim | approved, referrer paid 80 |
| 17 | Registered, never ordered | approved, the bonus waits for the order |
| 19 | Claimed by phone, registered with an email | approved, referrer paid 80 |
| | **Not a referral** | |
| 9 | The claimed contact already belongs to a patient | already a customer: no reward, nobody told |
| 11b | Two customers claim the same friend: the later claim | the earlier claim keeps it |
| | **Nothing happens yet, or ever** | |
| 15 | The window closes with no delivery | the window closed, nothing released |
| 16 | Clicked the link, never registered | held: nobody has registered |

## Every case, and the evidence behind it

| # | Case | Names match | Household match | Verdict | Friend paid | Referrer paid |
|---|---|---|---|---|---|---|
| 1 | Same full name, same address, same postcode | first + last | address + postcode | **a human approved it** | yes | yes, 80 |
| 2 | Same full name, same address, different postcode | first + last | address | **a human approved it** | yes | yes, 80 |
| 3 | Same full name, same postcode, different address | first + last | postcode | **a human approved it** | yes | yes, 80 |
| 4 | Same full name, nothing else matches | first + last | neither | **a human approved it** | yes | yes, 80 |
| 5 | Same surname, address, postcode and bank card | last | address + postcode | **approved** | yes | yes, 80 |
| 6 | Same address and postcode only | neither | address + postcode | **approved** | yes | yes, 80 |
| 7 | Same first name, same postcode | first | postcode | **approved** | yes | yes, 80 |
| 8 | Nothing matches anyone | neither | neither | **approved** | yes | yes, 80 |
| 9 | The claimed contact already belongs to a patient | not checked | not checked | **refused** | no | no |
| 10 | An existing patient claims again under a new email | first + last | address + postcode | **a human refused it** | no | no |
| 11a | Two customers claim the same friend: the earlier claim | neither | neither | **approved** | yes | yes, 80 |
| 11b | Two customers claim the same friend: the later claim | neither | neither | **approved, but an earlier claim keeps it** | no | no |
| 12 | The referrer's first successful claim | neither | neither | **approved** | yes | yes, 80 |
| 13 | The same referrer, second successful claim | neither | neither | **approved** | yes | yes, 40 |
| 14 | A second 80 is attempted for the same referrer | not checked | not checked | **nothing to check yet** | no | no |
| 15 | The window closes with no delivery | neither | neither | **approved** | no | no |
| 16 | Clicked the link, never registered | not checked | not checked | **nothing to check yet** | no | no |
| 17 | Registered, never ordered | neither | neither | **approved** | yes | no |
| 18 | The photo ID check is still pending | first + last | address + postcode | **a human is looking** | no | no |
| 19 | Claimed by phone, registered with an email | neither | neither | **approved** | yes | yes, 80 |

6 claims went to a human, and every one of them turned on a full name.
3 claims matched an address or a postcode without matching both names.
0 of those were refused.

## Each case, and what the database recorded

### Case 1. Same full name, same address, same postcode

**Tom Ellery** referred `arthur.bell.jr@gmail.com` by `whatsapp_link` on 2026-07-11.
The claim reads `transaction_success`, and its window closes 2027-01-07.
They registered as **Arthur Bell**, 12 Larch Way, LS1 4AB.

| checked | result |
|---|---|
| first name matches an existing patient | yes |
| last name matches | yes |
| address matches | yes |
| postcode matches | yes |
| goes to a human | yes |
| a human approved it | yes |
| inside the window | yes |
| friend discount released | yes |

Recorded reason: could be father and son, same name, same address. photo ID checked: a distinct person

Referrer side: first claim yes, amount 80, released yes.

### Case 2. Same full name, same address, different postcode

**Nadia Kova** referred `margaret.osei91@gmail.com` by `email_link` on 2026-07-12.
The claim reads `transaction_success`, and its window closes 2027-01-08.
They registered as **Margaret Osei**, 9 Mill Court, M4 2QT.

| checked | result |
|---|---|
| first name matches an existing patient | yes |
| last name matches | yes |
| address matches | yes |
| postcode matches | no |
| goes to a human | yes |
| a human approved it | yes |
| inside the window | yes |
| friend discount released | yes |

Recorded reason: could be the same person, sending to a different postcode with coincidence same address. photo ID checked: a distinct person

Referrer side: first claim yes, amount 80, released yes.

### Case 3. Same full name, same postcode, different address

**Ben Achebe** referred `dnash.bristol@gmail.com` by `qr_code` on 2026-07-13.
The claim reads `transaction_success`, and its window closes 2027-01-09.
They registered as **Derek Nash**, 6 Sable Road, BS2 8HG.

| checked | result |
|---|---|
| first name matches an existing patient | yes |
| last name matches | yes |
| address matches | no |
| postcode matches | yes |
| goes to a human | yes |
| a human approved it | yes |
| inside the window | yes |
| friend discount released | yes |

Recorded reason: neighbours with same names. photo ID checked: a distinct person

Referrer side: first claim yes, amount 80, released yes.

### Case 4. Same full name, nothing else matches

**Lucy Tran** referred `g.adu@outlook.com` by `whatsapp_link` on 2026-07-14.
The claim reads `transaction_success`, and its window closes 2027-01-10.
They registered as **George Adu**, 5 Quay Lane, L1 8XY.

| checked | result |
|---|---|
| first name matches an existing patient | yes |
| last name matches | yes |
| address matches | no |
| postcode matches | no |
| goes to a human | yes |
| a human approved it | yes |
| inside the window | yes |
| friend discount released | yes |

Recorded reason: could be the same person sending to a different address. photo ID checked: a distinct person

Referrer side: first claim yes, amount 80, released yes.

### Case 5. Same surname, address, postcode and bank card

**Omar Said** referred `tessa.nash@gmail.com` by `sms_link` on 2026-07-15.
The claim reads `transaction_success`, and its window closes 2027-01-11.
They registered as **Tessa Nash**, 63 Marsh Way, EH3 9QA.

| checked | result |
|---|---|
| first name matches an existing patient | no |
| last name matches | yes |
| address matches | yes |
| postcode matches | yes |
| goes to a human | no |
| a human approved it | not yet |
| inside the window | yes |
| friend discount released | yes |

Recorded reason: family members

Referrer side: first claim yes, amount 80, released yes.

### Case 6. Same address and postcode only

**Grace Ito** referred `jack.mora@gmail.com` by `whatsapp_link` on 2026-07-16.
The claim reads `transaction_success`, and its window closes 2027-01-12.
They registered as **Jack Mora**, 12 Larch Way, LS1 4AB.

| checked | result |
|---|---|
| first name matches an existing patient | no |
| last name matches | no |
| address matches | yes |
| postcode matches | yes |
| goes to a human | no |
| a human approved it | not yet |
| inside the window | yes |
| friend discount released | yes |

Recorded reason: unrelated housemates

Referrer side: first claim yes, amount 80, released yes.

### Case 7. Same first name, same postcode

**Kofi Mensah** referred `arthur.kane@gmail.com` by `qr_code` on 2026-07-17.
The claim reads `transaction_success`, and its window closes 2027-01-13.
They registered as **Arthur Kane**, 14 Larch Way, LS1 4AB.

| checked | result |
|---|---|
| first name matches an existing patient | yes |
| last name matches | no |
| address matches | no |
| postcode matches | yes |
| goes to a human | no |
| a human approved it | not yet |
| inside the window | yes |
| friend discount released | yes |

Recorded reason: neighbours with the same first name

Referrer side: first claim yes, amount 80, released yes.

### Case 8. Nothing matches anyone

**Dana Cole** referred `yara.solis@gmail.com` by `email_link` on 2026-07-18.
The claim reads `transaction_success`, and its window closes 2027-01-14.
They registered as **Yara Solis**, 3 Birch Grove, OX4 7PL.

| checked | result |
|---|---|
| first name matches an existing patient | no |
| last name matches | no |
| address matches | no |
| postcode matches | no |
| goes to a human | no |
| a human approved it | not yet |
| inside the window | yes |
| friend discount released | yes |

Recorded reason: nothing here identifies this person as an existing patient

Referrer side: first claim yes, amount 80, released yes.

### Case 9. The claimed contact already belongs to a patient

**Ada Okon** referred `m.osei@outlook.com` by `whatsapp_link` on 2026-07-19.
The claim reads `discount_code_clicked`, and its window closes 2027-01-15.
Nobody registered on this claim, so there is nothing to compare.

| checked | result |
|---|---|
| first name matches an existing patient | not yet |
| last name matches | not yet |
| address matches | not yet |
| postcode matches | not yet |
| goes to a human | not yet |
| a human approved it | not yet |
| inside the window | yes |
| friend discount released | no |

Recorded reason: the claimed contact already belongs to an account opened before the claim

Referrer side: first claim yes, amount none yet, released no.

### Case 10. An existing patient claims again under a new email

**Tom Ellery** referred `fiona.c.new@gmail.com` by `email_link` on 2026-07-20.
The claim reads `account_created`, and its window closes 2027-01-16.
They registered as **Fiona Clarke**, 21 Fen Street, CF10 3AT.

| checked | result |
|---|---|
| first name matches an existing patient | yes |
| last name matches | yes |
| address matches | yes |
| postcode matches | yes |
| goes to a human | yes |
| a human approved it | no |
| inside the window | yes |
| friend discount released | no |

Recorded reason: could be father and son, same name, same address. photo ID checked: an existing patient

Referrer side: first claim no, amount none yet, released no.

### Case 11a. Two customers claim the same friend: the earlier claim

**Sam Rhodes** referred `zoe.quinn@gmail.com` by `whatsapp_link` on 2026-07-22.
The claim reads `transaction_success`, and its window closes 2027-01-18.
They registered as **Zoe Quinn**, 40 Ash Row, SW9 1DE.

| checked | result |
|---|---|
| first name matches an existing patient | no |
| last name matches | no |
| address matches | no |
| postcode matches | no |
| goes to a human | no |
| a human approved it | not yet |
| inside the window | yes |
| friend discount released | yes |

Recorded reason: nothing here identifies this person as an existing patient

Referrer side: first claim yes, amount 80, released yes.

### Case 11b. Two customers claim the same friend: the later claim

**Ada Okon** referred `zoe.quinn@gmail.com` by `sms_link` on 2026-07-24.
The claim reads `discount_code_clicked`, and its window closes 2027-01-20.
Nobody registered on this claim, so there is nothing to compare.

| checked | result |
|---|---|
| first name matches an existing patient | no |
| last name matches | no |
| address matches | no |
| postcode matches | no |
| goes to a human | no |
| a human approved it | not yet |
| inside the window | yes |
| friend discount released | no |

Recorded reason: nothing here identifies this person as an existing patient. an earlier claim already released for this person; the successful claim keeps it

Referrer side: first claim yes, amount none yet, released no.

### Case 12. The referrer's first successful claim

**Priya Sharma** referred `leo.park@gmail.com` by `whatsapp_link` on 2026-07-01.
The claim reads `transaction_success`, and its window closes 2026-12-28.
They registered as **Leo Park**, 18 Vale Croft, M20 3RW.

| checked | result |
|---|---|
| first name matches an existing patient | no |
| last name matches | no |
| address matches | no |
| postcode matches | no |
| goes to a human | no |
| a human approved it | not yet |
| inside the window | yes |
| friend discount released | yes |

Recorded reason: nothing here identifies this person as an existing patient

Referrer side: first claim yes, amount 80, released yes.

### Case 13. The same referrer, second successful claim

**Priya Sharma** referred `nina.okafor@gmail.com` by `whatsapp_link` on 2026-07-21.
The claim reads `transaction_success`, and its window closes 2027-01-17.
They registered as **Nina Okafor**, 7 Dockside, E14 5AB.

| checked | result |
|---|---|
| first name matches an existing patient | no |
| last name matches | no |
| address matches | no |
| postcode matches | no |
| goes to a human | no |
| a human approved it | not yet |
| inside the window | yes |
| friend discount released | yes |

Recorded reason: nothing here identifies this person as an existing patient

Referrer side: first claim no, amount 40, released yes.

### Case 14. A second 80 is attempted for the same referrer

**Priya Sharma** referred `asha.verma@gmail.com` by `qr_code` on 2026-07-28.
The claim reads `discount_code_clicked`, and its window closes 2027-01-24.
Nobody registered on this claim, so there is nothing to compare.

| checked | result |
|---|---|
| first name matches an existing patient | not yet |
| last name matches | not yet |
| address matches | not yet |
| postcode matches | not yet |
| goes to a human | not yet |
| a human approved it | not yet |
| inside the window | yes |
| friend discount released | no |

Recorded reason: no account yet, so there is nothing to check

Referrer side: first claim no, amount none yet, released no.

### Case 15. The window closes with no delivery

**Elif Demir** referred `rosa.vane@gmail.com` by `email_link` on 2025-12-31.
The claim reads `account_created`, and its window closes 2026-06-30.
They registered as **Rosa Vane**, 2 Heath Way, NE1 6PQ.

| checked | result |
|---|---|
| first name matches an existing patient | no |
| last name matches | no |
| address matches | no |
| postcode matches | no |
| goes to a human | no |
| a human approved it | not yet |
| inside the window | no |
| friend discount released | no |

Recorded reason: nothing here identifies this person as an existing patient

Referrer side: first claim yes, amount none yet, released no.

### Case 16. Clicked the link, never registered

**Elif Demir** referred `pete.hale@gmail.com` by `whatsapp_link` on 2026-07-27.
The claim reads `discount_code_clicked`, and its window closes 2027-01-23.
Nobody registered on this claim, so there is nothing to compare.

| checked | result |
|---|---|
| first name matches an existing patient | not yet |
| last name matches | not yet |
| address matches | not yet |
| postcode matches | not yet |
| goes to a human | not yet |
| a human approved it | not yet |
| inside the window | yes |
| friend discount released | no |

Recorded reason: no account yet, so there is nothing to check

Referrer side: first claim yes, amount none yet, released no.

### Case 17. Registered, never ordered

**Elif Demir** referred `ivo.marsh@gmail.com` by `sms_link` on 2026-07-25.
The claim reads `account_created`, and its window closes 2027-01-21.
They registered as **Ivo Marsh**, 25 Glebe Road, BT7 1AA.

| checked | result |
|---|---|
| first name matches an existing patient | no |
| last name matches | no |
| address matches | no |
| postcode matches | no |
| goes to a human | no |
| a human approved it | not yet |
| inside the window | yes |
| friend discount released | yes |

Recorded reason: nothing here identifies this person as an existing patient

Referrer side: first claim yes, amount none yet, released no.

### Case 18. The photo ID check is still pending

**Elif Demir** referred `peggy.osei@gmail.com` by `qr_code` on 2026-07-26.
The claim reads `account_created`, and its window closes 2027-01-22.
They registered as **Margaret Osei**, 9 Mill Court, M4 2QQ.

| checked | result |
|---|---|
| first name matches an existing patient | yes |
| last name matches | yes |
| address matches | yes |
| postcode matches | yes |
| goes to a human | yes |
| a human approved it | not yet |
| inside the window | yes |
| friend discount released | no |

Recorded reason: could be father and son, same name, same address. awaiting manual photo ID check

Referrer side: first claim yes, amount none yet, released no.

### Case 19. Claimed by phone, registered with an email

**Noor Haddad** referred `+447700900555` by `whatsapp_link` on 2026-07-23.
The claim reads `transaction_success`, and its window closes 2027-01-19.
They registered as **Sana Iqbal**, 11 Rope Walk, PL1 3TT.

| checked | result |
|---|---|
| first name matches an existing patient | no |
| last name matches | no |
| address matches | no |
| postcode matches | no |
| goes to a human | no |
| a human approved it | not yet |
| inside the window | yes |
| friend discount released | yes |

Recorded reason: nothing here identifies this person as an existing patient

Referrer side: first claim yes, amount 80, released yes.

## The rule, as sixteen rows

Yes means that field matches an existing patient. A human looks only when both names
match. The other two columns are recorded and shown, and change nothing.

| first name | last name | address | postcode | verdict | why |
|---|---|---|---|---|---|
| yes | yes | yes | yes | **a human looks** | could be father and son, same name, same address |
| yes | yes | yes | no | **a human looks** | could be the same person, sending to a different postcode with coincidence same address |
| yes | yes | no | yes | **a human looks** | neighbours with same names |
| yes | yes | no | no | **a human looks** | could be the same person sending to a different address |
| yes | no | yes | yes | approved |  |
| yes | no | yes | no | approved |  |
| yes | no | no | yes | approved | neighbours with the same first name |
| yes | no | no | no | approved |  |
| no | yes | yes | yes | approved | family members |
| no | yes | yes | no | approved |  |
| no | yes | no | yes | approved |  |
| no | yes | no | no | approved |  |
| no | no | yes | yes | approved | unrelated housemates |
| no | no | yes | no | approved |  |
| no | no | no | yes | approved |  |
| no | no | no | no | approved |  |

## The tables in full

GitHub renders these as sortable, searchable grids. Same rows as above, same export.

- [`data/patients.csv`](data/patients.csv). The account list, with successful_referrals counted from released payouts.
- [`data/claims.csv`](data/claims.csv). One row per referral link click.
- [`data/friends.csv`](data/friends.csv). What each friend typed at registration.
- [`data/verification_matrix.csv`](data/verification_matrix.csv). The rule, as data.
- [`data/grant_friend_discount.csv`](data/grant_friend_discount.csv). One row per verification, with the reason stored at the time.
- [`data/grant_patient_discount.csv`](data/grant_patient_discount.csv). One row per payout decision.
