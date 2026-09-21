'use client'
/* PROTOTYPE variant B: Canvas.
   Home is a map: theme groups (positioned as clustering would), save cards
   inside, tensions as labelled edges. Click a theme for proposals; pick one
   and the right panel becomes the stress-test, dimming everything on the
   canvas that is not evidence. Hover a card, press + to add it to the lane
   you last clicked. React Flow, in-memory state. */
import { useMemo, useState } from 'react'
import {
  Background,
  Controls,
  Handle,
  Position,
  ReactFlow,
  type Edge,
  type Node,
  type NodeProps,
} from '@xyflow/react'
import '@xyflow/react/dist/style.css'
import { byId, idea, saves, savesFor, tensions, themeById, themes, type Lane, type Save } from '@/lib/seed/data'
import { Glyph, LANES, Thumb } from '@/components/space/shared'

type LaneKey = Lane
type Ctx = {
  activeTheme: string | null
  ideaOpen: boolean
  laneOf: Record<string, LaneKey>
  target: LaneKey
  onTheme: (id: string) => void
  onAdd: (id: string) => void
}

const CARD_W = 152
const COLS = 3
const GAP = 12
const PAD = 16
const HEAD = 64

/* Loose grid, four groups per row, height from card count. A real layout
   would come from UMAP over the embeddings. */
function layout() {
  const nodes: Node[] = []
  let x = 0
  let y = 0
  let rowMax = 0
  themes.concat([{ id: 'loose', name: 'Loose', line: 'Saved, not yet part of anything.', proposals: [] }]).forEach((t, i) => {
    const items = t.id === 'loose' ? saves.filter((s) => !s.theme) : savesFor(t.id)
    const rows = Math.ceil(items.length / COLS)
    const cardH = 104
    const h = HEAD + rows * (cardH + GAP) + PAD
    const w = PAD * 2 + COLS * CARD_W + (COLS - 1) * GAP
    if (i % 4 === 0 && i > 0) {
      x = 0
      y += rowMax + 48
      rowMax = 0
    }
    nodes.push({ id: `t:${t.id}`, type: 'theme', position: { x, y }, data: { theme: t, count: items.length }, style: { width: w, height: h }, draggable: true, selectable: false })
    items.forEach((s, j) => {
      nodes.push({
        id: s.id,
        type: 'save',
        parentId: `t:${t.id}`,
        extent: 'parent',
        position: { x: PAD + (j % COLS) * (CARD_W + GAP), y: HEAD + Math.floor(j / COLS) * (cardH + GAP) },
        data: { save: s },
      })
    })
    rowMax = Math.max(rowMax, h)
    x += w + 48
  })
  return nodes
}

function ThemeNode({ data }: NodeProps<Node<{ theme: (typeof themes)[number]; count: number }>>) {
  const ctx = data as unknown as { theme: (typeof themes)[number]; count: number; ctx: Ctx }
  const active = ctx.ctx.activeTheme === data.theme.id
  return (
    <div className={`theme-node${active ? ' active' : ''}`}>
      <div className="head" onClick={() => ctx.ctx.onTheme(data.theme.id)}>
        <span className="name">{data.theme.name}</span>
        <span className="n">{data.count}</span>
      </div>
      <div className="line garamond">{data.theme.line}</div>
      <Handle type="source" position={Position.Right} style={{ opacity: 0 }} />
      <Handle type="target" position={Position.Left} style={{ opacity: 0 }} />
    </div>
  )
}

function SaveNode({ data }: NodeProps<Node<{ save: Save }>>) {
  const d = data as unknown as { save: Save; ctx: Ctx }
  const s = d.save
  const lane = d.ctx.laneOf[s.id]
  const dim = d.ctx.ideaOpen && !lane
  return (
    <div className={`save-node${dim ? ' dim' : ''}`}>
      <div className="m">
        <Glyph source={s.source} />
        <span>{s.author} · {s.age}</span>
      </div>
      <div className="t">{s.title}</div>
      {s.image && <Thumb save={s} width={264} />}
      {lane && <span className="badge">{LANES[lane].name[0]}</span>}
      {d.ctx.ideaOpen && !lane && (
        <button className="add" onClick={() => d.ctx.onAdd(s.id)} aria-label="Add to lane">+</button>
      )}
    </div>
  )
}

const nodeTypes = { theme: ThemeNode, save: SaveNode }

