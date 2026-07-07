# Naru — Brainstorm Log

Working name: **Naru** (나루) — Korean for river crossing, ferry landing. Where content from different streams arrives in one place.

Previous working name: SaveBox

---

## 1. The Starting Idea

A universal content archiver. One app that syncs saved and liked content from every platform I use — Spotify, TikTok, Instagram, YouTube, Reddit — into a single hub. Any format: posts, reels, songs, videos, bookmarks.

Two requirements from the start:

1. **OAuth-style authentication.** Users connect platforms through a one-time auth flow (like connecting apps to Claude or Notion). No API keys, no manual setup.
2. **Passive background sync.** Users save content on their native platforms the way they always do. When they open Naru, new saves sync automatically. Zero behavior change required.

The saved content needs to show connections between items. Like Obsidian's graph view, but for saved content across platforms.

Platform choice (app store vs. web app) was undecided — go with whichever market is more profitable.

---

## 2. Validation Approach

Decided to pressure-test the idea domain by domain:

1. Competitive Landscape ✅
2. Market & Monetization (pending)
3. Technical Feasibility (pending)

Started with competitive landscape.

---

## 3. Competitive Landscape

### Positioning

Naru's differentiator: the focus goes beyond archiving. It shows how saved content relates to each other and, through those relationships, helps users understand their own identity. The thesis: what you save across all platforms, taken together, explains who you are.

### Why native platform saves won't replace this

Tech gives us too many apps, each with their own save button. Saved content scatters across a dozen platforms. Each platform's save list grows until it's forgotten. Naru is the centralized hub where all of it comes together.

### Competitor mapping

| Tool | Does | Falls Short |
|------|------|-------------|
| Pocket | Save articles for later | Single-format, no cross-platform, no connections |
| Raindrop | Organized bookmark manager | Better organization, same dead-end problem |
| Mymind | AI-powered personal archive | AI tags content, but you still browse a collection |
| Are.na | Curating = thinking | Closest in spirit. Manual-only, niche audience |
| Pinterest | Visual discovery boards | Outward-facing, single-format, no self-reflection |
| Native saves (Apple/Google) | OS-level save features | Siloed within ecosystem, no identity layer |

### The gap

No one connects content across platforms AND lets you work with the connections. The graph plus the workspace is the differentiator.

---

## 4. The Graveyard Problem

A critical insight surfaced during competitive analysis: every existing save tool (including good ones) eventually becomes another collection that users forget about. You add items, the collection grows, you stop looking at it.

This means Naru risks the same fate. Building a better archive still produces an archive. The problem isn't saving — it's that saving is a dead end everywhere. Content goes in, nothing comes out.

The solution: Naru can't be an archive. It needs to be a workspace where saved content becomes raw material.

---

## 5. The Canvas / Sandbox Concept

The product category shifted. Naru is a thinking tool powered by your digital footprint.

Saved content items are building blocks on a canvas — like sticky notes on a Miro board. You drag them, cluster them, draw connections, build something with them. The canvas is where self-discovery happens through active use, not passive browsing.

The retention mechanism is the workspace itself. If the workspace is engaging, people come back. If it isn't, Naru is another bookmark graveyard with extra steps.

### The open design question

Every canvas tool has a core verb. Miro: "brainstorm." Figma: "design." Obsidian: "write."

Naru needs a verb. Until that verb is defined, architecture and monetization are premature.

Candidates explored:

- **"Discover"** — app does the work, surfaces patterns. Easiest to build, hardest to retain. Once you've seen the insight, you close the app.
- **"Map"** — user builds something, drags and clusters content, labels connections. Strongest retention, highest friction. Most users won't do that kind of work unprompted.
- **"Connect"** — middle ground. App suggests relationships, user confirms, rejects, or refines. Low effort, high signal.

Current best candidate: **"Connect."** The app proposes connection clusters ("these items share a theme"), the user decides which connections matter. Over time, those decisions build a personal identity map without requiring a blank-canvas starting point.

A 10-minute session might look like: open Naru, see 12 new items synced since yesterday, the app proposes 3-4 connection clusters, swipe through them, accept or edit, identity graph grows.

**This verb is still unresolved. Defining it is the single most important next step.**

---

## 6. The OASIS/MiroFish Detour

Found two open-source projects:

- **OASIS** — a scalable social media simulator using LLM agents to mimic up to a million users on platforms like Twitter and Reddit. Studies information spread, group polarization, herd behavior.
- **MiroFish** — built on top of OASIS. A prediction engine that takes seed data (news, reports, signals), constructs a parallel digital world of AI agents, runs simulations, and returns prediction reports.

The integration idea: take a user's digital footprint from Naru, build a "digital twin" persona, drop it into an OASIS-powered simulation filled with AI agents. Let users see how a version of themselves would behave in simulated social environments.

