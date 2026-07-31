-- Nineteen cases, as data.
--
-- One case per situation on the sheet. Rows carry no case labels on purpose: a row records
-- what happened, never which scenario it was written for. Which claim belongs to which case
-- is knowable only from the comments here.
--
-- Every verdict, note, amount and release below is computed by decide_friend and
-- decide_patient at the bottom of this file, never typed in. The only hand-written inputs
-- are the events themselves and the two manual photo ID outcomes, because a human makes
-- those.
--
-- Everyone is invented. Phone numbers come from Ofcom's test range.
-- Claim ids are fixed because the pages key on them. Run after seed-matrix.sql.
-- Safe to re-run: clears its own rows first.

delete from public.grant_patient_discount;
delete from public.grant_friend_discount;
delete from public.friends;
delete from public.claims;
delete from public.patients;

-- ------------------------------------------------------------- the base: existing patients
-- Who the checks match against. All customers long before any claim below.

insert into public.patients
  (patient_id, first_name, last_name, email, phone, address_line, postcode,
   payment_fingerprint, customer_since) values
  ('11111111-0000-4000-8000-000000000001','Arthur','Bell','arthur.bell@gmail.com','+447700900101','12 Larch Way','LS1 4AB','c_9f01', now() - interval '300 days'),
  ('11111111-0000-4000-8000-000000000002','Margaret','Osei','m.osei@outlook.com','+447700900102','9 Mill Court','M4 2QQ','c_9f02', now() - interval '260 days'),
  ('11111111-0000-4000-8000-000000000003','Derek','Nash','derek.nash@yahoo.co.uk','+447700900103','4 Sable Road','BS2 8HG','c_9f03', now() - interval '220 days'),
  ('11111111-0000-4000-8000-000000000004','Fiona','Clarke','fiona.clarke@gmail.com','+447700900104','21 Fen Street','CF10 3AT','c_9f04', now() - interval '200 days'),
  ('11111111-0000-4000-8000-000000000005','Harold','Nash','h.nash@icloud.com','+447700900105','63 Marsh Way','EH3 9QA','c_9f05', now() - interval '180 days'),
  ('11111111-0000-4000-8000-000000000006','George','Adu','george.adu@gmail.com','+447700900106','88 King Street','G1 2AB','c_9f06', now() - interval '170 days');

-- ---------------------------------------------------------------------------- the referrers
-- Also patients. They share their links; the claims below are theirs.

insert into public.patients
  (patient_id, first_name, last_name, email, phone, address_line, postcode, customer_since) values
  ('11111111-0000-4000-8000-000000000011','Priya','Sharma','priya.sharma@gmail.com','+447700900201','5 Orchard Close','LE2 3FD', now() - interval '150 days'),
  ('11111111-0000-4000-8000-000000000012','Tom','Ellery','tom.ellery@gmail.com','+447700900202','30 Hazel Drive','S10 2LN', now() - interval '140 days'),
  ('11111111-0000-4000-8000-000000000013','Nadia','Kova','nadia.kova@outlook.com','+447700900203','8 Weir Gardens','NG7 1QP', now() - interval '130 days'),
  ('11111111-0000-4000-8000-000000000014','Ben','Achebe','ben.achebe@gmail.com','+447700900204','51 Corn Exchange','YO1 7HT', now() - interval '120 days'),
  ('11111111-0000-4000-8000-000000000015','Lucy','Tran','lucy.tran@proton.me','+447700900205','2 Dean Bank','DH1 4RA', now() - interval '110 days'),
  ('11111111-0000-4000-8000-000000000016','Omar','Said','omar.said@gmail.com','+447700900206','19 Firth Avenue','HD1 5PL', now() - interval '100 days'),
  ('11111111-0000-4000-8000-000000000017','Grace','Ito','grace.ito@icloud.com','+447700900207','44 Lea View','LU1 2TR', now() - interval '90 days'),
  ('11111111-0000-4000-8000-000000000018','Ada','Okon','ada.okon@outlook.com','+447700900208','16 Brook End','CB4 1XN', now() - interval '80 days'),
  ('11111111-0000-4000-8000-000000000019','Sam','Rhodes','sam.rhodes@gmail.com','+447700900209','27 Pier Road','BN1 6GH', now() - interval '75 days'),
  ('11111111-0000-4000-8000-000000000020','Elif','Demir','elif.demir@gmail.com','+447700900210','9 Kiln Court','ST4 2DP', now() - interval '70 days'),
  ('11111111-0000-4000-8000-000000000021','Noor','Haddad','noor.haddad@gmail.com','+447700900211','12 Ferry Lane','SO14 3JX', now() - interval '65 days'),
  ('11111111-0000-4000-8000-000000000022','Kofi','Mensah','kofi.mensah@gmail.com','+447700900212','6 Moor Gate','PR1 8UQ', now() - interval '60 days'),
  ('11111111-0000-4000-8000-000000000023','Dana','Cole','dana.cole@outlook.com','+447700900213','71 Spring Row','DE1 3QZ', now() - interval '55 days');

