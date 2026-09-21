'use client'
/* The space, after the things.pool.day reference.
   One space: every save on a uniform 160-cell grid, 210 pitch, newest at
   the centre, pan and zoom, nothing else on screen. One bar: a glass pill
   at the bottom, measured off Pool. One verb: gather. Type a thought and a
   tile lands where you are looking with the saves that argue for, against
   and near it pulled in around it; click any save and its kin gather the
   same way. Idea tiles open as A's document. In-memory, seeded. */
import { createContext, useCallback, useContext, useEffect, useMemo, useRef, useState } from 'react'
import { ReactFlow, ReactFlowProvider, useReactFlow, type Node, type NodeProps } from '@xyflow/react'
import { AnimatePresence, motion, MotionConfig } from 'motion/react'
import { Menu } from 'bloom-menu'
import { ThinkingOrb } from 'thinking-orbs'
import { Box, Heart, Inbox, Info, Plus, Tag } from 'lucide-react'
import '@xyflow/react/dist/style.css'
import { LANE_ORDER, themes, type Idea, type Lane, type Source } from '@/lib/seed/data'
import { ideaFor } from '@/lib/seed/ideas'
import { big, bigById, countBySource, SOURCE_LIST, type BigSave } from '@/lib/seed/data-big'
import { IdeaDoc } from './idea-doc'
import { Glyph, LANES, Mark, Pic, POOL, thumbIndex, thumbUrl } from './shared'
import { Space3D } from './space-3d'
import { SaveCard } from './save-card'

/* ─────────────────────────────────────────────────────────
 * DOCUMENT TRANSITION STORYBOARD (tile click → document)
 *
 * Read top-to-bottom. Each `at` value is ms after the click.
 *
 *    0ms   space (grid, bar, pills) fades out, opacity 1 → 0
 *  160ms   document surface slides up, y 24 → 0, opacity 0 → 1
 *  220ms   header (back, eyebrow, title, meta) rises, y 16 → 0
 *  300ms   sections rise one by one (staggered 60ms), y 16 → 0
 *    +     brief block rises last, same stagger
 *  back:   document fades, 150ms ease-in; space fades back in
 * ───────────────────────────────────────────────────────── */

/* Tunables. Defaults are the shipped values; the lab (?lab=1) overrides
   them through DialKit. Sizes in px, times in ms. */
export type DocTiming = {
  fadeOut: number //   space fades out
  slideIn: number //   document surface starts rising
  headerAt: number // header block rises
  sectionsAt: number // first section rises
  stagger: number //   gap between sections
  offsetY: number //   px the surface and children rise from
}
export type Tune = { cell: number; pitch: number; gatherMs: number; argueMs: number; ringPad: number; doc: DocTiming }
export const DOC_TIMING: DocTiming = {
  fadeOut: 160, //     space fades out
  slideIn: 160, //     document surface starts rising
  headerAt: 220, //    header block rises
  sectionsAt: 300, //  first section rises
  stagger: 60, //      gap between sections
  offsetY: 24, //      px the surface rises from
}
export const DEFAULT_TUNE: Tune = { cell: 200, pitch: 210, gatherMs: 600, argueMs: 1100, ringPad: 1, doc: DOC_TIMING }
const TuneContext = createContext<Tune>(DEFAULT_TUNE)

type Kind = 'thought' | 'idea'
type Cell = [number, number]
type LaneTag = Lane | 'near'
type Tile = { id: string; kind: Kind; text: string; evidence: string[]; lanes: Record<string, LaneTag>; idea: Idea | null; cell: Cell }
/* A stored value can parse cleanly and still be the wrong shape: JSON.parse
   of "null" throws nothing and would put null into state. */
function readList(key: string): string[] {
  try {
    const v = JSON.parse(localStorage.getItem(key) ?? '[]')
    return Array.isArray(v) ? v.filter((x): x is string => typeof x === 'string') : []
  } catch {
    return []
  }
}

type Scope = { source: Source | null; fav: boolean; tags: string[] }
const NO_SCOPE: Scope = { source: null, fav: false, tags: [] }
type Ctx = { lit: Set<string> | null; lanes: Record<string, LaneTag>; revealed: string | null; selected: string | null; hopped: Set<string>; cellOf: (id: string) => Cell }
const C = createContext<Ctx>({ lit: null, lanes: {}, revealed: null, selected: null, hopped: new Set(), cellOf: () => [0, 0] })

/* Square spiral from the origin: index 0 is the centre, then rings outward. */
function spiral(i: number): Cell {
  if (i === 0) return [0, 0]
  const r = Math.ceil((Math.sqrt(i + 1) - 1) / 2)
  const side = 2 * r
  const start = (2 * r - 1) ** 2
  const k = i - start
  const leg = Math.floor(k / side)
  const t = (k % side) + 1
  if (leg === 0) return [r, -r + t]
  if (leg === 1) return [r - t, r]
  if (leg === 2) return [-r, r - t]
  return [-r + t, -r]
}
const key = (c: Cell) => `${c[0]},${c[1]}`
const toPos = (c: Cell, pitch: number) => ({ x: c[0] * pitch, y: c[1] * pitch })
const around = (c: Cell, pitch: number): { x: number; y: number; width: number; height: number } => ({ x: (c[0] - 3) * pitch, y: (c[1] - 1.5) * pitch, width: 7 * pitch, height: 4 * pitch })

/* Ring cells around a centre, nearest first, skipping reserved cells. */
function ring(c: Cell, n: number, reserved: Set<string> = new Set()): Cell[] {
  const out: Cell[] = []
  for (let r = 1; out.length < n && r < 8; r++) {
    const layer: Cell[] = []
    for (let dx = -r; dx <= r; dx++) for (let dy = -r; dy <= r; dy++) if (Math.max(Math.abs(dx), Math.abs(dy)) === r) layer.push([c[0] + dx, c[1] + dy])
    layer.sort((a, b) => Math.hypot(a[0] - c[0], a[1] - c[1]) - Math.hypot(b[0] - c[0], b[1] - c[1]))
    out.push(...layer.filter((x) => !reserved.has(key(x))))
  }
  return out.slice(0, n)
}

/* Slots by lane: Agrees on the row above, Disagrees on the row below,
   Visual and Mood to the left, Precedent and How-to to the right. A plain
   "near" gather (no argument yet) is nearest-first. */
