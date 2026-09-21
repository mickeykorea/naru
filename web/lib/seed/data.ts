/* PROTOTYPE seed data. Throwaway. Stands in for a synced archive so the two
   UX variants can be judged before sync exists. ~90 saves across the
   platforms Mickey actually uses, grouped into the themes a clustering pass
   would produce, plus the tensions and proposals the model would write. */

export type Source =
  | 'instagram'
  | 'tiktok'
  | 'youtube'
  | 'spotify'
  | 'x'
  | 'arena'
  | 'web'
  | 'linkedin'

export type Save = {
  id: string
  source: Source
  title: string
  summary: string
  author: string
  age: string
  theme: string | null
  image: boolean
  ratio: number
  /* A real record's cover, when the save is one; wins over the theme pool. */
  cover?: string
}

export type Theme = {
  id: string
  name: string
  line: string
  proposals: string[]
}

export type Tension = {
  a: string
  b: string
  line: string
}

export type Lane = 'agrees' | 'disagrees' | 'visual' | 'precedent' | 'howto' | 'mood'
export const LANE_ORDER: Lane[] = ['agrees', 'disagrees', 'visual', 'precedent', 'howto', 'mood']

export type Idea = {
  title: string
  themeId: string
  lanes: Partial<Record<Lane, { id: string; why: string }[]>>
  pushback: { q: string; evidence: string[] }[]
}

let n = 0
const s = (
  source: Source,
  title: string,
  summary: string,
  author: string,
  age: string,
  theme: string | null,
  image = true,
  ratio = 1,
): Save => ({ id: `s${++n}`, source, title, summary, author, age, theme, image, ratio })

export const themes: Theme[] = [
  {
    id: 'slow',
    name: 'Slow interfaces',
    line: 'Software that waits for you. Restraint, weight, one signature moment.',
    proposals: [
      'A reading app with no feed, one page a day, chosen from what you already saved',
      'A calendar that shows only the next thing and hides the rest until you ask',
      'A notes app where nothing can be formatted, only weighted',
    ],
  },
  {
    id: 'seoul',
    name: 'Seoul, remembered from London',
    line: 'Cassette mixes, tteokbokki alleys, the Han at night. Homesick in a specific way.',
    proposals: [
      'A map of Seoul built only from places your friends have saved, no reviews',
      'A radio that plays your Seoul playlists only after sunset in Seoul time',
      'A shared cassette: one side you, one side a friend back home',
    ],
  },
  {
    id: 'solo',
    name: 'Building alone with AI',
    line: 'One person, a coding agent, and the question of what is worth building.',
    proposals: [
      'A tool that turns your saves into the spec you hand to a coding agent',
      'A weekly page that tells a solo builder what they have been circling',
      'A changelog that writes itself from your commits and your saves',
    ],
  },
  {
    id: 'clay',
    name: 'Hands, clay, wood',
    line: 'Objects that took a person a long time. The opposite of your job.',
    proposals: [
      'A slow catalogue of one object per week, no shop',
      'A studio-visit booking site for potters who hate booking sites',
      'A kiln timer that is also a journal',
    ],
  },
  {
    id: 'run',
    name: 'Running and recovery',
    line: 'Zone 2, heart-rate variability, sleep debt, energy. Numbers you check in the morning.',
    proposals: [
      'A run planner that reads your sleep score and moves the hard day',
      'A watch face that shows one number: whether today is a rest day',
      'A recovery log you talk to instead of type into',
    ],
  },
  {
    id: 'type',
    name: 'Type and editorial layout',
    line: 'Garamond, grids, magazines from before the web. What white space is for.',
    proposals: [
      'A magazine-style front page for your own saves, printed weekly',
      'A type specimen tool that renders your real content, not lorem ipsum',
      'An editorial template pack for people who ship with AI and ship ugly',
    ],
  },
  {
    id: 'food',
    name: 'Cooking the things you miss',
    line: 'Kimchi jjigae at 1am, bakeries in Hackney, the bread your mother made.',
    proposals: [
      'A recipe app with no recipes, only the dish and who taught it to you',
      'A pantry list that knows which Korean staples London stores stock',
      'A supper-club matcher for people cooking the same homesick dish',
    ],
  },
  {
    id: 'career',
    name: 'The London job hunt',
    line: 'Design engineer roles, portfolio advice, interview loops. The part you do not save on purpose.',
    proposals: [
      'A portfolio that is just the tools you built for yourself',
      'A weekly digest of design-engineer roles ranked by what you actually saved',
      'A rehearsal tool that grills you on your own case studies',
    ],
  },
]