-- --------------------------------------------------------------------------------- claims
-- One row per link click. Cases 1 to 8 walk the matrix; 9 to 11 are the dedupe catches;
-- 12 to 14 the payout tiers; 15 to 18 the lifecycle; 19 the phone-to-email recovery.

insert into public.claims
  (claim_id, referrer_id, claim_channel, friend_email, friend_phone,
   creation_date, expiry_date, claim_status) values
  -- case 1: same full name, same address, same postcode as Arthur Bell. Father and son.
  ('22222222-0000-4000-8000-000000000001','11111111-0000-4000-8000-000000000012','whatsapp_link','arthur.bell.jr@gmail.com', null, now() - interval '20 days', now() + interval '160 days','transaction_success'),
  -- case 2: same full name and address as Margaret Osei, different postcode.
  ('22222222-0000-4000-8000-000000000002','11111111-0000-4000-8000-000000000013','email_link','margaret.osei91@gmail.com', null, now() - interval '19 days', now() + interval '161 days','transaction_success'),
  -- case 3: same full name and postcode as Derek Nash, different address. Neighbours.
  ('22222222-0000-4000-8000-000000000003','11111111-0000-4000-8000-000000000014','qr_code','dnash.bristol@gmail.com', null, now() - interval '18 days', now() + interval '162 days','transaction_success'),
  -- case 4: same full name as George Adu, nothing else matches.
  ('22222222-0000-4000-8000-000000000004','11111111-0000-4000-8000-000000000015','whatsapp_link','g.adu@outlook.com', null, now() - interval '17 days', now() + interval '163 days','transaction_success'),
  -- case 5: same surname, address and postcode as Harold Nash. Family members.
  ('22222222-0000-4000-8000-000000000005','11111111-0000-4000-8000-000000000016','sms_link','tessa.nash@gmail.com', null, now() - interval '16 days', now() + interval '164 days','transaction_success'),
  -- case 6: same address and postcode as Arthur Bell only. Unrelated housemates.
  ('22222222-0000-4000-8000-000000000006','11111111-0000-4000-8000-000000000017','whatsapp_link','jack.mora@gmail.com', null, now() - interval '15 days', now() + interval '165 days','transaction_success'),
  -- case 7: same first name and postcode. Neighbours with the same first name.
  ('22222222-0000-4000-8000-000000000007','11111111-0000-4000-8000-000000000022','qr_code','arthur.kane@gmail.com', null, now() - interval '14 days', now() + interval '166 days','transaction_success'),
  -- case 8: nothing matches anyone.
  ('22222222-0000-4000-8000-000000000008','11111111-0000-4000-8000-000000000023','email_link','yara.solis@gmail.com', null, now() - interval '13 days', now() + interval '167 days','transaction_success'),
  -- case 9: the claimed contact is Margaret Osei's own email. Already a customer.
  ('22222222-0000-4000-8000-000000000009','11111111-0000-4000-8000-000000000018','whatsapp_link','m.osei@outlook.com', null, now() - interval '12 days', now() + interval '168 days','discount_code_clicked'),
  -- case 10: registers as Fiona Clarke at Fiona Clarke's address, on a fresh email.
  ('22222222-0000-4000-8000-000000000010','11111111-0000-4000-8000-000000000012','email_link','fiona.c.new@gmail.com', null, now() - interval '11 days', now() + interval '169 days','account_created'),
  -- case 11, first claim: Sam refers Zoe. She converts through this one.
  ('22222222-0000-4000-8000-000000000011','11111111-0000-4000-8000-000000000019','whatsapp_link','zoe.quinn@gmail.com', null, now() - interval '9 days', now() + interval '171 days','transaction_success'),
  -- case 11, second claim: Ada refers the same Zoe two days later.
  ('22222222-0000-4000-8000-000000000020','11111111-0000-4000-8000-000000000018','sms_link','zoe.quinn@gmail.com', null, now() - interval '7 days', now() + interval '173 days','discount_code_clicked'),
  -- case 12: Priya's first successful referral.
  ('22222222-0000-4000-8000-000000000012','11111111-0000-4000-8000-000000000011','whatsapp_link','leo.park@gmail.com', null, now() - interval '30 days', now() + interval '150 days','transaction_success'),
  -- case 13: Priya's second successful referral.
  ('22222222-0000-4000-8000-000000000013','11111111-0000-4000-8000-000000000011','whatsapp_link','nina.okafor@gmail.com', null, now() - interval '10 days', now() + interval '170 days','transaction_success'),
  -- case 14: Priya's open claim. The refused second 80 is demonstrated on it at the bottom.
  ('22222222-0000-4000-8000-000000000014','11111111-0000-4000-8000-000000000011','qr_code','asha.verma@gmail.com', null, now() - interval '3 days', now() + interval '177 days','discount_code_clicked'),
  -- case 15: registered, approved, then the window closed with no delivery.
  ('22222222-0000-4000-8000-000000000015','11111111-0000-4000-8000-000000000020','email_link','rosa.vane@gmail.com', null, now() - interval '7 months', now() - interval '1 month','account_created'),
  -- case 16: clicked the link, never registered.
  ('22222222-0000-4000-8000-000000000016','11111111-0000-4000-8000-000000000020','whatsapp_link','pete.hale@gmail.com', null, now() - interval '4 days', now() + interval '176 days','discount_code_clicked'),
  -- case 17: registered, discount approved, no order yet.
  ('22222222-0000-4000-8000-000000000017','11111111-0000-4000-8000-000000000020','sms_link','ivo.marsh@gmail.com', null, now() - interval '6 days', now() + interval '174 days','account_created'),
  -- case 18: registered as a full name-and-address match. Photo ID check still pending.
  ('22222222-0000-4000-8000-000000000018','11111111-0000-4000-8000-000000000020','qr_code','peggy.osei@gmail.com', null, now() - interval '5 days', now() + interval '175 days','account_created'),
  -- case 19: claimed with a phone number only; registered with an email.
  ('22222222-0000-4000-8000-000000000019','11111111-0000-4000-8000-000000000021','whatsapp_link', null,'+447700900555', now() - interval '8 days', now() + interval '172 days','transaction_success');

