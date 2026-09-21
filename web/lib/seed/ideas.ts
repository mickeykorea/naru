/* PROTOTYPE. One hand-written idea per placeholder, so every demo path
   gathers real lanes. Routed by keyword in ideaFor(). */
import { idea as seeded, saves, type Idea } from './data'

const find = (title: string) => {
  const hit = saves.find((x) => x.title.startsWith(title))
  if (!hit) throw new Error(`ideas: no save starting "${title}"`)
  return hit.id
}

const calendar: Idea = {
  title: 'A calendar that plans around energy, not the clock',
  themeId: 'run',
  lanes: {
    agrees: [
      { id: find('What the Oura readiness'), why: 'Energy is already measured, passively' },
      { id: find('Zone 2 is boring'), why: 'Pacing by state, not by schedule' },
      { id: find('Sleep debt compounds'), why: 'The cost of ignoring the curve' },
    ],
    disagrees: [
      { id: find('Twelve calendar startups'), why: 'Category graveyard' },
      { id: find('Nobody logs their energy'), why: 'Input cost killed the same shape' },
      { id: find('Time-blocking works because'), why: 'Flexibility as a bug' },
    ],
    precedent: [{ id: find('Rise app: energy'), why: 'Someone already draws the curve from sleep alone' }],
    howto: [{ id: find('Screen time as a proxy'), why: 'A zero-input signal you could read' }],
    visual: [{ id: find('How the Clock app'), why: 'What an empty day could look like' }],
    mood: [{ id: find('Deep Focus, 3h 42m'), why: 'Your own morning pattern, two weeks running' }, { id: find('Victoria Park loop'), why: 'The 6am slot the calendar never sees' }],
  },
  pushback: [
    { q: 'Four of your saves say calendar apps die as products. Why does yours survive as one?', evidence: [find('Twelve calendar startups')] },
    { q: 'You saved a founder saying nobody logs energy. Where does your energy signal come from if not the user?', evidence: [find('Nobody logs their energy'), find('What the Oura readiness')] },
    { q: 'The Times piece argues rigidity is why time-blocking works. What does your calendar refuse to flex on?', evidence: [find('Time-blocking works because')] },
  ],
}

const kilns: Idea = {
  title: 'A slow catalogue of one object per week, no shop',
  themeId: 'clay',
  lanes: {
    agrees: [
      { id: find('Why handmade objects feel'), why: 'The premise, in someone else\u2019s words' },
      { id: find('Hackney furniture maker'), why: 'One a month is already a cadence' },
      { id: find('A potter who only sells'), why: 'No shop works, at the door' },
    ],
    disagrees: [
      { id: find('Why catalogues die'), why: 'The moment it sells, it stops being read' },
      { id: find('Pieter Levels'), why: 'Slow is the opposite of how you ship' },
      { id: find('Mymind is a graveyard'), why: 'Beautiful collections still get abandoned' },
    ],
    visual: [
      { id: find('Moon jar, wood-fired'), why: 'Time made visible in a surface' },
      { id: find('Apartamento issue'), why: 'One photo, a lot of nothing' },
      { id: find('Kintsugi bowl'), why: 'The story is the object' },
    ],
    precedent: [{ id: find('Hannam-dong bookshop'), why: 'Curation by removing, already working' }],
    howto: [{ id: find('Onggi, Korean earthenware'), why: 'A full process, filmed' }],
    mood: [{ id: find('Mingei and the unknown'), why: 'Beauty nobody signed' }],
  },
  pushback: [
    { q: 'You saved an essay saying catalogues die the moment they sell. If there is no shop, what is the catalogue for?', evidence: [find('Why catalogues die')] },
    { q: 'Half your archive is about shipping in a weekend. Can you keep a weekly promise for a year?', evidence: [find('Pieter Levels')] },
  ],
}

