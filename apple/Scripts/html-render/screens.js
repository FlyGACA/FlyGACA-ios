// Faithful HTML recreations of the FlyGACA iOS screens using the exact Falcon
// palette (FlyGACAKit/Sources/FeatureUI/Theme.swift) and each app's real bundled
// GACAR content. Rendered to PNG at App Store device resolutions via Playwright +
// the pre-installed Chromium (see render.js).
//
// The chrome is identical across every app in the family (they share FeatureUI),
// so per-app screenshots differ only by the module's own banks/questions/lessons
// and its display name — an honest mirror of the shipping app. `buildScreens(app)`
// loads `apple/Apps/<app.dir>/Content` and returns the screen set for that module;
// ground-school screens are included only when the module ships groundschool.json
// (today just PPL).

const fs = require('fs');
const path = require('path');

// Falcon palette — verbatim from FeatureUI/Theme.swift (shared by every app).
const C = {
  night: '#0A0E12',
  deep: '#0F1A24',
  mist: '#1A2A38',
  teal: '#2D6E8A',
  sage: '#8FC9A8',
  gold: '#C8A04A',
  clay: '#CF6B52',
  white: '#FFFFFF',
  sec: 'rgba(235,240,245,0.55)',   // iOS secondaryLabel on dark
  ter: 'rgba(235,240,245,0.28)',
};

// iOS system font stack + shared chrome
const BASE = `
  * { margin:0; padding:0; box-sizing:border-box; -webkit-font-smoothing:antialiased; }
  html,body { height:100%; }
  body {
    font-family:-apple-system,'SF Pro Text','SF Pro Display','Helvetica Neue',Helvetica,Arial,sans-serif;
    background:${C.night}; color:${C.white}; overflow:hidden;
    letter-spacing:-0.01em;
  }
  .screen { display:flex; flex-direction:column; height:100%; background:${C.night}; }
  .statusbar {
    height:54px; display:flex; align-items:flex-end; justify-content:space-between;
    padding:0 30px 6px; font-size:17px; font-weight:600; flex:none;
  }
  .statusbar .icons { display:flex; gap:7px; align-items:center; }
  .statusbar .icons svg { display:block; }
  .navbar { padding:4px 20px 10px; flex:none; }
  .navbar.large .title { font-size:34px; font-weight:700; letter-spacing:-0.02em; }
  .navbar .back { color:${C.teal}; font-size:17px; display:flex; align-items:center; gap:3px; margin-bottom:8px; }
  .navbar .mid { text-align:center; font-size:17px; font-weight:600; }
  .body { flex:1; overflow:hidden; padding:0 16px; }
  .section-hdr {
    font-size:13px; text-transform:uppercase; letter-spacing:0.04em;
    color:${C.sec}; font-weight:600; padding:18px 8px 8px;
  }
  .card { background:${C.deep}; border-radius:14px; overflow:hidden; }
  .row {
    display:flex; align-items:center; justify-content:space-between;
    padding:14px 16px; border-bottom:0.5px solid ${C.mist};
  }
  .row:last-child { border-bottom:none; }
  .row .chev { color:${C.ter}; font-size:15px; }
  .row .lead { display:flex; flex-direction:column; gap:2px; }
  .row .lead .t { font-size:17px; }
  .row .lead .s { font-size:13px; color:${C.sec}; }
  .disclaimer { font-size:12px; color:${C.sec}; padding:14px 10px; line-height:1.45; }
  .tealbtn {
    background:${C.teal}; color:#fff; border:none; border-radius:12px;
    font-size:17px; font-weight:600; padding:15px; width:100%; text-align:center;
  }
`;

