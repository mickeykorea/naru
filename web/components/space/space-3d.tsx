'use client'
/* The 3D view: every save placed by its (seeded) embedding, so
   distance means relatedness. No lines. A tilted field seen from above,
   drag to move, wheel to zoom, depth of field by distance from the focus
   plane. Click a save and everything else drops to 12% opacity. CSS 3D,
   no WebGL. */
import { useMemo, useRef, useState } from 'react'
import { themes } from '@/lib/seed/data'
import { big } from '@/lib/seed/data-big'
import { Glyph, Pic, thumbUrl } from './shared'

const TILT = 52
type P3 = { x: number; y: number; z: number }

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

/* Theme centres spread over a plane with a little height each; items sit in
   a gaussian cloud around their theme. A real build projects the
   embedding to three axes instead. */
const positions: Record<string, P3> = (() => {
  const r = rng(23)
  const g = () => (r() + r() + r() + r() - 2) / 2
  const keys = themes.map((t) => t.id).concat('loose')
  const centre: Record<string, P3> = {}
  keys.forEach((k, i) => {
    const a = (i / keys.length) * Math.PI * 2
    const rad = k === 'loose' ? 0 : 2400
    centre[k] = { x: Math.cos(a) * rad, y: Math.sin(a) * rad * 0.75, z: (i % 3) * 90 }
  })
  const counts: Record<string, number> = {}
  for (const s of big) counts[s.theme ?? 'loose'] = (counts[s.theme ?? 'loose'] ?? 0) + 1
  const out: Record<string, P3> = {}
  for (const s of big) {
    const k = s.theme ?? 'loose'
    const c = centre[k]
    const spread = 260 + Math.sqrt(counts[k]) * 44
    out[s.id] = { x: c.x + g() * spread, y: c.y + g() * spread, z: c.z + g() * 120 }
  }
  return out
})()

export function Space3D({ focus, setFocus }: { focus: string | null; setFocus: (id: string | null) => void }) {
  const [cam, setCam] = useState({ x: 0, y: 0, zoom: 0.45 })
  const drag = useRef<{ x: number; y: number; cx: number; cy: number; moved: boolean } | null>(null)

  const items = useMemo(() => big.map((s) => ({ s, p: positions[s.id] })), [])

  return (
    <div
      className="space3d"
      onPointerDown={(e) => {
        drag.current = { x: e.clientX, y: e.clientY, cx: cam.x, cy: cam.y, moved: false }
      }}
      onPointerMove={(e) => {
        const d = drag.current
        if (!d) return
        const dx = e.clientX - d.x
        const dy = e.clientY - d.y
        if (Math.abs(dx) + Math.abs(dy) > 3) d.moved = true
        if (d.moved) setCam((c) => ({ ...c, x: d.cx + dx, y: d.cy + dy }))
      }}
      onPointerUp={() => {
        const d = drag.current
        drag.current = null
        if (d && !d.moved) setFocus(null)
      }}
      onWheel={(e) => setCam((c) => ({ ...c, zoom: Math.min(2, Math.max(0.35, c.zoom * (e.deltaY > 0 ? 0.92 : 1.08))) }))}
    >
      <div className="scene" style={{ transform: `translate(${cam.x}px, ${cam.y}px) scale(${cam.zoom}) rotateX(${TILT}deg)` }}>
        {items.map(({ s, p }) => {
          /* Depth of field: the focus plane is the row under the camera. */
          const depth = Math.abs(p.y + cam.y / cam.zoom) / 2200
          const blur = depth < 0.5 ? 0 : depth < 0.85 ? 1 : 2
          const dim = focus !== null && focus !== s.id
          return (
            <button
              type="button"
              key={s.id}
              aria-label={s.title}
              aria-pressed={focus === s.id}
              className={`obj blur-${blur}${dim ? ' dim' : ''}${focus === s.id ? ' focus' : ''}`}
              style={{ transform: `translate3d(${p.x}px, ${p.y}px, ${p.z}px) rotateX(${-TILT}deg)` }}
              onPointerUp={(e) => {
                if (drag.current?.moved) return
                e.stopPropagation()
                drag.current = null
                setFocus(s.id)
              }}
              onKeyDown={(e) => {
                if (e.key !== 'Enter' && e.key !== ' ') return
                e.preventDefault()
                e.stopPropagation()
                setFocus(focus === s.id ? null : s.id)
              }}
              title={s.title}
            >
              {s.image ? (
                <Pic src={thumbUrl(s)} lazy className="objpic" />
              ) : (
                <div className="text">
                  <Glyph source={s.source} />
                  <span>{s.title}</span>
                </div>
              )}
            </button>
          )
        })}
      </div>

    </div>
  )
}
