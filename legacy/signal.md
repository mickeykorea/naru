# Naru — Signal (Office Hours #1)

Date: 2026-03-30
Phase: Post-brainstorm, pre-build
Mode: Builder (side project, open to startup)

---

## What happened

Ran a YC-style office hours session against the brainstorm.md. Pressure-tested the idea, researched competitors and the landscape, challenged premises, generated approaches, and got a second opinion from an independent AI advisor.

---

## Key findings

### Competitor deep-dive

Two real competitors identified beyond the brainstorm's original list:

- **Shiori** (shiori.sh) — Power-user archiver. Connects to X bookmarks, YouTube (with transcripts), Notion, email newsletters. AI search and chat. CLI/API/MCP. $3-10/mo. Well-built, but the AI layer is retrieval, not insight.
- **Pool** (pool.day) — Casual screenshot-first organizer. Auto-categorizes into themed "pools." Social sharing layer. Frictionless input, lifestyle-oriented.

Both well-designed. Both graveyards. Neither shows you WHY you saved what you saved.

### Landscape research

The conventional wisdom says the fix for bookmark graveyards is better retrieval — AI search, smarter tags, contextual resurfacing. Every competitor is optimizing this.

Naru's thesis: retrieval is the wrong frame. Even perfect retrieval still produces a graveyard. The output should be self-knowledge, not content re-consumption. Nobody in the space is building in this direction.

### The "whoa" moment

The builder described the target feeling: "I have so many ambitions and dreams within me, and because they're too many and too bright, I think they made me sort of blind... I would get surprised if I can see the hidden talents and my knowledge base out of Naru, and actually release my potential."

This isn't a product person describing a user problem. This is someone who wants to build a tool to see themselves. The first user isn't a persona — it's a confession. Strongest possible starting position.

### Second opinion: contradiction mapping

An independent AI advisor proposed an angle the brainstorm hadn't considered: the most interesting self-discovery isn't in the clusters — it's in the TENSIONS between clusters. You save stoic philosophy AND impulsive travel content. Minimalist music AND maximalist visual art. Those contradictions are where identity lives.

Also suggested Khoj (github.com/khoj-ai/khoj) as a 50% starting point — it handles ingestion, chunking, embedding, and chat over personal data. The 50% to build is the clustering-to-insight layer.

---

## Agreed premises

1. People's saved/liked content across platforms reveals meaningful patterns about who they are.
2. An AI can identify those patterns in a way that surprises the user.
3. The "Connect" interaction model (app proposes clusters, user confirms/rejects) will produce engagement. The workspace IS the retention mechanism.
4. Getting user content is solvable through a mix of OAuth, manual export, and potentially browser extension. MVP needs 2-3 sources.
5. A single person can build an MVP that demonstrates the self-discovery moment.

---

## Approaches considered

### A: "Weekend Proof" (CHOSEN)
Python script. Two data sources (Spotify + YouTube/Takeout). Embeddings, HDBSCAN clustering, LLM-generated identity hypotheses. Single HTML output page. Builder is the only user. One weekend.

**Purpose:** Validate the hardest premise — does your own data, clustered and interpreted by an LLM, tell you something true about yourself that surprises you?

### B: "Interactive Canvas MVP" (NEXT)
Web app with OAuth for 2-3 platforms. Card-based UI where Naru proposes connection clusters and contradictions. User confirms/rejects. Identity graph grows over time. 2-4 weeks.

### C: "The Talking Mirror"
Chat-first interface. Conversational agent that has ingested your digital footprint. You ask it questions about yourself, it answers with evidence. 1-2 weeks. Risk: novelty wears off, no retention.

---

## Decision

Do A first. If the static page makes you feel seen, build B with confidence. If it feels like horoscope fluff, the thesis needs refinement before investing more.

---

## Open threads

- The canvas interaction verb ("Connect") is still unresolved in practice — Approach A skips it, Approach B will force the design decision
- Contradiction mapping (from second opinion) should be built into the clustering from day one
- Platform API audit still pending — deferred until after thesis validation
- Khoj as potential foundation for Approach B — worth evaluating during or after the weekend proof

---

## Next action

Build Approach A: Python script, Spotify + YouTube data, embeddings, HDBSCAN, LLM hypotheses, one HTML page. Validate the self-discovery moment with your own data.