const seoul: Idea = {
  title: 'A map of Seoul built only from places your friends have saved, no reviews',
  themeId: 'seoul',
  lanes: {
    agrees: [
      { id: find('Hannam-dong bookshop'), why: 'The kind of place only a friend knows' },
      { id: find('Tteokbokki alley'), why: 'Specific, not rated' },
      { id: find('Korea\u2019s convenience stores'), why: 'The city\u2019s real third place, unlisted' },
    ],
    disagrees: [
      { id: find('Google Maps lists'), why: 'Saved places die unvisited' },
      { id: find('Foursquare killed'), why: 'The category already lost once' },
      { id: find('Mymind is a graveyard'), why: 'A map of saves is still a save' },
    ],
    visual: [
      { id: find('Euljiro at 2am'), why: 'A place as a feeling' },
      { id: find('Bukchon rooftops'), why: 'The palette' },
      { id: find('Han river at night'), why: 'What the map should feel like at night' },
    ],
    mood: [{ id: find('Clairo, Charm'), why: 'What plays while you walk it' }, { id: find('Jeju Cassette'), why: 'Saved every Sunday, after 11pm' }],
    precedent: [{ id: find('Naru means ferry'), why: 'Where things arrive' }],
  },
  pushback: [
    { q: 'You saved the Verge piece calling Google Maps lists a graveyard. Why is a map of friends\u2019 saves not the same graveyard with better friends?', evidence: [find('Google Maps lists')] },
    { q: 'Foursquare had a hundred million users and still killed the city guide. What do you know that they did not?', evidence: [find('Foursquare killed')] },
  ],
}

const ugly: Idea = {
  title: 'An editorial template pack for people who ship with AI and ship ugly',
  themeId: 'type',
  lanes: {
    agrees: [
      { id: find('Pieter Levels'), why: 'The people this is for' },
      { id: find('Every job post says'), why: 'Everyone ships now; few ship well' },
      { id: find('Butterick'), why: 'Weight, not size, is the whole trick' },
    ],
    disagrees: [
      { id: find('Every AI app looks'), why: 'Templates caused the sameness' },
      { id: find('v0 output'), why: 'Forty apps, indistinguishable' },
      { id: find('The case for boring'), why: 'Restraint cannot be installed' },
    ],
    visual: [
      { id: find('Garamond in use'), why: 'What the pack would ship with' },
      { id: find('Apartamento issue'), why: 'Where the taste comes from' },
      { id: find('BeReal\u2019s type system'), why: 'A system small enough to copy' },
    ],
    precedent: [{ id: find('Editorial layouts for software'), why: 'Linear, Stripe, Vercel already do this in-house' }],
    howto: [{ id: find('Emil Kowalski'), why: 'The motion rules the pack would encode' }],
  },
  pushback: [
    { q: 'Two of your saves blame templates for every AI app looking the same. How is your pack not more of the same?', evidence: [find('Every AI app looks'), find('v0 output')] },
    { q: 'You admire restraint. Can restraint be a product, or only a habit?', evidence: [find('The case for boring')] },
  ],
}

const reader: Idea = {
  title: 'A reading app with no feed: one page a day from what you already saved',
  themeId: 'slow',
  lanes: {
    agrees: [
      { id: find('The Kindle is the only device'), why: 'E-ink is the last calm screen, in your own words' },
      { id: find('Why iOS Notes never got a feed'), why: 'Eleven years of refusing the feed, and it held' },
      { id: find('Calm technology reading list'), why: 'Interfaces that stay at the periphery' },
    ],
    disagrees: [
      { id: find('Tools for thought, 2026 survey'), why: 'Twelve of fourteen reading tools are archives' },
      { id: find('Mymind is a graveyard'), why: 'A reading list is still a save' },
      { id: find('Maggie Appleton'), why: 'The open web you would read from is thinning' },
    ],
    visual: [
      { id: find('How the Clock app'), why: 'An empty day with no illustration and no copy' },
      { id: find('Apartamento issue'), why: 'One page, a lot of nothing' },
    ],
    precedent: [{ id: find('Linear’s new onboarding'), why: 'A product that teaches itself by being legible' }],
    howto: [{ id: find('Emil Kowalski'), why: 'The page turn, under 300ms' }],
    mood: [{ id: find('Dieter Rams'), why: 'Less, but better' }],
  },
  pushback: [
    { q: 'You saved a survey where twelve of fourteen reading tools are archives. Why is one page a day not an archive with a smaller door?', evidence: [find('Tools for thought, 2026 survey')] },
    { q: 'Your Kindle save says e-ink is the last calm screen. Can this exist on a phone at all?', evidence: [find('The Kindle is the only device')] },
  ],
}

