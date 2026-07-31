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
  ('fef54078-1366-4518-b231-668f8fa54a09','Arthur','Bell','arthur.bell@gmail.com','+447700900101','12 Larch Way','LS1 4AB','c_9f01', now() - interval '300 days'),
  ('d66f3bf4-d699-4ab5-9fc1-f62b46283780','Margaret','Osei','m.osei@outlook.com','+447700900102','9 Mill Court','M4 2QQ','c_9f02', now() - interval '260 days'),
  ('e9c85da6-8102-462c-a857-f6181de52ca1','Derek','Nash','derek.nash@yahoo.co.uk','+447700900103','4 Sable Road','BS2 8HG','c_9f03', now() - interval '220 days'),
  ('5791276b-0909-4752-a65e-41c41a55bbd4','Fiona','Clarke','fiona.clarke@gmail.com','+447700900104','21 Fen Street','CF10 3AT','c_9f04', now() - interval '200 days'),
  ('3d200824-af07-406d-9b01-b5fb65d5dc50','Harold','Nash','h.nash@icloud.com','+447700900105','63 Marsh Way','EH3 9QA','c_9f05', now() - interval '180 days'),
  ('2d08648b-0f50-4718-9e90-0719b36eb9e7','George','Adu','george.adu@gmail.com','+447700900106','88 King Street','G1 2AB','c_9f06', now() - interval '170 days');

-- ---------------------------------------------------------------------------- the referrers
-- Also patients. They share their links; the claims below are theirs.

insert into public.patients
  (patient_id, first_name, last_name, email, phone, address_line, postcode, customer_since) values
  ('73814d21-5cea-4aef-8072-7e283abdd7b8','Priya','Sharma','priya.sharma@gmail.com','+447700900201','5 Orchard Close','LE2 3FD', now() - interval '150 days'),
  ('f5377cb0-df2b-475a-a414-5f2e6a771501','Tom','Ellery','tom.ellery@gmail.com','+447700900202','30 Hazel Drive','S10 2LN', now() - interval '140 days'),
  ('97103342-c46a-4772-a326-1391153eb8b1','Nadia','Kova','nadia.kova@outlook.com','+447700900203','8 Weir Gardens','NG7 1QP', now() - interval '130 days'),
  ('855e19a2-33d4-4fad-8add-1f4f2731c970','Ben','Achebe','ben.achebe@gmail.com','+447700900204','51 Corn Exchange','YO1 7HT', now() - interval '120 days'),
  ('ac7306ce-e1c3-4cf0-a518-3564c337ad35','Lucy','Tran','lucy.tran@proton.me','+447700900205','2 Dean Bank','DH1 4RA', now() - interval '110 days'),
  ('e1116be5-322b-44e8-a2af-b21fc41acfad','Omar','Said','omar.said@gmail.com','+447700900206','19 Firth Avenue','HD1 5PL', now() - interval '100 days'),
  ('3b108f69-68e6-43b7-acaf-61762c0bd45d','Grace','Ito','grace.ito@icloud.com','+447700900207','44 Lea View','LU1 2TR', now() - interval '90 days'),
  ('46291c27-ccb8-43ea-a25e-a3c23a7db933','Ada','Okon','ada.okon@outlook.com','+447700900208','16 Brook End','CB4 1XN', now() - interval '80 days'),
  ('cd0925c0-e8d9-41d8-a7cf-71bf94551ac2','Sam','Rhodes','sam.rhodes@gmail.com','+447700900209','27 Pier Road','BN1 6GH', now() - interval '75 days'),
  ('d197999f-a021-4cdf-83e3-c73d17f39c68','Elif','Demir','elif.demir@gmail.com','+447700900210','9 Kiln Court','ST4 2DP', now() - interval '70 days'),
  ('2c4d14e8-0a56-43f0-a522-461136381b08','Noor','Haddad','noor.haddad@gmail.com','+447700900211','12 Ferry Lane','SO14 3JX', now() - interval '65 days'),
  ('a3035c9b-dc5c-422d-b65e-58e77acefb9a','Kofi','Mensah','kofi.mensah@gmail.com','+447700900212','6 Moor Gate','PR1 8UQ', now() - interval '60 days'),
  ('91acab7b-12f6-4076-9d7f-721936e16aa9','Dana','Cole','dana.cole@outlook.com','+447700900213','71 Spring Row','DE1 3QZ', now() - interval '55 days');