function laneSlots(c: Cell, ids: string[], lanes: Record<string, LaneTag>, reserved: Set<string>): Record<string, Cell> {
  const out: Record<string, Cell> = {}
  const taken = new Set<string>(reserved)
  const place = (list: string[], cells: Cell[]) => {
    const free = cells.filter((x) => !taken.has(key(x)))
    list.forEach((id, i) => {
      const cell = free[i]
      if (!cell) return
      out[id] = cell
      taken.add(key(cell))
    })
  }
  const of = (l: LaneTag) => ids.filter((i) => lanes[i] === l)
  if (ids.every((i) => lanes[i] === 'near')) {
    place(ids, ring(c, 60, reserved))
    return out
  }
  const row = (dy: number) => [0, -1, 1, -2, 2, -3, 3].map((dx) => [c[0] + dx, c[1] + dy] as Cell)
  const col = (dx: number) => [0, -1, 1].map((dy) => [c[0] + dx, c[1] + dy] as Cell)
  place(of('agrees'), [...row(-1), ...row(-2)])
  place(of('disagrees'), [...row(1), ...row(2)])
  place([...of('visual'), ...of('mood')], [...col(-1), ...col(-2), ...col(-3)])
  place([...of('precedent'), ...of('howto')], [...col(1), ...col(2), ...col(3)])
  place(of('near'), ring(c, 60, reserved))
  return out
}

const newestFirst = [...big].sort((a, b) => a.ageDays - b.ageDays)
const homeCell: Record<string, Cell> = {}
newestFirst.forEach((s, i) => (homeCell[s.id] = spiral(i)))

const STOP = new Set(['that', 'this', 'with', 'from', 'your', 'what', 'about', 'into', 'have', 'only', 'than', 'them', 'they', 'when', 'where', 'which', 'would', 'could', 'should', 'like', 'just', 'make', 'thing', 'things', 'around', 'made'])
const words = (t: string) => t.toLowerCase().split(/[^a-z0-9]+/).filter((w) => w.length >= 4 && !STOP.has(w)).map((w) => w.slice(0, 5))

/* What gathers around a thought: the seeded idea when the words hit it,
   otherwise title matches, otherwise the theme whose name matches. */
type Gathered = { ids: string[]; lanes: Record<string, LaneTag>; idea: Idea | null }
function gatherFor(text: string, scope?: Set<string> | null): Gathered {
  const found = ideaFor(text)
  /* A scope narrows the idea itself, so the tile tally, the ring and the
     document all describe the same saves. */
  const idea = found && scope ? { ...found, lanes: Object.fromEntries(LANE_ORDER.map((l) => [l, (found.lanes[l] ?? []).filter((e) => scope.has(e.id))]).filter(([, v]) => (v as unknown[]).length)) as Idea['lanes'] } : found
  if (idea) {
    const lanes: Record<string, LaneTag> = {}
    for (const l of LANE_ORDER) for (const e of idea.lanes[l] ?? []) if (!lanes[e.id]) lanes[e.id] = l
    const ids = Object.keys(lanes)
    if (ids.length) return { ids, lanes, idea }
  }
  const ids = evidenceFor(text, 12, scope)
  return { ids, lanes: Object.fromEntries(ids.map((id) => [id, 'near' as LaneTag])), idea: null }
}
function evidenceFor(text: string, n = 12, scope?: Set<string> | null): string[] {
  const ws = words(text)
  const pool0 = scope ? big.filter((s) => scope.has(s.id)) : big
  const scored = pool0
    .map((s) => ({ s, k: words(s.title + ' ' + (themes.find((t) => t.id === s.theme)?.name ?? '')).filter((w) => ws.includes(w)).length }))
    .filter((x) => x.k > 0)
  const perTheme: Record<string, number> = {}
  for (const x of scored) perTheme[x.s.theme ?? 'loose'] = (perTheme[x.s.theme ?? 'loose'] ?? 0) + x.k
  const top = Object.entries(perTheme).sort((a, b) => b[1] - a[1])[0]?.[0]
  const themeId = top ?? themes.find((t) => words(t.name + ' ' + t.line).some((w) => ws.includes(w)))?.id
  scored.sort((a, b) => b.k - a.k || Number((b.s.theme ?? 'loose') === themeId) - Number((a.s.theme ?? 'loose') === themeId) || Number(b.s.featured) - Number(a.s.featured))
  const hits = scored.slice(0, n).map((x) => x.s.id)
  if (hits.length >= n || !themeId) return hits
  const pool = pool0.filter((s) => s.theme === themeId && !hits.includes(s.id))
  return hits.concat(pool.filter((s) => s.featured).concat(pool.filter((s) => !s.featured)).map((s) => s.id)).slice(0, n)
}
function kinOf(id: string, n = 8): string[] {
  const s = bigById[id]
  const pool = big.filter((x) => x.id !== id && x.theme === s.theme && x.source !== s.source)
  return pool.filter((x) => x.featured).concat(pool.filter((x) => !x.featured)).slice(0, n).map((x) => x.id)
}

function SaveNode({ data, id }: NodeProps<Node<{ save: BigSave }>>) {
  const ctx = useContext(C)
  const s = data.save
  const dim = !!ctx.lit && !ctx.lit.has(id)
  const lane = ctx.lit?.has(id) ? ctx.lanes[id] : undefined
  const sel = ctx.selected === id
  const hop = ctx.hopped.has(id)
  const c = ctx.cellOf(id)
  return (
    <button
      type="button"
      className={`cell${dim && !sel ? ' dim' : ''}${lane ? ' ' + lane : ''}${sel ? ' selected' : ''}${hop ? ' hop' : ''}`}
      style={hop ? { animationDelay: `${(Math.abs(c[0]) + Math.abs(c[1])) * 28}ms` } : undefined}
      aria-label={lane && lane !== 'near' ? `${LANES[lane].name}: ${s.title}` : s.title}
      aria-pressed={sel}
      title={s.title}
    >
      {lane && lane !== 'near' && <span className="lane" aria-hidden="true" title={LANES[lane].hint}>{LANES[lane].name}</span>}
      {s.image ? (
        <Pic src={thumbUrl(s)} lazy className="cellpic" />
      ) : (
        <div className="text">
          <Glyph source={s.source} size={28} />
          <span>{s.title}</span>
        </div>
      )}
    </button>
  )
}

function TileNode({ data, id }: NodeProps<Node<{ tile: Tile }>>) {
  const ctx = useContext(C)
  const t = data.tile
  const dim = !!ctx.lit && !ctx.lit.has(id)
  return (
    <button type="button" className={`cell tile ${t.kind}${dim ? ' dim' : ''}`} aria-label={`Open the document for: ${t.text}`}>
      <span className="display">{t.text}</span>
      <span className="open">
        {t.idea && ctx.revealed === t.id ? tally(t.idea) : t.evidence.length ? `${t.evidence.length}\u00a0related saves` : 'No related saves. Save around it and gather again.'}
      </span>
    </button>
  )
}