-- ---------------------------------------------------------------------- the registrations
-- What each friend typed at registration. Cases 9, 14 and 16 never registered.

insert into public.friends
  (claim_id, first_name, last_name, email, phone, address_line, postcode) values
  ('22222222-0000-4000-8000-000000000001','Arthur','Bell','arthur.bell.jr@gmail.com','+447700900301','12 Larch Way','LS1 4AB'),
  ('22222222-0000-4000-8000-000000000002','Margaret','Osei','margaret.osei91@gmail.com','+447700900302','9 Mill Court','M4 2QT'),
  ('22222222-0000-4000-8000-000000000003','Derek','Nash','dnash.bristol@gmail.com','+447700900303','6 Sable Road','BS2 8HG'),
  ('22222222-0000-4000-8000-000000000004','George','Adu','g.adu@outlook.com','+447700900304','5 Quay Lane','L1 8XY'),
  ('22222222-0000-4000-8000-000000000005','Tessa','Nash','tessa.nash@gmail.com','+447700900305','63 Marsh Way','EH3 9QA'),
  ('22222222-0000-4000-8000-000000000006','Jack','Mora','jack.mora@gmail.com','+447700900306','12 Larch Way','LS1 4AB'),
  ('22222222-0000-4000-8000-000000000007','Arthur','Kane','arthur.kane@gmail.com','+447700900307','14 Larch Way','LS1 4AB'),
  ('22222222-0000-4000-8000-000000000008','Yara','Solis','yara.solis@gmail.com','+447700900308','3 Birch Grove','OX4 7PL'),
  ('22222222-0000-4000-8000-000000000010','Fiona','Clarke','fiona.c.new@gmail.com','+447700900310','21 Fen Street','CF10 3AT'),
  ('22222222-0000-4000-8000-000000000011','Zoe','Quinn','zoe.quinn@gmail.com','+447700900311','40 Ash Row','SW9 1DE'),
  ('22222222-0000-4000-8000-000000000012','Leo','Park','leo.park@gmail.com','+447700900312','18 Vale Croft','M20 3RW'),
  ('22222222-0000-4000-8000-000000000013','Nina','Okafor','nina.okafor@gmail.com','+447700900313','7 Dockside','E14 5AB'),
  ('22222222-0000-4000-8000-000000000015','Rosa','Vane','rosa.vane@gmail.com','+447700900315','2 Heath Way','NE1 6PQ'),
  ('22222222-0000-4000-8000-000000000017','Ivo','Marsh','ivo.marsh@gmail.com','+447700900317','25 Glebe Road','BT7 1AA'),
  ('22222222-0000-4000-8000-000000000018','Margaret','Osei','peggy.osei@gmail.com','+447700900318','9 Mill Court','M4 2QQ'),
  ('22222222-0000-4000-8000-000000000019','Sana','Iqbal','sana.iq@gmail.com','+447700900555','11 Rope Walk','PL1 3TT');

