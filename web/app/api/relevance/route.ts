/* Scores the saves on screen against the thought being typed.

   Jev answers a noul per save in one round trip, so every save gets its own
   probability rather than competing for one. Roughly 300ms for sixty saves.
   The key stays here; the browser never sees it. */
import { NextResponse } from 'next/server'

const ENDPOINT = 'https://api.typesafe.ai/v1/systemone'
const MAX_SAVES = 60

type Candidate = { id: string; title: string }

export async function POST(req: Request) {
  const key = process.env.TYPESAFE_API_KEY
  if (!key) return NextResponse.json({ rel: {}, reason: 'no key' }, { status: 200 })

  /* The space is public, the key is not: only this page may spend it. */
  const origin = req.headers.get('origin')
  if (origin && new URL(req.url).origin !== origin) return NextResponse.json({ rel: {} }, { status: 403 })

  const { thought, saves } = (await req.json()) as { thought?: string; saves?: Candidate[] }
  const text = (thought ?? '').trim().slice(0, 300)
  const list = (saves ?? []).slice(0, MAX_SAVES)
  /* One short word is a real query: 'pottery' should already sort the grid. */
  if (text.length < 3 || list.length === 0) return NextResponse.json({ rel: {} })

  const questions = Object.fromEntries(
    list.map((s) => [
      s.id,
      {
        type: 'noul',
        instructions: {
          save: s.title,
          question: 'Is this `save` related to the `thought`? Related means it supports the thought, contradicts it, shows what it could look like, or is precedent for it.',
        },
        criteria: {
          true: 'The save would earn a place in a brief about this thought',
          false: 'The save is about something else entirely',
        },
      },
    ]),
  )

  try {
    const r = await fetch(ENDPOINT, {
      method: 'POST',
      headers: { Authorization: `Bearer ${key}`, 'Content-Type': 'application/json' },
      body: JSON.stringify({ state: { thought: text }, model: 'jev-latest', questions }),
      signal: AbortSignal.timeout(8000),
    })
    if (!r.ok) return NextResponse.json({ rel: {}, reason: `jev ${r.status}` })
    const data = (await r.json()) as { answers?: Record<string, { noul?: number }> }
    const rel: Record<string, number> = {}
    for (const [id, a] of Object.entries(data.answers ?? {})) if (typeof a.noul === 'number') rel[id] = a.noul
    return NextResponse.json({ rel })
  } catch {
    /* A slow or failed read just means the space stays as it was. */
    return NextResponse.json({ rel: {}, reason: 'unreachable' })
  }
}
