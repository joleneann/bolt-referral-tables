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

// ------------------------------------------------------------------ index.html
// The page. Prose is written here; every table in it is read out of the live database in the
// same run that writes results.md, so the page and the tables cannot disagree.

// Found by shape, not by id: the housemate case is the one approved on a shared address and
// postcode with neither name matching.
const housemate = gfd.find(g => g.address_match && g.postcode_match
  && !g.first_name_match && !g.last_name_match && g.release_friend_discount)
// The referrer who has been paid both tiers.
const tiered = gpd.filter(g => g.release_patient_discount)
  .reduce((acc, g) => { (acc[g.referrer_id] ||= []).push(g); return acc }, {})
const tieredId = Object.keys(tiered).find(k => tiered[k].some(g => g.referral_amount === 80)
  && tiered[k].some(g => g.referral_amount === 40))
const tieredClaims = gpd.filter(g => g.referrer_id === tieredId)
  .sort((a, b) => (claims.find(c => c.claim_id === a.claim_id)?.creation_date || '')
    .localeCompare(claims.find(c => c.claim_id === b.claim_id)?.creation_date || ''))
const refusals = ordered.filter(c => {
  const f = byClaimF.get(c.claim_id)
  return f && (f.approved === false || (f.approved && !f.release_friend_discount && f.within_window))
})

const cell = v => v === null || v === undefined || v === '' ? '<td class="q">not checked</td>'
  : typeof v === 'boolean' ? `<td>${v ? 'yes' : 'no'}</td>` : `<td>${esc(v)}</td>`

const matrixRows = matrix.map(m => `<tr${m.approved === 'manual' ? ' class="hit"' : ''}>`
  + [m.first_name_match, m.last_name_match, m.address_match, m.postcode_match].map(cell).join('')
  + `<td><b>${m.approved === 'manual' ? 'a human looks' : 'approved'}</b></td>`
  + `<td class="q">${esc(m.note || '')}</td></tr>`).join('\n')

const caseRows = (() => {
  const seen = new Set(); const out = []
  for (const [title, test] of GROUPS) {
    const mine = ordered.filter(c => !seen.has(c.claim_id) && test(c))
    if (!mine.length) continue
    mine.forEach(c => seen.add(c.claim_id))
    out.push(`<tr class="grp"><td colspan="3">${title}</td></tr>`)
    for (const c of mine) {
      const [n, label] = CASES[c.claim_id]
      out.push(`<tr><td class="q">${n}</td><td>${esc(label)}</td><td class="ok">${esc(solution(c))}</td></tr>`)
    }
  }
  return out.join('\n')
})()

