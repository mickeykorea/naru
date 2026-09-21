import type { Metadata } from 'next'
import { NaruLab } from './naru-lab'

export const metadata: Metadata = {
  title: 'Naru desktop lab',
  robots: { index: false, follow: false },
}

export default function LabPage() {
  return <NaruLab />
}
