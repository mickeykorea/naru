/* PROTOTYPE. Grows the hand-written seed to ~1,200 saves so the canvas can
   be judged at the scale Mickey described, and computes a position per save
   for each lens (topic, source, time). Deterministic. */
import { saves as seed, themes, type Save, type Source } from './data'
import COVERS from './covers.json'

export type Lens = 'topic' | 'source' | 'time'
export type BigSave = Save & { ageDays: number; featured: boolean }

const SOURCES: Source[] = ['instagram', 'tiktok', 'youtube', 'spotify', 'x', 'arena', 'web', 'linkedin']

/* Which platforms each theme mostly comes from. */
const MIX: Record<string, Source[]> = {
  slow: ['x', 'web', 'youtube', 'arena', 'instagram'],
  seoul: ['instagram', 'tiktok', 'spotify', 'youtube', 'instagram', 'tiktok'],
  solo: ['x', 'youtube', 'web', 'linkedin', 'x'],
  clay: ['instagram', 'tiktok', 'youtube', 'instagram', 'arena'],
  run: ['tiktok', 'youtube', 'web', 'spotify', 'x'],
  type: ['arena', 'instagram', 'web', 'x', 'instagram'],
  food: ['tiktok', 'instagram', 'youtube', 'instagram', 'tiktok', 'web'],
  career: ['linkedin', 'x', 'web', 'youtube'],
  loose: SOURCES,
}

const STEMS: Record<string, string[]> = {
  slow: ['Calm software, notes', 'An interface that waits', 'Rams principle', 'No feed, on purpose', 'One button, one job', 'Restraint as a feature', 'Quiet defaults', 'E-ink and nothing else'],
  seoul: ['Euljiro after midnight', 'Han river walk', 'Sindang alley', 'Hongdae busking clip', 'Cassette mix, side A', 'Hannam bookshop', 'Line 2 loop', 'Bukchon in winter'],
  solo: ['Ship the ugly version', 'One person, one agent', 'What to build next', 'Weekend build log', 'Spec from saves', 'Agent workflow notes', 'Taste is the bottleneck', 'Solo founder thread'],
  clay: ['Moon jar firing', 'Plane iron, sharpened', 'One chair a month', 'Onggi process', 'Kintsugi repair', 'Wheel throwing, real time', 'Studio in four tools', 'Wood-fired kiln log'],
  run: ['Zone 2, boring on purpose', 'Readiness score', 'Sleep debt thread', 'Victoria Park loop', 'Recovery week', 'Easy run, easy pace', 'HRV, morning', 'Long run playlist'],
  type: ['Garamond in use', 'Apartamento spread', 'Weight, not size', 'Editorial grid', 'Magazine scan', 'Specimen sheet', 'White space costs', 'Masonry reference'],
  food: ['Kimchi jjigae, 1am', 'Sourdough Saturday', 'Doenjang from scratch', 'Korean grocery run', 'Gyeran-mari', 'Patbingsu history', 'Cooking Sunday', 'Bakery queue'],
  career: ['Design engineer role', 'Portfolio review', 'Interview loop notes', 'Global talent visa', 'AI-native job post', 'Case study rehearsal', 'Hiring manager thread', 'London studio list'],
  loose: ['Deep sea clip', 'Dog refuses stairs', 'Hardware event', 'Jacket weather app', 'Cat opens fridge', 'Desk tour', 'Mudlarking find', 'Random tab'],
}

const SUFFIX = ['', ', part 2', ', the follow-up', ' (thread)', ', saved twice', ', 4K', ', full process', ', notes', ', clip', ', v2', ', again', ', from a friend', ', late night', ', archive', ', 2026']
const AUTHORS = ['seoul.film', '@eatseoul', 'kwon.ceramics', 'raunofreiberg', 'levelsio', 'Design Details', 'are.na/mickey', 'linkedin', 'mobbin', '@slowtech', 'e8.workshop', '@londonrunclub', 'apartamentomagazine', '@latenightkorean', 'stratechery', 'Maangchi', 'Fireship', 'printarchive', 'hanok.archive', 'The Quantified Scientist']

function rng(seedN: number) {
  let a = seedN >>> 0
  return () => {
    a = (a + 0x6d2b79f5) >>> 0
    let t = a
    t = Math.imul(t ^ (t >>> 15), t | 1)
    t ^= t + Math.imul(t ^ (t >>> 7), t | 61)
    return ((t ^ (t >>> 14)) >>> 0) / 4294967296
  }
}
const r = rng(7)
const pick = <T,>(arr: T[]) => arr[Math.floor(r() * arr.length)]