const grocery: Idea = {
  title: 'A grocery run planned from what you actually cook, not from recipes',
  themeId: 'food',
  lanes: {
    agrees: [
      { id: find('Every Korean grocery'), why: 'The shops are already mapped and ranked' },
      { id: find('Kimchi jjigae'), why: 'What you actually cook, at 1am' },
      { id: find('H Mart is opening'), why: 'The supply is arriving' },
    ],
    disagrees: [
      { id: find('Nobody logs their energy'), why: 'Input cost killed a planner with the same shape' },
      { id: find('Twelve calendar startups'), why: 'Planning apps die as products' },
      { id: find('Google Maps lists'), why: 'A list of shops is a list of saved places' },
    ],
    visual: [
      { id: find('E5 Bakehouse'), why: 'The queue is the product' },
      { id: find('Mum’s gyeran-mari'), why: 'The dish this is really about' },
    ],
    precedent: [{ id: find('Maangchi'), why: 'A year spent on one ingredient' }],
    howto: [{ id: find('Why Korean bakeries'), why: 'Where the ingredients come from' }],
    mood: [{ id: find('Cooking Sunday'), why: 'Plays while the rice cooker runs' }],
  },
  pushback: [
    { q: 'Your founder post-mortem says nobody logs anything past day four. Who logs what they cooked?', evidence: [find('Nobody logs their energy')] },
    { q: 'The Verge piece calls saved-place lists a graveyard. Is a grocery list a list of places or a list of meals?', evidence: [find('Google Maps lists')] },
  ],
}

const portfolio: Idea = {
  title: 'A portfolio that is only the tools you built for yourself',
  themeId: 'career',
  lanes: {
    agrees: [
      { id: find('Your portfolio should be'), why: 'A hiring manager already asks for exactly this' },
      { id: find('Every job post says'), why: 'AI-native means you ship' },
      { id: find('What design engineers actually do'), why: 'The seam between design and code is the job' },
    ],
    disagrees: [
      { id: find('Design engineer portfolio review'), why: 'Four torn down; presentation still decided' },
      { id: find('Palantir product design interview'), why: 'The loop wants process, not artefacts' },
      { id: find('Pieter Levels'), why: 'A portfolio is polish; you save advice to ship ugly' },
    ],
    visual: [
      { id: find('Editorial layouts for software'), why: 'How the tools would be laid out' },
      { id: find('Kinfolk before'), why: 'Before it got soft' },
    ],
    precedent: [{ id: find('The Weekend Proof'), why: 'A method that is itself a tool' }],
    howto: [{ id: find('Building a SaaS in a weekend'), why: 'No cuts, real errors' }],
    mood: [{ id: find('Hackney Half'), why: 'Your own post. Fair' }],
  },
  pushback: [
    { q: 'A hiring manager’s thread got 4k saves for saying tools are the portfolio. Which of yours would you show, and which would you hide?', evidence: [find('Your portfolio should be')] },
    { q: 'The interview write-up says the loop wants process. Does a tool show process, or hide it?', evidence: [find('Palantir product design interview')] },
  ],
}

