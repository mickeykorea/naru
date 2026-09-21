'use client'
/* The Naru desktop mock, dropped in as-is: markup here, styles in
   naru-desktop.css, behaviour in public/mock/naru-desktop.js (loaded after
   hydration so its getElementById calls find this markup). Temporary stand-in
   until real components exist; InterfaceKit can still pick its elements and
   DialKit tunes its custom properties from naru-lab.tsx. */
import Script from 'next/script'
import { EB_Garamond } from 'next/font/google'
import './naru-desktop.css'

const garamond = EB_Garamond({
  subsets: ['latin'],
  weight: ['400', '500'],
  style: ['normal', 'italic'],
  variable: '--font-garamond',
})

const MARKUP = `
<div class="app">

  <aside class="col pool" aria-label="Archive">
    <label class="search">
      <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5" stroke-linecap="round"><circle cx="11" cy="11" r="7"/><path d="m20 20-3.5-3.5"/></svg>
      <input id="poolSearch" type="search" placeholder="Search your saves" aria-label="Search your saves">
    </label>
    <div class="tabs" role="tablist" id="tabs">
      <button role="tab" aria-selected="true" data-cat="">All<span class="count">48</span></button>
      <button role="tab" data-cat="Reads">Reads<span class="count">21</span></button>
      <button role="tab" data-cat="Watch">Watch<span class="count">12</span></button>
      <button role="tab" data-cat="Sounds">Sounds<span class="count">6</span></button>
      <button role="tab" data-cat="Inspiration">Inspiration<span class="count">9</span></button>
    </div>
    <div class="rows" id="rows"></div>
  </aside>

  <main class="col doc" aria-label="Idea">
    <div class="doc-head">
      <div class="eyebrow-row">
        <span class="eyebrow">Idea</span>
        <span class="meta" style="padding:0">Started today</span>
      </div>
      <h1 class="idea" contenteditable="true" spellcheck="false">A calendar that plans around your energy, not the clock</h1>
      <div class="meta"><b id="pulled">9</b> saves pulled from your archive · <b id="decided">0</b> decided · <b id="gaps">2</b> blind spots</div>
    </div>

    <div class="lanes" id="lanes">
      <section class="lane" data-lane="supports">
        <div class="lane-head"><span class="eyebrow">Supports<span class="count" data-count="supports">3</span></span><span class="hint">What you've saved that argues for it</span></div>
        <div class="stack"></div>
      </section>
      <section class="lane" data-lane="contradicts">
        <div class="lane-head"><span class="eyebrow">Contradicts<span class="count" data-count="contradicts">3</span></span><span class="hint">What you've saved that argues against it</span></div>
        <div class="stack"></div>
      </section>
      <section class="lane" data-lane="adjacent">
        <div class="lane-head"><span class="eyebrow">Adjacent<span class="count" data-count="adjacent">3</span></span><span class="hint">Near it, not obviously about it</span></div>
        <div class="stack"></div>
      </section>
      <section class="lane" data-lane="blindspot">
        <div class="lane-head"><span class="eyebrow">Blind spot<span class="count" data-count="blindspot">2</span></span><span class="hint">What it depends on that you haven't saved</span></div>
        <div class="stack">
          <div class="gap">
            <div class="t">Nothing saved about calendar sync</div>
            <div class="s garamond">Every idea here assumes it reads the user's existing calendar. You have no saves on CalDAV, Google Calendar's API, or how other apps handle two-way sync.</div>
            <div class="b"><button class="pill small" data-find="calendar sync">Find inputs</button><button class="textbtn" data-dismiss-gap>Not needed</button></div>
          </div>
          <div class="gap">
            <div class="t">Nothing saved about pricing</div>
            <div class="s garamond">You've saved twelve productivity apps and zero pieces on what any of them charge, or whether indie calendar apps survive on subscriptions.</div>
            <div class="b"><button class="pill small" data-find="indie app pricing">Find inputs</button><button class="textbtn" data-dismiss-gap>Not needed</button></div>
          </div>
        </div>
      </section>
    </div>
  </main>

  <aside class="col rail" aria-label="Pushback">
    <section>
      <div class="rail-head"><span class="eyebrow">Pushback</span><span class="count" id="qCount">1 of 5</span></div>
      <p class="q garamond" id="qText"></p>
      <div class="q-evidence" id="qEvidence"></div>
      <textarea class="answer" id="answer" placeholder="Answer, or drag a save in as your evidence"></textarea>
      <div class="dropped" id="dropped"></div>
      <div class="q-acts">
        <button class="pill" id="next">Next</button>
        <button class="textbtn" id="skip">Skip</button>
      </div>
      <div class="answered" id="answered"></div>
    </section>

    <section class="brief">
      <span class="eyebrow">Brief</span>
      <div class="ln"><span>Supports kept</span><span id="bKept">0 of 3</span></div>
      <div class="ln"><span>Contradictions answered</span><span id="bAns">0 of 5</span></div>
      <div class="ln"><span>Blind spots open</span><span id="bGaps">2</span></div>
      <div class="bar"><i id="bar"></i></div>
      <button class="pill" id="export" disabled>Export brief</button>
      <div class="note">Exports as a spec you can hand to Claude Code or Cursor. Unlocks when every lane is decided.</div>
    </section>
  </aside>

</div>
<div class="toast" id="toast"></div>
`

export function NaruMock() {
  return (
    <>
      <div className={garamond.variable} dangerouslySetInnerHTML={{ __html: MARKUP }} />
      <Script src="/mock/naru-desktop.js" strategy="afterInteractive" />
    </>
  )
}