-- ------------------------------------------------------------------- the referral chain
-- Every patient was referred by someone who joined before them. Arthur is the root: the
-- oldest account, from before the programme, so he alone has no referrer.

update public.patients set referrer_id = 'fef54078-1366-4518-b231-668f8fa54a09' where email = 'm.osei@outlook.com';       -- Margaret <- Arthur
update public.patients set referrer_id = 'fef54078-1366-4518-b231-668f8fa54a09' where email = 'derek.nash@yahoo.co.uk';   -- Derek <- Arthur
update public.patients set referrer_id = 'd66f3bf4-d699-4ab5-9fc1-f62b46283780' where email = 'fiona.clarke@gmail.com';   -- Fiona <- Margaret
update public.patients set referrer_id = 'e9c85da6-8102-462c-a857-f6181de52ca1' where email = 'h.nash@icloud.com';        -- Harold <- Derek
update public.patients set referrer_id = '5791276b-0909-4752-a65e-41c41a55bbd4' where email = 'george.adu@gmail.com';     -- George <- Fiona
update public.patients set referrer_id = '3d200824-af07-406d-9b01-b5fb65d5dc50' where email = 'priya.sharma@gmail.com';   -- Priya <- Harold
update public.patients set referrer_id = '2d08648b-0f50-4718-9e90-0719b36eb9e7' where email = 'tom.ellery@gmail.com';     -- Tom <- George
update public.patients set referrer_id = 'd66f3bf4-d699-4ab5-9fc1-f62b46283780' where email = 'nadia.kova@outlook.com';   -- Nadia <- Margaret
update public.patients set referrer_id = 'e9c85da6-8102-462c-a857-f6181de52ca1' where email = 'ben.achebe@gmail.com';     -- Ben <- Derek
update public.patients set referrer_id = '73814d21-5cea-4aef-8072-7e283abdd7b8' where email = 'lucy.tran@proton.me';      -- Lucy <- Priya
update public.patients set referrer_id = 'f5377cb0-df2b-475a-a414-5f2e6a771501' where email = 'omar.said@gmail.com';      -- Omar <- Tom
update public.patients set referrer_id = '5791276b-0909-4752-a65e-41c41a55bbd4' where email = 'grace.ito@icloud.com';     -- Grace <- Fiona
update public.patients set referrer_id = '97103342-c46a-4772-a326-1391153eb8b1' where email = 'ada.okon@outlook.com';     -- Ada <- Nadia
update public.patients set referrer_id = '855e19a2-33d4-4fad-8add-1f4f2731c970' where email = 'sam.rhodes@gmail.com';     -- Sam <- Ben
update public.patients set referrer_id = 'ac7306ce-e1c3-4cf0-a518-3564c337ad35' where email = 'elif.demir@gmail.com';     -- Elif <- Lucy
update public.patients set referrer_id = 'e1116be5-322b-44e8-a2af-b21fc41acfad' where email = 'noor.haddad@gmail.com';    -- Noor <- Omar
update public.patients set referrer_id = '3b108f69-68e6-43b7-acaf-61762c0bd45d' where email = 'kofi.mensah@gmail.com';    -- Kofi <- Grace
update public.patients set referrer_id = '46291c27-ccb8-43ea-a25e-a3c23a7db933' where email = 'dana.cole@outlook.com';    -- Dana <- Ada

-- --------------------------------------------------------------------------------- claims
-- One row per link click. Cases 1 to 8 walk the matrix; 9 to 11 are the dedupe catches;
-- 12 to 14 the payout tiers; 15 to 18 the lifecycle; 19 the phone-to-email recovery.

