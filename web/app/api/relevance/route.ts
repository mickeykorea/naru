/* Scores the saves on screen against the thought being typed.

   Jev answers a noul per save in one round trip, so every save gets its own
   probability rather than competing for one. Roughly 300ms for sixty saves.
   The key stays here; the browser never sees it. */
import { NextResponse } from 'next/server'

const ENDPOINT = 'https://api.typesafe.ai/v1/systemone'
const MAX_SAVES = 60
/* The key is a prepaid balance, so a loop against this endpoint is the cost.
   A read takes about 5k tokens, and the whole balance is a few tens of
   thousands of them: cheap to spend, cheap to defend. One typed sentence is
   six to eight reads, so the burst has to hold a few sentences back to back. */
const PER_MINUTE = 60
const BURST = 24

type Candidate = { id: string; title: string }

/* Per instance, so it is a speed bump rather than a wall: a serverless
   function that scales out forgets what the other copies have seen. The real
   ceiling is the spend alert on the account. */
const seen = new Map<string, { tokens: number; at: number }>()

function allow(ip: string) {
  const now = Date.now()
  const b = seen.get(ip) ?? { tokens: BURST, at: now }
  b.tokens = Math.min(BURST, b.tokens + ((now - b.at) / 60000) * PER_MINUTE)
  b.at = now
  if (seen.size > 5000) seen.clear()
  if (b.tokens < 1) {
    seen.set(ip, b)
    return false
  }
  b.tokens -= 1
  seen.set(ip, b)
  return true
}

export async function POST(req: Request) {
  const key = process.env.TYPESAFE_API_KEY
  if (!key) return NextResponse.json({ rel: {}, reason: 'no key' }, { status: 200 })

  /* The space is public, the key is not: only this page may spend it. A
     missing Origin used to pass, which is exactly what a script sends. */
  const here = new URL(req.url).origin
  const origin = req.headers.get('origin')
  const referer = req.headers.get('referer')
  const fromHere = origin ? origin === here : !!referer && referer.startsWith(here)
  if (!fromHere && process.env.NODE_ENV === 'production') return NextResponse.json({ rel: {} }, { status: 403 })

  const ip = req.headers.get('x-forwarded-for')?.split(',')[0].trim() ?? 'local'
  if (!allow(ip)) return NextResponse.json({ rel: {} }, { status: 429 })

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
