'use client'
/* PROTOTYPE variant A: Index + idea document.
   Home is "You": tensions on top, themes as an index. A theme proposes
   ideas; picking one opens the idea as a document that fills itself
   (Supports / Contradicts / Adjacent / Blind spot as sections, pushback as
   inline comments). Same route, in-memory state. */
import { useState } from 'react'
import { saves, savesFor, tensions, themeById, themes } from '@/lib/seed/data'
import { Thumb } from '@/components/space/shared'
import { IdeaDoc } from '@/components/space/idea-doc'

export function VariantIndex() {
  const [open, setOpen] = useState<string | null>(null)
  return open ? <IdeaDoc title={open} onBack={() => setOpen(null)} /> : <Index onOpen={setOpen} />
}

function Index({ onOpen }: { onOpen: (title: string) => void }) {
  const [expanded, setExpanded] = useState<string | null>(null)
  return (
    <main className="doc">
      <div className="eyebrow">You</div>
      <p className="meta" style={{ margin: '4px 0 40px' }}>
        <b>{saves.length}</b> saves across <b>8</b> sources · synced 4 min ago · <b>{themes.length}</b> themes
      </p>

      <div className="eyebrow" style={{ marginBottom: 12 }}>Tensions</div>
      {tensions.map((t) => (
        <p key={t.a + t.b} className="tension garamond">
          <b>{themeById[t.a].name}</b> · <b>{themeById[t.b].name}</b>
          <br />
          {t.line}
        </p>
      ))}

      <div className="eyebrow" style={{ margin: '48px 0 12px' }}>Themes</div>
      {themes.map((t) => {
        const items = savesFor(t.id)
        const isOpen = expanded === t.id
        return (
          <section key={t.id} className="theme-row">
            <div className="top">
              <span className="name">{t.name}</span>
              <span className="n">{items.length}</span>
            </div>
            <p className="line garamond">{t.line}</p>
            <div className="strip">
              {items.slice(0, 6).map((x) =>
                x.image ? (
                  <Thumb key={x.id} save={x} width={112} />
                ) : (
                  <div key={x.id} className="text">{x.title}</div>
                ),
              )}
            </div>
            <button className="textbtn" onClick={() => setExpanded(isOpen ? null : t.id)}>
              {isOpen ? 'Close' : 'What could I build from this?'}
            </button>
            {isOpen && (
              <ol className="proposals">
                {t.proposals.map((p, i) => (
                  <li key={p}>
                    <span className="k">{i + 1}</span>
                    <button onClick={() => onOpen(p)}>{p}</button>
                  </li>
                ))}
                <li>
                  <span className="k">+</span>
                  <button className="textbtn" style={{ height: 'auto', padding: 0 }} onClick={() => onOpen('')}>
                    Something else
                  </button>
                </li>
              </ol>
            )}
          </section>
        )
      })}
    </main>
  )
}