function statusbar() {
  const col = '#fff';
  return `<div class="statusbar" style="color:${col}">
    <span>9:41</span>
    <span class="icons">
      <svg width="18" height="12" viewBox="0 0 18 12"><g fill="${col}">
        <rect x="0" y="7" width="3" height="5" rx="1"/><rect x="4.5" y="4.5" width="3" height="7.5" rx="1"/>
        <rect x="9" y="2" width="3" height="10" rx="1"/><rect x="13.5" y="0" width="3" height="12" rx="1"/>
      </g></svg>
      <svg width="17" height="12" viewBox="0 0 17 12" fill="none"><path d="M8.5 2.5c2.1 0 4 .8 5.4 2.1l1.3-1.4A9.6 9.6 0 0 0 8.5.6 9.6 9.6 0 0 0 1.8 3.2l1.3 1.4A7.6 7.6 0 0 1 8.5 2.5Z" fill="${col}"/><path d="M8.5 6c1 0 2 .4 2.7 1.1l1.4-1.4A6 6 0 0 0 8.5 4a6 6 0 0 0-4.1 1.7l1.4 1.4A3.8 3.8 0 0 1 8.5 6Z" fill="${col}"/><circle cx="8.5" cy="9.8" r="1.6" fill="${col}"/></svg>
      <svg width="27" height="13" viewBox="0 0 27 13"><rect x="0.5" y="0.5" width="22" height="12" rx="3.5" fill="none" stroke="${col}" stroke-opacity="0.4"/><rect x="2" y="2" width="19" height="9" rx="2" fill="${col}"/><rect x="23.5" y="4" width="2" height="5" rx="1" fill="${col}" fill-opacity="0.5"/></svg>
    </span>
  </div>`;
}

function chevron() { return `<span class="chev">›</span>`; }

function choicesBlock(choices) {
  return `<style>
    .choice{display:flex;align-items:center;justify-content:space-between;
      border:1px solid ${C.mist};border-radius:10px;padding:14px 14px;margin-bottom:10px;font-size:16px;line-height:1.3}
    .choice .ic{font-size:19px;margin-left:12px}
  </style>${choices}`;
}

function stat(value, label, color) {
  return `<div style="flex:1;text-align:center">
    <div style="font-size:24px;font-weight:600;font-variant-numeric:tabular-nums;${color ? `color:${color}` : ''}">${value}</div>
    <div style="font-size:13px;color:${C.sec};margin-top:2px">${label}</div>
  </div>`;
}

function page(inner) {
  return `<!doctype html><html><head><meta charset="utf-8"><style>${BASE}</style></head>
    <body><div class="screen">${inner}</div></body></html>`;
}

