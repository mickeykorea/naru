import type { Metadata } from 'next'
import { Suspense } from 'react'
import { Prototype } from './prototype'

export const metadata: Metadata = {
  title: 'Naru prototype',
  robots: { index: false, follow: false },
}

/* PROTOTYPE route. Two variants of the web home, switchable via
   ?variant=A|B. Throwaway: answers "index + idea document, or canvas?" */
export default function PrototypePage() {
  return (
    <Suspense>
      <Prototype />
    </Suspense>
  )
}