-- ------------------------------------------------------------------------ the conversions
-- After an order completes, the friend becomes a patient, referred by their referrer.

insert into public.patients
  (patient_id, referrer_id, first_name, last_name, email, phone, address_line, postcode, customer_since) values
  ('11111111-0000-4000-8000-000000000031','11111111-0000-4000-8000-000000000012','Arthur','Bell','arthur.bell.jr@gmail.com','+447700900301','12 Larch Way','LS1 4AB', now() - interval '18 days'),
  -- Tessa (case 5) also pays with Harold's card: the shared card is recorded and, like the
  -- shared address, decides nothing. Set separately below to keep this insert uniform.
  ('11111111-0000-4000-8000-000000000032','11111111-0000-4000-8000-000000000013','Margaret','Osei','margaret.osei91@gmail.com','+447700900302','9 Mill Court','M4 2QT', now() - interval '17 days'),
  ('11111111-0000-4000-8000-000000000033','11111111-0000-4000-8000-000000000014','Derek','Nash','dnash.bristol@gmail.com','+447700900303','6 Sable Road','BS2 8HG', now() - interval '16 days'),
  ('11111111-0000-4000-8000-000000000034','11111111-0000-4000-8000-000000000015','George','Adu','g.adu@outlook.com','+447700900304','5 Quay Lane','L1 8XY', now() - interval '15 days'),
  ('11111111-0000-4000-8000-000000000035','11111111-0000-4000-8000-000000000016','Tessa','Nash','tessa.nash@gmail.com','+447700900305','63 Marsh Way','EH3 9QA', now() - interval '14 days'),
  ('11111111-0000-4000-8000-000000000036','11111111-0000-4000-8000-000000000017','Jack','Mora','jack.mora@gmail.com','+447700900306','12 Larch Way','LS1 4AB', now() - interval '13 days'),
  ('11111111-0000-4000-8000-000000000037','11111111-0000-4000-8000-000000000022','Arthur','Kane','arthur.kane@gmail.com','+447700900307','14 Larch Way','LS1 4AB', now() - interval '12 days'),
  ('11111111-0000-4000-8000-000000000038','11111111-0000-4000-8000-000000000023','Yara','Solis','yara.solis@gmail.com','+447700900308','3 Birch Grove','OX4 7PL', now() - interval '11 days'),
  ('11111111-0000-4000-8000-000000000039','11111111-0000-4000-8000-000000000019','Zoe','Quinn','zoe.quinn@gmail.com','+447700900311','40 Ash Row','SW9 1DE', now() - interval '5 days'),
  ('11111111-0000-4000-8000-000000000040','11111111-0000-4000-8000-000000000011','Leo','Park','leo.park@gmail.com','+447700900312','18 Vale Croft','M20 3RW', now() - interval '25 days'),
  ('11111111-0000-4000-8000-000000000041','11111111-0000-4000-8000-000000000011','Nina','Okafor','nina.okafor@gmail.com','+447700900313','7 Dockside','E14 5AB', now() - interval '5 days'),
  ('11111111-0000-4000-8000-000000000042','11111111-0000-4000-8000-000000000021','Sana','Iqbal','sana.iq@gmail.com','+447700900555','11 Rope Walk','PL1 3TT', now() - interval '6 days');

