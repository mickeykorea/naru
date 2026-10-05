/* Scores everything in the archive against the thought being typed.

   Jev answers a noul per picture in one round trip, so each gets its own
   probability rather than competing for one. About 560 of them, 16k tokens,
   600ms. The list lives here, so the browser sends only the thought, and the
   key stays here too. */
import { NextResponse } from 'next/server'
import { LOOKS } from '@/lib/seed/looks'

const ENDPOINT = 'https://api.typesafe.ai/v1/systemone'
/* The key is a prepaid balance, so a loop against this endpoint is the cost.
   A read takes about 20k tokens, and the whole balance is a few thousand
   of them: cheap to spend, cheap to defend. One typed sentence is
   six to eight reads, so the burst has to hold a few sentences back to back. */
const PER_MINUTE = 60
const BURST = 24

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

  const { thought } = (await req.json()) as { thought?: string }
  const text = (thought ?? '').trim().slice(0, 300)
  /* One short word is a real query: 'pottery' should already sort the grid. */
  if (text.length < 3) return NextResponse.json({ rel: {} })

  const questions = Object.fromEntries(
    Object.entries(LOOKS).map(([k, look]) => [
      k,
      { type: 'noul', instructions: { save: look, question: 'Would this `save` belong on a moodboard for the `thought`?' } },
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