insert into public.claims
  (claim_id, referrer_id, claim_channel, friend_email, friend_phone,
   creation_date, expiry_date, claim_status) values
  -- case 1: same full name, same address, same postcode as Arthur Bell. Father and son.
  ('9278afb9-8331-4fe1-9b62-65a1b8d8ed02','f5377cb0-df2b-475a-a414-5f2e6a771501','whatsapp_link','arthur.bell.jr@gmail.com', null, now() - interval '20 days', now() + interval '160 days','transaction_success'),
  -- case 2: same full name and address as Margaret Osei, different postcode.
  ('a4488223-6308-4015-94f9-49e50c51a4a1','97103342-c46a-4772-a326-1391153eb8b1','email_link','margaret.osei91@gmail.com', null, now() - interval '19 days', now() + interval '161 days','transaction_success'),
  -- case 3: same full name and postcode as Derek Nash, different address. Neighbours.
  ('abd523c6-0935-408d-a8b4-1da1c2cd2cc8','855e19a2-33d4-4fad-8add-1f4f2731c970','qr_code','dnash.bristol@gmail.com', null, now() - interval '18 days', now() + interval '162 days','transaction_success'),
  -- case 4: same full name as George Adu, nothing else matches.
  ('b0049305-6016-441b-a464-a25a5edf7c20','ac7306ce-e1c3-4cf0-a518-3564c337ad35','whatsapp_link','g.adu@outlook.com', null, now() - interval '17 days', now() + interval '163 days','transaction_success'),
  -- case 5: same surname, address and postcode as Harold Nash. Family members.
  ('847e904c-355c-4188-b5e7-712de3d5ef17','e1116be5-322b-44e8-a2af-b21fc41acfad','sms_link','tessa.nash@gmail.com', null, now() - interval '16 days', now() + interval '164 days','transaction_success'),
  -- case 6: same address and postcode as Arthur Bell only. Unrelated housemates.
  ('73ab6008-b9a4-44c6-bab5-b388e9e3f38a','3b108f69-68e6-43b7-acaf-61762c0bd45d','whatsapp_link','jack.mora@gmail.com', null, now() - interval '15 days', now() + interval '165 days','transaction_success'),
  -- case 7: same first name and postcode. Neighbours with the same first name.
  ('56f5ad4d-062a-4d62-8047-ac20fb6c85ca','a3035c9b-dc5c-422d-b65e-58e77acefb9a','qr_code','arthur.kane@gmail.com', null, now() - interval '14 days', now() + interval '166 days','transaction_success'),
  -- case 8: nothing matches anyone.
  ('638dd1bf-ca20-4311-bb53-6b35d8075066','91acab7b-12f6-4076-9d7f-721936e16aa9','email_link','yara.solis@gmail.com', null, now() - interval '13 days', now() + interval '167 days','transaction_success'),
  -- case 9: the claimed contact is Margaret Osei's own email. Already a customer.
  ('ed8c179c-0102-41a4-adf7-d2a5b81e1811','46291c27-ccb8-43ea-a25e-a3c23a7db933','whatsapp_link','m.osei@outlook.com', null, now() - interval '12 days', now() + interval '168 days','discount_code_clicked'),
  -- case 10: registers as Fiona Clarke at Fiona Clarke's address, on a fresh email.
  ('3df0a425-e9e0-464d-b14a-299f2fc9e00d','f5377cb0-df2b-475a-a414-5f2e6a771501','email_link','fiona.c.new@gmail.com', null, now() - interval '11 days', now() + interval '169 days','account_created'),
  -- case 11, first claim: Sam refers Zoe. She converts through this one.
  ('3cf9a9c7-4eeb-421b-a309-1a6d90d76683','cd0925c0-e8d9-41d8-a7cf-71bf94551ac2','whatsapp_link','zoe.quinn@gmail.com', null, now() - interval '9 days', now() + interval '171 days','transaction_success'),
  -- case 11, second claim: Ada refers the same Zoe two days later.
  ('6b0b3721-d258-401e-bd3c-5550233221e1','46291c27-ccb8-43ea-a25e-a3c23a7db933','sms_link','zoe.quinn@gmail.com', null, now() - interval '7 days', now() + interval '173 days','discount_code_clicked'),
  -- case 12: Priya's first successful referral.
  ('4c904f72-3f3c-44bd-a1f6-54529db00387','73814d21-5cea-4aef-8072-7e283abdd7b8','whatsapp_link','leo.park@gmail.com', null, now() - interval '30 days', now() + interval '150 days','transaction_success'),
  -- case 13: Priya's second successful referral.
  ('de3eb6d2-ab0a-41b2-85e4-fa35dd409267','73814d21-5cea-4aef-8072-7e283abdd7b8','whatsapp_link','nina.okafor@gmail.com', null, now() - interval '10 days', now() + interval '170 days','transaction_success'),
  -- case 14: Priya's open claim. The refused second 80 is demonstrated on it at the bottom.
  ('fa739966-9b2d-4498-ad86-4509473d4fa3','73814d21-5cea-4aef-8072-7e283abdd7b8','qr_code','asha.verma@gmail.com', null, now() - interval '3 days', now() + interval '177 days','discount_code_clicked'),
  -- case 15: registered, approved, then the window closed with no delivery.
  ('a4920614-9eac-416e-b39d-55c5b9b1c764','d197999f-a021-4cdf-83e3-c73d17f39c68','email_link','rosa.vane@gmail.com', null, now() - interval '7 months', now() - interval '1 month','account_created'),
  -- case 16: clicked the link, never registered.
  ('603b4114-3edc-4e07-bcb1-5a33c2f473ac','d197999f-a021-4cdf-83e3-c73d17f39c68','whatsapp_link','pete.hale@gmail.com', null, now() - interval '4 days', now() + interval '176 days','discount_code_clicked'),
  -- case 17: registered, discount approved, no order yet.
  ('70f73779-7630-425c-a0c1-e207aad40870','d197999f-a021-4cdf-83e3-c73d17f39c68','sms_link','ivo.marsh@gmail.com', null, now() - interval '6 days', now() + interval '174 days','account_created'),
  -- case 18: registered as a full name-and-address match. Photo ID check still pending.
  ('a5763c67-2a64-40c7-9c77-583345753999','d197999f-a021-4cdf-83e3-c73d17f39c68','qr_code','peggy.osei@gmail.com', null, now() - interval '5 days', now() + interval '175 days','account_created'),
  -- case 19: claimed with a phone number only; registered with an email.
  ('1ec4eacd-0019-4455-b7b8-36dfdd6505fd','2c4d14e8-0a56-43f0-a522-461136381b08','whatsapp_link', null,'+447700900555', now() - interval '8 days', now() + interval '172 days','transaction_success');

