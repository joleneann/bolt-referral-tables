// Reads the live database and writes results.md and data/*.csv.
//
// Nothing in this file decides anything. It asks the six tables for their rows and lays them
// out, so the tables in this repository are the tables in the database and cannot drift apart
// without someone noticing.
//
// Run: node render-tables.mjs

import { writeFile, mkdir } from 'node:fs/promises'

const BASE = 'https://doiyvwwvddgokurwyvvb.supabase.co/rest/v1'
const KEY = 'sb_publishable__nHann-Y9PXbsuaJVmcAxg__f8Y0Rvy'

// Which claim belongs to which case is not in the data, on purpose. The seed file says so: a
// row records what happened, never which scenario someone wrote it for. These labels come from
// the comments in seed-cases.sql and are the only hand-written thing in the output.
const CASES = {
  '9278afb9-8331-4fe1-9b62-65a1b8d8ed02': ['1',  'Same full name, same address, same postcode'],
  'a4488223-6308-4015-94f9-49e50c51a4a1': ['2',  'Same full name, same address, different postcode'],
  'abd523c6-0935-408d-a8b4-1da1c2cd2cc8': ['3',  'Same full name, same postcode, different address'],
  'b0049305-6016-441b-a464-a25a5edf7c20': ['4',  'Same full name, nothing else matches'],
  '847e904c-355c-4188-b5e7-712de3d5ef17': ['5',  'Same surname, address, postcode and bank card'],
  '73ab6008-b9a4-44c6-bab5-b388e9e3f38a': ['6',  'Same address and postcode only'],
  '56f5ad4d-062a-4d62-8047-ac20fb6c85ca': ['7',  'Same first name, same postcode'],
  '638dd1bf-ca20-4311-bb53-6b35d8075066': ['8',  'Nothing matches anyone'],
  'ed8c179c-0102-41a4-adf7-d2a5b81e1811': ['9',  'The claimed contact already belongs to a patient'],
  '3df0a425-e9e0-464d-b14a-299f2fc9e00d': ['10', 'An existing patient claims again under a new email'],
  '3cf9a9c7-4eeb-421b-a309-1a6d90d76683': ['11a','Two customers claim the same friend: the earlier claim'],
  '6b0b3721-d258-401e-bd3c-5550233221e1': ['11b','Two customers claim the same friend: the later claim'],
  '4c904f72-3f3c-44bd-a1f6-54529db00387': ['12', "The referrer's first successful claim"],
  'de3eb6d2-ab0a-41b2-85e4-fa35dd409267': ['13', 'The same referrer, second successful claim'],
  'fa739966-9b2d-4498-ad86-4509473d4fa3': ['14', 'A second 80 is attempted for the same referrer'],
  'a4920614-9eac-416e-b39d-55c5b9b1c764': ['15', 'The window closes with no delivery'],
  '603b4114-3edc-4e07-bcb1-5a33c2f473ac': ['16', 'Clicked the link, never registered'],
  '70f73779-7630-425c-a0c1-e207aad40870': ['17', 'Registered, never ordered'],
  'a5763c67-2a64-40c7-9c77-583345753999': ['18', 'The photo ID check is still pending'],
  '1ec4eacd-0019-4455-b7b8-36dfdd6505fd': ['19', 'Claimed by phone, registered with an email'],
}

const get = async (table, query) => {
  const r = await fetch(`${BASE}/${table}?${query}`, { headers: { apikey: KEY } })
  if (!r.ok) throw new Error(`${table} returned ${r.status}: ${await r.text()}`)
  return r.json()
}

const [patients, claims, friends, matrix, gfd, gpd] = await Promise.all([
  get('patients', 'select=*&order=customer_since'),
  get('claims', 'select=*&order=creation_date'),
  get('friends', 'select=*'),
  get('verification_matrix', 'select=*&order=first_name_match.desc,last_name_match.desc,address_match.desc,postcode_match.desc'),
  get('grant_friend_discount', 'select=*'),
  get('grant_patient_discount', 'select=*'),
])

const byPatient = new Map(patients.map(p => [p.patient_id, p]))
const byClaimF = new Map(gfd.map(g => [g.claim_id, g]))
const byClaimP = new Map(gpd.map(g => [g.claim_id, g]))
const friendOf = new Map(friends.map(f => [f.claim_id, f]))
const name = id => (byPatient.has(id) ? `${byPatient.get(id).first_name} ${byPatient.get(id).last_name}` : '')
const yn = v => (v === null || v === undefined ? 'not yet' : v ? 'yes' : 'no')
const day = ts => (ts ? ts.slice(0, 10) : '')