// Build the screen set for one app. `app` = { dir, name }.
function buildScreens(app) {
  const CONTENT = path.resolve(__dirname, '../../Apps', app.dir, 'Content');
  const quiz = JSON.parse(fs.readFileSync(path.join(CONTENT, 'quiz.json'), 'utf8'));
  const gsPath = path.join(CONTENT, 'groundschool.json');
  const hasGS = fs.existsSync(gsPath);
  const gs = hasGS ? JSON.parse(fs.readFileSync(gsPath, 'utf8')) : null;
  const name = app.name;

  // A bank that's safe to reference on every module (ELPT ships a single bank).
  const examBank = quiz.banks[Math.min(2, quiz.banks.length - 1)];

  function home() {
    const quizRows = quiz.banks.slice(0, 4).map(b =>
      `<div class="row"><div class="lead"><span class="t">${b.title}</span><span class="s">${b.questions.length} questions</span></div>${chevron()}</div>`).join('');
    const studySection = hasGS
      ? `<div class="section-hdr">Study</div>
         <div class="card">${gs.modules.slice(0, 3).map(m =>
            `<div class="row"><div class="lead"><span class="t">${m.title}</span></div>${chevron()}</div>`).join('')}</div>`
      : `<div class="section-hdr">Practice</div>
         <div class="card">
           <div class="row"><span class="t" style="font-size:17px">Flashcards — spaced repetition</span>${chevron()}</div>
           <div class="row"><span class="t" style="font-size:17px">Quiz — all questions</span>${chevron()}</div>
         </div>`;
    return page(`
      ${statusbar()}
      <div class="navbar large"><div class="title">${name}</div></div>
      <div class="body">
        ${studySection}
        <div class="section-hdr">Quiz by topic</div>
        <div class="card">${quizRows}</div>
        <div class="section-hdr">Exam</div>
        <div class="card">
          <div class="row"><span class="t" style="font-size:17px">Mock exam (untimed)</span>${chevron()}</div>
          <div class="row"><span class="t" style="font-size:17px">Timed exam — 30 min, pass 75%</span>${chevron()}</div>
        </div>
      </div>
    `);
  }

  function quizBanks() {
    const rows = quiz.banks.slice(0, 8).map(b =>
      `<div class="row"><div class="lead"><span class="t">${b.title}</span><span class="s">${b.questions.length} questions</span></div>${chevron()}</div>`).join('');
    return page(`
      ${statusbar()}
      <div class="navbar"><div class="back">‹ ${name}</div><div class="mid">Quiz by topic</div></div>
      <div class="body"><div class="card">${rows}</div></div>
    `);
  }

  function quizQuestion() {
    const q = quiz.banks[0].questions[0];
    const choices = q.options.map(o =>
      `<div class="choice"><span>${o}</span><span class="ic" style="color:${C.ter}">○</span></div>`).join('');
    return page(`
      ${statusbar()}
      <div class="navbar"><div class="back">‹ Quiz by topic</div><div class="mid">${quiz.banks[0].title}</div></div>
      <div class="body" style="overflow:hidden">
        <div style="padding:8px 6px">
          <div style="font-size:13px;color:${C.sec};margin-bottom:14px">Question 1 of ${quiz.banks[0].questions.length}</div>
          <div style="font-size:17px;font-weight:600;line-height:1.35;margin-bottom:20px">${q.q}</div>
          ${choicesBlock(choices)}
          <button class="tealbtn" style="margin-top:22px;opacity:0.5">Next</button>
        </div>
      </div>
    `);
  }

  function quizAnswered() {
    const q = quiz.banks[0].questions[0];
    const choices = q.options.map((o, i) => {
      if (i === q.answer) return `<div class="choice" style="border-color:${C.sage}"><span>${o}</span><span class="ic" style="color:${C.sage}">✓</span></div>`;
      return `<div class="choice"><span>${o}</span><span class="ic" style="color:${C.ter}">○</span></div>`;
    }).join('');
    return page(`
      ${statusbar()}
      <div class="navbar"><div class="back">‹ Quiz by topic</div><div class="mid">${quiz.banks[0].title}</div></div>
      <div class="body" style="overflow:hidden">
        <div style="padding:8px 6px">
          <div style="font-size:13px;color:${C.sec};margin-bottom:14px">Question 1 of ${quiz.banks[0].questions.length}</div>
          <div style="font-size:17px;font-weight:600;line-height:1.35;margin-bottom:20px">${q.q}</div>
          ${choicesBlock(choices)}
          <div style="border:1px solid ${C.mist};border-radius:10px;padding:14px;margin-top:18px">
            <div style="color:${C.sage};font-weight:600;font-size:15px;margin-bottom:6px">Correct</div>
            <div style="font-size:15px;line-height:1.4;margin-bottom:8px">${q.explain}</div>
            <div style="font-size:13px;color:${C.sec}">${q.cite}</div>
          </div>
          <button class="tealbtn" style="margin-top:18px">Next</button>
        </div>
      </div>
    `);
  }

  function flashcard(revealed) {
    const q = quiz.banks[0].questions[1];
    const front = q.q;
    const back = `${q.options[q.answer]}\n\n${q.explain}`;
    const cardInner = revealed
      ? `<div style="font-size:16px;line-height:1.5;white-space:pre-line">${back}</div>`
      : `<div style="font-size:19px;font-weight:600;line-height:1.4">${front}</div>`;
    const controls = revealed
      ? `<div style="display:flex;gap:12px;margin-top:16px">
           <button style="flex:1;background:transparent;border:1px solid ${C.clay};color:${C.clay};border-radius:12px;padding:14px;font-size:16px;font-weight:600">Again</button>
           <button style="flex:1;background:${C.teal};border:none;color:#fff;border-radius:12px;padding:14px;font-size:16px;font-weight:600">Got it</button>
         </div>`
      : `<div style="text-align:center;font-size:13px;color:${C.sec};margin-top:16px">Tap the card to reveal</div>`;
    return page(`
      ${statusbar()}
      <div class="navbar"><div class="back">‹ Flashcards</div><div class="mid">${quiz.banks[0].title}</div></div>
      <div class="body" style="display:flex;flex-direction:column;padding:20px 22px">
        <div style="text-align:center;font-size:13px;color:${C.sec};margin-bottom:18px">2 of ${quiz.banks[0].questions.length}</div>
        <div style="background:${C.deep};border-radius:16px;min-height:300px;display:flex;align-items:center;justify-content:center;text-align:center;padding:28px">
          ${cardInner}
        </div>
        ${controls}
      </div>
    `);
  }

  function timedStart() {
    const q = examBank.questions[0];
    const choices = q.options.map(o => `<div class="choice"><span>${o}</span><span class="ic" style="color:${C.ter}">○</span></div>`).join('');
    return page(`
      ${statusbar()}
      <div class="navbar"><div class="back" style="justify-content:space-between;display:flex;width:100%">‹ ${name} <span style="color:${C.sec};font-weight:600;font-variant-numeric:tabular-nums">30:00</span></div><div class="mid">GACAR Knowledge — Mock Exam</div></div>
      <div class="body" style="overflow:hidden">
        <div style="padding:8px 6px">
          <div style="font-size:13px;color:${C.sec};margin-bottom:14px">Question 1 of 25</div>
          <div style="font-size:17px;font-weight:600;line-height:1.35;margin-bottom:20px">${q.q}</div>
          ${choicesBlock(choices)}
        </div>
      </div>
    `);
  }

  function timedActive() {
    const q = examBank.questions[1] || examBank.questions[0];
    const choices = q.options.map((o, i) => i === 1
      ? `<div class="choice" style="border-color:${C.teal}"><span>${o}</span><span class="ic" style="color:${C.teal}">◉</span></div>`
      : `<div class="choice"><span>${o}</span><span class="ic" style="color:${C.ter}">○</span></div>`).join('');
    return page(`
      ${statusbar()}
      <div class="navbar"><div class="back" style="justify-content:space-between;display:flex;width:100%">‹ Exam <span style="color:${C.clay};font-weight:700;font-variant-numeric:tabular-nums">0:48</span></div><div class="mid">GACAR Knowledge — Mock Exam</div></div>
      <div class="body" style="overflow:hidden">
        <div style="padding:8px 6px">
          <div style="font-size:13px;color:${C.sec};margin-bottom:14px">Question 12 of 25</div>
          <div style="font-size:17px;font-weight:600;line-height:1.35;margin-bottom:20px">${q.q}</div>
          ${choicesBlock(choices)}
          <button class="tealbtn" style="margin-top:20px">Next</button>
        </div>
      </div>
    `);
  }

  function results() {
    const banks = quiz.banks.slice(0, 6);
    const tots = [4, 5, 3, 4, 5, 4], cors = [4, 4, 3, 3, 5, 3];
    const rows = banks.map((b, i) =>
      `<div class="row"><span style="font-size:16px">${b.title}</span><span style="color:${C.sec};font-variant-numeric:tabular-nums">${cors[i]}/${tots[i]}</span></div>`).join('');
    return page(`
      ${statusbar()}
      <div class="navbar"><div class="back">‹ ${name}</div><div class="mid">Results</div></div>
      <div class="body">
        <div class="card" style="margin-top:6px">
          <div style="display:flex;padding:22px 8px">
            ${stat('82%', 'Score')}${stat('22/25', 'Correct')}${stat('Pass', 'Result', C.sage)}
          </div>
        </div>
        <div class="section-hdr">By topic</div>
        <div class="card">${rows}</div>
      </div>
    `);
  }

  function lessons() {
    const m = gs.modules[0];
    const rows = m.lessons.slice(0, 6).map(l =>
      `<div class="row" style="align-items:flex-start"><div class="lead"><span class="t" style="font-weight:600">${l.title}</span><span class="s" style="line-height:1.4">${l.objective}</span></div></div>`).join('');
    return page(`
      ${statusbar()}
      <div class="navbar"><div class="back">‹ ${name}</div><div class="mid">${m.title}</div></div>
      <div class="body">
        <div class="card" style="margin-top:6px"><div style="padding:14px 16px;font-size:15px;color:${C.sec};line-height:1.45">${m.summary}</div></div>
        <div class="card" style="margin-top:14px">${rows}</div>
      </div>
    `);
  }

  const set = {
    '01-home': home,
    '02-quiz-banks': quizBanks,
    '03-quiz-question': quizQuestion,
    '04-quiz-answered': quizAnswered,
    '05-flashcard-front': () => flashcard(false),
    '06-flashcard-back': () => flashcard(true),
    '07-timed-exam-start': timedStart,
    '08-timed-exam-timer': timedActive,
    '09-mock-results': results,
  };
  if (hasGS) set['10-lessons-list'] = lessons;
  return set;
}

module.exports = { buildScreens };