/* "4 agree · 3 disagree · 8 references": opinions counted apart from the
   content-type lanes. */
const tally = (idea: Idea) => {
  const n = (l: Lane) => idea.lanes[l]?.length ?? 0
  const refs = n('visual') + n('precedent') + n('howto') + n('mood')
  return `${n('agrees')}\u00a0agree ·\u00a0${n('disagrees')}\u00a0disagree ·\u00a0${refs}\u00a0references`
}

const nodeTypes = { save: SaveNode, tile: TileNode }
const EASE = [0.22, 1, 0.36, 1] as const

/* The dock morphs on bloom-menu's own spring and content fade, so the panels
   that grow out of the bar and the Sources sheet that grows out of its pill
   move the same way. */
const BLOOM = {
  initial: { height: 0, opacity: 0, filter: 'blur(10px)' },
  animate: { height: 'auto', opacity: 1, filter: 'blur(0px)' },
  exit: { height: 0, opacity: 0, filter: 'blur(10px)', transition: { type: 'spring', visualDuration: 0.22, bounce: 0 } },
  transition: {
    height: { type: 'spring', visualDuration: 0.32, bounce: 0.16 },
    opacity: { type: 'spring', visualDuration: 0.3, bounce: 0, delay: 0.03 },
    filter: { type: 'spring', visualDuration: 0.3, bounce: 0, delay: 0.03 },
  },
} as const

/* Tags start from the theme; edits and favorites persist per browser. */
const defaultTags = (id: string) => {
  const t = bigById[id]?.theme
  return t ? [t] : []
}
const loadTags = (): Record<string, string[]> => {
  try {
    const v = JSON.parse(localStorage.getItem('naru.tags') ?? '{}')
    if (!v || typeof v !== 'object' || Array.isArray(v)) return {}
    const out: Record<string, string[]> = {}
    for (const [id, list] of Object.entries(v)) if (Array.isArray(list)) out[id] = list.filter((x): x is string => typeof x === 'string')
    return out
  } catch {
    return {}
  }
}
const saveTags = (m: Record<string, string[]>) => {
  try {
    localStorage.setItem('naru.tags', JSON.stringify(m))
  } catch {}
}
const loadFavs = (): Set<string> => {
  try {
    return new Set<string>(JSON.parse(localStorage.getItem('naru.favs') ?? '[]'))
  } catch {
    return new Set()
  }
}
const saveFavs = (f: Set<string>) => {
  try {
    localStorage.setItem('naru.favs', JSON.stringify([...f]))
  } catch {}
}

const PLACEHOLDERS = [
  'plan my week around energy. the clock can wait',
  'why do I keep saving kilns',
  'a map of Seoul my friends made',
  'something for people who ship ugly',
  'the tool I wish existed last Tuesday',
]

/* First visit opens on a gathered example, so the first frame is the
   product working rather than an archive. */
/* The scope dot is the one colour in the product: a soft two-tone orb in the
   manner of OpenAI's news gradients, picked at random each load. Painted onto
   the element directly so the server and the client never disagree on it. */
const ORBS: [string, string][] = [
  ['#5b6cff', '#dfe4ff'],
  ['#ff7a45', '#ffd9c9'],
  ['#2fbf8f', '#d6f5e8'],
  ['#b26bff', '#ecdcff'],
  ['#ff5c8a', '#ffdbe6'],
  ['#ffb020', '#fff0c4'],
  ['#2f9bff', '#d3ebff'],
]
const nextOrb = (current: number) => {
  let i = Math.floor(Math.random() * (ORBS.length - 1))
  if (i >= current) i++
  return i
}

const SEEDS: Tile[] = (
  [
    ['what if my saves are the spec i never wrote', [0, 0]],
    ['plan my week around energy. the clock can wait', [-6, -4]],
    ['one object a week. no shop, no shipping, just the catalogue', [6, -3]],
    ['seoul, but only the places my friends bothered to save', [-7, 3]],
    ['templates for people who ship ugly and know it', [7, 4]],
    ['no feed. one page a day. only from what i saved', [1, -8]],
    ['shopping list from what i actually cook, not recipes', [-1, 8]],
    ['my portfolio = the tools i built for myself', [-12, -1]],
    ['every song should remember where i was when i saved it', [12, 1]],
    ['this week as a wall of notes, no feed', [-6, 10]],
  ] as [string, Cell][]
).map(([text, cell], i) => {
  const g = gatherFor(text)
  return { id: `tile:seed-${i}`, kind: 'idea', text, evidence: g.ids, lanes: g.lanes, idea: g.idea, cell }
})

/* Moves the evidence for one idea into its lanes around `centre`, pushing
   bystanders out to the far end of the ring, and never leaves two saves on
   one cell or any save under a tile. Pure, so the opening layout and a live
   gather share it. */
function applyGather(prev: Record<string, Cell>, centre: Cell, ids: string[], lanes: Record<string, LaneTag>, reserved: Set<string>, reserveCentre: boolean, displaced: Set<string>) {
  const next = { ...prev }
  const at: Record<string, string> = {}
  for (const [id, c] of Object.entries(next)) at[key(c)] = id
  const slots = laneSlots(centre, ids, lanes, reserved)
  const spares = ring(centre, 120, new Set([...reserved, ...Object.values(slots).map(key)]))
  const move = (id: string, to: Cell) => {
    const from = next[id]
    const other = at[key(to)]
    next[id] = to
    at[key(to)] = id
    if (other && other !== id && !ids.includes(other)) {
      const dest = reserved.has(key(from)) ? spares.pop() ?? from : from
      next[other] = dest
      at[key(dest)] = other
      displaced.add(other)
    } else if (at[key(from)] === id) delete at[key(from)]
  }
  if (reserveCentre) {
    const occupant = at[key(centre)]
    if (occupant && !ids.includes(occupant)) {
      const spare = spares.pop()
      if (spare) {
        move(occupant, spare)
        displaced.add(occupant)
      }
    }
  }
  for (const id of ids) if (slots[id] && key(next[id]) !== key(slots[id])) move(id, slots[id])
  const seen = new Set<string>()
  for (const [id, c] of Object.entries(next)) {
    if (seen.has(key(c)) || reserved.has(key(c))) {
      const spare = spares.pop()
      if (spare) {
        next[id] = spare
        displaced.add(id)
      }
    }
    seen.add(key(next[id]))
  }
  return next
}

