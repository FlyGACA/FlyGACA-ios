// Marketing-caption layer for the App Store screenshot renderer.
//
// The base screens (screens.js) are faithful, caption-less recreations of the
// shipping SwiftUI views. For the store, each shot gets a value-prop caption
// band (Falcon palette) above the device, and the set is reordered value-prop
// first (hero -> scored exam -> results -> the study loop). render-store.js
// consumes this; the original render.js (raw screens) is left untouched.
//
// Copy is EN only for now; an ar-SA caption pass is a tracked follow-up
// (SEO-PLAN.md 2.1) — the base screens are identical, only `head`/`sub` localize.

const C = { night: '#0A0E12', sage: '#8FC9A8', white: '#FFFFFF', sec: 'rgba(235,240,245,0.55)', mist: '#1A2A38' };

// Compose one captioned shot: caption band on top, the real screen below in a
// device bezel, scaled to fit. W/H are the slot's logical pixels.
function compose(screenDoc, head, sub, W, H) {
  const srcdoc = screenDoc.replace(/&/g, '&amp;').replace(/"/g, '&quot;');
  const capH = Math.round(H * 0.24);
  const s = (H - capH - Math.round(H * 0.05)) / H;
  const sw = Math.round(W * s), sh = Math.round(H * s);
  const headPx = Math.round(W * 0.077), subPx = Math.round(W * 0.038), padX = Math.round(W * 0.084);
  return `<!doctype html><html><head><meta charset="utf-8"><style>
    *{margin:0;padding:0;box-sizing:border-box;-webkit-font-smoothing:antialiased}
    html,body{width:${W}px;height:${H}px}
    body{background:${C.night};font-family:-apple-system,'SF Pro Display','Helvetica Neue',Arial,sans-serif;
      color:${C.white};overflow:hidden;display:flex;flex-direction:column}
    .cap{height:${capH}px;flex:none;display:flex;flex-direction:column;justify-content:flex-end;
      padding:0 ${padX}px ${Math.round(capH * 0.11)}px}
    .kl{width:${Math.round(W * 0.10)}px;height:${Math.round(W * 0.012)}px;background:${C.sage};
      border-radius:3px;margin-bottom:${Math.round(H * 0.021)}px}
    .cap h1{font-size:${headPx}px;line-height:1.12;font-weight:700;letter-spacing:-0.02em}
    .cap p{margin-top:${Math.round(H * 0.015)}px;font-size:${subPx}px;line-height:1.4;color:${C.sec};
      max-width:${Math.round(W * 0.86)}px}
    .stage{flex:1;display:flex;align-items:center;justify-content:center}
    .bezel{width:${sw}px;height:${sh}px;border-radius:${Math.round(46 * s)}px;overflow:hidden;background:#000;
      box-shadow:0 ${Math.round(24 * s)}px ${Math.round(60 * s)}px rgba(0,0,0,0.55),0 0 0 2px ${C.mist};position:relative}
    .bezel iframe{width:${W}px;height:${H}px;border:0;transform:scale(${s});transform-origin:top left;position:absolute;top:0;left:0}
  </style></head><body>
    <div class="cap"><div class="kl"></div><h1>${head}</h1><p>${sub}</p></div>
    <div class="stage"><div class="bezel"><iframe srcdoc="${srcdoc}"></iframe></div></div>
  </body></html>`;
}

// The reordered store sequence. `screen` names a key from buildScreens();
// `name` is the output filename (its numeric prefix drives App Store order).
// A caption pair is either a string or a fn(meta) for per-app tailoring.
const SEQUENCE = [
  { name: '01-home',            screen: '01-home',            head: (m) => m.hero.head, sub: (m) => m.hero.sub },
  { name: '02-timed-exam',      screen: '08-timed-exam-timer', head: 'Sit the real exam',      sub: 'A timed mock under exam conditions — 30 minutes, 75% to pass.' },
  { name: '03-results',         screen: '09-mock-results',    head: 'Know when you’re ready', sub: 'Per-topic analytics and a pass score after every mock exam.' },
  { name: '04-quiz-topics',     screen: '02-quiz-banks',      head: 'Study by topic',         sub: 'Focused question banks across the whole syllabus.' },
  { name: '05-quiz-question',   screen: '03-quiz-question',   head: 'Practice anywhere',      sub: 'Work the bank fully offline — no signal needed.' },
  { name: '06-quiz-explained',  screen: '04-quiz-answered',   head: 'Every answer, cited',    sub: 'The correct choice, the why, and the exact GACAR Part and section.' },
  { name: '07-flashcard',       screen: '05-flashcard-front', head: 'Flashcards that stick',  sub: 'Spaced repetition brings back what you’re about to forget.' },
  { name: '08-flashcard-answer', screen: '06-flashcard-back', head: 'Learn the reasoning',    sub: 'Front and back — the rule and the reference, together.' },
  { name: '09-exam-start',      screen: '07-timed-exam-start', head: 'Exam conditions',        sub: '25 questions, 30 minutes — one pass through, just like the day.' },
  { name: '10-lessons',         screen: '10-lessons-list',    head: 'Ground school built in', sub: 'Structured lessons with an objective for every topic.', optional: true },
];

// Per-app hero copy (the rest of the captions are shared, shot-level).
const HERO = {
  PPL:  { head: 'The Saudi PPL exam,<br>in your pocket',  sub: 'The full question bank, offline — every answer cites the exact GACAR.' },
  CPL:  { head: 'The Saudi CPL exam,<br>in your pocket',  sub: 'Commercial-pilot theory, offline — every answer cites the exact GACAR.' },
  IR:   { head: 'The Saudi Instrument<br>Rating, mastered', sub: 'IFR rules and procedures, offline — every answer cites the exact GACAR.' },
  ATPL: { head: 'The Saudi ATPL exam,<br>in your pocket', sub: 'Airline-transport theory, offline — every answer cites the exact GACAR.' },
  ELPT: { head: 'Aviation English,<br>exam-ready',        sub: 'ICAO Level 4 prep — phraseology and comprehension, fully offline.' },
  AIP:  { head: 'The Saudi AIP,<br>made studyable',       sub: 'Aerodromes, airspace and charts — offline, and always cited.' },
};

function captionsFor(dir) {
  const meta = { hero: HERO[dir] || HERO.PPL };
  return SEQUENCE.map((s) => ({
    name: s.name,
    screen: s.screen,
    optional: !!s.optional,
    head: typeof s.head === 'function' ? s.head(meta) : s.head,
    sub: typeof s.sub === 'function' ? s.sub(meta) : s.sub,
  }));
}

module.exports = { compose, captionsFor, SEQUENCE, HERO };