-- ---------------------------------------------------------------------- the registrations
-- What each friend typed at registration. Cases 9, 14 and 16 never registered.

insert into public.friends
  (claim_id, first_name, last_name, email, phone, address_line, postcode) values
  ('9278afb9-8331-4fe1-9b62-65a1b8d8ed02','Arthur','Bell','arthur.bell.jr@gmail.com','+447700900301','12 Larch Way','LS1 4AB'),
  ('a4488223-6308-4015-94f9-49e50c51a4a1','Margaret','Osei','margaret.osei91@gmail.com','+447700900302','9 Mill Court','M4 2QT'),
  ('abd523c6-0935-408d-a8b4-1da1c2cd2cc8','Derek','Nash','dnash.bristol@gmail.com','+447700900303','6 Sable Road','BS2 8HG'),
  ('b0049305-6016-441b-a464-a25a5edf7c20','George','Adu','g.adu@outlook.com','+447700900304','5 Quay Lane','L1 8XY'),
  ('847e904c-355c-4188-b5e7-712de3d5ef17','Tessa','Nash','tessa.nash@gmail.com','+447700900305','63 Marsh Way','EH3 9QA'),
  ('73ab6008-b9a4-44c6-bab5-b388e9e3f38a','Jack','Mora','jack.mora@gmail.com','+447700900306','12 Larch Way','LS1 4AB'),
  ('56f5ad4d-062a-4d62-8047-ac20fb6c85ca','Arthur','Kane','arthur.kane@gmail.com','+447700900307','14 Larch Way','LS1 4AB'),
  ('638dd1bf-ca20-4311-bb53-6b35d8075066','Yara','Solis','yara.solis@gmail.com','+447700900308','3 Birch Grove','OX4 7PL'),
  ('3df0a425-e9e0-464d-b14a-299f2fc9e00d','Fiona','Clarke','fiona.c.new@gmail.com','+447700900310','21 Fen Street','CF10 3AT'),
  ('3cf9a9c7-4eeb-421b-a309-1a6d90d76683','Zoe','Quinn','zoe.quinn@gmail.com','+447700900311','40 Ash Row','SW9 1DE'),
  ('4c904f72-3f3c-44bd-a1f6-54529db00387','Leo','Park','leo.park@gmail.com','+447700900312','18 Vale Croft','M20 3RW'),
  ('de3eb6d2-ab0a-41b2-85e4-fa35dd409267','Nina','Okafor','nina.okafor@gmail.com','+447700900313','7 Dockside','E14 5AB'),
  ('a4920614-9eac-416e-b39d-55c5b9b1c764','Rosa','Vane','rosa.vane@gmail.com','+447700900315','2 Heath Way','NE1 6PQ'),
  ('70f73779-7630-425c-a0c1-e207aad40870','Ivo','Marsh','ivo.marsh@gmail.com','+447700900317','25 Glebe Road','BT7 1AA'),
  ('a5763c67-2a64-40c7-9c77-583345753999','Margaret','Osei','peggy.osei@gmail.com','+447700900318','9 Mill Court','M4 2QQ'),
  ('1ec4eacd-0019-4455-b7b8-36dfdd6505fd','Sana','Iqbal','sana.iq@gmail.com','+447700900555','11 Rope Walk','PL1 3TT');