### Why it was cut

This was excitement-driven, not strategically motivated.

- It merges two different products. The content archiver with identity canvas is one product. Agent-based social simulation is a different product for different users.
- Technical complexity jumped 10x. Running multi-agent simulations per user session is a completely different infrastructure and cost model.
- The identity construction problem doubles. Saved content reflects what catches your eye, not how you'd behave in social environments. Different signals.
- OASIS simulations cost $5-25 per run at mid-scale. Multiply that per user. Unsustainable for a consumer product.

The shared surface-level theme (digital identity) masked a gap in actual problem-solution fit. OASIS solves "predict group dynamics." Naru solves "help individuals understand themselves through their saves."

### The useful takeaway

The word "sandbox" kept coming up before and after finding OASIS. The instinct toward an interactive workspace is consistent. The detour confirmed the canvas direction without the agent simulation layer.

---

## 7. Naming

Explored naming options. Requirements: short, memorable, works internationally.

### Explored Korean-rooted names

- Damda (담다) — to hold, to contain
- Moa (모아) — to gather ❌ taken (Korean AI platform "MOA Tools" + others)
- Gyeol (결) — grain, texture, natural pattern
- Tari (타래) — skein of thread ❌ taken (Tari blockchain protocol + Tari fitness app)
- Sori (소리) — sound, voice
- Dari (다리) — bridge
- Jari (자리) — a spot, your seat
- Nuri (누리) — old Korean for "world"
- Naru (나루) — river crossing, ferry landing ✅

### Other candidates explored

- Drift, Sift, Loom, Hearth, Lantern, Vestige, Cairn, Tarn, Onda, Miru, Fenn, Orbis, Hyllo, Cura, Relic, Kelp, Vora, Jigu, Kirok, Sumul, Taba, Pallete

### Final pick: Naru (나루)

Where content from different streams arrives in one place. A crossing point where scattered things converge. Clean search results — no competing SaaS products using the name.

Next step: grab naru.app or getnaru.com.

---

## 8. Technical Challenges (Identified, Not Yet Validated)

### OAuth-based platform auth
Users connect platforms through one-time OAuth flows. Risk level: medium. Spotify, YouTube, Reddit have mature OAuth APIs with saved/liked content access. TikTok and Instagram restrict this data. Platform coverage determines launch viability.

### Passive background sync
Users never change how they save on native platforms. Naru syncs new saves when opened. Risk level: high. Depends on each platform's API exposing saved/liked content. A native mobile app is likely required — web apps can't poll APIs in the background.

### Cross-format relationship engine
A Spotify track, a TikTok video, and a saved tweet are different formats. Building connections between them requires content understanding: metadata, AI-generated tags, embeddings, or manual user input. Risk level: high. Automated connections need to be meaningful or the graph becomes noise.

---

## 9. Open Questions & Action Items

### Must resolve first
- [ ] Define the canvas interaction verb. Sketch three candidate models (paper or Figma). For each: primary verb, 10-minute session walkthrough, what "done" looks like.

### Next validation domains
- [ ] Market & Monetization — target user, willingness to pay, pricing model
- [ ] Technical Feasibility — platform API audit, sync architecture

### Research tasks
- [ ] Audit platform APIs. Spreadsheet: platform, OAuth support, saved/liked content access, rate limits, ToS restrictions. Start with Spotify, YouTube, Reddit, Twitter/X, TikTok, Instagram.
- [ ] Find 5-10 people who hoard saves across platforms. Interview them. Ask what they do with saved content, whether they've built workarounds (screenshotting saves into Miro, copying links into Notion, building mood boards from scattered sources).
- [ ] Web app vs. native app decision. Background sync may force native. Validate whether web-only MVP delivers enough value without passive sync.
- [ ] Write the one-sentence pitch. Target: something like "See the hidden patterns in everything you've ever saved."
- [ ] Domain availability check: naru.app, getnaru.com, naru.io

---

## 10. Key Principles (Running List)

1. **Save tools fail because they optimize for input, not use.** Every competitor makes it easy to save. None make saves useful.
2. **A bigger archive is still an archive.** If Naru becomes another collection, it fails the same way Pocket does.
3. **The canvas needs structure.** Open-ended sandboxes get abandoned too. The interaction model needs enough structure to prompt action without constraining exploration.
4. **Scope creep kills early-stage ideas.** OASIS integration was exciting but would have produced a different product. Stay focused on the core value prop.
5. **The moat is the workspace, not the aggregation.** Cross-platform sync alone is vulnerable to platform players building native solutions. The identity canvas on top is the defensible layer.
6. **API access is the biggest structural risk.** Platforms can restrict saved content access at any time. Instagram and TikTok already do.
