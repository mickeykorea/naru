/* What each tile actually shows, in words, keyed the way the space keys a
   picture (its URL). Jev reads these instead of titles: a mock save's title
   and its Are.na thumbnail were never paired, so a title match looked like a
   random picture coming forward. The captions were written by looking at
   every image once (scripts would need a vision model and a key). */
import CAPTIONS from './captions.json'
import COVERS from './covers.json'
import { big } from './data-big'

export const LOOKS: Record<string, string> = {
  ...Object.fromEntries(Object.entries(CAPTIONS).map(([k, v]) => [`/mock/thumbs/${k}.jpg`, v])),
  ...Object.fromEntries(COVERS.map((c) => [c.file, `${c.genre} album cover, ${c.artist}, ${c.album}`])),
  ...Object.fromEntries(big.filter((s) => !s.image && !s.cover).map((s) => [`text:${s.id}`, s.title])),
}