-- ------------------------------------------------------------------------ the conversions
-- After an order completes, the friend becomes a patient, referred by their referrer.

insert into public.patients
  (patient_id, referrer_id, first_name, last_name, email, phone, address_line, postcode, customer_since) values
  ('7d34c8bc-9a65-4133-9d01-f31d95677735','f5377cb0-df2b-475a-a414-5f2e6a771501','Arthur','Bell','arthur.bell.jr@gmail.com','+447700900301','12 Larch Way','LS1 4AB', now() - interval '18 days'),
  -- Tessa (case 5) also pays with Harold's card: the shared card is recorded and, like the
  -- shared address, decides nothing. Set separately below to keep this insert uniform.
  ('33c782a4-d1ed-4782-b5b7-141bef2daf27','97103342-c46a-4772-a326-1391153eb8b1','Margaret','Osei','margaret.osei91@gmail.com','+447700900302','9 Mill Court','M4 2QT', now() - interval '17 days'),
  ('e507801f-0f57-4be7-957e-f450eac3a786','855e19a2-33d4-4fad-8add-1f4f2731c970','Derek','Nash','dnash.bristol@gmail.com','+447700900303','6 Sable Road','BS2 8HG', now() - interval '16 days'),
  ('5bdc0232-8584-48aa-9f54-eef54a0cbcdd','ac7306ce-e1c3-4cf0-a518-3564c337ad35','George','Adu','g.adu@outlook.com','+447700900304','5 Quay Lane','L1 8XY', now() - interval '15 days'),
  ('d209a08d-a211-469e-9ce9-9a79a5bf6f67','e1116be5-322b-44e8-a2af-b21fc41acfad','Tessa','Nash','tessa.nash@gmail.com','+447700900305','63 Marsh Way','EH3 9QA', now() - interval '14 days'),
  ('7e971f22-16f2-46ef-a596-8c8012c31e54','3b108f69-68e6-43b7-acaf-61762c0bd45d','Jack','Mora','jack.mora@gmail.com','+447700900306','12 Larch Way','LS1 4AB', now() - interval '13 days'),
  ('855c5b72-7f01-4d8f-8d91-cd2e24a299af','a3035c9b-dc5c-422d-b65e-58e77acefb9a','Arthur','Kane','arthur.kane@gmail.com','+447700900307','14 Larch Way','LS1 4AB', now() - interval '12 days'),
  ('d7b63986-0080-4e3b-adfa-10bc9182907d','91acab7b-12f6-4076-9d7f-721936e16aa9','Yara','Solis','yara.solis@gmail.com','+447700900308','3 Birch Grove','OX4 7PL', now() - interval '11 days'),
  ('e5e0afdd-cf27-4b72-ac73-a29fc1573042','cd0925c0-e8d9-41d8-a7cf-71bf94551ac2','Zoe','Quinn','zoe.quinn@gmail.com','+447700900311','40 Ash Row','SW9 1DE', now() - interval '5 days'),
  ('e88ca8b3-0810-4f2b-9939-6d8abad825d2','73814d21-5cea-4aef-8072-7e283abdd7b8','Leo','Park','leo.park@gmail.com','+447700900312','18 Vale Croft','M20 3RW', now() - interval '25 days'),
  ('108446c6-57f9-4051-b9fd-51411ef8e41a','73814d21-5cea-4aef-8072-7e283abdd7b8','Nina','Okafor','nina.okafor@gmail.com','+447700900313','7 Dockside','E14 5AB', now() - interval '5 days'),
  ('6df17ab9-a9b9-4266-93b5-2eaf290cc282','2c4d14e8-0a56-43f0-a522-461136381b08','Sana','Iqbal','sana.iq@gmail.com','+447700900555','11 Rope Walk','PL1 3TT', now() - interval '6 days');

