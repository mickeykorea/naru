'use client'
/* Lab around the desktop mock: DialKit writes the mock's custom properties
   on <html>, so every knob restyles the real markup live. */
import { useDialKit } from 'dialkit'
import { useEffect } from 'react'
import { NaruMock } from './naru-mock'
import { LabTools, useDialHints } from '@/components/lab/lab-tools'

const HINTS = {
  Layout: 'The three-column frame.',
  'Left Column': 'Width of the archive pool on the left, in pixels.',
  'Right Column': 'Width of the pushback rail on the right, in pixels.',
  'Lane Gap X': 'Horizontal space between the two lane columns, in pixels.',
  'Lane Gap Y': 'Vertical space between lane rows, in pixels.',
  Cards: 'The save cards inside each lane.',
  Radius: 'Corner rounding of cards, blind-spot boxes, and lane drop zones, in pixels.',
  Padding: 'Inner padding of each card, in pixels.',
  'Card Gap': 'Space between stacked cards in a lane, in pixels.',
  Colors: 'Light-mode colors only. Dark mode keeps the mock\'s own palette.',
  Ink: 'The accent color: primary buttons, keep marks, the progress bar.',
  Surface: 'The card and answer-box background.',
  Dark: 'Preview the mock in its dark palette. Off forces light. Ink and Surface pause while dark is on.',
}

export function NaruLab() {
  const p = useDialKit('Naru desktop', {
    layout: {
      leftColumn: [280, 200, 400, 4],
      rightColumn: [320, 240, 440, 4],
      laneGapX: [20, 0, 48, 4],
      laneGapY: [28, 0, 64, 4],
    },
    cards: {
      radius: [22, 0, 40, 1],
      padding: [16, 8, 32, 1],
      cardGap: [12, 0, 32, 1],
    },
    colors: {
      ink: '#000000',
      surface: '#ffffff',
    },
    dark: false,
  })
  useDialHints(HINTS)

  useEffect(() => {
    const s = document.documentElement.style
    s.setProperty('--col-left', `${p.layout.leftColumn}px`)
    s.setProperty('--col-right', `${p.layout.rightColumn}px`)
    s.setProperty('--lane-gap-x', `${p.layout.laneGapX}px`)
    s.setProperty('--lane-gap-y', `${p.layout.laneGapY}px`)
    s.setProperty('--radius-card', `${p.cards.radius}px`)
    s.setProperty('--card-pad', `${p.cards.padding}px`)
    s.setProperty('--card-gap', `${p.cards.cardGap}px`)
    /* Fixed colors would override the dark palette, so they apply in
       light mode only. */
    if (p.dark) {
      s.removeProperty('--ink')
      s.removeProperty('--surface')
    } else {
      s.setProperty('--ink', p.colors.ink)
      s.setProperty('--surface', p.colors.surface)
    }
    document.documentElement.dataset.theme = p.dark ? 'dark' : 'light'
  })
  useEffect(
    () => () => {
      document.documentElement.removeAttribute('style')
      delete document.documentElement.dataset.theme
    },
    [],
  )

  return (
    <>
      <NaruMock />
      <LabTools />
    </>
  )
}