const page = `<!doctype html>
<html lang="en">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>The duplicate check, rebuilt</title>
<meta name="description" content="A referral duplicate check that stops refusing households, running on live Postgres.">
<style>
  :root {
    --ink:#1a1d21; --dim:#6b727a; --faint:#9aa1a9; --line:#e4e7ea; --bg:#fff; --wash:#fafbfc;
    --ok:#1a7f37; --hit:#8a5a00;
  }
  @media (prefers-color-scheme: dark) {
    :root { --ink:#e6e8ea; --dim:#a2a9b0; --faint:#7c848c; --line:#2a2f35; --bg:#15181b; --wash:#1b1f23;
            --ok:#4ac26b; --hit:#d9a441; }
  }
  * { box-sizing:border-box; margin:0; padding:0; }
  html { -webkit-text-size-adjust:100%; }
  body { font:17px/1.6 -apple-system,BlinkMacSystemFont,"Segoe UI",Roboto,Helvetica,Arial,sans-serif;
         color:var(--ink); background:var(--bg); padding:0 20px 72px; }
  main { max-width:38rem; margin:0 auto; }
  .kicker { font-size:11px; letter-spacing:.14em; text-transform:uppercase; color:var(--faint);
            padding:44px 0 18px; }
  h1 { font-size:29px; line-height:1.22; letter-spacing:-.015em; margin:0 0 20px; }
  h2 { font-size:19px; line-height:1.3; margin:44px 0 12px; letter-spacing:-.01em; }
  p { margin:0 0 16px; }
  .lead { font-size:18px; }
  .q { color:var(--dim); }
  b, strong { font-weight:600; }
  a { color:inherit; text-decoration:underline; text-underline-offset:2px;
      text-decoration-color:var(--faint); }
  a:hover { text-decoration-color:currentColor; }
  .scroll { overflow-x:auto; -webkit-overflow-scrolling:touch; margin:0 0 16px; }
  table { border-collapse:collapse; width:100%; font-size:14px; line-height:1.45; }
  th { text-align:left; font-size:10.5px; letter-spacing:.1em; text-transform:uppercase;
       color:var(--faint); font-weight:600; padding:0 12px 8px 0; border-bottom:1px solid var(--line);
       white-space:nowrap; }
  td { padding:7px 12px 7px 0; border-bottom:1px solid var(--line); vertical-align:top; }
  tr:last-child td { border-bottom:0; }
  tr.hit td { color:var(--hit); }
  tr.grp td { padding:20px 0 6px; border-bottom:0; font-size:10.5px; font-weight:700;
              letter-spacing:.12em; text-transform:uppercase; color:var(--ink); }
  td.ok { color:var(--ok); }
  .gone { border:1px dashed var(--line); border-radius:8px; background:var(--wash);
          padding:30px 20px; text-align:center; color:var(--faint); font-size:14px; margin:0 0 16px; }
  pre { background:var(--wash); border:1px solid var(--line); border-radius:8px; padding:14px 16px;
        overflow-x:auto; font:13px/1.55 ui-monospace,SFMono-Regular,Menlo,Consolas,monospace;
        margin:0 0 16px; }
  ul { margin:0 0 16px 20px; }
  li { margin:0 0 7px; }
  footer { margin-top:52px; padding-top:20px; border-top:1px solid var(--line);
           font-size:14px; color:var(--dim); }
</style>
</head>
<body>
<main>

<p class="kicker">Bolt Pharmacy referral programme &middot; a working rebuild &middot; Jolene Fernandes</p>

<h1>The duplicate check asks the wrong question</h1>

<p class="lead">Bolt refuses referrals between people who share an address. Two customers wrote it
down in public. One was told his housemate was already a customer. That was untrue, and the
housemate bought from a competitor instead. The other joined because her husband referred her,
then watched her own credit vanish when their accounts merged over a shared home address.</p>

<p>Both of those referrals happened. Neither was paid. The check is what decides whether a real
referral gets dispensed, and in both cases it decided wrong.</p>

<h2>The one number I do not have</h2>

<p>I cannot size how often that happens. Nobody publishes how many referrals the check refuses,
and no review tells you the denominator. That is the first query I would run: pull the refusal
reasons and count what share of blocks are households rather than genuine duplicates. Until it
runs the rate is unknown, and I will not guess at it.</p>

<h2>A pharmacy can ask a better question than a shop can</h2>

<p>A shop has to ask "same address?", because an address is all it holds. A pharmacy holds patient
records, so it can ask whether this is the same person. Those two questions disagree exactly where
it hurts. A couple. A houseshare. A parent and an adult child.</p>

<p><b>So the rule is one line. A human looks only when a first name and a last name both match an
existing patient.</b> A shared address changes nothing. A shared postcode changes nothing. A shared
bank card changes nothing. All three are recorded, shown, and ignored by the verdict.</p>

<p>The whole rule is 16 rows in a table, not logic buried in code:</p>

<div class="scroll">
<table>
<thead><tr><th>first name</th><th>last name</th><th>address</th><th>postcode</th><th>verdict</th><th>why</th></tr></thead>
<tbody>
${matrixRows}
</tbody>
</table>
</div>

<p>Read those <a href="${BASE}/verification_matrix?select=first_name_match,last_name_match,address_match,postcode_match,approved,note&amp;order=first_name_match.desc,last_name_match.desc,address_match.desc,postcode_match.desc&amp;apikey=${KEY}">16 rows straight out of the live database</a>, no account needed.
Change the rule and you edit a row, not a deploy.</p>

<h2>The refusal screen is the thing this deletes</h2>

<p>Here is the housemate case, running. Same address, same postcode, two different people. This is
where the old check said no:</p>

<div class="gone">no screen here</div>

<p>Nothing is shown to anyone, because nothing needs deciding. The comparison still ran, and the
database still recorded what it found:</p>

<div class="scroll">
<table>
<thead><tr><th>first name</th><th>last name</th><th>address</th><th>postcode</th><th>goes to a human</th><th>verdict</th></tr></thead>
<tbody>
<tr>${[housemate.first_name_match, housemate.last_name_match, housemate.address_match,
      housemate.postcode_match, housemate.manual_verification_needed].map(cell).join('')}<td class="ok"><b>approved</b></td></tr>
</tbody>
</table>
</div>

<p class="q">Reason stored at the time: "${esc(housemate.verdict_note)}"</p>

<h2>Nineteen cases, decided inside the database</h2>

<div class="scroll">
<table>
<thead><tr><th></th><th>situation</th><th>what happened</th></tr></thead>
<tbody>
${caseRows}
</tbody>
</table>
</div>

<p>${manualCount} of the ${ordered.length} claims went to a human, and every one of them turned on
a full name. ${householdOnly} matched an address or a postcode without matching both names.
${refusedOnHousehold} of those were refused.</p>

<p>Every verdict above was computed inside Postgres, not typed. <a href="results.md">The full
readback</a> carries each comparison and the reason stored at the time, and
<a href="${BASE}/claims?select=friend_email,friend_phone,claim_status,grant_friend_discount(approved,verdict_note,release_friend_discount),grant_patient_discount(first_claim,referral_amount,release_patient_discount)&amp;order=creation_date&amp;apikey=${KEY}">the same rows are readable live</a>.</p>

<h2>What it refuses to pay</h2>

<div class="scroll">
<table>
<thead><tr><th></th><th>situation</th><th>reason stored at the time</th></tr></thead>
<tbody>
${refusals.map(c => {
  const f = byClaimF.get(c.claim_id)
  return `<tr><td class="q">${CASES[c.claim_id][0]}</td><td>${esc(CASES[c.claim_id][1])}</td><td class="q">${esc(shorten(f.verdict_note))}</td></tr>`
}).join('\n')}
</tbody>
</table>
</div>

<p>The tiers hold too. One referrer, three claims, in the order they arrived:</p>

<div class="scroll">
<table>
<thead><tr><th>first claim</th><th>amount</th><th>paid</th></tr></thead>
<tbody>
${tieredClaims.map(g => `<tr>${cell(g.first_claim)}<td>${g.referral_amount === null ? '<span class="q">none yet</span>' : g.referral_amount}</td>${cell(g.release_patient_discount)}</tr>`).join('\n')}
</tbody>
</table>
</div>

<p>Two promises are held by the database itself rather than by code that could race or be
rewritten:</p>

<pre>create unique index one_first_claim_per_referrer
  on grant_patient_discount (referrer_id) where referral_amount = 80;

create unique index one_release_per_friend
  on grant_friend_discount (friend_patient_id) where release_friend_discount;</pre>

<p>A referrer is paid 80 once, ever. A friend is released once, ever, no matter how many people
claimed them. The seed file attempts a second 80 on purpose and fails loudly if the database ever
accepts it.</p>

<h2>What this does not do</h2>

<p>It does not decide who gets asked to refer, or when. It does not touch the share moment, the
message, or anything before the click. It starts at the claim and stops at the payout. Getting
more people to refer is a different job from paying correctly the ones who already did.</p>

<p>It also puts nothing in public. Sharing stays inside private 1 to 1 channels. Public posts
naming prescription medicines are advertising, and the regulator ruled against four UK brands for
exactly that in February 2026.</p>

<h2>How it is put together</h2>

<p>Six tables. <b>patients</b> is the account list. <b>claims</b> is one row per link click, written
the moment someone clicks, before any account exists, so a closed tab no longer ends a referral.
<b>friends</b> is what the friend typed at registration. <b>verification_matrix</b> is the 16 rows
above. <b>grant_friend_discount</b> holds one verification per claim with the reason copied in at
the time. <b>grant_patient_discount</b> holds one payout decision per claim.</p>

<p>Read any of it live, with no account and no terminal. The key in these links is the publishable
one, which is meant to be public:</p>

<ul>
<li><a href="${BASE}/patients?select=first_name,last_name,address_line,postcode,successful_referrals,customer_since&amp;order=customer_since&amp;apikey=${KEY}">the patients, with successful_referrals counted from released payouts</a></li>
<li><a href="${BASE}/grant_friend_discount?select=first_name_match,last_name_match,address_match,postcode_match,manual_verification_needed,manual_approved,approved,verdict_note,release_friend_discount&amp;apikey=${KEY}">every verification, with the four comparisons</a></li>
<li><a href="${BASE}/grant_patient_discount?select=transaction_success,first_claim,referral_amount,release_patient_discount&amp;apikey=${KEY}">every payout decision</a></li>
<li><a href="https://github.com/joleneann/bolt-referral-tables">the repository</a>: schema, the design written before the SQL, and the 19 cases as data</li>
</ul>

<p>Select is the only privilege granted to anonymous readers, so an insert returns 42501.</p>

<footer>
<p>The tables, the rule, the two indexes and both decision functions are real. The people are
invented and the phone numbers come from Ofcom's test range. The 80 and 40 are Bolt's own
published amounts, captured from their live referral page on 2026-07-23. The old rule is inferred
from what customers described in public and labelled as inference wherever it appears, because
Bolt has never published how their check works.</p>
<p>This page was written by a script that read the live tables, so it cannot drift away from what
the system does. Concept work by Jolene Fernandes. Not affiliated with Bolt Pharmacy.</p>
</footer>

</main>
</body>
</html>
`

await writeFile(new URL('./index.html', import.meta.url), page, 'utf8')

const manual = gfd.filter(g => g.manual_verification_needed).length
const released = gfd.filter(g => g.release_friend_discount).length
console.log(`results.md, index.html, cases.html and 6 csv files written.`)
console.log(`${patients.length} patients, ${claims.length} claims, ${matrix.length} matrix rows.`)
console.log(`${manual} claims went to a human, ${released} friend discounts released.`)
