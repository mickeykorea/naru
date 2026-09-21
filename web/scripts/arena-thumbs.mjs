/* Replaces the mock thumbnails with images from public Are.na channels that
   sit near each theme, so the archive looks like inspiration rather than
   stock. One pool of POOL images per theme for the generated saves, and one
   image per hand-written save, drawn from the same channels.

   Run once: node scripts/arena-thumbs.mjs
   Prototype only. The images belong to the people who posted them. */
import { writeFile, mkdir, readdir, unlink } from 'node:fs/promises'
import { readFileSync } from 'node:fs'

const POOL = 36
const OUT = 'public/mock/thumbs'

const CHANNELS = {
  slow: ['computer-grass-is-natural-grass', 'slimemold-interfaces', 'index-of-calm-technologies', 'software-interface', 'offbeat-ui'],
  seoul: ['seoul-zlmhi6zo8dc', 'ttt-location-seoul', 'gbh-seoul-forest', 'seoul-1-zdl4kkmea', 'next-living-seoul'],
  solo: ['user-interfaces-from-technical-software', 'terminal-ruins', 'digital-product-design-s-ljfc89s8g', 'workspace-idealism'],
  clay: ['studio-craft-ceramics', 'objects-ceramics', 'japanese-ceramics', 'tea-ceramics'],
  run: ['running-feels-like', 'inspo-running-imagery', 'photography-running-jwvpjlns_jo', 'road-running'],
  type: ['editorial-design-layouts', 'editorial-design-references', 'typography-foundries-wuvxrmj5hkm', 'sleek-magazine-editorial-design'],
  food: ['food-photography', 'neo-food-photography', 'food-we-made', 'nf-alchimist-kitchen-scullery'],
  career: ['workspace-de1lg-7rwy0', 'studio-desk-01', 'interior-analog-workspace', 'product-design-portfolios-gifanhlvp54'],
  loose: ['everyday', 'anachromatic-daily-living', 'found-photos-hcn14dukzm8', 'washed-in-time'],
}

/* The hand-written saves, so each gets its own image from its theme. */
const src = readFileSync(new URL('../lib/seed/data.ts', import.meta.url), 'utf8')
const saves = []
let n = 0
for (const m of src.matchAll(/s\('(\w+)', '((?:[^'\\]|\\.)*)', '(?:[^'\\]|\\.)*', '(?:[^'\\]|\\.)*', '[^']*', ('(\w+)'|null)(?:, (true|false))?/g)) {
  n++
  const [, , , , theme, image] = m
  saves.push({ id: `s${n}`, theme: theme ?? 'loose', image: image !== 'false' })
}

const headers = { 'User-Agent': 'naru-prototype (mickeyoh.com)', Accept: 'application/json' }
const sleep = (ms) => new Promise((r) => setTimeout(r, ms))

async function imagesOf(slug, want) {
  const urls = []
  for (let page = 1; page <= 6 && urls.length < want; page++) {
    const r = await fetch(`https://api.are.na/v2/channels/${slug}/contents?per_page=100&page=${page}`, { headers })
    if (!r.ok) break
    const d = await r.json()
    const items = d.contents ?? []
    for (const b of items) {
      if (b.class !== 'Image' || !b.image?.square?.url) continue
      const ct = b.image.content_type ?? ''
      if (ct.includes('gif')) continue
      urls.push({ key: b.image.original?.url ?? b.image.square.url, url: b.image.square.url })
    }
    if (items.length < 100) break
    await sleep(250)
  }
  return urls
}

async function grab(url, file) {
  for (let attempt = 0; attempt < 3; attempt++) {
    const r = await fetch(url, { headers: { 'User-Agent': headers['User-Agent'], Accept: 'image/jpeg,image/*' } })
    if (r.ok) {
      await writeFile(file, Buffer.from(await r.arrayBuffer()))
      return true
    }
    await sleep(400)
  }
  return false
}

await mkdir(OUT, { recursive: true })
for (const f of await readdir(OUT)) if (/\.jpg$/.test(f)) await unlink(`${OUT}/${f}`)

let written = 0
let failed = 0
for (const [theme, slugs] of Object.entries(CHANNELS)) {
  const own = saves.filter((s) => s.image && s.theme === theme)
  const want = POOL + own.length
  const seen = new Set()
  const pool = []
  for (const slug of slugs) {
    if (pool.length >= want) break
    for (const im of await imagesOf(slug, want - pool.length)) {
      if (seen.has(im.key)) continue
      seen.add(im.key)
      pool.push(im.url)
      if (pool.length >= want) break
    }
  }
  const jobs = []
  pool.slice(0, POOL).forEach((url, i) => jobs.push([url, `${OUT}/${theme}-${i}.jpg`]))
  own.forEach((s, i) => jobs.push([pool[POOL + i] ?? pool[i % pool.length], `${OUT}/${s.id}.jpg`]))
  for (let i = 0; i < jobs.length; i += 6) {
    const res = await Promise.all(jobs.slice(i, i + 6).map(([u, f]) => grab(u, f)))
    written += res.filter(Boolean).length
    failed += res.filter((x) => !x).length
  }
  console.log(`${theme}: ${pool.length} found, ${Math.min(pool.length, POOL)} pooled, ${own.length} own`)
}
console.log(`done: ${written} written, ${failed} failed`)
