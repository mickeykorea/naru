/* Naru desktop mock behaviour, verbatim from the artifact. Loaded by
   app/lab/naru-mock.tsx after hydration; expects the mock markup in the DOM. */
const saves = [
  { id: 1, src: "S", brand: "substack", age: "3d", cat: "Reads", title: "Your brain runs on 90-minute cycles and your calendar ignores every one of them", sum: "Ultradian rhythms explain why the 2pm slump is biological, not moral. Most schedules fight the cycle instead of riding it.", lane: "supports", why: "Energy cycles, the core premise" },
  { id: 2, src: "Y", brand: "youtube", age: "1w", cat: "Watch", title: "Why I quit Google Calendar after 11 years", sum: "A designer walks through the moment time-blocking stopped working: the blocks were right, the person filling them was wrong.", lane: "supports", why: "The user you're building for" },
  { id: 3, src: "R", brand: "reddit", age: "2w", cat: "Reads", title: "r/productivity: I schedule by mood now and it's the only system that stuck", sum: "Top comment thread. Dozens of people describing the same hack: morning for hard things, afternoons for admin, nothing else works.", lane: "supports", why: "Demand signal, unprompted" },
  { id: 4, src: "M", brand: "medium", age: "5d", cat: "Reads", title: "Twelve calendar startups launched. Zero survived.", sum: "Sunrise, Fantastical's pivot, Woven, Clockwise: every one either sold small or died. The calendar is a feature, not a product.", lane: "contradicts", why: "Category graveyard" },
  { id: 5, src: "R", brand: "reddit", age: "3w", cat: "Reads", title: "Nobody logs their energy level. Nobody. Stop building this.", sum: "A founder's post-mortem on a mood-tracking planner. Retention died at day four because the input cost outran the output.", lane: "contradicts", why: "Input cost kills it" },
  { id: 6, src: "N", brand: "nytimes", age: "1mo", cat: "Reads", title: "Time-blocking works because it's rigid, not in spite of it", sum: "The discipline is the point. Systems that flex to how you feel become systems you never use.", lane: "contradicts", why: "Flexibility as a bug" },
  { id: 7, src: "Y", brand: "youtube", age: "4d", cat: "Watch", title: "What the Oura readiness score actually measures", sum: "Heart-rate variability, sleep debt, body temperature, folded into one morning number. The score is a prediction of your day.", lane: "adjacent", why: "Energy already measured, passively" },
  { id: 8, src: "S", brand: "substack", age: "2w", cat: "Reads", title: "Screen time as a proxy for flow", sum: "Long unbroken app sessions correlate with deep work better than any self-report. Your phone already knows when you were focused.", lane: "adjacent", why: "Zero-input signal" },
  { id: 9, src: "P", brand: "spotify", age: "6d", cat: "Sounds", title: "Deep Focus playlist, 3h 42m", sum: "Saved every workday for two weeks. Always between 9 and 12.", lane: "adjacent", why: "Your own morning pattern" },
  { id: 10, src: "G", brand: "github", age: "1w", cat: "Inspiration", title: "cal.com", sum: "Open-source scheduling infrastructure. The sync layer is already written." },
  { id: 11, src: "X", brand: "x", age: "2d", cat: "Reads", title: "Paul Graham: maker's schedule, manager's schedule", sum: "A single meeting can blow a whole afternoon for a maker. Half-days are the real unit." },
  { id: 12, src: "F", brand: "figma", age: "3d", cat: "Inspiration", title: "Amie calendar onboarding flow", sum: "Nine screens, no form fields. Every preference inferred from the first week." },
  { id: 13, src: "S", brand: "substack", age: "1mo", cat: "Reads", title: "The case against optimizing your life", sum: "Every system promising more output eventually asks for more input than it returns." },
  { id: 14, src: "Y", brand: "youtube", age: "5d", cat: "Watch", title: "Rise app: sleep debt as a daily energy forecast", sum: "A product demo. Energy as a curve across the day, drawn from sleep alone." },
  { id: 15, src: "B", brand: "behance", age: "2w", cat: "Inspiration", title: "Circular day planner concept", sum: "Twenty-four hours as a ring. Tasks sit on the arc where energy peaks." },
];

const questions = [
  { q: "Four of your saves say calendar apps die as products. Why does yours survive as one?", ev: [4] },
  { q: "You saved a founder saying nobody logs energy. Where does your energy signal come from if not the user?", ev: [5, 7, 8] },
  { q: "The Times piece argues rigidity is why time-blocking works. What does your calendar refuse to flex on?", ev: [6] },
  { q: "You've listened to the same focus playlist every morning for two weeks. Is the product a calendar, or a mirror of patterns you already have?", ev: [9] },
  { q: "Who pays, and how much? You have no saves on this.", ev: [] },
];