-- Case 5's shared family card, recorded like the shared address and deciding nothing.
update public.patients set payment_fingerprint = 'c_9f05'
 where patient_id = '11111111-0000-4000-8000-000000000035';

update public.claims set friend_patient_id = '11111111-0000-4000-8000-000000000031' where claim_id = '22222222-0000-4000-8000-000000000001';
update public.claims set friend_patient_id = '11111111-0000-4000-8000-000000000032' where claim_id = '22222222-0000-4000-8000-000000000002';
update public.claims set friend_patient_id = '11111111-0000-4000-8000-000000000033' where claim_id = '22222222-0000-4000-8000-000000000003';
update public.claims set friend_patient_id = '11111111-0000-4000-8000-000000000034' where claim_id = '22222222-0000-4000-8000-000000000004';
update public.claims set friend_patient_id = '11111111-0000-4000-8000-000000000035' where claim_id = '22222222-0000-4000-8000-000000000005';
update public.claims set friend_patient_id = '11111111-0000-4000-8000-000000000036' where claim_id = '22222222-0000-4000-8000-000000000006';
update public.claims set friend_patient_id = '11111111-0000-4000-8000-000000000037' where claim_id = '22222222-0000-4000-8000-000000000007';
update public.claims set friend_patient_id = '11111111-0000-4000-8000-000000000038' where claim_id = '22222222-0000-4000-8000-000000000008';
-- case 9: the claim resolves to Margaret Osei's existing account.
update public.claims set friend_patient_id = '11111111-0000-4000-8000-000000000002' where claim_id = '22222222-0000-4000-8000-000000000009';
update public.claims set friend_patient_id = '11111111-0000-4000-8000-000000000039' where claim_id = '22222222-0000-4000-8000-000000000011';
-- case 11, second claim: resolves to the same Zoe.
update public.claims set friend_patient_id = '11111111-0000-4000-8000-000000000039' where claim_id = '22222222-0000-4000-8000-000000000020';
update public.claims set friend_patient_id = '11111111-0000-4000-8000-000000000040' where claim_id = '22222222-0000-4000-8000-000000000012';
update public.claims set friend_patient_id = '11111111-0000-4000-8000-000000000041' where claim_id = '22222222-0000-4000-8000-000000000013';
update public.claims set friend_patient_id = '11111111-0000-4000-8000-000000000042' where claim_id = '22222222-0000-4000-8000-000000000019';

-- ------------------------------------------------------------------------- the decisions
-- Everything below is computed. The boolean argument is the human photo ID verdict, passed
-- only where the matrix sent the case to manual.

