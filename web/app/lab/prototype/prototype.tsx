'use client'
import { useSearchParams } from 'next/navigation'
import { EB_Garamond } from 'next/font/google'
import { Switcher } from './switcher'
import { VariantIndex } from './variant-index'
import { VariantCanvas } from './variant-canvas'
import { Space } from '@/components/space/space'
import './prototype.css'

const garamond = EB_Garamond({
  subsets: ['latin'],
  weight: ['400', '500'],
  style: ['normal', 'italic'],
  variable: '--font-garamond',
})

const VARIANTS = {
  C: 'Merged: canvas home + document',
  A: 'Index + idea document',
  B: 'Canvas',
}

export function Prototype() {
  const variant = useSearchParams().get('variant') ?? 'C'
  return (
    <div className={`proto ${garamond.variable}`}>
      {variant === 'A' ? <VariantIndex /> : variant === 'B' ? <VariantCanvas /> : <Space />}
      <Switcher variants={VARIANTS} />
    </div>
  )
}