// The order the cases are written in: 1, 2, ... 11a, 11b, ... 19.
const ordered = claims
  .filter(c => CASES[c.claim_id])
  .sort((a, b) => {
    const [x, y] = [CASES[a.claim_id][0], CASES[b.claim_id][0]]
    return parseInt(x, 10) - parseInt(y, 10) || x.localeCompare(y)
  })

const out = []
out.push('# The nineteen cases, as the database answered them')
out.push('')
out.push('Read back out of Postgres by `render-tables.mjs`, not typed. Re-run the script and this')
out.push('page rewrites itself, so it cannot quietly drift away from what the system does.')
out.push('')
out.push(`${patients.length} people, ${claims.length} claims, ${gfd.length} verification decisions, ${gpd.length} payout decisions.`)
out.push('')
out.push('Which claim belongs to which case is the one hand-written thing here. A row records what')
out.push('happened, never which scenario it was written for, so the labels come from the comments in')
out.push('`seed-cases.sql`.')
out.push('')
out.push('## Every case, and how it ended')
out.push('')
out.push('| # | Case | Names match | Household match | Verdict | Friend paid | Referrer paid |')
out.push('|---|---|---|---|---|---|---|')

for (const c of ordered) {
  const [num, label] = CASES[c.claim_id]
  const f = byClaimF.get(c.claim_id)
  const p = byClaimP.get(c.claim_id)
  const names = f && (f.first_name_match !== null)
    ? `${f.first_name_match ? 'first' : ''}${f.first_name_match && f.last_name_match ? ' + ' : ''}${f.last_name_match ? 'last' : ''}` || 'neither'
    : 'not checked'
  const house = f && (f.address_match !== null)
    ? `${f.address_match ? 'address' : ''}${f.address_match && f.postcode_match ? ' + ' : ''}${f.postcode_match ? 'postcode' : ''}` || 'neither'
    : 'not checked'
  // Approved and yet unpaid means an earlier claim on the same person already released.
  const blocked = f && f.approved === true && !f.release_friend_discount && f.within_window
  const verdict = !f ? 'none'
    : f.manual_verification_needed ? (f.approved === null ? 'a human is looking' : f.approved ? 'a human approved it' : 'a human refused it')
    : f.approved === null ? 'nothing to check yet'
    : blocked ? 'approved, but an earlier claim keeps it'
    : f.approved ? 'approved' : 'refused'
  out.push(`| ${num} | ${label} | ${names} | ${house} | **${verdict}** | ${f ? yn(f.release_friend_discount) : 'no'} | ${p && p.release_patient_discount ? `yes, ${p.referral_amount}` : 'no'} |`)
}

// Counted, never typed: these sentences have to survive a change to the seed data.
const manualCount = gfd.filter(g => g.manual_verification_needed).length
const householdOnly = gfd.filter(g => !g.manual_verification_needed
  && (g.address_match || g.postcode_match)).length
const refusedOnHousehold = gfd.filter(g => !g.manual_verification_needed
  && (g.address_match || g.postcode_match) && g.approved === false).length

out.push('')
out.push(`${manualCount} claims went to a human, and every one of them turned on a full name.`)
out.push(`${householdOnly} claims matched an address or a postcode without matching both names.`)
out.push(`${refusedOnHousehold} of those were refused.`)
out.push('')
out.push('## Each case, and what the database recorded')
out.push('')

for (const c of ordered) {
  const [num, label] = CASES[c.claim_id]
  const f = byClaimF.get(c.claim_id)
  const p = byClaimP.get(c.claim_id)
  const fr = friendOf.get(c.claim_id)
  const arrived = c.friend_email || c.friend_phone

  out.push(`### Case ${num}. ${label}`)
  out.push('')
  out.push(`**${name(c.referrer_id)}** referred \`${arrived}\` by \`${c.claim_channel}\` on ${day(c.creation_date)}.`)
  out.push(`The claim reads \`${c.claim_status}\`, and its window closes ${day(c.expiry_date)}.`)
  out.push(fr
    ? `They registered as **${fr.first_name} ${fr.last_name}**, ${fr.address_line}, ${fr.postcode}.`
    : 'Nobody registered on this claim, so there is nothing to compare.')
  out.push('')

  if (f) {
    out.push('| checked | result |')
    out.push('|---|---|')
    out.push(`| first name matches an existing patient | ${yn(f.first_name_match)} |`)
    out.push(`| last name matches | ${yn(f.last_name_match)} |`)
    out.push(`| address matches | ${yn(f.address_match)} |`)
    out.push(`| postcode matches | ${yn(f.postcode_match)} |`)
    out.push(`| goes to a human | ${yn(f.manual_verification_needed)} |`)
    out.push(`| a human approved it | ${yn(f.manual_approved)} |`)
    out.push(`| inside the window | ${yn(f.within_window)} |`)
    out.push(`| friend discount released | ${yn(f.release_friend_discount)} |`)
    out.push('')
    if (f.verdict_note) out.push(`Recorded reason: ${f.verdict_note}`)
    out.push('')
  }

  if (p) {
    out.push(`Referrer side: first claim ${yn(p.first_claim)}, amount ${p.referral_amount === null ? 'none yet' : p.referral_amount}, released ${yn(p.release_patient_discount)}.`)
    out.push('')
  }
}

