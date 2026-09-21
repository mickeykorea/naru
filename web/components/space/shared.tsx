'use client'
/* Source glyph and thumbnail. */
import { useEffect, useState } from 'react'
import { Asterisk, Globe } from 'lucide-react'
import type { Save, Source } from '@/lib/seed/data'

/* Brand marks are the same Simple Icons SVGs the iOS app ships, tinted
   through a CSS mask so they follow currentColor. Sources without a mark
   get a Lucide glyph. */
const BRAND: Partial<Record<Source, string>> = { instagram: 'instagram', tiktok: 'tiktok', youtube: 'youtube', spotify: 'spotify', x: 'x' }

/* Marks a user-added source can match by name. Same Simple Icons set as the
   built-ins, tinted through a mask so a brand's own colour never leaks in. */
const NAMED = ['applemusic', 'pinterest', 'reddit', 'substack', 'soundcloud', 'vimeo', 'behance', 'dribbble', 'notion', 'figma', 'github', 'medium', 'tumblr', 'goodreads', 'letterboxd', 'bandcamp', 'threads', 'bluesky', 'discord', 'twitch', 'instagram', 'tiktok', 'youtube', 'spotify', 'x']
export const markFor = (name: string) => {
  const slug = name.toLowerCase().replace(/[^a-z0-9]/g, '')
  return NAMED.includes(slug) ? slug : null
}

export function Mark({ name, size = 16 }: { name: string; size?: number }) {
  const slug = markFor(name)
  const inner = Math.round(size * 0.55)
  return (
    <span className="glyph" title={name} style={{ width: size, height: size }}>
      {slug ? (
        <span className="mark" style={{ width: inner, height: inner, maskImage: `url(/brands/${slug}.svg)`, WebkitMaskImage: `url(/brands/${slug}.svg)` }} />
      ) : (
        <Globe size={inner} strokeWidth={2} />
      )}
    </span>
  )
}

export function Glyph({ source, size = 16 }: { source: Source; size?: number }) {
  const brand = BRAND[source]
  const inner = Math.round(size * 0.55)
  return (
    <span className="glyph" title={source} style={{ width: size, height: size }}>
      {brand ? (
        <span className="mark" style={{ width: inner, height: inner, maskImage: `url(/brands/${brand}.svg)`, WebkitMaskImage: `url(/brands/${brand}.svg)` }} />
      ) : source === 'linkedin' ? (
        <span className="in" style={{ fontSize: Math.round(size * 0.5) }}>in</span>
      ) : source === 'arena' ? (
        <Asterisk size={inner + 2} strokeWidth={2} />
      ) : (
        <Globe size={inner} strokeWidth={2} />
      )}
    </span>
  )
}

/* Mock thumbnails live in public/mock/thumbs (scripts/mock-thumbs.mjs):
   one per hand-written save, a pool of twelve per theme for the rest. */
/* Generated saves draw from a pool of POOL images per theme. Which one each
   save gets is decided once from the opening layout (see seedLayout), so two
   saves near each other never show the same picture, and every view, cell,
   card and 3D object, reads the same choice. */
export const POOL = 36
export const thumbIndex = new Map<string, number>()
export function thumbUrl(save: Save) {
  if (save.cover) return save.cover
  if (save.id.startsWith('s')) return `/mock/thumbs/${save.id}.jpg`
  const n = parseInt(save.id.slice(1), 10) || 0
  const k = thumbIndex.get(save.id) ?? n % POOL
  return `/mock/thumbs/${save.theme ?? 'loose'}-${k}.jpg`
}

/* A thumbnail that holds its own space: the skeleton is exactly the size the
   image will be, so nothing shifts when the bytes land.

   The mock thumbnails are local files that decode before the first frame, so
   the skeleton would never be seen. Each slot therefore holds it for a
   deterministic beat, keyed off the src, and the grid fills in the way a
   real archive does. Drop `hold` when the images come off the network. */
const HOLD_MIN = 260
const HOLD_SPREAD = 620
const beat = (src: string) => {
  let h = 0
  for (let i = 0; i < src.length; i++) h = (h * 31 + src.charCodeAt(i)) >>> 0
  return HOLD_MIN + (h % HOLD_SPREAD)
}

export function Pic({ src, className = '', alt = '', lazy = false, hold = true, style }: { src: string; className?: string; alt?: string; lazy?: boolean; hold?: boolean; style?: React.CSSProperties }) {
  const [state, setState] = useState<'loading' | 'done' | 'failed'>('loading')
  const [held, setHeld] = useState(!hold)
  useEffect(() => {
    if (!hold) return
    const id = window.setTimeout(() => setHeld(true), beat(src))
    return () => window.clearTimeout(id)
  }, [hold, src])
  const shown = held ? state : 'loading'
  return (
    <span className={`pic-slot ${className}`} style={style} data-state={shown}>
      {shown === 'loading' && <span className="skel" aria-hidden="true" />}
      {/* eslint-disable-next-line @next/next/no-img-element */}
      <img
        alt={alt}
        src={src}
        loading={lazy ? 'lazy' : undefined}
        draggable={false}
        onLoad={() => setState('done')}
        onError={() => setState('failed')}
      />
    </span>
  )
}

/* Where a save came from. The mock archive has no URLs, so this is the
   platform or the author's page: enough for the link to be real. */
const HOME: Record<string, string> = {
  spotify: 'https://open.spotify.com',
  youtube: 'https://www.youtube.com',
  tiktok: 'https://www.tiktok.com',
  instagram: 'https://www.instagram.com',
  x: 'https://x.com',
  arena: 'https://www.are.na',
  linkedin: 'https://www.linkedin.com',
}
export function linkFor(save: Save) {
  const handle = save.author.replace(/^@/, '')
  if (save.source === 'web') return `https://${handle.split('/')[0]}`
  if (save.source === 'x') return `https://x.com/${handle}`
  if (save.source === 'tiktok') return `https://www.tiktok.com/@${handle}`
  if (save.source === 'arena') return `https://www.are.na/${handle.replace(/^are\.na\//, '')}`
  return HOME[save.source] ?? 'https://naru.app'
}

/* A still opens in place; anything that plays goes back to where it lives. */
export const opensOut = (save: Save) => save.source === 'spotify' || save.source === 'youtube' || save.source === 'tiktok'

export function Thumb({ save, width = 400 }: { save: Save; width?: number }) {
  if (!save.image) return null
  const h = Math.round(width * save.ratio)
  return (
    // eslint-disable-next-line @next/next/no-img-element
    <img className="thumb" alt="" src={thumbUrl(save)} style={{ aspectRatio: `${width} / ${h}` }} />
  )
}

export const LANES = {
  agrees: { name: 'Agrees', hint: 'Saves that argue for this idea' },
  disagrees: { name: 'Disagrees', hint: 'Saves that argue against it' },
  visual: { name: 'Visual', hint: 'How it could look. Screenshots, design, photos' },
  precedent: { name: 'Precedent', hint: 'Someone already built this, or something close' },
  howto: { name: 'How-to', hint: 'Methods, tools, tutorials you could build it with' },
  mood: { name: 'Mood', hint: 'Music and video that set the feeling' },
} as const