/* The opening layout: every seeded idea gathered in turn, then one sweep so
   that a save two ideas both claim ends up on exactly one cell. */
function seedLayout(): Record<string, Cell> {
  const reserved = new Set(SEEDS.map((s) => key(s.cell)))
  let cells = homeCell
  for (const s of SEEDS) cells = applyGather(cells, s.cell, s.evidence, s.lanes, reserved, true, new Set())
  const taken = new Set<string>(reserved)
  const out: Record<string, Cell> = {}
  let probe = 0
  for (const [id, c] of Object.entries(cells)) {
    let cell = c
    while (taken.has(key(cell))) cell = spiral(probe++)
    taken.add(key(cell))
    out[id] = cell
  }
  assignThumbs(out)
  return out
}

/* Picks a pool image for every generated save so that no save within two
   cells, in the same theme, shows the same picture. Sequential ids modulo the
   pool put twins side by side on the spiral; this walks the layout instead. */
function assignThumbs(cells: Record<string, Cell>) {
  const at = new Map<string, string>()
  for (const [id, c] of Object.entries(cells)) at.set(key(c), id)
  const ids = Object.keys(cells).filter((id) => id.startsWith('g')).sort((a, b) => parseInt(a.slice(1), 10) - parseInt(b.slice(1), 10))
  for (const id of ids) {
    const s = bigById[id]
    const c = cells[id]
    const used = new Set<number>()
    for (let dx = -2; dx <= 2; dx++)
      for (let dy = -2; dy <= 2; dy++) {
        const o = at.get(key([c[0] + dx, c[1] + dy]))
        if (!o || o === id || !o.startsWith('g') || bigById[o]?.theme !== s.theme) continue
        const k = thumbIndex.get(o)
        if (k !== undefined) used.add(k)
      }
    const start = parseInt(id.slice(1), 10) % POOL
    let k = start
    for (let i = 0; i < POOL && used.has(k); i++) k = (start + i + 1) % POOL
    thumbIndex.set(id, k)
  }
}