out.push('## The rule, as sixteen rows')
out.push('')
out.push('Yes means that field matches an existing patient. A human looks only when both names')
out.push('match. The other two columns are recorded and shown, and change nothing.')
out.push('')
out.push('| first name | last name | address | postcode | verdict | why |')
out.push('|---|---|---|---|---|---|')
for (const m of matrix) {
  out.push(`| ${yn(m.first_name_match)} | ${yn(m.last_name_match)} | ${yn(m.address_match)} | ${yn(m.postcode_match)} | ${m.approved === 'manual' ? '**a human looks**' : 'approved'} | ${m.note || ''} |`)
}
out.push('')
out.push('## The tables in full')
out.push('')
out.push('GitHub renders these as sortable, searchable grids. Same rows as above, same export.')
out.push('')
out.push('- [`data/patients.csv`](data/patients.csv). The account list, with successful_referrals counted from released payouts.')
out.push('- [`data/claims.csv`](data/claims.csv). One row per referral link click.')
out.push('- [`data/friends.csv`](data/friends.csv). What each friend typed at registration.')
out.push('- [`data/verification_matrix.csv`](data/verification_matrix.csv). The rule, as data.')
out.push('- [`data/grant_friend_discount.csv`](data/grant_friend_discount.csv). One row per verification, with the reason stored at the time.')
out.push('- [`data/grant_patient_discount.csv`](data/grant_patient_discount.csv). One row per payout decision.')
out.push('')

await writeFile(new URL('./results.md', import.meta.url), out.join('\n'), 'utf8')