-- Case 5's shared family card, recorded like the shared address and deciding nothing.
update public.patients set payment_fingerprint = 'c_9f05'
 where patient_id = 'd209a08d-a211-469e-9ce9-9a79a5bf6f67';

update public.claims set friend_patient_id = '7d34c8bc-9a65-4133-9d01-f31d95677735' where claim_id = '9278afb9-8331-4fe1-9b62-65a1b8d8ed02';
update public.claims set friend_patient_id = '33c782a4-d1ed-4782-b5b7-141bef2daf27' where claim_id = 'a4488223-6308-4015-94f9-49e50c51a4a1';
update public.claims set friend_patient_id = 'e507801f-0f57-4be7-957e-f450eac3a786' where claim_id = 'abd523c6-0935-408d-a8b4-1da1c2cd2cc8';
update public.claims set friend_patient_id = '5bdc0232-8584-48aa-9f54-eef54a0cbcdd' where claim_id = 'b0049305-6016-441b-a464-a25a5edf7c20';
update public.claims set friend_patient_id = 'd209a08d-a211-469e-9ce9-9a79a5bf6f67' where claim_id = '847e904c-355c-4188-b5e7-712de3d5ef17';
update public.claims set friend_patient_id = '7e971f22-16f2-46ef-a596-8c8012c31e54' where claim_id = '73ab6008-b9a4-44c6-bab5-b388e9e3f38a';
update public.claims set friend_patient_id = '855c5b72-7f01-4d8f-8d91-cd2e24a299af' where claim_id = '56f5ad4d-062a-4d62-8047-ac20fb6c85ca';
update public.claims set friend_patient_id = 'd7b63986-0080-4e3b-adfa-10bc9182907d' where claim_id = '638dd1bf-ca20-4311-bb53-6b35d8075066';
-- case 9: the claim resolves to Margaret Osei's existing account.
update public.claims set friend_patient_id = 'd66f3bf4-d699-4ab5-9fc1-f62b46283780' where claim_id = 'ed8c179c-0102-41a4-adf7-d2a5b81e1811';
update public.claims set friend_patient_id = 'e5e0afdd-cf27-4b72-ac73-a29fc1573042' where claim_id = '3cf9a9c7-4eeb-421b-a309-1a6d90d76683';
-- case 11, second claim: resolves to the same Zoe.
update public.claims set friend_patient_id = 'e5e0afdd-cf27-4b72-ac73-a29fc1573042' where claim_id = '6b0b3721-d258-401e-bd3c-5550233221e1';
update public.claims set friend_patient_id = 'e88ca8b3-0810-4f2b-9939-6d8abad825d2' where claim_id = '4c904f72-3f3c-44bd-a1f6-54529db00387';
update public.claims set friend_patient_id = '108446c6-57f9-4051-b9fd-51411ef8e41a' where claim_id = 'de3eb6d2-ab0a-41b2-85e4-fa35dd409267';
update public.claims set friend_patient_id = '6df17ab9-a9b9-4266-93b5-2eaf290cc282' where claim_id = '1ec4eacd-0019-4455-b7b8-36dfdd6505fd';

-- ------------------------------------------------------------------------- the decisions
-- Everything below is computed. The boolean argument is the human photo ID verdict, passed
-- only where the matrix sent the case to manual.

