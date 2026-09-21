'use client'
/* Shared lab chrome: DialKit panels top-right, InterfaceKit's paintbrush
   top-left, and a Bloom hint card that opens left of the panel when a
   control is hovered. Every /lab page mounts this once. */
import { DialRoot } from 'dialkit'
import { InterfaceKit } from 'interface-kit/react'
import { Container, Content, Root, Trigger } from 'bloom-menu'
import { useCallback, useEffect, useRef, useState } from 'react'
import 'dialkit/styles.css'

/* Plain-words hover help for DialKit controls, keyed by the label DialKit
   renders ("Smooth Time", not "smoothTime"). DialKit has no description
   field, so this stamps data-hint on each control after it renders; the
   observer re-applies when folders open or panels remount. DialHintCard
   below reads it on hover. */
export function useDialHints(hints: Record<string, string>) {
  useEffect(() => {
    const apply = () => {
      for (const el of document.querySelectorAll<HTMLElement>('.dialkit-root [class*="-label"]')) {
        const label = el.textContent?.trim() ?? ''
        const hint = hints[label]
        if (!hint) continue
        const row = el.parentElement ?? el
        row.dataset.hint = hint
        row.dataset.hintLabel = label
      }
    }
    /* Body, not .dialkit-root: DialRoot mounts client-side after this
       effect, so its root does not exist yet. */
    apply()
    const mo = new MutationObserver(apply)
    mo.observe(document.body, { childList: true, subtree: true })
    return () => mo.disconnect()
  }, [hints])
}

type Hint = { label: string; text: string; top: number; right: number }
const BUTTON = 28
const GAP = 8
/* Bloom pushes the open card 0.75 × button further in its direction; the
   wrapper slides the same amount back so the card hugs the panel. */
const BLOOM_SHIFT = BUTTON * 0.75

/* Two-step hover. Hovering a control shows a "?" dot just left of the
   panel, level with that row. Hovering the dot blooms it into the card.
   Leaving both hides the dot after a short grace so the pointer can cross
   the gap between row and dot. */
function DialHintCard() {
  const [hint, setHint] = useState<Hint | null>(null)
  const [open, setOpen] = useState(false)
  const dotRef = useRef<HTMLDivElement>(null)
  const hideTimer = useRef(0)

  const cancelHide = useCallback(() => window.clearTimeout(hideTimer.current), [])
  const scheduleHide = useCallback(() => {
    cancelHide()
    hideTimer.current = window.setTimeout(() => {
      setOpen(false)
      hideTimer.current = window.setTimeout(() => setHint(null), 350)
    }, 250)
  }, [cancelHide])

  useEffect(() => {
    const over = (e: PointerEvent) => {
      const row = (e.target as Element | null)?.closest?.<HTMLElement>('[data-hint]')
      if (!row) return
      cancelHide()
      const panel = row.closest('.dialkit-panel')?.getBoundingClientRect()
      const r = row.getBoundingClientRect()
      setHint((prev) => {
        const label = row.dataset.hintLabel ?? ''
        if (prev?.label !== label) setOpen(false)
        return {
          label,
          text: row.dataset.hint ?? '',
          top: r.top + r.height / 2 - BUTTON / 2,
          right: window.innerWidth - (panel?.left ?? r.left) + GAP,
        }
      })
    }
    const out = (e: PointerEvent) => {
      const from = (e.target as Element | null)?.closest?.('[data-hint]')
      const to = e.relatedTarget as Node | null
      if (!from || (to && (from.contains(to) || dotRef.current?.contains(to)))) return
      scheduleHide()
    }
    document.addEventListener('pointerover', over)
    document.addEventListener('pointerout', out)
    return () => {
      document.removeEventListener('pointerover', over)
      document.removeEventListener('pointerout', out)
      cancelHide()
    }
  }, [cancelHide, scheduleHide])

  if (!hint) return null
  return (
    <div
      ref={dotRef}
      onPointerEnter={() => {
        cancelHide()
        setOpen(true)
      }}
      onPointerLeave={scheduleHide}
      style={{
        position: 'fixed',
        top: hint.top,
        right: hint.right,
        zIndex: 10000,
        transform: `translateX(${open ? BLOOM_SHIFT : 0}px)`,
        transition: 'transform 250ms cubic-bezier(0.2, 0.8, 0.2, 1)',
      }}
    >
      <Root open={open} direction="left" closeOnClickOutside={false} closeOnEscape={false}>
        <Container
          buttonSize={BUTTON}
          menuWidth={260}
          menuRadius={16}
          style={{ background: '#fff', color: '#1b1b1b', font: '400 13px/20px system-ui, sans-serif' }}
        >
          <Trigger>
            <span style={{ color: 'var(--muted, #a1a1aa)', fontSize: 13 }}>?</span>
          </Trigger>
          {/* Fixed width: Bloom measures content height while the box is
              still dot-sized, so unsized text would wrap letter by letter. */}
          <Content style={{ padding: 16, width: 260, boxSizing: 'border-box' }}>
            <div style={{ fontWeight: 500, marginBottom: 4 }}>{hint.label}</div>
            <div style={{ color: 'var(--muted-deep, #71717a)' }}>{hint.text}</div>
          </Content>
        </Container>
      </Root>
    </div>
  )
}

export function LabTools() {
  /* ponytail: interface-kit 0.1.3 has no position prop. Its launcher is a
     draggable fixed div inside a shadow root whose position lives in a
     motion value, so a CSS override is forgotten on open/close. Drag it
     to the left corner for real once it mounts: pointerdown on the
     launcher, pointermove/up on document (where it listens). Upgrade
     path: a position prop upstream. */
  useEffect(() => {
    const MARGIN = 16
    let tries = 0
    const t = window.setInterval(() => {
      if (++tries > 40) return window.clearInterval(t)
      for (const host of Array.from(document.body.children)) {
        const sr = host.shadowRoot
        if (!sr?.getElementById('interface-kit-runtime-styles')) continue
        const el = sr.querySelector<HTMLElement>('.fixed')
        if (!el) continue
        window.clearInterval(t)
        /* Its start is innerWidth - margin - size; the rect is unreliable
           mid entrance-animation (scaled), so derive dx from that. */
        const startLeft = window.innerWidth - MARGIN - 44
        const from = { clientX: startLeft + 22, clientY: MARGIN + 22 }
        const to = { clientX: MARGIN + 22, clientY: MARGIN + 22 }
        const ev = (type: string, at: typeof from) =>
          new PointerEvent(type, { ...at, bubbles: true, composed: true, pointerId: 1, isPrimary: true })
        el.dispatchEvent(ev('pointerdown', from))
        document.dispatchEvent(ev('pointermove', to))
        document.dispatchEvent(ev('pointerup', to))
        return
      }
    }, 50)
    return () => window.clearInterval(t)
  }, [])

  return (
    <>
      {/* Dev-only, like InterfaceKit. DialKit's own check reads NODE_ENV in a
          form Next does not inline, so it would render on Vercel; this exact
          expression is inlined at build time. */}
      <DialRoot position="top-right" defaultOpen={false} productionEnabled={process.env.NODE_ENV !== 'production'} />
      <DialHintCard />
      <InterfaceKit />
    </>
  )
}
