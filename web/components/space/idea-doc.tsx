'use client'
/* The idea as a document: one section per relationship the saves have to
   it (Agrees, Disagrees, Visual, Precedent, How-to, Mood), the questions
   the saves raise one at a time under Disagrees, and a brief you copy as
   markdown for a coding agent. */
import { useEffect, useRef, useState } from 'react'
import { motion } from 'motion/react'
import type { DocTiming } from './space'
import { ArrowLeft, Check, X } from 'lucide-react'
import { byId, idea as seeded, LANE_ORDER, themeById, type Idea, type Lane } from '@/lib/seed/data'
import { Glyph, LANES } from './shared'

export function IdeaDoc({ title, onBack, from, backLabel = 'You', idea: given, anim }: { title: string; onBack: () => void; from?: string; backLabel?: string; idea?: Idea | null; anim?: DocTiming }) {
  const idea = given === undefined ? seeded : given
  /* Storyboard stages: header at anim.headerAt, then each block at
     anim.sectionsAt + index * anim.stagger. Without `anim` nothing moves. */
  const rise = (index: number) =>
    anim
      ? {
          initial: { opacity: 0, y: anim.offsetY * 0.66 },
          animate: { opacity: 1, y: 0 },
          transition: { delay: (index < 0 ? anim.headerAt : anim.sectionsAt + index * anim.stagger) / 1000, duration: 0.32, ease: [0.22, 1, 0.36, 1] as const },
        }
      : {}
  const [name, setName] = useState(title)
  const [brief, setBrief] = useState<string | null>(null)
  const [kept, setKept] = useState<Set<string>>(new Set())
  const [gone, setGone] = useState<Set<string>>(new Set())
  const [answers, setAnswers] = useState<Record<number, string>>({})
  const [draft, setDraft] = useState('')
  const [scrolled, setScrolled] = useState(false)
  const ref = useRef<HTMLElement>(null)
  useEffect(() => {
    const el = ref.current?.closest('.overlay')
    if (!el) return
    const onScroll = () => setScrolled(el.scrollTop > 0)
    el.addEventListener('scroll', onScroll, { passive: true })
    return () => el.removeEventListener('scroll', onScroll)
  }, [])
  const lanes = idea ? LANE_ORDER.filter((lane) => (idea.lanes[lane] ?? []).length > 0) : []

  const copy = (md: string) => {
    setBrief(md)
    navigator.clipboard?.writeText(md).catch(() => {})
  }

  if (idea === null) {
    const md = `# ${name.trim() || 'Untitled idea'}\n\n## From my saves\n- Nothing in the archive relates to this yet.\n\n## Build\n- Treat every assumption as a spike before feature work.`
    return (
      <main className="doc" ref={ref}>
        <nav className="rail"><button className="back" onClick={onBack}><ArrowLeft size={14} strokeWidth={2} /> {backLabel}</button></nav>
        <div className="head"><h1 className="display" contentEditable suppressContentEditableWarning spellCheck={false}>{title || 'Untitled idea'}</h1></div>
        <p className="read display">Nothing in your archive relates to this yet. Save around it and gather again.</p>
        <div className="brief">
          <div className="meta">Nothing to include yet. The brief will hold the title and one build note.</div>
          <button className="pill" onClick={() => copy(md)}>Copy as a build brief</button>
        </div>
        {brief && <BriefOut md={brief} />}
      </main>
    )
  }

  const theme = themeById[idea.themeId]
  const pulled = new Set(Object.values(idea.lanes).flat().map((e) => e.id)).size
  const nextQ = idea.pushback.findIndex((_, i) => answers[i] === undefined)
  const done = nextQ === -1

  const toggle = (set: React.Dispatch<React.SetStateAction<Set<string>>>, id: string) =>
    set((s) => {
      const n = new Set(s)
      if (n.has(id)) n.delete(id)
      else n.add(id)
      return n
    })
  const keep = (id: string) => toggle(setKept, id)
  const dismiss = (id: string) => toggle(setGone, id)
  const answer = (i: number, text: string) => {
    setAnswers((a) => ({ ...a, [i]: text }))
    setDraft('')
  }

  const rows = (lane: Lane) =>
    (idea.lanes[lane] ?? []).map(({ id, why }) => {
      const x = byId[id]
      const cls = ['save-row', kept.has(id) && 'kept', gone.has(id) && 'gone'].filter(Boolean).join(' ')
      return (
        <div key={lane + id} className={cls}>
          <Glyph source={x.source} />
          <div>
            <div className="t">{x.title}</div>
            <div className="why">{why} · <span className="meta">{x.author}&nbsp;·&nbsp;{x.age}</span></div>
          </div>
          <div className="acts">
            <button className="circ keep" onClick={() => keep(id)} aria-label="Keep" aria-pressed={kept.has(id)}><Check size={14} strokeWidth={2} /></button>
            <button className="circ" onClick={() => dismiss(id)} aria-label={gone.has(id) ? 'Restore' : 'Dismiss'} aria-pressed={gone.has(id)}><X size={14} strokeWidth={2} /></button>
          </div>
        </div>
      )
    })

  return (
    <main className="doc" ref={ref}>
      <motion.nav className="rail" aria-label="Sections" {...rise(-1)}>
        <div className={`links${scrolled ? ' dim' : ''}`}>
          <button className="back" onClick={onBack}><ArrowLeft size={14} strokeWidth={2} /> {backLabel}</button>
          {lanes.map((lane) => <a key={lane} href={`#${lane}`}>{LANES[lane].name}</a>)}
          <a href="#brief">Build brief</a>
        </div>
      </motion.nav>
      <motion.div {...rise(-1)}>
        <div className="head">
          <h1
            className="display"
            contentEditable
            suppressContentEditableWarning
            spellCheck={false}
            role="textbox"
            aria-label="Idea title"
            onInput={(e) => setName(e.currentTarget.textContent ?? '')}
          >
            {title || 'Untitled idea'}
          </h1>
        </div>
        {title && idea.title.toLowerCase() !== title.toLowerCase() && <p className="read display">Naru read this as: {idea.title}</p>}
        <p className="meta">
          From {from ?? theme.name} · <b>{pulled}</b>&nbsp;of your saves relate to this · <b>{kept.size + gone.size}</b>&nbsp;reviewed
        </p>
      </motion.div>

      {lanes.map((lane, i) => (
        <motion.section key={lane} id={lane} className="section" {...rise(i)}>
          <div className="section-head">
            <span className="name display">{LANES[lane].name}</span>
            <span className="n">{idea.lanes[lane]!.length}</span>
            <span className="hint">{LANES[lane].hint}</span>
          </div>
          {rows(lane)}
          {lane === 'disagrees' &&
            idea.pushback.map((p, i) => {
              const a = answers[i]
              if (a !== undefined) {
                return (
                  <div key={i} className="ask done">
                    <div className="meta">A question your saves raised</div>
                    <div className="q display" style={{ fontSize: 15, lineHeight: '24px', color: 'var(--p-ink-3)' }}>{p.q}</div>
                    <div className="a">{a || 'Skipped'}</div>
                  </div>
                )
              }
              if (i !== nextQ) return null
              return (
                <div key={i} className="ask">
                  <div className="meta">A question your saves raise · {i + 1} of {idea.pushback.length}</div>
                  <p className="q display">{p.q}</p>
                  <div className="ev">
                    {p.evidence.length ? 'From your saves: ' + p.evidence.map((id) => byId[id].title).join(' · ') : 'No evidence in your archive yet.'}
                  </div>
                  <textarea
                    value={draft}
                    onChange={(e) => {
                      setDraft(e.target.value)
                      e.target.style.height = 'auto'
                      e.target.style.height = `${e.target.scrollHeight}px`
                    }}
                    placeholder="Answer here"
                    rows={2}
                  />
                  <div className="acts">
                    <button className="pill" onClick={() => answer(i, draft.trim())} disabled={!draft.trim()}>Next</button>
                    <button className="textbtn" onClick={() => answer(i, '')}>Skip</button>
                  </div>
                </div>
              )
            })}
        </motion.section>
      ))}

      <motion.div id="brief" className="brief" {...rise(lanes.length)}>
        <div className="meta">
          {done ? 'Every question answered.' : `${idea.pushback.length - Object.keys(answers).length} questions still open. They go into the brief as open questions.`}
        </div>
        <button className="pill" onClick={() => copy(briefMarkdown(name.trim() || 'Untitled idea', idea, kept, gone, answers))}>Copy as a build brief</button>
      </motion.div>
      {brief && <BriefOut md={brief} />}
    </main>
  )
}