export const tensions: Tension[] = [
  {
    a: 'slow',
    b: 'solo',
    line: 'You save essays about software that waits, and tutorials about shipping in a weekend. One of these is the product and one is the pace.',
  },
  {
    a: 'clay',
    b: 'solo',
    line: 'Half your saves admire objects that took a year. The other half are about making things in an afternoon with an agent.',
  },
  {
    a: 'seoul',
    b: 'career',
    line: 'Everything about Seoul is warm and specific. Everything about the London search is efficient and cold. The archive is homesick and ambitious at once.',
  },
]

export const saves: Save[] = [
  // slow interfaces
  s('web', 'The case for boring software', 'Fast software is a feature. Software that stops asking is a bigger one. On restraint as a product decision.', 'linus.dev', '3d', 'slow'),
  s('x', 'Rauno on the last 10% of a transition', 'Thread. Every spring you add is a decision about how much the interface should perform for you.', 'raunofreiberg', '1w', 'slow', false),
  s('youtube', 'Why iOS Notes never got a feed', 'A designer walks through the Notes team’s refusal to add recommendations for eleven years.', 'Design Details', '2w', 'slow', true, 0.56),
  s('instagram', 'Teenage Engineering OP-1 field, one button per job', 'Hardware that does not scroll.', 'teenageengineering', '5d', 'slow', true, 1),
  s('arena', 'Calm technology reading list', 'Amber Case, Weiser, and eleven essays on interfaces that stay at the periphery.', 'are.na/mickey', '1mo', 'slow'),
  s('web', 'Emil Kowalski: animations should be felt, not seen', 'Duration under 300ms, ease-out, and why the bounce on your modal is a lie.', 'emilkowal.ski', '2w', 'slow'),
  s('tiktok', 'The Kindle is the only device I do not hate', 'A creator on why e-ink is the last calm screen.', '@slowtech', '4d', 'slow', true, 0.56),
  s('x', 'Linear’s new onboarding has no tooltips', 'Screenshots. The product teaches itself by being legible.', 'karrisaarinen', '6d', 'slow', true, 1.4),
  s('web', 'How the Clock app handles empty states', 'Apple’s world clock shows nothing until you add a city. No illustration, no copy.', 'mobbin', '3w', 'slow', true, 0.7),
  s('youtube', 'Dieter Rams, Ten Principles, 4K restoration', 'Less, but better, as a video essay.', 'Vitsœ', '2mo', 'slow', true, 0.56),

  // seoul
  s('spotify', 'Jeju Cassette, Side B, Night Drive Mix', 'Saved every Sunday for a month. Always after 11pm.', 'spotify', '2w', 'seoul', true, 1),
  s('instagram', 'Euljiro at 2am, film', 'Neon, welding shops, one open pojangmacha.', 'seoul.film', '1w', 'seoul', true, 1.25),
  s('tiktok', 'Tteokbokki alley in Sindang, the one with the wooden stools', 'A creator eats through the alley in order.', '@eatseoul', '3d', 'seoul', true, 0.56),
  s('spotify', 'Clairo, Charm', 'Bedroom pop trades for a warm analog band. Wurlitzer, flute, drums way back in the room.', 'spotify', '1w', 'seoul', true, 1),
  s('youtube', 'Han river at night, 1 hour, no talking', 'Ambient. Saved twice.', 'Seoul Walker', '1mo', 'seoul', true, 0.56),
  s('instagram', 'Hannam-dong bookshop that only stocks 40 titles', 'A shop that curates by removing.', 'thebookshop.hannam', '2w', 'seoul', true, 1),
  s('x', 'Korea’s convenience stores are the real third place', 'Thread on GS25 as urban infrastructure.', 'seoulurbanism', '4d', 'seoul', false),
  s('spotify', 'Hyukoh, 23', 'Saved the day the visa came through.', 'spotify', '3mo', 'seoul', true, 1),
  s('web', 'Naru means ferry landing', 'On Korean words for arrival.', 'koreanwords.co', '2mo', 'seoul'),
  s('instagram', 'Bukchon rooftops, winter', 'Hanok tiles under snow. Saved for the palette.', 'hanok.archive', '1mo', 'seoul', true, 0.8),
  s('tiktok', 'Subway line 2 loop, sped up 20x', 'The whole circle in 90 seconds.', '@seoulmetro.fan', '2w', 'seoul', true, 0.56),

  // solo builder
  s('x', 'Pieter Levels: ship the ugly version', 'Thread. The gap between your saved inspiration and what you ship is where products die.', 'levelsio', '2d', 'solo', false),
  s('youtube', 'Building a SaaS in a weekend with Claude Code', 'Screen recording, no cuts, real errors.', 'Theo', '5d', 'solo', true, 0.56),
  s('web', 'Knowing what to build is the new bottleneck', 'When anyone can build anything, taste and input quality decide the output.', 'stratechery', '1w', 'solo'),
  s('x', 'Your saves are a spec you never wrote', 'A one-liner that went around. Saved without comment.', 'jh3yy', '3d', 'solo'),
  s('web', 'The Weekend Proof method', 'Validate the scariest premise with a script and your own data before building a product.', 'signal.md', '2mo', 'solo'),
  s('youtube', 'Cursor vs Claude Code vs Codex, one project, three agents', 'A builder runs the same spec through all three.', 'Fireship', '1w', 'solo', true, 0.56),
  s('linkedin', 'Palantir design: show us how you use AI to build', 'Saved the brief.', 'palantir', '4d', 'solo'),
  s('x', 'Andrej Karpathy on vibe coding, the follow-up', 'The first post was a joke. The follow-up is not.', 'karpathy', '2w', 'solo'),
  s('web', 'Mymind is a graveyard with better lighting', 'A review. Every save tool optimises for input and none for use.', 'bookmarkless.com', '3w', 'solo'),
  s('arena', 'Tools for thought, 2026 survey', 'Fourteen apps. Twelve are archives.', 'are.na/mickey', '1mo', 'solo'),
  s('youtube', 'Maggie Appleton: the expanding dark forest', 'On generative AI and the death of the open web.', 'Maggie Appleton', '2mo', 'solo', true, 0.56),

  // clay, wood
  s('instagram', 'Moon jar, wood-fired, 30 hours', 'A potter films the kiln at hour 28.', 'kwon.ceramics', '6d', 'clay', true, 1.25),
  s('tiktok', 'Sharpening a plane iron for eleven minutes', 'No talking. Saved for the sound.', '@japanesetools', '1w', 'clay', true, 0.56),
  s('instagram', 'Hackney furniture maker, one chair a month', 'The whole studio is four tools.', 'e8.workshop', '2w', 'clay', true, 0.8),
  s('youtube', 'Onggi, Korean earthenware, full process', 'From clay pit to fermentation jar.', 'Korean Craft Archive', '1mo', 'clay', true, 0.56),
  s('web', 'Why handmade objects feel expensive', 'Time is visible in the surface.', 'craftsmanship.net', '3w', 'clay'),
  s('instagram', 'Kintsugi bowl, the crack is the point', 'Repair as decoration.', 'urushi.studio', '2mo', 'clay', true, 1),
  s('arena', 'Mingei and the unknown craftsman', 'Yanagi on beauty that nobody signed.', 'are.na/mickey', '3mo', 'clay'),
  s('tiktok', 'Throwing 50 identical cups, real time', 'Repetition as skill.', '@wheelthrown', '3d', 'clay', true, 0.56),

  // running
  s('youtube', 'What the Oura readiness score actually measures', 'HRV, sleep debt, temperature, folded into one number.', 'The Quantified Scientist', '4d', 'run', true, 0.56),
  s('web', 'Zone 2 is boring on purpose', 'Why the easy run is the one that makes you fast.', 'runningwritings', '1w', 'run'),
  s('x', 'Sleep debt compounds like interest', 'A physiologist’s thread. Saved after a bad week.', 'drmattwalker', '2w', 'run'),
  s('tiktok', 'Victoria Park loop at 6am', 'A runner’s POV, saved for the route.', '@londonrunclub', '5d', 'run', true, 0.56),
  s('spotify', 'Deep Focus, 3h 42m', 'Saved every weekday. Always between 9 and 12.', 'spotify', '6d', 'run', true, 1),
  s('web', 'Rise app: energy as a curve, drawn from sleep alone', 'A product teardown.', 'risescience', '3w', 'run', true, 0.7),
  s('youtube', 'Nobody logs their energy. Stop building this.', 'A founder’s post-mortem on a mood planner. Retention died at day four.', 'Indie Hackers', '1mo', 'run', true, 0.56),
  s('instagram', 'Hackney Half, finish line, 1:52', 'Saved your own post. Fair.', 'mickeyoh', '2mo', 'run', true, 1),

  // type
  s('arena', 'Garamond in use, 2020 to now', 'Sixty examples of a 500-year-old face on screens.', 'are.na/mickey', '2w', 'type', true, 1),
  s('instagram', 'Apartamento issue 33, spread', 'Two columns, one photo, a lot of nothing.', 'apartamentomagazine', '4d', 'type', true, 1.3),
  s('web', 'Butterick: Practical Typography, the free parts', 'Point size is not the hierarchy. Weight is.', 'practicaltypography', '1mo', 'type'),
  s('x', 'BeReal’s type system is weight-only', 'Screenshots. Four weights, one size, no underlines.', 'mobbin', '3mo', 'type', true, 1),
  s('instagram', 'Kinfolk before it got soft', 'Early issues, scanned.', 'printarchive', '2w', 'type', true, 0.8),
  s('youtube', 'The grid is a promise, Massimo Vignelli', 'A lecture from 1991, restored.', 'AIGA', '2mo', 'type', true, 0.56),
  s('web', 'iOS 26 Notes masonry, Apple press shot', 'Staggered cards, title inside the card, corner glass buttons.', 'apple.com', '2mo', 'type', true, 0.75),
  s('arena', 'Editorial layouts for software', 'Linear changelog, Stripe press, Vercel blog. What white space costs.', 'are.na/mickey', '1mo', 'type', true, 1),

  // food
  s('tiktok', 'Kimchi jjigae, the 1am version', 'Canned tuna, old kimchi, eight minutes.', '@latenightkorean', '2d', 'food', true, 0.56),
  s('instagram', 'E5 Bakehouse, sourdough Saturday', 'The queue is the product.', 'e5bakehouse', '1w', 'food', true, 1),
  s('youtube', 'Maangchi, doenjang from scratch, one year', 'Fermentation as patience.', 'Maangchi', '3w', 'food', true, 0.56),
  s('web', 'H Mart is opening in London', 'Finally. Saved with three exclamation marks in the note.', 'eater.london', '4d', 'food'),
  s('instagram', 'Mum’s gyeran-mari, wobbly', 'Screenshot of a video call. Saved on purpose.', 'mickeyoh', '2w', 'food', true, 1),
  s('tiktok', 'Every Korean grocery in Zone 2, ranked', 'New Malden is not Zone 2 but it is on the list.', '@koreanlondon', '1w', 'food', true, 0.56),
  s('spotify', 'Cooking Sunday, 2h 10m', 'Plays while the rice cooker runs.', 'spotify', '1mo', 'food', true, 1),
  s('web', 'Why Korean bakeries put beans in everything', 'A short history of patbingsu.', 'koreanfoodhistory', '2mo', 'food'),

  // career
  s('linkedin', 'Design engineer, London, Series B fintech', 'Saved, not applied.', 'linkedin', '3d', 'career'),
  s('web', 'What design engineers actually do at Linear', 'The job is the seam between design and code.', 'linear.app/careers', '1w', 'career'),
  s('x', 'Your portfolio should be the tools you built for yourself', 'A hiring manager’s thread that got 4k saves.', 'sarah_edo', '2w', 'career'),
  s('linkedin', 'Palantir product design interview loop, what to expect', 'A former designer’s write-up.', 'linkedin', '5d', 'career'),
  s('youtube', 'Design engineer portfolio review, live', 'Four portfolios torn down in an hour.', 'Design Buddies', '1mo', 'career', true, 0.56),
  s('web', 'UK Global Talent visa for designers, 2026 update', 'Endorsement criteria changed in March.', 'gov.uk', '2mo', 'career'),
  s('x', 'Every job post says AI-native now. Here is what it means.', 'Thread. Mostly it means you ship.', 'jaredpalmer', '1w', 'career'),

  // added for the placeholder ideas
  s('web', 'Twelve calendar startups launched. Zero survived.', 'Sunrise, Woven, Clockwise: every one sold small or died. The calendar is a feature, not a product.', 'medium', '5d', 'run'),
  s('web', 'Time-blocking works because it is rigid, not in spite of it', 'Systems that flex to how you feel become systems you never use.', 'nytimes', '1mo', 'run'),
  s('x', 'Screen time as a proxy for flow', 'Long unbroken app sessions correlate with deep work better than any self-report.', 'substack', '2w', 'run'),
  s('web', 'Google Maps lists are where recommendations go to die', 'Forty saved places, zero visited. The list is the graveyard.', 'theverge', '3w', 'seoul'),
  s('x', 'Foursquare killed the city guide', 'The thread that mourned it. Everyone saved places, nobody went.', 'foursquare', '2mo', 'seoul'),
  s('x', 'Every AI app looks the same now', 'Same shadcn, same hero, same three cards. Templates are why.', 'jsngr', '6d', 'type'),
  s('web', 'v0 output, side by side, forty apps', 'A gallery. You cannot tell them apart.', 'v0.app', '2w', 'type', true, 0.75),
  s('instagram', 'A potter who only sells at the studio door', 'No shop, no shipping, a queue on Saturdays.', 'kwon.ceramics', '3w', 'clay', true, 1),
  s('web', 'Why catalogues die', 'The moment a catalogue tries to sell, it stops being read.', 'themargins', '1mo', 'clay'),
  // unthemed / noise
  s('youtube', 'The deep sea is darker than you think', 'A documentary clip.', 'Real Science', '3w', null, true, 0.56),
  s('instagram', 'Golden retriever refuses stairs', 'Saved for a friend.', 'dogsofldn', '2d', null, true, 1),
  s('web', 'Apple, hardware announcements', 'Landing page for the September event.', 'apple.com', '2w', null, true, 0.7),
  s('x', 'A weather app that only shows if you need a jacket', 'Someone’s side project.', 'jacket.app', '1mo', null),
  s('tiktok', 'Cat learns to open a fridge', 'Nine million views.', '@catfacts', '4d', null, true, 0.56),
  s('spotify', 'lofi beats to type a cover letter to', 'Once. Never again.', 'spotify', '3mo', null, true, 1),
  s('web', 'Analog desk tour, 2026', 'A desk with no screen on it.', 'blog.example.net', '1mo', null, true, 0.8),
  s('instagram', 'Thames at low tide, mudlarking', 'A clay pipe from 1700.', 'mudlark.london', '3w', null, true, 1.25),
]

