import type { Metadata } from 'next'
import { Goudy_Bookletter_1911 } from 'next/font/google'
import { Space } from '@/components/space/space'
import { SpaceLab } from '@/components/lab/space-lab'
import '@/components/space/space.css'

const display = Goudy_Bookletter_1911({ subsets: ['latin'], weight: '400', variable: '--font-display' })

export const metadata: Metadata = { title: 'Naru', description: 'Everything you saved, in one space. Gather it around a thought.' }

/* ?lab=1 mounts DialKit and InterfaceKit over the real space (dev only;
   the lab tools are no-ops in production builds). */
export default async function Home(props: PageProps<'/'>) {
  const q = await props.searchParams
  const lab = q.lab === '1' && process.env.NODE_ENV !== 'production'
  return (
    <div className={`proto ${display.variable}`}>
      {lab ? <SpaceLab /> : <Space />}
    </div>
  )
}