function BriefOut({ md }: { md: string }) {
  return (
    <div className="brief-out" role="status">
      <div className="meta">Copied. Paste it into Claude Code or Cursor. If the copy failed, select the text below.</div>
      <pre>{md}</pre>
    </div>
  )
}

function briefMarkdown(title: string, idea: Idea, kept: Set<string>, gone: Set<string>, answers: Record<number, string>) {
  const row = ({ id, why }: { id: string; why: string }) => `- ${byId[id].title} (${byId[id].author}) · ${why}` + (kept.has(id) ? ' · kept' : '')
  const section = (lane: Lane) => {
    const rows = (idea.lanes[lane] ?? []).filter((e) => !gone.has(e.id))
    return rows.length ? [`## ${LANES[lane].name}: ${LANES[lane].hint}`, ...rows.map(row), ''] : []
  }
  return [
    `# ${title}`,
    '',
    ...LANE_ORDER.flatMap(section),
    '## Questions my saves raised',
    ...idea.pushback.map((p, i) => `- Q: ${p.q}\n  A: ${answers[i] === undefined ? 'OPEN' : answers[i] || 'skipped'}`),
    '',
    '## Build',
    '- Start from the kept Agrees. Treat every OPEN question as a spike before feature work.',
  ].join('\n')
}
