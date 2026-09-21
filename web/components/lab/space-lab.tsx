'use client'
/* The space with DialKit and InterfaceKit mounted. Every knob restyles the
   real markup live: CSS knobs land on <html> as custom properties, layout
   knobs go through the Tune context. Dev only, reached with ?lab=1. */
import { useDialKit } from 'dialkit'
import { useEffect } from 'react'
import { Space } from '@/components/space/space'
import { LabTools, useDialHints } from './lab-tools'

const HINTS = {
  Layout: 'The grid every save sits on.',
  Cell: 'Size of one save, in pixels. Pitch follows unless you set it.',
  Pitch: 'Distance between cell origins, in pixels. Pitch minus cell is the gap.',
  Gather: 'What happens after you press Gather: evidence slides into a ring around the tile, then re-sorts into for / against / near.',
  'Gather Ms': 'How long the evidence takes to slide into the ring. Type a thought and press Gather to see it.',
  'Argue Ms': 'Pause between the ring landing and it re-sorting into for (above), against (below), near (sides).',
  Dim: 'Opacity of everything that is not evidence while a ring is lit, and of non-matches when a tag filter is on.',
  Bar: 'The glass pill at the bottom.',
  Bottom: 'Distance from the bottom edge, in pixels. Pool uses 69.',
  Height: 'Pill height, in pixels. Pool uses 39.',
  Blur: 'Backdrop blur behind the pill, in pixels.',
  Surfaces: 'Cards and sheets.',
  Radius: 'Corner radius of every card and sheet.',
  Hairline: 'Opacity of the 1px border on cards and sheets.',
  Transition: 'Tile click → document. The space fades, the document slides up, then its header and sections rise in turn. Times are ms after the click.',
  'Fade Out': 'How long the space takes to fade to nothing.',
  'Slide In': 'When the document surface starts rising.',
  'Header At': 'When the back link, title and meta rise.',
  'Sections At': 'When the first section rises.',
  Stagger: 'Gap between one section rising and the next.',
  'Offset Y': 'How many pixels the surface rises from. Children rise two thirds of it.',
  Cells: 'The saves and the black idea tile.',
  'Cell Radius': 'Corner radius of thumbnails, text cells and the idea tile. Not the cards.',
  'Tile Font': 'Goudy size on the idea tile, in pixels.',
}

export function SpaceLab() {
  const p = useDialKit('Naru space', {
    layout: { cell: [200, 96, 240, 4], pitch: [210, 120, 320, 2] },
    gather: { gatherMs: [600, 150, 1200, 50], argueMs: [1100, 0, 2500, 50], dim: [0.22, 0.05, 0.6, 0.01] },
    bar: { bottom: [40, 16, 160, 1], height: [44, 32, 64, 1], blur: [36, 0, 60, 1] },
    surfaces: { radius: [27, 4, 40, 1], hairline: [0.2, 0, 0.3, 0.01] },
    cells: { cellRadius: [3, 0, 24, 1], tileFont: [21, 14, 28, 1] },
    transition: { fadeOut: [160, 0, 600, 10], slideIn: [160, 0, 800, 10], headerAt: [220, 0, 1000, 10], sectionsAt: [300, 0, 1200, 10], stagger: [60, 0, 240, 5], offsetY: [24, 0, 64, 2] },
  })
  useDialHints(HINTS)

  useEffect(() => {
    const s = document.documentElement.style
    s.setProperty('--cell', `${p.layout.cell}px`)
    s.setProperty('--dim', String(p.gather.dim))
    s.setProperty('--gather-ms', `${p.gather.gatherMs}ms`)
    s.setProperty('--bar-bottom', `${p.bar.bottom}px`)
    s.setProperty('--bar-h', `${p.bar.height}px`)
    s.setProperty('--glass', `blur(${p.bar.blur}px) saturate(1.9) brightness(1.02)`)
    s.setProperty('--radius-surface', `${p.surfaces.radius}px`)
    s.setProperty('--hairline', `rgba(0, 0, 0, ${p.surfaces.hairline})`)
    s.setProperty('--tile-font', `${p.cells.tileFont}px`)
    s.setProperty('--tile-radius', `${p.cells.cellRadius}px`)
  })
  useEffect(() => () => document.documentElement.removeAttribute('style'), [])

  return (
    <>
      <Space tune={{ cell: p.layout.cell, pitch: Math.max(p.layout.pitch, p.layout.cell), gatherMs: p.gather.gatherMs, argueMs: p.gather.argueMs, ringPad: 1, doc: { fadeOut: p.transition.fadeOut, slideIn: p.transition.slideIn, headerAt: p.transition.headerAt, sectionsAt: p.transition.sectionsAt, stagger: p.transition.stagger, offsetY: p.transition.offsetY } }} />
      <LabTools />
    </>
  )
}