const byId = Object.fromEntries(saves.map(s => [s.id, s]));
const state = { q: 0, answered: [], kept: new Set(), dismissed: new Set(), gapsOpen: 2, dropped: [] };

const el = id => document.getElementById(id);
const fmt = n => String(n);

function toast(msg) {
  const t = el("toast");
  t.textContent = msg;
  t.classList.add("show");
  clearTimeout(toast.h);
  toast.h = setTimeout(() => t.classList.remove("show"), 1800);
}

function glyph(s) {
  return `<span class="glyph" title="${s.brand}">${s.src}</span>`;
}

function cardHTML(s, lane) {
  return `
    <article class="card${state.kept.has(s.id) ? " kept" : ""}" draggable="true" data-id="${s.id}" tabindex="0">
      <div class="m">${glyph(s)}<span>${s.brand} · ${s.age}</span></div>
      <div class="t">${s.title}</div>
      <div class="s garamond">${s.sum}</div>
      <div class="why">${s.why || (lane === "supports" ? "Added by you" : "Dragged in from your archive")}</div>
      <div class="acts">
        <button class="circ keep" title="Keep" aria-label="Keep">✓</button>
        <button class="circ" title="Dismiss" aria-label="Dismiss">✕</button>
      </div>
      <div class="kept-mark">✓</div>
    </article>`;
}

function renderLanes() {
  document.querySelectorAll(".lane").forEach(lane => {
    const name = lane.dataset.lane;
    if (name === "blindspot") return;
    const stack = lane.querySelector(".stack");
    stack.innerHTML = saves.filter(s => s.lane === name && !state.dismissed.has(s.id)).map(s => cardHTML(s, name)).join("");
  });
  updateCounts();
  renderRows();
}

function updateCounts() {
  const lanes = ["supports", "contradicts", "adjacent"];
  let pulled = 0;
  lanes.forEach(name => {
    const n = saves.filter(s => s.lane === name && !state.dismissed.has(s.id)).length;
    pulled += n;
    document.querySelector(`[data-count="${name}"]`).textContent = fmt(n);
  });
  document.querySelector('[data-count="blindspot"]').textContent = fmt(state.gapsOpen);
  el("pulled").textContent = fmt(pulled);
  el("gaps").textContent = fmt(state.gapsOpen);
  el("decided").textContent = fmt(state.kept.size + state.dismissed.size);

  const supports = saves.filter(s => s.lane === "supports" && !state.dismissed.has(s.id));
  const keptSupports = supports.filter(s => state.kept.has(s.id)).length;
  el("bKept").textContent = `${keptSupports} of ${supports.length}`;
  el("bAns").textContent = `${state.answered.length} of ${questions.length}`;
  el("bGaps").textContent = fmt(state.gapsOpen);

  const total = supports.length + questions.length + 2;
  const done = keptSupports + state.answered.length + (2 - state.gapsOpen);
  el("bar").style.width = `${Math.round((done / total) * 100)}%`;
  const complete = keptSupports === supports.length && state.answered.length === questions.length && state.gapsOpen === 0;
  el("export").disabled = !complete;
}

function renderRows() {
  const q = el("poolSearch").value.trim().toLowerCase();
  const cat = document.querySelector('#tabs [aria-selected="true"]').dataset.cat;
  el("rows").innerHTML = saves
    .filter(s => !cat || s.cat === cat)
    .filter(s => !q || (s.title + s.sum + s.brand).toLowerCase().includes(q))
    .map(s => `
      <div class="row${s.lane && !state.dismissed.has(s.id) ? " used" : ""}" draggable="true" data-id="${s.id}" title="Drag into a lane or the answer">
        ${glyph(s)}
        <div><div class="t">${s.title}</div><div class="m">${s.brand} · ${s.age}</div></div>
        <span class="in" aria-hidden="true"></span>
      </div>`).join("");
}

function renderQuestion() {
  const q = questions[state.q];
  el("qCount").textContent = `${Math.min(state.q + 1, questions.length)} of ${questions.length}`;
  if (!q) {
    el("qText").textContent = "No more pushback. The brief is yours.";
    el("qEvidence").textContent = "";
    el("answer").hidden = true; el("next").hidden = true; el("skip").hidden = true; el("dropped").hidden = true;
    return;
  }
  el("qText").textContent = q.q;
  el("qEvidence").innerHTML = q.ev.length
    ? "From your saves: " + q.ev.map(id => `<a href="#" data-jump="${id}">${byId[id].title.split(":")[0].slice(0, 40)}${byId[id].title.length > 40 ? "…" : ""}</a>`).join(", ")
    : "No evidence in your archive yet.";
  el("answer").value = "";
  state.dropped = [];
  renderDropped();
}

function renderDropped() {
  el("dropped").innerHTML = state.dropped.map(id => `<span class="chip">${glyph(byId[id])}${byId[id].title.slice(0, 32)}${byId[id].title.length > 32 ? "…" : ""}</span>`).join("");
}