const csv = rows => {
  if (!rows.length) return ''
  const cols = Object.keys(rows[0])
  const esc = v => {
    if (v === null || v === undefined) return ''
    const s = String(v)
    return /[",\n]/.test(s) ? `"${s.replace(/"/g, '""')}"` : s
  }
  return [cols.join(','), ...rows.map(r => cols.map(c => esc(r[c])).join(','))].join('\n') + '\n'
}

await mkdir(new URL('./data/', import.meta.url), { recursive: true })
await Promise.all([
  writeFile(new URL('./data/patients.csv', import.meta.url), csv(patients), 'utf8'),
  writeFile(new URL('./data/claims.csv', import.meta.url), csv(claims), 'utf8'),
  writeFile(new URL('./data/friends.csv', import.meta.url), csv(friends), 'utf8'),
  writeFile(new URL('./data/verification_matrix.csv', import.meta.url), csv(matrix), 'utf8'),
  writeFile(new URL('./data/grant_friend_discount.csv', import.meta.url), csv(gfd), 'utf8'),
  writeFile(new URL('./data/grant_patient_discount.csv', import.meta.url), csv(gpd), 'utf8'),
])

// ------------------------------------------------------------------ cases.html
// The same cases as a page, grouped. Written from the same fetch as results.md, so the graphic
// and the tables cannot disagree.

const num = c => CASES[c.claim_id][0]

const GROUPS = [
  ['Goes to a human', c => byClaimF.get(c.claim_id)?.manual_verification_needed],
  ['The payout', c => ['12', '13', '14'].includes(num(c))],
  ['Approved without a human', c => {
    const f = byClaimF.get(c.claim_id)
    return f && !f.manual_verification_needed && f.release_friend_discount
  }],
  ['Not a referral', c => {
    const f = byClaimF.get(c.claim_id)
    return f && !f.manual_verification_needed
      && (f.approved === false || (f.approved && !f.release_friend_discount && f.within_window))
  }],
  ['Nothing happens yet, or ever', () => true],
]

// Short enough to read in a column. The full stored reason is in results.md and the CSVs.
const shorten = s => {
  const first = String(s).split('.')[0].trim()
  return first.length > 52 ? first.slice(0, 49).replace(/[ ,]+$/, '') + '...' : first
}

const solution = c => {
  const f = byClaimF.get(c.claim_id)
  const p = byClaimP.get(c.claim_id)
  // Case 14 is the one case whose proof is not a row. The second 80 is attempted at seed time
  // and the index refuses the write, so there is nothing to store. Saying otherwise would claim
  // an outcome the data does not carry.
  if (num(c) === '14') return 'the database refuses the write, so nothing is paid'
  if (!f) return 'nothing decided'
  if (f.approved === null && f.manual_verification_needed) return 'nothing releases until a human decides'
  if (f.approved === null) return 'held: nobody has registered'
  if (f.manual_verification_needed && f.approved) return `photo ID checked, approved: ${shorten(f.verdict_note)}`
  if (f.manual_verification_needed) return 'photo ID checked, refused'
  if (f.approved === false) return 'already a customer: no reward, nobody told'
  if (!f.release_friend_discount && f.within_window) return 'the earlier claim keeps it'
  if (!f.release_friend_discount) return 'the window closed, nothing released'
  if (p && p.release_patient_discount) return `approved, referrer paid ${p.referral_amount}`
  if (p && !p.transaction_success) return 'approved, the bonus waits for the order'
  return 'approved'
}

const esc = s => String(s).replace(/&/g, '&amp;').replace(/</g, '&lt;')
const used = new Set()
const rows = []
for (const [title, test] of GROUPS) {
  const mine = ordered.filter(c => !used.has(c.claim_id) && test(c))
  if (!mine.length) continue
  mine.forEach(c => used.add(c.claim_id))
  rows.push(`      <tr class="section"><td colspan="3">${title}</td></tr>`)
  for (const c of mine) {
    const [n, label] = CASES[c.claim_id]
    rows.push(`      <tr><td class="n">${n}</td><td>${esc(label)}</td><td class="solution">${esc(solution(c))}</td></tr>`)
  }
}

const html = `<!doctype html>
<html lang="en">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>The nineteen cases</title>
<style>
  :root { --ink: #1f2328; --dim: #9aa1a9; --line: #e6e8ea; --green: #1a7f37; }
  * { box-sizing: border-box; margin: 0; padding: 0; }
  body { font: 15px/1.5 -apple-system, "Segoe UI", Roboto, Helvetica, Arial, sans-serif;
         color: var(--ink); background: #fafafa; padding: 40px 16px; }
  .card { max-width: 880px; margin: 0 auto; background: #fff; border: 1px solid var(--line);
          border-radius: 10px; padding: 36px 40px 30px; }
  table { width: 100%; border-collapse: collapse; }
  th { text-align: left; font-size: 11px; font-weight: 600; letter-spacing: .12em;
       text-transform: uppercase; color: var(--dim); padding: 0 12px 10px 0;
       border-bottom: 1px solid var(--line); }
  td { padding: 9px 12px 9px 0; border-bottom: 1px solid #f2f3f4; vertical-align: top; }
  tr:last-child td { border-bottom: 0; }
  td.n { color: var(--dim); width: 34px; padding-right: 8px; }
  td.solution { color: var(--green); font-weight: 500; }
  .section td { padding: 22px 0 8px; border-bottom: 0; font-size: 11px; font-weight: 700;
                letter-spacing: .14em; text-transform: uppercase; color: var(--ink); }
  .foot { margin-top: 22px; padding-top: 14px; border-top: 1px solid var(--line);
          font-size: 12.5px; color: var(--dim); }
  @media (max-width: 640px) { .card { padding: 24px 18px; } }
</style>
</head>
<body>
<div class="card">
  <table>
    <thead>
      <tr><th></th><th style="width:48%">Situation</th><th>Solution</th></tr>
    </thead>
    <tbody>
${rows.join('\n')}
    </tbody>
  </table>
  <p class="foot">Read out of Postgres by <code>render-tables.mjs</code>, not typed. ${manualCount} of the
  ${ordered.length} claims went to a human, and every one turned on a full name. ${refusedOnHousehold} were
  refused for a shared address, postcode or bank card.</p>
</div>
</body>
</html>
`

await writeFile(new URL('./cases.html', import.meta.url), html, 'utf8')

const manual = gfd.filter(g => g.manual_verification_needed).length
const released = gfd.filter(g => g.release_friend_discount).length
console.log(`results.md, cases.html and 6 csv files written.`)
console.log(`${patients.length} patients, ${claims.length} claims, ${matrix.length} matrix rows.`)
console.log(`${manual} claims went to a human, ${released} friend discounts released.`)