const ageLabel = (d: number) => (d < 7 ? `${Math.max(1, d)}d` : d < 60 ? `${Math.round(d / 7)}w` : d < 365 ? `${Math.round(d / 30)}mo` : `${(d / 365).toFixed(0)}y`)
const ageDaysOf = (age: string) => {
  const n = parseInt(age, 10)
  return age.endsWith('mo') ? n * 30 : age.endsWith('w') ? n * 7 : age.endsWith('y') ? n * 365 : n
}

const COUNTS: Record<string, number> = { slow: 120, seoul: 190, solo: 140, clay: 110, run: 90, type: 130, food: 170, career: 70, loose: 120 }

export const big: BigSave[] = [
  ...seed.map((s) => ({ ...s, ageDays: ageDaysOf(s.age), featured: true })),
]
let n = 0
let spotifyN = 0
for (const [theme, count] of Object.entries(COUNTS)) {
  for (let i = 0; i < count; i++) {
    const ageDays = Math.floor(Math.pow(r(), 1.6) * 700) + 1
    /* Almost everything has a thumbnail: an article has a hero image, a post
       has media. Only a text thread on X or LinkedIn has none. */
    const source = pick(MIX[theme])
    const image = source === 'x' || source === 'linkedin' ? r() > 0.3 : true
    /* A Spotify save is a real record off the charts: its title is the
       artist and album, its picture the cover. */
    const record = source === 'spotify' && COVERS.length ? COVERS[spotifyN++ % COVERS.length] : null
    big.push({
      id: `g${++n}`,
      source,
      title: record ? `${record.artist}, ${record.album}` : pick(STEMS[theme]) + pick(SUFFIX),
      summary: '',
      author: record ? 'spotify' : pick(AUTHORS),
      age: ageLabel(ageDays),
      theme: theme === 'loose' ? null : theme,
      image,
      ratio: record ? 1 : image ? pick([0.56, 0.75, 1, 1, 1.25, 1.4]) : 1,
      cover: record?.file,
      ageDays,
      featured: false,
    })
  }
}

export const bigById = Object.fromEntries(big.map((s) => [s.id, s]))
export const count = (theme: string | null) => big.filter((s) => s.theme === theme).length
export const countBySource = (src: Source) => big.filter((s) => s.source === src).length

/* Cluster centres per lens. Spread scales with sqrt(count) so dense themes
   take more room, the way a projection would. */
type Pt = { x: number; y: number }
const ring = (keys: string[], radius: number): Record<string, Pt> => {
  const out: Record<string, Pt> = {}
  keys.forEach((k, i) => {
    const a = (i / keys.length) * Math.PI * 2 - Math.PI / 2
    out[k] = { x: Math.cos(a) * radius * (1 + (i % 2) * 0.25), y: Math.sin(a) * radius }
  })
  return out
}
export const themeCentres: Record<string, Pt> = { ...ring(themes.map((t) => t.id), 1700), loose: { x: 0, y: 0 } }
export const sourceCentres: Record<string, Pt> = ring(SOURCES, 1500)
export const themeOrder = themes.map((t) => t.id).concat('loose')

export const spread = (c: number) => 140 + Math.sqrt(c) * 34

const posCache: Record<Lens, Record<string, Pt>> = { topic: {}, source: {}, time: {} }
const rt = rng(11)
const g2 = () => (rt() + rt() + rt() + rt() - 2) / 2
for (const s of big) {
  const t = s.theme ?? 'loose'
  const tc = themeCentres[t]
  const st = spread(count(s.theme))
  posCache.topic[s.id] = { x: tc.x + g2() * st, y: tc.y + g2() * st }
  const sc = sourceCentres[s.source]
  const ss = spread(countBySource(s.source))
  posCache.source[s.id] = { x: sc.x + g2() * ss, y: sc.y + g2() * ss }
  posCache.time[s.id] = { x: Math.sqrt(s.ageDays / 700) * 5200, y: themeOrder.indexOf(t) * 360 + g2() * 130 }
}
export const positionFor = (lens: Lens, id: string) => posCache[lens][id]
export const SOURCE_LIST = SOURCES