function commitAnswer(skipped) {
  const q = questions[state.q];
  if (!q) return;
  const text = el("answer").value.trim();
  if (!skipped && !text && !state.dropped.length) { toast("Answer it or skip it"); return; }
  state.answered.push({ q: q.q, a: skipped ? "Skipped" : (text || `${state.dropped.length} save${state.dropped.length > 1 ? "s" : ""} as evidence`) });
  el("answered").insertAdjacentHTML("beforeend", `<div class="item"><span>${state.answered.at(-1).a}</span></div>`);
  state.q++;
  renderQuestion();
  updateCounts();
}

/* ---- events ---- */
el("lanes").addEventListener("click", e => {
  const card = e.target.closest(".card");
  if (card) {
    const id = +card.dataset.id;
    if (e.target.closest(".keep")) {
      state.kept.add(id); card.classList.add("kept"); updateCounts(); toast("Kept");
    } else if (e.target.closest(".circ")) {
      card.classList.add("leaving");
      setTimeout(() => { state.dismissed.add(id); state.kept.delete(id); renderLanes(); }, 250);
      toast("Dismissed");
    }
    return;
  }
  if (e.target.matches("[data-find]")) {
    toast(`Looking for inputs on ${e.target.dataset.find}`);
    return;
  }
  if (e.target.matches("[data-dismiss-gap]")) {
    const g = e.target.closest(".gap");
    g.style.opacity = 0; g.style.transition = "opacity 250ms ease-out";
    setTimeout(() => { g.remove(); state.gapsOpen--; updateCounts(); }, 250);
  }
});

el("next").addEventListener("click", () => commitAnswer(false));
el("skip").addEventListener("click", () => commitAnswer(true));
el("answer").addEventListener("keydown", e => { if (e.key === "Enter" && (e.metaKey || e.ctrlKey)) commitAnswer(false); });
el("export").addEventListener("click", () => toast("Brief exported"));

el("qEvidence").addEventListener("click", e => {
  const a = e.target.closest("[data-jump]");
  if (!a) return;
  e.preventDefault();
  const card = document.querySelector(`.card[data-id="${a.dataset.jump}"]`);
  if (card) { card.scrollIntoView({ behavior: "smooth", block: "center" }); card.focus(); }
});

el("poolSearch").addEventListener("input", renderRows);
el("tabs").addEventListener("click", e => {
  const b = e.target.closest("[role=tab]");
  if (!b) return;
  document.querySelectorAll("#tabs [role=tab]").forEach(t => t.setAttribute("aria-selected", t === b));
  renderRows();
});

/* drag and drop: archive rows and cards into lanes, or into the answer */
let dragId = null;
document.addEventListener("dragstart", e => {
  const src = e.target.closest("[data-id]");
  if (!src) return;
  dragId = +src.dataset.id;
  src.classList.add("dragging");
  e.dataTransfer.effectAllowed = "move";
  e.dataTransfer.setData("text/plain", String(dragId));
});
document.addEventListener("dragend", () => {
  document.querySelectorAll(".dragging").forEach(n => n.classList.remove("dragging"));
  document.querySelectorAll(".over").forEach(n => n.classList.remove("over"));
});
document.querySelectorAll(".lane").forEach(lane => {
  if (lane.dataset.lane === "blindspot") return;
  lane.addEventListener("dragover", e => { e.preventDefault(); lane.classList.add("over"); });
  lane.addEventListener("dragleave", e => { if (!lane.contains(e.relatedTarget)) lane.classList.remove("over"); });
  lane.addEventListener("drop", e => {
    e.preventDefault();
    lane.classList.remove("over");
    if (dragId == null) return;
    const s = byId[dragId];
    const target = lane.dataset.lane;
    if (s.lane === target && !state.dismissed.has(s.id)) return;
    const fromArchive = !s.lane || state.dismissed.has(s.id);
    s.lane = target;
    state.dismissed.delete(s.id);
    if (fromArchive) s.why = "Dragged in from your archive";
    renderLanes();
    const card = document.querySelector(`.card[data-id="${s.id}"]`);
    if (card) card.classList.add("entering");
    toast(`Moved to ${lane.querySelector(".eyebrow").firstChild.textContent.trim()}`);
  });
});
const answer = el("answer");
answer.addEventListener("dragover", e => { e.preventDefault(); answer.classList.add("over"); });
answer.addEventListener("dragleave", () => answer.classList.remove("over"));
answer.addEventListener("drop", e => {
  e.preventDefault(); answer.classList.remove("over");
  if (dragId == null || state.dropped.includes(dragId)) return;
  state.dropped.push(dragId);
  renderDropped();
  toast("Added as evidence");
});

renderLanes();
renderQuestion();