export const byId = Object.fromEntries(saves.map((x) => [x.id, x]))
export const savesFor = (themeId: string) => saves.filter((x) => x.theme === themeId)
export const themeById = Object.fromEntries(themes.map((t) => [t.id, t]))

const find = (title: string) => {
  const hit = saves.find((x) => x.title.startsWith(title))
  if (!hit) throw new Error(`seed: no save starting "${title}"`)
  return hit.id
}

/* The idea the home opens on. */
export const idea: Idea = {
  title: 'A tool that turns your saves into the spec you hand to a coding agent',
  themeId: 'solo',
  lanes: {
    agrees: [
      { id: find('Knowing what to build'), why: 'The core premise, in someone else\u2019s words' },
      { id: find('Your saves are a spec'), why: 'The one-liner is the product' },
      { id: find('Pieter Levels'), why: 'The gap between saved and shipped is the problem' },
      { id: find('Palantir design'), why: 'The deadline that made it real' },
    ],
    disagrees: [
      { id: find('Mymind is a graveyard'), why: 'Every save tool dies as an archive. Why not this one' },
      { id: find('Nobody logs their energy'), why: 'Input cost killed a product with the same shape' },
      { id: find('The case for boring software'), why: 'You admire software that asks less. This asks a lot' },
    ],
    precedent: [
      { id: find('Tools for thought, 2026'), why: 'Fourteen tools, twelve of them archives' },
      { id: find('Mymind is a graveyard'), why: 'The closest existing product, and its verdict' },
    ],
    howto: [
      { id: find('The Weekend Proof'), why: 'Your own method for testing the scariest premise' },
      { id: find('Cursor vs Claude Code'), why: 'Where the spec ends up' },
      { id: find('Building a SaaS in a weekend'), why: 'What building from a brief looks like' },
    ],
    visual: [
      { id: find('Linear\u2019s new onboarding'), why: 'A product that teaches itself by being legible' },
      { id: find('iOS 26 Notes masonry'), why: 'The archive layout you already copied' },
    ],
    mood: [{ id: find('Deep Focus, 3h 42m'), why: 'What plays while you build it' }],
  },
  pushback: [
    { q: 'Twelve of your fourteen saved tools-for-thought are archives you stopped opening. What makes the output of this one something you return to?', evidence: [find('Tools for thought, 2026'), find('Mymind is a graveyard')] },
    { q: 'You saved a founder saying retention died at day four because input cost outran output. Where does this tool get its input without asking you for it?', evidence: [find('Nobody logs their energy')] },
    { q: 'Half your archive admires software that asks less of you. Is a tool that interrogates your ideas the software you would actually want?', evidence: [find('The case for boring software'), find('Rauno on the last')] },
  ],
}