function SpaceInner() {
  const flow = useReactFlow()
  const tune = useContext(TuneContext)
  const { pitch, cell: cellPx } = tune
  const [cells, setCells] = useState<Record<string, Cell>>(seedLayout)
  const [tiles, setTiles] = useState<Tile[]>(() => SEEDS)
  const [active, setActive] = useState<{ id: string; ids: string[] } | null>(null)
  const [text, setText] = useState('')
  const [summary, setSummary] = useState<string | null>(null)
  const [laneReveal, setLaneReveal] = useState<string | null>(null)
  const [ph, setPh] = useState(0)
  const [history, setHistory] = useState(false)
  const [gathering, setGathering] = useState(false)
  const [busy, setBusy] = useState(false)
  const [tip, setTip] = useState(false)
  const argueTimer = useRef<number | null>(null)
  const tileN = useRef(0)
  const pending = useRef(false)
  /* Dismissing a gather has to cancel the second beat too: without this the
     ring re-sorts and the tally comes back a second after you cleared it. */
  const clearRing = useCallback(() => {
    if (argueTimer.current) {
      window.clearTimeout(argueTimer.current)
      argueTimer.current = null
    }
    pending.current = false
    setBusy(false)
    setActive(null)
    setLaneReveal(null)
    setSummary(null)
  }, [])
  useEffect(() => () => {
    if (argueTimer.current) window.clearTimeout(argueTimer.current)
  }, [])
  const [doc, setDoc] = useState<Tile | null>(null)
  const [view3d, setView3d] = useState(false)
  const [selected, setSelected] = useState<string | null>(null)
  const [focus3d, setFocus3d] = useState<string | null>(null)
  const [warm, setWarm] = useState(false)
  const [tags, setTags] = useState<Record<string, string[]>>(() => loadTags())
  const [favs, setFavs] = useState<Set<string>>(() => loadFavs())
  /* The scope is an intersection: one source at most, favorites or not, and
     any tags. Each part narrows the others. */
  const [filter, setFilter] = useState<Scope>(NO_SCOPE)
  const [filterOpen, setFilterOpen] = useState(false)
  const tagsOf = (id: string) => tags[id] ?? defaultTags(id)
  const setTagsFor = (id: string, next: string[]) => {
    setTags((m) => {
      const out = { ...m, [id]: next }
      saveTags(out)
      return out
    })
  }
  const toggleFav = (id: string) =>
    setFavs((f) => {
      const n = new Set(f)
      if (n.has(id)) n.delete(id)
      else n.add(id)
      saveFavs(n)
      return n
    })
  const tagCounts = useMemo(() => {
    const c: Record<string, number> = {}
    for (const s of big) for (const t of tags[s.id] ?? defaultTags(s.id)) c[t] = (c[t] ?? 0) + 1
    return Object.entries(c).sort((a, b) => b[1] - a[1])
  }, [tags])
  /* Plain click sets one part and closes. Shift or ⌘ click keeps the list
     open, so a source, favorites and tags can be combined. */
  const pickFilter = (f: Scope, keepOpen = false) => {
    setFilter(f)
    setActive(null)
    setSelected(null)
    /* The bar's line follows the scope: the favorites nudge only while that
       part is set and empty, and nothing stale from a ring just cleared. */
    setSummary(f.fav && favs.size === 0 ? 'No favorites yet. Press ♥ on a save.' : null)
    if (!keepOpen) setFilterOpen(false)
  }
  const pickTag = (t: string, additive: boolean) => {
    const cur = scope.tags
    if (!additive) {
      pickFilter({ ...scope, tags: cur.length === 1 && cur[0] === t ? [] : [t] })
      return
    }
    pickFilter({ ...scope, tags: cur.includes(t) ? cur.filter((x) => x !== t) : [...cur, t] }, true)
  }
  const [off, setOff] = useState<string[]>(() => readList('naru.sources.off'))
  useEffect(() => {
    try {
      localStorage.setItem('naru.sources.off', JSON.stringify(off))
    } catch {}
  }, [off])

  /* A scope can outlive what it points at: a source removed in the Sources
     sheet, or a tag taken off the last save that carried it. The live scope is
     derived, so a dead part simply stops counting instead of leaving a scope
     that matches nothing and cannot be unset. */
  const liveTags = new Set(tagCounts.map(([tag]) => tag))
  const scope: Scope = {
    source: filter.source && !off.includes(filter.source) ? filter.source : null,
    fav: filter.fav,
    tags: filter.tags.filter((tag) => liveTags.has(tag)),
  }

  const filterOn = !!(scope.source || scope.fav || scope.tags.length)

  const filterIds = !filterOn
    ? null
    : new Set(
        big
          .filter((s) => !scope.source || s.source === scope.source)
          .filter((s) => !scope.fav || favs.has(s.id))
          .filter((s) => !scope.tags.length || (tags[s.id] ?? defaultTags(s.id)).some((t) => scope.tags.includes(t)))
          .map((s) => s.id),
      )
  const filterLabel = !filterOn
    ? 'All saves'
    : [scope.source, scope.fav ? 'favorites' : null, ...(scope.tags.length ? [scope.tags.length === 1 ? `#${scope.tags[0]}` : `#${scope.tags[0]} +${scope.tags.length - 1}`] : [])].filter(Boolean).join(' · ')
  const [sources, setSources] = useState(false)
  const [custom, setCustom] = useState<string[]>(() => readList('naru.sources'))

  const [editing, setEditing] = useState(false)
  const [adding, setAdding] = useState(false)
  const [draftSource, setDraftSource] = useState('')
  useEffect(() => {
    try {
      localStorage.setItem('naru.sources', JSON.stringify(custom))
    } catch {}
  }, [custom])
  const [syncing, setSyncing] = useState<string | null>(null)
  const [synced, setSynced] = useState<Record<string, number>>({})
  /* Replays a source arriving: its saves fade in with a stagger, newest
     first, the way the real ingest would land pages of fifty. */
  const sync = (src: string) => {
    setSyncing(src)
    setSynced((m) => ({ ...m, [src]: Date.now() }))
    const ids = big.filter((x) => x.source === src).map((x) => x.id)
    setHopped(new Set(ids))
    window.setTimeout(() => {
      setHopped(new Set())
      setSyncing(null)
    }, 1400)
  }

  /* The orb takes a new colour with every prompt, painted straight onto the
     element after mount so the server and client never disagree, and the
     registered custom properties let the browser cross-fade the gradient. */
  const orbRef = useRef<HTMLButtonElement>(null)
  const orbIndex = useRef(-1)
  useEffect(() => {
    const el = orbRef.current
    if (!el) return
    orbIndex.current = nextOrb(orbIndex.current)
    const [a, b] = ORBS[orbIndex.current]
    el.style.setProperty('--orb-a', a)
    el.style.setProperty('--orb-b', b)
  }, [ph])

  /* The prompt cycles only while the bar is the thing you are looking at. */
  useEffect(() => {
    if (filterOpen || history || sources || selected || text) return
    const t = setInterval(() => setPh((p) => (p + 1) % PLACEHOLDERS.length), 3200)
    return () => clearInterval(t)
  }, [filterOpen, history, sources, selected, text])

  const [hopped, setHopped] = useState<Set<string>>(new Set())
  const vw = typeof window === 'undefined' ? 1024 : window.innerWidth
  const vh = typeof window === 'undefined' ? 768 : window.innerHeight

  useEffect(() => {
    const id = requestAnimationFrame(() => requestAnimationFrame(() => setWarm(true)))
    return () => cancelAnimationFrame(id)
  }, [])

  const nodes = useMemo<Node[]>(() => {
    /* Every cell is 160 square, so React Flow gets the size up front and
       never has to measure 1,200 nodes (the measuring pass raced with
       instant local thumbnails and left everything hidden). */
    /* React Flow culls off-screen nodes, but not on the first render: before
       it has measured its container every node counts as visible and the
       whole archive mounts for about a second. Until it has measured, hand it
       only the cells around the opening viewport. */
    const near = warm
      ? big
      : big.filter((s) => {
          const c = cells[s.id]
          if (!c) return false
          const p = toPos(c, pitch)
          return Math.abs(p.x) < vw && Math.abs(p.y) < vh
        })
    const out: Node[] = near.map((s) => ({ id: s.id, type: 'save', position: toPos(cells[s.id], pitch), data: { save: s }, width: cellPx, height: cellPx, draggable: false, selectable: false }))
    for (const t of tiles) out.push({ id: t.id, type: 'tile', position: toPos(t.cell, pitch), data: { tile: t }, width: cellPx, height: cellPx, draggable: false, selectable: false, zIndex: 2 })
    return out
  }, [cells, tiles, pitch, cellPx, warm, vw, vh])

  /* Move evidence into the ring around a centre; whoever sat in a ring cell
     takes the vacated cell, so the grid stays full. `reserve` is a cell the
     centre itself will occupy (a new tile), whose occupant is pushed out. */
  const gather = useCallback((centre: Cell, ids: string[], lanes: Record<string, LaneTag>, reserved: Set<string>, reserveCentre: boolean) => {
    const displaced = new Set<string>()
    setCells((prev) => applyGather(prev, centre, ids, lanes, reserved, reserveCentre, displaced))
    setHopped(displaced)
    setGathering(true)
    window.setTimeout(() => setHopped(new Set()), 400)
    window.setTimeout(() => setGathering(false), 700)
  }, [setHopped])

  const centreCell = (): Cell => {
    const { x, y, zoom } = flow.getViewport()
    const cx = (window.innerWidth / 2 - x) / zoom - cellPx / 2
    const cy = (window.innerHeight / 2 - y) / zoom - cellPx / 2
    return [Math.round(cx / pitch), Math.round(cy / pitch)]
  }

  /* A new tile lands where you are looking, nudged to the nearest cell that
     keeps clear of every existing tile and its ring. */
  const placeTile = (c: Cell): Cell => {
    const clear = (x: Cell) => tiles.every((t) => Math.max(Math.abs(t.cell[0] - x[0]), Math.abs(t.cell[1] - x[1])) > 4)
    if (clear(c)) return c
    for (let i = 1; i < 400; i++) {
      const d = spiral(i)
      const x: Cell = [c[0] + d[0], c[1] + d[1]]
      if (clear(x)) return x
    }
    return c
  }

  const submit = () => {
    const t = text.trim()
    /* A ref, not the busy state: five clicks in one tick all read the same
       state and would each land a tile. */
    if (!t || pending.current) return
    const cell = placeTile(centreCell())
    const g = gatherFor(t, filterIds)
    const tile: Tile = { id: `tile:${(tileN.current += 1)}`, kind: 'idea', text: t, evidence: g.ids, lanes: g.lanes, idea: g.idea, cell }
    setTiles((ts) => [...ts, tile])
    /* Two beats, as in production: the ring lands by similarity first, then
       re-slots by lane when the argument arrives. */
    const reserved = new Set([...tiles.map((x) => key(x.cell)), key(cell)])
    const near = Object.fromEntries(g.ids.map((x) => [x, 'near' as LaneTag]))
    if (argueTimer.current) window.clearTimeout(argueTimer.current)
    gather(cell, g.ids, near, reserved, true)
    setActive({ id: tile.id, ids: g.ids })
    setLaneReveal(null)
    setSummary(g.ids.length ? `Found ${g.ids.length}\u00a0related saves. Sorting…` : `Nothing in ${filterOn ? filterLabel : 'your saves'} relates to this yet`)
    if (g.idea) {
      pending.current = true
      setBusy(true)
      argueTimer.current = window.setTimeout(() => {
        gather(cell, g.ids, g.lanes, reserved, true)
        setLaneReveal(tile.id)
        setSummary(tally(g.idea!))
        pending.current = false
        setBusy(false)
        argueTimer.current = null
      }, tune.argueMs)
    } else if (g.ids.length) setSummary(`${g.ids.length}\u00a0related saves`)
    setText('')
    flow.fitBounds(around(cell, pitch), { duration: tune.gatherMs, ease: (t: number) => 1 - (1 - t) ** 5, interpolate: 'linear' })
  }

  /* Escape backs out one layer at a time, and listens on the window because
     focus is often on a canvas object or on nothing at all. A field that
     wants Escape for itself stops the event before it gets here. */
  useEffect(() => {
    const onKey = (e: KeyboardEvent) => {
      if (e.key !== 'Escape') return
      if (doc) setDoc(null)
      else if (view3d ? focus3d : selected) {
        if (view3d) setFocus3d(null)
        else setSelected(null)
      } else if (sources || filterOpen || history) {
        setSources(false)
        setFilterOpen(false)
        setHistory(false)
      } else if (active) clearRing()
      else if (view3d) setView3d(false)
      else return
      e.preventDefault()
    }
    window.addEventListener('keydown', onKey)
    return () => window.removeEventListener('keydown', onKey)
  }, [doc, view3d, focus3d, selected, sources, filterOpen, history, active, clearRing])

  /* Both views dock the same card: 2D selection, 3D focus. */
  const pick = view3d ? focus3d : selected
  const shown = pick && bigById[pick] ? pick : null
  /* The dock holds its open width until a closing panel has finished
     collapsing: dropped early, the dock sizes to the still-present panel's
     natural width and flares out before settling. */
  const dockOpen = !!shown || filterOpen || (history && tiles.length > 0)
  /* The bar's own width, watched while it is laid out, so opening and closing
     are the same animation run in opposite directions. */
  const [barW, setBarW] = useState<number | null>(null)
  /* A callback ref, not an effect: the dock unmounts in the 3D view and comes
     back as a new element, and an observer left on the old one would never
     report again, freezing the dock at a stale width. */
  const barObserver = useRef<ResizeObserver | null>(null)
  const barRef = useCallback((el: HTMLFormElement | null) => {
    barObserver.current?.disconnect()
    barObserver.current = null
    if (!el) return
    const read = () => setBarW(Math.ceil(el.scrollWidth) + 14)
    read()
    const ro = new ResizeObserver(read)
    ro.observe(el)
    barObserver.current = ro
  }, [])
  const activeTile = active ? tiles.find((t) => t.id === active.id) : undefined
  const onSave = (id: string) => {
    setFilterOpen(false)
    setSources(false)
    setHistory(false)
    setSelected((cur) => (cur === id ? null : id))
  }
  const ctx: Ctx = {
    lit: active ? new Set([active.id, ...active.ids]) : filterIds && filterIds.size ? filterIds : null,
    lanes: activeTile && laneReveal === activeTile.id ? activeTile.lanes : {},
    revealed: laneReveal,
    selected,
    hopped,
    cellOf: (id) => cells[id] ?? [0, 0],
  }
  const actions = {
    gatherAround: (id: string) => {
      setSelected(null)
      const ids = kinOf(id)
      gather(cells[id], ids, Object.fromEntries(ids.map((x) => [x, 'near' as LaneTag])), new Set(tiles.map((x) => key(x.cell))), false)
      setActive({ id, ids })
      setSummary(`${ids.length}\u00a0related saves`)
      flow.fitBounds(around(cells[id], pitch), { duration: tune.gatherMs, ease: (t: number) => 1 - (1 - t) ** 5, interpolate: 'linear' })
    },
    onTile: (id: string) => {
      const t = tiles.find((x) => x.id === id)
      if (!t) return
      setSources(false)
      setFilterOpen(false)
      setHistory(false)
      setActive({ id, ids: t.evidence })
      setLaneReveal(id)
      setDoc(t)
    },
  }


  return (
    <C.Provider value={ctx}>
      <div
        className={`space${gathering ? ' gathering' : ''}`}
      >
        <button type="button" aria-pressed={view3d} className={`toggle3d${view3d ? ' on' : ''}`} onClick={() => setView3d((v) => !v)} aria-label="3D view" title="3D view">
          <Box size={14} strokeWidth={2} />
          <span>3D</span>
        </button>
        {view3d && (
          <Space3D
            focus={focus3d}
            setFocus={(id) => {
              setFocus3d(id)
              if (id) {
                setFilterOpen(false)
                setHistory(false)
                setSources(false)
              }
            }}
          />
        )}
        <motion.div className="stage" animate={{ opacity: doc ? 0 : 1 }} transition={{ duration: tune.doc.fadeOut / 1000, ease: doc ? [0.4, 0, 1, 1] : EASE }} style={{ pointerEvents: doc ? 'none' : undefined }}>
        <ReactFlow
          nodes={nodes}
          nodesFocusable={false}
          nodeTypes={nodeTypes}
          defaultViewport={{ x: vw / 2 - cellPx / 2, y: vh / 2 - cellPx / 2, zoom: 1 }}
          minZoom={0.3}
          maxZoom={2}
          onlyRenderVisibleElements
          nodesConnectable={false}
          elementsSelectable={false}
          zoomOnDoubleClick={false}
          proOptions={{ hideAttribution: true }}
          onNodeClick={(_, node) => (node.type === 'tile' ? actions.onTile(node.id) : onSave(node.id))}
          onPaneClick={() => {
            clearRing()
            setSelected(null)
            setHistory(false)
            setSources(false)
            setFilterOpen(false)
          }}
        />


        <div className="topleft">
          <Menu.Root open={sources} onOpenChange={(v) => { setSources(v); if (v) setFilterOpen(false) }} direction="bottom" anchor="start" visualDuration={0.32} bounce={0.16} animationConfig={{ contentScale: 1 }} closeOnEscape={false}>
          <Menu.Container className="bloom" buttonSize={{ width: 268, height: 32 }} menuWidth={360} menuRadius={27} buttonRadius={16}>
            <Menu.Trigger className="count trigger">
              <Inbox size={14} strokeWidth={2} />
              <span><b>{big.length.toLocaleString()}</b> saves · <b>{big.filter((s) => s.ageDays <= 3).length}</b> new since Friday</span>
            </Menu.Trigger>
            <Menu.Content className="sources">
              {/* bloom unmounts its trigger when the sheet opens, which would
                  drop keyboard focus to the page; the sheet takes it instead. */}
              <span tabIndex={-1} ref={(el) => el?.focus()} className="sr-only">Sources</span>
              <div className="eyebrow head">
                <span>Sources</span>
                <span className="info">
                  <button type="button" aria-describedby="sources-tip" aria-label="How saves get here" onClick={() => setTip((v) => !v)} onMouseEnter={() => setTip(true)} onMouseLeave={() => setTip(false)} onFocus={() => setTip(true)} onBlur={() => setTip(false)}>
                    <Info size={14} strokeWidth={2} />
                  </button>
                  <span id="sources-tip" role="tooltip" className="tip" hidden={!tip}>
                    Spotify, YouTube, Are.na and X sync on their own. Instagram saves and TikTok likes are pulled by a small browser extension while you are logged in. Everything else you share to Naru from your phone.
                  </span>
                </span>
                <button type="button" className="textbtn edit" onClick={() => setEditing((v) => !v)} aria-pressed={editing}>
                  {editing ? 'Done' : 'Edit'}
                </button>
              </div>
              {SOURCE_LIST.filter((src) => !off.includes(src)).map((src) => {
                const n = countBySource(src)
                const mode = ['spotify', 'youtube', 'arena', 'x'].includes(src) ? 'synced automatically' : ['instagram', 'tiktok'].includes(src) ? 'via browser extension' : 'shared from your phone'
                return (
                  <div key={src} className="row">
                    <Glyph source={src} size={28} />
                    <span className="who">
                      <span className="name">{src}</span>
                      <span className="how">{synced[src] ? 'synced just now' : mode}</span>
                    </span>
                    <span className="n">{n}</span>
                    {editing ? (
                      <button type="button" className="textbtn drop" onClick={() => setOff([...off, src])}>Remove</button>
                    ) : (
                      <button type="button" className="textbtn" disabled={syncing === src} onClick={() => sync(src)}>
                        {syncing === src ? 'Syncing…' : synced[src] ? 'Sync again' : 'Sync'}
                      </button>
                    )}
                  </div>
                )
              })}
              {custom.map((src) => (
                <div key={src} className="row">
                  <Mark name={src} size={28} />
                  <span className="who">
                    <span className="name">{src}</span>
                    <span className="how">{synced[src] ? 'synced just now' : 'waiting for its first sync'}</span>
                  </span>
                  <span className="n">{synced[src] ? 0 : ''}</span>
                  {editing ? (
                    <button type="button" className="textbtn drop" onClick={() => setCustom(custom.filter((x) => x !== src))}>Remove</button>
                  ) : (
                    <button type="button" className="textbtn" disabled={syncing === src} onClick={() => sync(src)}>
                      {syncing === src ? 'Syncing…' : synced[src] ? 'Sync again' : 'Sync'}
                    </button>
                  )}
                </div>
              ))}
              {editing && <div className="addhint" ref={(el) => el?.scrollIntoView({ block: 'nearest' })}>Removing a source stops it syncing. The saves already in your space stay.</div>}
              {adding ? (
                <form
                  className="row add"
                  onSubmit={(e) => {
                    e.preventDefault()
                    const name = draftSource.trim()
                    const back = off.find((s) => s.toLowerCase() === name.toLowerCase())
                    if (back) setOff(off.filter((s) => s !== back))
                    else if (name) setCustom([...custom, name])
                    setDraftSource('')
                    setAdding(false)
                  }}
                >
                  <span className="plus"><Plus size={16} strokeWidth={2} /></span>
                  <input
                    autoFocus
                    value={draftSource}
                    onChange={(e) => setDraftSource(e.target.value)}
                    onKeyDown={(e) => {
                      if (e.key === 'Escape') {
                        e.stopPropagation()
                        setAdding(false)
                        setDraftSource('')
                      }
                    }}
                    placeholder="Name it. Pinterest, Apple Music…"
                    aria-label="Name the source you want to add"
                  />
                  <button type="submit" className="textbtn" disabled={!draftSource.trim()}>Add</button>
                </form>
              ) : (
                <button type="button" className="row add" onClick={() => setAdding(true)}>
                  <span className="plus"><Plus size={16} strokeWidth={2} /></span>
                  <span className="who"><span className="name">Add a source</span></span>
                </button>
              )}
              {adding && <div className="addhint" ref={(el) => el?.scrollIntoView({ block: 'nearest' })}>Name the place you save things. Naru asks you to sign in to it next.</div>}
            </Menu.Content>
          </Menu.Container>
          </Menu.Root>
        </div>

        {(!view3d || !!shown) && (
        <div className={`dock${dockOpen ? ' open' : ''}${shown ? ' card' : ''}`} style={barW ? ({ '--barw': `${barW}px` } as React.CSSProperties) : undefined}>
        <AnimatePresence>
        {history && tiles.length > 0 && (
          <motion.div
            key="history"
            className="scope"
            role="group"
            aria-label="Ideas you have gathered"
            onPointerDown={(e) => e.stopPropagation()}
            {...BLOOM}
          >
            <div className="inner">
            <div className="eyebrow">Ideas you have gathered</div>
            {[...tiles].reverse().map((t) => (
              <button
                key={t.id}
                className="row"
                onClick={() => {
                  setHistory(false)
                  setActive({ id: t.id, ids: t.evidence })
                  setLaneReveal(t.id)
                  flow.fitBounds(around(t.cell, pitch), { duration: tune.gatherMs, ease: (t: number) => 1 - (1 - t) ** 5, interpolate: 'linear' })
                }}
              >
                <span className="name">{t.text}</span>
                <span className="n">{t.evidence.length}</span>
              </button>
            ))}
            </div>
          </motion.div>
        )}
        </AnimatePresence>

        <AnimatePresence>
        {filterOpen && (
          <motion.div
            key="scope"
            className="scope"
            role="group"
            aria-label="What Gather pulls from"
            onPointerDown={(e) => e.stopPropagation()}
            {...BLOOM}
          >
            <div className="inner">
            <div className="eyebrow">Gather from</div>
            <button type="button" aria-pressed={!filterOn} className={`row${!filterOn ? ' on' : ''}`} onClick={() => pickFilter(NO_SCOPE)}>
              <Inbox size={13} strokeWidth={2} />
              <span className="name">All saves</span>
              <span className="n">{big.length.toLocaleString()}</span>
            </button>
            <button type="button" aria-pressed={scope.fav} className={`row${filter.fav ? ' on' : ''}`} onClick={(e) => pickFilter({ ...scope, fav: !scope.fav }, e.shiftKey || e.metaKey || e.ctrlKey)}>
              <Heart size={13} strokeWidth={2} fill={scope.fav ? 'currentColor' : 'none'} />
              <span className="name">Favorites</span>
              <span className="n">{favs.size}</span>
            </button>
            <div className="sep" />
            {SOURCE_LIST.filter((src) => !off.includes(src)).map((src) => {
              const on = scope.source === src
              return (
                <button type="button" aria-pressed={on} key={src} className={`row${on ? ' on' : ''}`} onClick={(e) => pickFilter({ ...scope, source: on ? null : src }, e.shiftKey || e.metaKey || e.ctrlKey)}>
                  <Glyph source={src} />
                  <span className="name">{src}</span>
                  <span className="n">{countBySource(src)}</span>
                </button>
              )
            })}
            {tagCounts.length > 0 && <div className="sep" />}
            {tagCounts.map(([tag, n]) => {
              const on = scope.tags.includes(tag)
              return (
                <button type="button" aria-pressed={on} key={tag} className={`row${on ? ' on' : ''}`} onClick={(e) => pickTag(tag, e.shiftKey || e.metaKey || e.ctrlKey)}>
                  <Tag size={13} strokeWidth={2} />
                  <span className="name">#{tag}</span>
                  <span className="n">{n}</span>
                </button>
              )
            })}
            <div className="meta note">Shift-click keeps the list open, so a source and tags combine.</div>
            </div>
          </motion.div>
        )}
        </AnimatePresence>

        <AnimatePresence>
        {shown && (
          <SaveCard
            save={bigById[shown]}
            tags={tagsOf(shown)}
            fav={favs.has(shown)}
            onTag={(t) => setTagsFor(shown, Array.from(new Set([...tagsOf(shown), t])))}
            onUntag={(t) => setTagsFor(shown, tagsOf(shown).filter((x) => x !== t))}
            onFav={() => toggleFav(shown)}
            onGather={() => (view3d ? setView3d(false) : null, window.setTimeout(() => actions.gatherAround(shown), view3d ? 50 : 0))}
            onClose={() => (view3d ? setFocus3d(null) : setSelected(null))}
          />
        )}
        </AnimatePresence>


        <form
          ref={barRef}
          className="bar"
          onSubmit={(e) => {
            e.preventDefault()
            submit()
          }}
        >
          <button
            type="button"
            ref={orbRef}
            className={`orbslot${filterOpen ? ' open' : ''}`}
            onClick={() => { setFilterOpen((v) => !v); setSelected(null); setSources(false); setHistory(false) }}
            aria-expanded={filterOpen}
            aria-label={`Gather from ${filterLabel}`}
            title={`Gather from ${filterLabel}`}
          >
            {busy ? (
              <ThinkingOrb state="working" size={20} theme="light" aria-label="Gathering your saves" />
            ) : scope.source ? (
              <Glyph source={scope.source} size={20} />
            ) : (
              <span className={`dot${filterOn || active ? ' on' : ''}`} />
            )}
          </button>
          <input
            autoFocus
            value={text}
            onChange={(e) => {
              setText(e.target.value)
              if (summary) setSummary(null)
            }}
            onKeyDown={(e) => {
              if (e.key === 'Enter') {
                e.preventDefault()
                submit()
              }
              /* Escape empties the field first, then lets go of it. Only
                 once the bar is out of the way does it reach the space. */
              if (e.key === 'Escape') {
                if (text) {
                  e.stopPropagation()
                  setText('')
                } else {
                  e.stopPropagation()
                  e.currentTarget.blur()
                }
              }
            }}
            placeholder={selected ? PLACEHOLDERS[ph] : summary ?? PLACEHOLDERS[ph]}
            style={{ '--w': `${Math.min(44, Math.max(14, (text || (selected ? '' : summary) || PLACEHOLDERS[ph]).length + 1))}ch` } as React.CSSProperties}
            aria-label="Thought"
          />
          <output className="sr-only" aria-live="polite">{summary ?? ''}</output>
          <button type="submit" className="go" disabled={!text.trim() || busy} aria-label="Gather">
            {busy ? 'Gathering…' : 'Gather'}
          </button>
          <button type="button" className={`ideas${history ? ' on' : ''}`} disabled={tiles.length === 0} onClick={() => { setHistory((h) => !h); setFilterOpen(false); setSelected(null) }} aria-expanded={history} aria-label="Ideas you have gathered">
            Ideas
          </button>
        </form>
        </div>
        )}

        </motion.div>

        <AnimatePresence>
        {doc && (
          <motion.div
            key="doc"
            className="overlay"
            role="dialog"
            aria-modal="true"
            aria-label={doc.text}
            initial={{ opacity: 0, y: tune.doc.offsetY }}
            animate={{ opacity: 1, y: 0, transition: { delay: tune.doc.slideIn / 1000, duration: 0.3, ease: EASE } }}
            exit={{ opacity: 0, transition: { duration: 0.15, ease: [0.4, 0, 1, 1] } }}
            ref={(el) => el?.querySelector<HTMLElement>('.back')?.focus()}
          >
            <IdeaDoc title={doc.text} onBack={() => setDoc(null)} backLabel="Space" from="your space" idea={doc.idea} anim={tune.doc} />
          </motion.div>
        )}
        </AnimatePresence>
      </div>
    </C.Provider>
  )
}

export function Space({ tune = DEFAULT_TUNE }: { tune?: Tune }) {
  return (
    <TuneContext.Provider value={tune}>
      <MotionConfig reducedMotion="user">
        <ReactFlowProvider>
          <SpaceInner />
        </ReactFlowProvider>
      </MotionConfig>
    </TuneContext.Provider>
  )
}