select public.decide_friend('22222222-0000-4000-8000-000000000001', true);   -- father and son: distinct
select public.decide_friend('22222222-0000-4000-8000-000000000002', true);
select public.decide_friend('22222222-0000-4000-8000-000000000003', true);
select public.decide_friend('22222222-0000-4000-8000-000000000004', true);
select public.decide_friend('22222222-0000-4000-8000-000000000005');
select public.decide_friend('22222222-0000-4000-8000-000000000006');
select public.decide_friend('22222222-0000-4000-8000-000000000007');
select public.decide_friend('22222222-0000-4000-8000-000000000008');
select public.decide_friend('22222222-0000-4000-8000-000000000009');
select public.decide_friend('22222222-0000-4000-8000-000000000010', false);  -- photo ID: an existing patient
select public.decide_friend('22222222-0000-4000-8000-000000000011');
select public.decide_friend('22222222-0000-4000-8000-000000000020');         -- after Zoe's first claim: refused
select public.decide_friend('22222222-0000-4000-8000-000000000012');
select public.decide_friend('22222222-0000-4000-8000-000000000013');
select public.decide_friend('22222222-0000-4000-8000-000000000014');
select public.decide_friend('22222222-0000-4000-8000-000000000015');
select public.decide_friend('22222222-0000-4000-8000-000000000016');
select public.decide_friend('22222222-0000-4000-8000-000000000017');
select public.decide_friend('22222222-0000-4000-8000-000000000018');         -- no verdict passed: pending
select public.decide_friend('22222222-0000-4000-8000-000000000019');

-- Order matters on the referrer side: Priya's first claim must be priced before her second.
select public.decide_patient('22222222-0000-4000-8000-000000000012');        -- Priya, first: 80
select public.decide_patient('22222222-0000-4000-8000-000000000013');        -- Priya, second: 40
select public.decide_patient('22222222-0000-4000-8000-000000000001');
select public.decide_patient('22222222-0000-4000-8000-000000000002');
select public.decide_patient('22222222-0000-4000-8000-000000000003');
select public.decide_patient('22222222-0000-4000-8000-000000000004');
select public.decide_patient('22222222-0000-4000-8000-000000000005');
select public.decide_patient('22222222-0000-4000-8000-000000000006');
select public.decide_patient('22222222-0000-4000-8000-000000000007');
select public.decide_patient('22222222-0000-4000-8000-000000000008');
select public.decide_patient('22222222-0000-4000-8000-000000000009');
select public.decide_patient('22222222-0000-4000-8000-000000000010');
select public.decide_patient('22222222-0000-4000-8000-000000000011');
select public.decide_patient('22222222-0000-4000-8000-000000000020');
select public.decide_patient('22222222-0000-4000-8000-000000000014');
select public.decide_patient('22222222-0000-4000-8000-000000000015');
select public.decide_patient('22222222-0000-4000-8000-000000000016');
select public.decide_patient('22222222-0000-4000-8000-000000000017');
select public.decide_patient('22222222-0000-4000-8000-000000000018');
select public.decide_patient('22222222-0000-4000-8000-000000000019');

-- ------------------------------------------------------- case 14: the refused second 80
-- Priya already holds a released 80. Handing her another is attempted here on purpose, and
-- the one_first_claim_per_referrer index throws it out. If it ever stops throwing, this
-- file fails loudly.

delete from public.grant_patient_discount where claim_id = '22222222-0000-4000-8000-000000000014';
do $$
begin
  insert into public.grant_patient_discount
    (claim_id, referrer_id, transaction_status, transaction_success,
     first_claim, referral_amount, release_patient_discount)
  values
    ('22222222-0000-4000-8000-000000000014','11111111-0000-4000-8000-000000000011',
     'success', true, true, 80, true);
  raise exception 'a second 80 for the same referrer was accepted: the index is missing';
exception when unique_violation then
  raise notice 'second 80 for the same referrer refused by one_first_claim_per_referrer, as designed';
end $$;
-- The claim's honest pending row goes back.
select public.decide_patient('22222222-0000-4000-8000-000000000014');