export function VariantCanvas() {
  const [activeTheme, setActiveTheme] = useState<string | null>(null)
  const [ideaTitle, setIdeaTitle] = useState<string | null>(null)
  const [target, setTarget] = useState<LaneKey>('agrees')
  const [extra, setExtra] = useState<Record<string, LaneKey>>({})
  const [answers, setAnswers] = useState<Record<number, string>>({})
  const [draft, setDraft] = useState('')

  const laneOf = useMemo(() => {
    const m: Record<string, LaneKey> = { ...extra }
    if (ideaTitle) for (const lane of Object.keys(idea.lanes) as LaneKey[]) for (const { id } of idea.lanes[lane] ?? []) m[id] = lane
    return m
  }, [ideaTitle, extra])

  const ctx: Ctx = {
    activeTheme,
    ideaOpen: !!ideaTitle,
    laneOf,
    target,
    onTheme: (id) => {
      setActiveTheme((cur) => (cur === id ? null : id))
      setIdeaTitle(null)
      setExtra({})
    },
    onAdd: (id) => setExtra((e) => ({ ...e, [id]: target })),
  }

  const base = useMemo(() => layout(), [])
  const nodes = base.map((n) => ({ ...n, data: { ...n.data, ctx } }))
  const edges: Edge[] = tensions.map((t) => ({
    id: `${t.a}-${t.b}`,
    source: `t:${t.a}`,
    target: `t:${t.b}`,
    label: t.line.split('.')[0],
    type: 'straight',
  }))

  const theme = activeTheme ? themeById[activeTheme] : null
  const nextQ = idea.pushback.findIndex((_, i) => answers[i] === undefined)

  return (
    <div className="canvas">
      <ReactFlow nodes={nodes} edges={edges} nodeTypes={nodeTypes} fitView minZoom={0.15} maxZoom={1.5}>
        <Background gap={24} size={1} color="var(--p-line)" />
        <Controls showInteractive={false} position="bottom-left" />
      </ReactFlow>

      <div className="hud">
        <span className="eyebrow">You</span>
        <span className="meta"><b>{saves.length}</b> saves · <b>{themes.length}</b> themes · <b>{tensions.length}</b> tensions</span>
      </div>

      {theme && !ideaTitle && (
        <aside className="panel">
          <div className="eyebrow">Theme</div>
          <h2>{theme.name}</h2>
          <div className="line garamond">{theme.line}</div>
          <div className="eyebrow" style={{ marginTop: 8 }}>What could I build from this?</div>
          <ol className="proposals">
            {theme.proposals.map((p, i) => (
              <li key={p}>
                <span className="k">{i + 1}</span>
                <button onClick={() => setIdeaTitle(p)}>{p}</button>
              </li>
            ))}
          </ol>
        </aside>
      )}

      {theme && ideaTitle && (
        <aside className="panel">
          <button className="back" onClick={() => setIdeaTitle(null)}>← {theme.name}</button>
          <div>
            <div className="eyebrow">Idea</div>
            <h2>{ideaTitle}</h2>
            <div className="meta">Evidence is lit on the canvas. Click a lane, then + on any card to add it.</div>
          </div>
          {(Object.keys(LANES) as LaneKey[]).map((lane) => {
            const ids = Object.entries(laneOf).filter(([, l]) => l === lane).map(([id]) => id)
            return (
              <section key={lane} className={`lane${target === lane ? ' target' : ''}`} onClick={() => setTarget(lane)}>
                <div className="head">
                  <span className="eyebrow" style={{ color: 'var(--p-ink)' }}>{LANES[lane].name}</span>
                  <span className="n">{ids.length}</span>
                  <span className="hint">{target === lane ? 'adding here' : ''}</span>
                </div>
                {ids.map((id) => {
                  const why = (idea.lanes[lane] ?? []).find((e) => e.id === id)?.why ?? 'Added from the canvas'
                  return (
                    <div key={id} className="row">
                      <Glyph source={byId[id].source} />
                      <div>
                        <div>{byId[id].title}</div>
                        <div className="why">{why}</div>
                      </div>
                    </div>
                  )
                })}
              </section>
            )
          })}
          {nextQ >= 0 ? (
            <div className="ask">
              <div className="meta">Naru asks · {nextQ + 1} of {idea.pushback.length}</div>
              <p className="q garamond">{idea.pushback[nextQ].q}</p>
              <textarea value={draft} onChange={(e) => setDraft(e.target.value)} placeholder="Answer here" />
              <div className="acts">
                <button className="pill" disabled={!draft.trim()} onClick={() => { setAnswers((a) => ({ ...a, [nextQ]: draft.trim() })); setDraft('') }}>Next</button>
                <button className="textbtn" onClick={() => { setAnswers((a) => ({ ...a, [nextQ]: '' })); setDraft('') }}>Skip</button>
              </div>
            </div>
          ) : (
            <div className="ask done"><div className="a">No more pushback. The brief is yours.</div></div>
          )}
          <button className="pill" disabled={nextQ >= 0}>Export brief</button>
        </aside>
      )}
    </div>
  )
}
