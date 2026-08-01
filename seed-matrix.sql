-- The verification matrix: rows 15 to 30 of the sheet, as data.
--
-- Y means that field matches an existing patient, contacts distinct. The rule collapses to
-- one line: manual when first and last name both match, else yes. The other two columns
-- never move the verdict; the note says why the combination is safe or why a human looks.
--
-- Run after the migrations. Safe to re-run: clears its own rows first.

delete from public.verification_matrix;

insert into public.verification_matrix
  (first_name_match, last_name_match, address_match, postcode_match, approved, note) values
  (true,  true,  true,  true,  'manual', 'could be father and son, same name, same address'),
  (true,  true,  true,  false, 'manual', 'could be the same person, sending to a different postcode with coincidence same address'),
  (true,  true,  false, true,  'manual', 'neighbours with same names'),
  (true,  true,  false, false, 'manual', 'could be the same person sending to a different address'),
  (true,  false, true,  true,  'yes',    null),
  (true,  false, true,  false, 'yes',    null),
  (true,  false, false, true,  'yes',    'neighbours with the same first name'),
  (true,  false, false, false, 'yes',    null),
  (false, true,  true,  true,  'yes',    'family members'),
  (false, true,  true,  false, 'yes',    null),
  (false, true,  false, true,  'yes',    null),
  (false, true,  false, false, 'yes',    null),
  (false, false, true,  true,  'yes',    'unrelated housemates'),
  (false, false, true,  false, 'yes',    null),
  (false, false, false, true,  'yes',    null),
  (false, false, false, false, 'yes',    null);
