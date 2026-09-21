/* Real album covers for the Spotify saves, from Apple's most-played album
   charts (US and GB; no Korean chart, no K-pop), which need no login and carry the same art Spotify
   shows. Writes public/mock/covers/{i}.jpg and lib/seed/covers.json, and
   fetches the cover for the hand-written saves that name a real record.

   Run once: node scripts/album-covers.mjs
   Prototype only. The art belongs to the labels. */
import { writeFile, mkdir, readdir, unlink } from 'node:fs/promises'
import { readFileSync } from 'node:fs'

const OUT = 'public/mock/covers'
const REGIONS = ['us', 'gb']
const SKIP = /christmas|holiday|soundtrack|children|karaoke|worship|classical|k-pop|kpop/i
const UA = { 'User-Agent': 'Mozilla/5.0 naru-prototype' }

async function chart(cc) {
  const r = await fetch(`https://rss.applemarketingtools.com/api/v2/${cc}/music/most-played/50/albums.json`, { headers: UA, redirect: 'follow' })
  if (!r.ok) return []
  return (await r.json()).feed.results
}

const seen = new Set()
const list = []
for (const cc of REGIONS) {
  for (const a of await chart(cc)) {
    const genre = a.genres?.find((g) => g.name !== 'Music')?.name ?? a.genres?.[0]?.name ?? ''
    const keyId = a.id ?? a.artworkUrl100
    if (seen.has(keyId) || SKIP.test(genre) || SKIP.test(a.name)) continue
    seen.add(keyId)
    list.push({
      album: a.name.replace(/\s*-\s*(EP|Single)$/i, '').replace(/\s*\((Deluxe|Explicit)[^)]*\)$/i, ''),
      artist: a.artistName,
      genre,
      art: a.artworkUrl100.replace(/100x100bb/, '400x400bb'),
      region: cc,
    })
  }
}

await mkdir(OUT, { recursive: true })
for (const f of await readdir(OUT)) if (/\.jpg$/.test(f)) await unlink(`${OUT}/${f}`)

async function grab(url, file) {
  for (let i = 0; i < 3; i++) {
    const r = await fetch(url, { headers: UA })
    if (r.ok) {
      await writeFile(file, Buffer.from(await r.arrayBuffer()))
      return true
    }
    await new Promise((res) => setTimeout(res, 400))
  }
  return false
}

const covers = []
for (let i = 0; i < list.length; i += 8) {
  const batch = list.slice(i, i + 8)
  const ok = await Promise.all(batch.map((a, j) => grab(a.art, `${OUT}/${i + j}.jpg`)))
  batch.forEach((a, j) => {
    if (ok[j]) covers.push({ file: `/mock/covers/${i + j}.jpg`, album: a.album, artist: a.artist, genre: a.genre, region: a.region })
  })
}
await writeFile('lib/seed/covers.json', JSON.stringify(covers, null, 2) + '\n')
console.log(`charts: ${list.length} albums, ${covers.length} covers written`)
const byGenre = {}
for (const c of covers) byGenre[c.genre] = (byGenre[c.genre] ?? 0) + 1
console.log(byGenre)

/* Hand-written saves that name a real record get that record's cover. */
const src = readFileSync(new URL('../lib/seed/data.ts', import.meta.url), 'utf8')
let n = 0
const own = []
for (const m of src.matchAll(/s\('(\w+)', '((?:[^'\\]|\\.)*)'/g)) {
  n++
  own.push({ id: `s${n}`, source: m[1], title: m[2] })
}
const REAL = [
  ['Clairo, Charm', 'Clairo Charm'],
  ['Hyukoh, 23', 'Hyukoh 23'],
]
for (const [prefix, term] of REAL) {
  const save = own.find((s) => s.title.startsWith(prefix))
  if (!save) continue
  const r = await fetch(`https://itunes.apple.com/search?term=${encodeURIComponent(term)}&entity=album&limit=1`, { headers: UA })
  const hit = (await r.json()).results?.[0]
  if (!hit) continue
  const ok = await grab(hit.artworkUrl100.replace(/100x100bb/, '440x440bb'), `public/mock/thumbs/${save.id}.jpg`)
  console.log(`${save.id} ${prefix} → ${hit.collectionName} by ${hit.artistName}: ${ok ? 'ok' : 'failed'}`)
}
