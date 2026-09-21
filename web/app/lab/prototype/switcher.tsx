'use client'
/* PROTOTYPE. Floating variant switcher, red so it is obviously not part of
   the design. Dev only. */
import { useRouter, useSearchParams } from 'next/navigation'
import { useEffect } from 'react'

export function Switcher({ variants }: { variants: Record<string, string> }) {
  const router = useRouter()
  const params = useSearchParams()
  const keys = Object.keys(variants)
  const current = params.get('variant') ?? keys[0]
  const go = (dir: 1 | -1) => {
    const i = keys.indexOf(current)
    const next = keys[(i + dir + keys.length) % keys.length]
    router.replace(`?variant=${next}`)
  }

  useEffect(() => {
    const onKey = (e: KeyboardEvent) => {
      const t = e.target as HTMLElement | null
      if (t && (t.tagName === 'INPUT' || t.tagName === 'TEXTAREA' || t.isContentEditable)) return
      if (e.key === 'ArrowLeft') go(-1)
      if (e.key === 'ArrowRight') go(1)
    }
    window.addEventListener('keydown', onKey)
    return () => window.removeEventListener('keydown', onKey)
  })

  if (process.env.NODE_ENV === 'production') return null
  return (
    <div className="switcher">
      <button onClick={() => go(-1)} aria-label="Previous variant">←</button>
      <span>
        {current} · {variants[current]}
      </span>
      <button onClick={() => go(1)} aria-label="Next variant">→</button>
    </div>
  )
}