select public.decide_friend('9278afb9-8331-4fe1-9b62-65a1b8d8ed02', true);   -- father and son: distinct
select public.decide_friend('a4488223-6308-4015-94f9-49e50c51a4a1', true);
select public.decide_friend('abd523c6-0935-408d-a8b4-1da1c2cd2cc8', true);
select public.decide_friend('b0049305-6016-441b-a464-a25a5edf7c20', true);
select public.decide_friend('847e904c-355c-4188-b5e7-712de3d5ef17');
select public.decide_friend('73ab6008-b9a4-44c6-bab5-b388e9e3f38a');
select public.decide_friend('56f5ad4d-062a-4d62-8047-ac20fb6c85ca');
select public.decide_friend('638dd1bf-ca20-4311-bb53-6b35d8075066');
select public.decide_friend('ed8c179c-0102-41a4-adf7-d2a5b81e1811');
select public.decide_friend('3df0a425-e9e0-464d-b14a-299f2fc9e00d', false);  -- photo ID: an existing patient
select public.decide_friend('3cf9a9c7-4eeb-421b-a309-1a6d90d76683');
select public.decide_friend('6b0b3721-d258-401e-bd3c-5550233221e1');         -- after Zoe's first claim: refused
select public.decide_friend('4c904f72-3f3c-44bd-a1f6-54529db00387');
select public.decide_friend('de3eb6d2-ab0a-41b2-85e4-fa35dd409267');
select public.decide_friend('fa739966-9b2d-4498-ad86-4509473d4fa3');
select public.decide_friend('a4920614-9eac-416e-b39d-55c5b9b1c764');
select public.decide_friend('603b4114-3edc-4e07-bcb1-5a33c2f473ac');
select public.decide_friend('70f73779-7630-425c-a0c1-e207aad40870');
select public.decide_friend('a5763c67-2a64-40c7-9c77-583345753999');         -- no verdict passed: pending
select public.decide_friend('1ec4eacd-0019-4455-b7b8-36dfdd6505fd');

-- Order matters on the referrer side: Priya's first claim must be priced before her second.
select public.decide_patient('4c904f72-3f3c-44bd-a1f6-54529db00387');        -- Priya, first: 80
select public.decide_patient('de3eb6d2-ab0a-41b2-85e4-fa35dd409267');        -- Priya, second: 40
select public.decide_patient('9278afb9-8331-4fe1-9b62-65a1b8d8ed02');
select public.decide_patient('a4488223-6308-4015-94f9-49e50c51a4a1');
select public.decide_patient('abd523c6-0935-408d-a8b4-1da1c2cd2cc8');
select public.decide_patient('b0049305-6016-441b-a464-a25a5edf7c20');
select public.decide_patient('847e904c-355c-4188-b5e7-712de3d5ef17');
select public.decide_patient('73ab6008-b9a4-44c6-bab5-b388e9e3f38a');
select public.decide_patient('56f5ad4d-062a-4d62-8047-ac20fb6c85ca');
select public.decide_patient('638dd1bf-ca20-4311-bb53-6b35d8075066');
select public.decide_patient('ed8c179c-0102-41a4-adf7-d2a5b81e1811');
select public.decide_patient('3df0a425-e9e0-464d-b14a-299f2fc9e00d');
select public.decide_patient('3cf9a9c7-4eeb-421b-a309-1a6d90d76683');
select public.decide_patient('6b0b3721-d258-401e-bd3c-5550233221e1');
select public.decide_patient('fa739966-9b2d-4498-ad86-4509473d4fa3');
select public.decide_patient('a4920614-9eac-416e-b39d-55c5b9b1c764');
select public.decide_patient('603b4114-3edc-4e07-bcb1-5a33c2f473ac');
select public.decide_patient('70f73779-7630-425c-a0c1-e207aad40870');
select public.decide_patient('a5763c67-2a64-40c7-9c77-583345753999');
select public.decide_patient('1ec4eacd-0019-4455-b7b8-36dfdd6505fd');

-- ------------------------------------------------------- case 14: the refused second 80
-- Priya already holds a released 80. Handing her another is attempted here on purpose, and
-- the one_first_claim_per_referrer index throws it out. If it ever stops throwing, this
-- file fails loudly.

delete from public.grant_patient_discount where claim_id = 'fa739966-9b2d-4498-ad86-4509473d4fa3';
do $$
begin
  insert into public.grant_patient_discount
    (claim_id, referrer_id, transaction_status, transaction_success,
     first_claim, referral_amount, release_patient_discount)
  values
    ('fa739966-9b2d-4498-ad86-4509473d4fa3','73814d21-5cea-4aef-8072-7e283abdd7b8',
     'success', true, true, 80, true);
  raise exception 'a second 80 for the same referrer was accepted: the index is missing';
exception when unique_violation then
  raise notice 'second 80 for the same referrer refused by one_first_claim_per_referrer, as designed';
end $$;
-- The claim's honest pending row goes back.
select public.decide_patient('fa739966-9b2d-4498-ad86-4509473d4fa3');
