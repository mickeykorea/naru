/* Fetches keyword photos for the mock archive into public/mock/thumbs.
   One per hand-written save (by title keyword), twelve per theme pool for
   the generated saves. Run once: node scripts/mock-thumbs.mjs */
import { writeFile, access } from 'node:fs/promises'
import { readFileSync } from 'node:fs'

const src = readFileSync(new URL('../lib/seed/data.ts', import.meta.url), 'utf8')
const saves = []
let n = 0
for (const m of src.matchAll(/s\('(\w+)', '((?:[^'\\]|\\.)*)', '(?:[^'\\]|\\.)*', '(?:[^'\\]|\\.)*', '[^']*', ('(\w+)'|null)(?:, (true|false))?/g)) {
  n++
  const [, , title, , theme, image] = m
  saves.push({ id: `s${n}`, title, theme: theme ?? 'loose', image: image !== 'false' })
}

const THEME = {
  slow: ['minimalism', 'eink', 'desk', 'kindle', 'calm'],
  seoul: ['seoul', 'hanok', 'korea night', 'han river', 'seoul street'],
  solo: ['laptop', 'coding', 'notebook', 'startup desk', 'keyboard'],
  clay: ['pottery', 'ceramics', 'woodworking', 'kiln', 'handmade'],
  run: ['running', 'morning run', 'park run', 'sneakers', 'trail'],
  type: ['typography', 'magazine', 'print', 'letterpress', 'editorial'],
  food: ['korean food', 'kimchi', 'bakery', 'sourdough', 'bibimbap'],
  career: ['london office', 'city london', 'workspace', 'meeting', 'portfolio'],
  loose: ['nature', 'dog', 'cat', 'ocean', 'street'],
}
const OVERRIDE = [
  [/moon jar|onggi|kintsugi|cups/i, 'ceramic'], [/plane iron|chair|furniture/i, 'woodworking'], [/han river/i, 'han river'], [/euljiro|sindang|hongdae|bukchon|hannam|subway|line 2/i, 'seoul'],
  [/kimchi|doenjang|gyeran|korean grocery|bibimbap/i, 'korean food'], [/bakehouse|sourdough|bakery/i, 'bakery'], [/oura|hrv|sleep/i, 'sleep'], [/run|park|half/i, 'running'],
  [/garamond|butterick|type/i, 'typography'], [/apartamento|kinfolk|magazine|spread/i, 'magazine'], [/kindle|e-ink/i, 'kindle'], [/deep sea/i, 'deep sea'], [/dog/i, 'dog'], [/cat /i, 'cat'],
  [/thames|mudlark/i, 'thames'], [/desk/i, 'desk'], [/spotify|cassette|playlist|charm|hyukoh/i, 'vinyl'], [/london|linkedin|design engineer|portfolio|palantir|visa/i, 'london'],
]
const kw = (s) => OVERRIDE.find(([re]) => re.test(s.title))?.[1] ?? THEME[s.theme][0]

async function grab(urls, file) {
  try { await access(file); return 'cached' } catch {}
  for (const url of urls) {
    const r = await fetch(url, { redirect: 'follow' })
    if (r.ok) { await writeFile(file, Buffer.from(await r.arrayBuffer())); return 'ok' }
    await new Promise((res) => setTimeout(res, 300))
  }
  return 'fail'
}
const jobs = []
const u = (k, lock) => `https://loremflickr.com/320/320/${encodeURIComponent(k)}?lock=${lock}`
saves.filter((s) => s.image).forEach((s, i) => jobs.push([[u(kw(s), 100 + i), u(THEME[s.theme][0], 100 + i), u(THEME[s.theme][1], 300 + i), `https://loremflickr.com/320/320?lock=${100 + i}`], `public/mock/thumbs/${s.id}.jpg`]))
for (const [theme, words] of Object.entries(THEME)) for (let i = 0; i < 12; i++) jobs.push([[u(words[i % words.length], 500 + i), u(words[0], 500 + i), `https://loremflickr.com/320/320?lock=${500 + i}`], `public/mock/thumbs/${theme}-${i}.jpg`])
let done = 0, fail = 0
for (let i = 0; i < jobs.length; i += 6) {
  const res = await Promise.all(jobs.slice(i, i + 6).map(([u, f]) => grab(u, f)))
  done += res.filter((r) => r !== 'fail').length
  fail += res.filter((r) => r === 'fail').length
  process.stdout.write(`\r${done + fail}/${jobs.length}`)
}
console.log(`\ndone ${done}, failed ${fail}, featured ${saves.filter((s) => s.image).length}`)
