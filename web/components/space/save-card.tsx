'use client'
/* The selected save: what it is, its tags, favorite, and the one action
   that leads somewhere (gather around it). Used by the 2D space. */
import { useEffect, useState } from 'react'
import { createPortal } from 'react-dom'
import { AnimatePresence, motion } from 'motion/react'
import { ExternalLink, Heart, Maximize2, X } from 'lucide-react'
import type { BigSave } from '@/lib/seed/data-big'
import { Glyph, linkFor, opensOut, Pic, thumbUrl } from './shared'

export function SaveCard({
  save,
  tags,
  fav,
  onTag,
  onUntag,
  onFav,
  onGather,
  onClose,
}: {
  save: BigSave
  tags: string[]
  fav: boolean
  onTag: (t: string) => void
  onUntag: (t: string) => void
  onFav: () => void
  onGather: () => void
  onClose: () => void
}) {
  const [draft, setDraft] = useState('')
  const [full, setFull] = useState(false)
  /* The picture lives in a portal on <body>, outside the React root's event
     delegation, so its own listeners close it. Escape is claimed in the
     capture phase so the space does not also close the card behind it. */
  useEffect(() => {
    if (!full) return
    const onKey = (e: KeyboardEvent) => {
      if (e.key !== 'Escape') return
      e.stopPropagation()
      e.stopImmediatePropagation()
      setFull(false)
    }
    window.addEventListener('keydown', onKey, true)
    return () => window.removeEventListener('keydown', onKey, true)
  }, [full])
  const add = () => {
    const t = draft.trim().replace(/^#/, '').toLowerCase()
    if (t) onTag(t)
    setDraft('')
  }
  return (
    <motion.aside
      key={save.id}
      className="savecard"
      onPointerDown={(e) => e.stopPropagation()}
      initial={{ height: 0, opacity: 0, filter: 'blur(10px)' }}
      animate={{ height: 'auto', opacity: 1, filter: 'blur(0px)' }}
      exit={{ height: 0, opacity: 0, filter: 'blur(10px)', transition: { type: 'spring', visualDuration: 0.22, bounce: 0 } }}
      transition={{
        height: { type: 'spring', visualDuration: 0.32, bounce: 0.16 },
        opacity: { type: 'spring', visualDuration: 0.3, bounce: 0, delay: 0.03 },
        filter: { type: 'spring', visualDuration: 0.3, bounce: 0, delay: 0.03 },
      }}
    >
      <div className="inner">
        <div className="m">
          <Glyph source={save.source} size={20} />
          <span>{save.author} · {save.age}</span>
          <span className="grow" />
          <button type="button" className={`heart${fav ? ' on' : ''}`} onClick={onFav} aria-pressed={fav} aria-label={fav ? 'Remove from favorites' : 'Add to favorites'}>
            <Heart size={16} strokeWidth={2} fill={fav ? 'currentColor' : 'none'} />
          </button>
          <button type="button" className="x" onClick={onClose} aria-label="Close">
            <X size={14} strokeWidth={2} />
          </button>
        </div>
      <div className="lead">
      {save.image && (
        opensOut(save) ? (
          <a className="picbtn" href={linkFor(save)} target="_blank" rel="noreferrer noopener" aria-label={`Open on ${save.source}`}>
            <Pic src={thumbUrl(save)} className="pic" />
            <span className="over" aria-hidden="true"><ExternalLink size={18} strokeWidth={2} /></span>
          </a>
        ) : (
          <button type="button" className="picbtn" onClick={() => setFull(true)} aria-label="See the picture full size">
            <Pic src={thumbUrl(save)} className="pic" />
            <span className="over" aria-hidden="true"><Maximize2 size={18} strokeWidth={2} /></span>
          </button>
        )
      )}
      <div className="body">
        <div className="t display">{save.title}</div>
        {save.summary && <div className="s">{save.summary}</div>}
      </div>
      </div>
        <output className="sr-only" aria-live="polite">{tags.length ? `Tags: ${tags.map((t) => '#' + t).join(', ')}` : 'No tags'}</output>
        <div className="tags">
          {tags.map((t) => (
            <button type="button" key={t} className="tag" onClick={() => onUntag(t)} title="Remove tag">
              #{t}
            </button>
          ))}
          <input
            value={draft}
            onChange={(e) => setDraft(e.target.value)}
            onKeyDown={(e) => {
              if (e.key === 'Enter' || e.key === ',') {
                e.preventDefault()
                add()
              }
              if (e.key === 'Escape') {
                e.stopPropagation()
                if (draft) setDraft('')
                else onClose()
              }
              if (e.key === 'Backspace' && !draft && tags.length) onUntag(tags[tags.length - 1])
            }}
            onBlur={add}
            placeholder="#tag"
            aria-label="Add a tag"
          />
        </div>
        <button type="button" className="pill cta" onClick={onGather}>Show related saves</button>
      </div>
      {createPortal(
      <AnimatePresence>
        {full && (
          <motion.div
            className="lightbox"
            onPointerDown={(e) => e.stopPropagation()}
            ref={(el) => {
              if (!el) return
              el.onclick = () => setFull(false)
            }}
            role="dialog"
            aria-modal="true"
            aria-label={save.title}
            initial={{ opacity: 0 }}
            animate={{ opacity: 1 }}
            exit={{ opacity: 0 }}
            transition={{ duration: 0.18, ease: [0.22, 1, 0.36, 1] as const }}
          >
            <motion.img
              alt={save.title}
              src={thumbUrl(save)}
              initial={{ scale: 0.94, opacity: 0 }}
              animate={{ scale: 1, opacity: 1 }}
              exit={{ scale: 0.97, opacity: 0 }}
              transition={{ type: 'spring', visualDuration: 0.32, bounce: 0.14 }}
            />
            <button type="button" className="close" aria-label="Close the picture"><X size={16} strokeWidth={2} /></button>
          </motion.div>
        )}
      </AnimatePresence>,
      document.body,
      )}
    </motion.aside>
  )
}