const music: Idea = {
  title: 'A playlist that remembers what you were doing when you saved the song',
  themeId: 'seoul',
  lanes: {
    agrees: [
      { id: find('Jeju Cassette'), why: 'Saved every Sunday after 11pm. The context is already there' },
      { id: find('Deep Focus, 3h 42m'), why: 'Weekdays, 9 to 12. A habit, not a taste' },
      { id: find('Hyukoh, 23'), why: 'Saved the day the visa came through' },
    ],
    disagrees: [
      { id: find('Foursquare killed'), why: 'Check-ins died; nobody wanted to remember where' },
      { id: find('Mymind is a graveyard'), why: 'Context does not make a save get used' },
      { id: find('Nobody logs their energy'), why: 'Nobody annotates a save either' },
    ],
    visual: [
      { id: find('Han river at night'), why: 'What it sounds like' },
      { id: find('Euljiro at 2am'), why: 'Where it was playing' },
    ],
    precedent: [{ id: find('Rise app'), why: 'A curve drawn from a passive signal' }],
    howto: [{ id: find('Screen time as a proxy'), why: 'Long sessions as the signal, no input' }],
    mood: [{ id: find('Clairo, Charm'), why: 'Warm, analog, way back in the room' }, { id: find('Cooking Sunday'), why: 'Two hours, every Sunday' }],
  },
  pushback: [
    { q: 'Foursquare had a check-in for every song you could have saved. Why did nobody want to remember where they were?', evidence: [find('Foursquare killed')] },
    { q: 'Your saves already carry the context: Sunday, after 11pm. What does the app add that the timestamp does not?', evidence: [find('Jeju Cassette')] },
  ],
}

const notes: Idea = {
  title: 'Notes with no feed: a wall of what you saved this week',
  themeId: 'type',
  lanes: {
    agrees: [
      { id: find('iOS 26 Notes masonry'), why: 'Apple already put notes on a wall' },
      { id: find('Why iOS Notes never got a feed'), why: 'Eleven years of refusing the feed' },
      { id: find('Apartamento issue'), why: 'A wall that breathes' },
    ],
    disagrees: [
      { id: find('Every AI app looks'), why: 'Masonry is a template too' },
      { id: find('Tools for thought, 2026 survey'), why: 'Walls become archives' },
      { id: find('The case for boring'), why: 'A wall asks to be looked at; the best software asks nothing' },
    ],
    visual: [
      { id: find('The grid is a promise'), why: 'Vignelli, 1991' },
      { id: find('Kinfolk before'), why: 'The early issues' },
      { id: find('BeReal’s type system'), why: 'Four weights, one size' },
    ],
    precedent: [{ id: find('Editorial layouts for software'), why: 'Linear, Stripe, Vercel do this in-house' }],
    howto: [{ id: find('Butterick'), why: 'Weight, not size, is the hierarchy' }],
    mood: [{ id: find('Teenage Engineering OP-1'), why: 'One button per job' }],
  },
  pushback: [
    { q: 'You saved Vignelli saying the grid is a promise. What does a wall of this week promise, and to whom?', evidence: [find('The grid is a promise')] },
    { q: 'Your restraint saves say the best software asks nothing. A wall asks to be looked at every day. Is that asking?', evidence: [find('The case for boring')] },
  ],
}

export const ideas: Record<string, Idea> = { seeded, calendar, kilns, seoul, ugly, reader, grocery, portfolio, music, notes }

/* Whole words only. Without the boundaries "already" routed to the reading
   app and "objective" to the catalogue. */
const ROUTES: [RegExp, string][] = [
  [/\bread(ing|er)?\b|\bpage a day\b/i, 'reader'],
  [/\bgrocer\w*\b|\bcook\w*\b|\bkitchen\b|\bshopping list\b/i, 'grocery'],
  [/\bportfolio\b|\btools i built\b|\bhiring\b/i, 'portfolio'],
  [/\bplaylist\b|\bsongs?\b|\bmusic\b|\balbums?\b/i, 'music'],
  [/\bnotes?\b|\bwall of\b/i, 'notes'],
  [/\bcalendar\b|\benergy\b|\bclock\b|\bschedule\b/i, 'calendar'],
  [/\bkilns?\b|\bclay\b|\bpotter\w*\b|\bobjects?\b|\bcatalogues?\b|\bcatalogs?\b/i, 'kilns'],
  [/\bseoul\b|\bkorean?\b/i, 'seoul'],
  [/\bugly\b|\btemplates?\b|\beditorial\b/i, 'ugly'],
  [/\bspecs?\b|\bsaves?\b|\bagents?\b|\bcoding\b/i, 'seeded'],
]
export const ideaFor = (text: string): Idea | null => {
  const hit = ROUTES.find(([re]) => re.test(text))
  return hit ? ideas[hit[1]] : null
}
