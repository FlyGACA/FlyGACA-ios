// Faithful HTML recreations of the FlyGACA iOS screens using the exact Falcon
// palette (FlyGACAKit/Sources/FeatureUI/Theme.swift) and each app's real bundled
// GACAR content. Rendered to PNG at App Store device resolutions via Playwright +
// the pre-installed Chromium (see render.js).
//
// The chrome is identical across every app in the family (they share FeatureUI),
// so per-app screenshots differ only by the module's own banks/questions/lessons
// and its display name — an honest mirror of the shipping app. `buildScreens(app,
// lang)` loads `apple/Apps/<app.dir>/Content` and returns the screen set for that
// module; ground-school screens are included only when the module ships
// groundschool.json (no current module ships it — the screen stays dormant).
//
// Localization: `lang` ('en' | 'ar') localizes the UI *chrome* to match the
// shipping bilingual FlyGACAKit UI (Resources/{en,ar}.lproj/Localizable.strings) —
// Arabic renders RTL. The English values below are the exact current chrome
// literals, so `lang: 'en'` reproduces the prior output byte-for-byte. Bundled
// CONTENT (question prompts, options, bank titles, citations, lesson text) stays
// English in every locale — it is monorepo-generated, not translated here.

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

// Arabic system font stack — mirrors captions.js FONT.ar (SF Arabic on Apple).
const FONT_AR = "'SF Arabic','Geeza Pro','Noto Naskh Arabic',-apple-system,'Helvetica Neue',Arial,sans-serif";

// UI-chrome strings, per locale. EN values are the exact prior literals (so the
// en set is unchanged); AR values are verbatim from FeatureUI ar.lproj, except
// six strings with no lproj key — marked [decided] — kept consistent with the
// caption copy in captions.js.
const STRINGS = {
  en: {
    study: 'Study', practice: 'Practice', quizByTopic: 'Quiz by topic',
    flashcards: 'Flashcards', flashcardsSpaced: 'Flashcards — spaced repetition',
    quizAll: 'Quiz — all questions', exam: 'Exam',
    mockUntimed: 'Mock exam (untimed)', timedExam: 'Timed exam — 30 min, pass 75%',
    next: 'Next', correct: 'Correct', again: 'Again', gotIt: 'Got it',
    tapToReveal: 'Tap the card to reveal', examTitle: 'GACAR Knowledge — Mock Exam',
    score: 'Score', resultCorrect: 'Correct', result: 'Result', pass: 'Pass',
    results: 'Results', byTopic: 'By topic',
    questionCount: (n) => `${n} questions`,
    questionProgress: (a, b) => `Question ${a} of ${b}`,
    cardProgress: (a, b) => `${a} of ${b}`,
    simTitle: 'Scenario simulator', transcript: 'RADIO EXCHANGE',
  },
  ar: {
    study: 'الدراسة', practice: 'تدريب' /* [decided] */, quizByTopic: 'اختبار حسب الموضوع',
    flashcards: 'البطاقات التعليمية',
    flashcardsSpaced: 'البطاقات التعليمية — التكرار المتباعد' /* [decided] */,
    quizAll: 'اختبار — كل الأسئلة' /* [decided] */, exam: 'الاختبار',
    mockUntimed: 'اختبار تجريبي (غير مؤقّت)', timedExam: 'اختبار مؤقّت — 30 دقيقة، النجاح 75%',
    next: 'التالي', correct: 'إجابة صحيحة', again: 'إعادة', gotIt: 'أتقنتها',
    tapToReveal: 'انقر البطاقة لإظهار الإجابة',
    examTitle: 'اختبار تجريبي' /* [decided]: localized mock title, not the EN composite */,
    score: 'الدرجة', resultCorrect: 'الصحيحة', result: 'النتيجة', pass: 'ناجح',
    results: 'النتائج' /* [decided]: plural of result.result */, byTopic: 'حسب الموضوع',
    questionCount: (n) => `${n} سؤال`,
    questionProgress: (a, b) => `السؤال ${a} من ${b}`,
    cardProgress: (a, b) => `${a} من ${b}`,
    simTitle: 'محاكي السيناريوهات', transcript: 'تبادل لاسلكي',
  },
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

function chevron(rtl) { return `<span class="chev">${rtl ? '‹' : '›'}</span>`; }

function choicesBlock(choices) {
  return `<style>
    .choice{display:flex;align-items:center;justify-content:space-between;
      border:1px solid ${C.mist};border-radius:10px;padding:14px 14px;margin-bottom:10px;font-size:16px;line-height:1.3}
    .choice .ic{font-size:19px;margin-inline-start:12px}
  </style>${choices}`;
}

function stat(value, label, color) {
  return `<div style="flex:1;text-align:center">
    <div style="font-size:24px;font-weight:600;font-variant-numeric:tabular-nums;${color ? `color:${color}` : ''}">${value}</div>
    <div style="font-size:13px;color:${C.sec};margin-top:2px">${label}</div>
  </div>`;
}

function page(inner, rtl) {
  const font = rtl ? ` body { font-family:${FONT_AR}; }` : '';
  return `<!doctype html><html${rtl ? ' dir="rtl" lang="ar"' : ''}><head><meta charset="utf-8"><style>${BASE}${font}</style></head>
    <body><div class="screen">${inner}</div></body></html>`;
}

// Build the screen set for one app. `app` = { dir, name }. `lang` = 'en' | 'ar'.
function buildScreens(app, lang = 'en') {
  const CONTENT = path.resolve(__dirname, '../../Apps', app.dir, 'Content');
  const quiz = JSON.parse(fs.readFileSync(path.join(CONTENT, 'quiz.json'), 'utf8'));
  // App-local additive pack (mirrors ContentLoader.extraBanks): merged after the
  // synced corpus so e.g. ELPT's scenario bank renders in its screenshots.
  const extraPath = path.join(CONTENT, 'quiz-extra.json');
  if (fs.existsSync(extraPath)) {
    const extra = JSON.parse(fs.readFileSync(extraPath, 'utf8'));
    quiz.banks = quiz.banks.concat(extra.banks || []);
  }
  const gsPath = path.join(CONTENT, 'groundschool.json');
  const hasGS = fs.existsSync(gsPath);
  const gs = hasGS ? JSON.parse(fs.readFileSync(gsPath, 'utf8')) : null;
  const name = app.name;
  const t = STRINGS[lang] || STRINGS.en;
  const rtl = lang === 'ar';
  const arrow = rtl ? '›' : '‹';   // back-chevron points toward the reading start

  // A bank that's safe to reference on every module (ELPT ships a single bank).
  const examBank = quiz.banks[Math.min(2, quiz.banks.length - 1)];

  function home() {
    const quizRows = quiz.banks.slice(0, 4).map(b =>
      `<div class="row"><div class="lead"><span class="t">${b.title}</span><span class="s">${t.questionCount(b.questions.length)}</span></div>${chevron(rtl)}</div>`).join('');
    const studySection = hasGS
      ? `<div class="section-hdr">${t.study}</div>
         <div class="card">${gs.modules.slice(0, 3).map(m =>
            `<div class="row"><div class="lead"><span class="t">${m.title}</span></div>${chevron(rtl)}</div>`).join('')}</div>`
      : `<div class="section-hdr">${t.practice}</div>
         <div class="card">
           <div class="row"><span class="t" style="font-size:17px">${t.flashcardsSpaced}</span>${chevron(rtl)}</div>
           <div class="row"><span class="t" style="font-size:17px">${t.quizAll}</span>${chevron(rtl)}</div>
         </div>`;
    return page(`
      ${statusbar()}
      <div class="navbar large"><div class="title">${name}</div></div>
      <div class="body">
        ${studySection}
        <div class="section-hdr">${t.quizByTopic}</div>
        <div class="card">${quizRows}</div>
        <div class="section-hdr">${t.exam}</div>
        <div class="card">
          <div class="row"><span class="t" style="font-size:17px">${t.mockUntimed}</span>${chevron(rtl)}</div>
          <div class="row"><span class="t" style="font-size:17px">${t.timedExam}</span>${chevron(rtl)}</div>
        </div>
      </div>
    `, rtl);
  }

  function quizBanks() {
    const rows = quiz.banks.slice(0, 8).map(b =>
      `<div class="row"><div class="lead"><span class="t">${b.title}</span><span class="s">${t.questionCount(b.questions.length)}</span></div>${chevron(rtl)}</div>`).join('');
    return page(`
      ${statusbar()}
      <div class="navbar"><div class="back">${arrow} ${name}</div><div class="mid">${t.quizByTopic}</div></div>
      <div class="body"><div class="card">${rows}</div></div>
    `, rtl);
  }

  function quizQuestion() {
    const q = quiz.banks[0].questions[0];
    const choices = q.options.map(o =>
      `<div class="choice"><span>${o}</span><span class="ic" style="color:${C.ter}">○</span></div>`).join('');
    return page(`
      ${statusbar()}
      <div class="navbar"><div class="back">${arrow} ${t.quizByTopic}</div><div class="mid">${quiz.banks[0].title}</div></div>
      <div class="body" style="overflow:hidden">
        <div style="padding:8px 6px">
          <div style="font-size:13px;color:${C.sec};margin-bottom:14px">${t.questionProgress(1, quiz.banks[0].questions.length)}</div>
          <div style="font-size:17px;font-weight:600;line-height:1.35;margin-bottom:20px">${q.q}</div>
          ${choicesBlock(choices)}
          <button class="tealbtn" style="margin-top:22px;opacity:0.5">${t.next}</button>
        </div>
      </div>
    `, rtl);
  }

  function quizAnswered() {
    const q = quiz.banks[0].questions[0];
    const choices = q.options.map((o, i) => {
      if (i === q.answer) return `<div class="choice" style="border-color:${C.sage}"><span>${o}</span><span class="ic" style="color:${C.sage}">✓</span></div>`;
      return `<div class="choice"><span>${o}</span><span class="ic" style="color:${C.ter}">○</span></div>`;
    }).join('');
    return page(`
      ${statusbar()}
      <div class="navbar"><div class="back">${arrow} ${t.quizByTopic}</div><div class="mid">${quiz.banks[0].title}</div></div>
      <div class="body" style="overflow:hidden">
        <div style="padding:8px 6px">
          <div style="font-size:13px;color:${C.sec};margin-bottom:14px">${t.questionProgress(1, quiz.banks[0].questions.length)}</div>
          <div style="font-size:17px;font-weight:600;line-height:1.35;margin-bottom:20px">${q.q}</div>
          ${choicesBlock(choices)}
          <div style="border:1px solid ${C.mist};border-radius:10px;padding:14px;margin-top:18px">
            <div style="color:${C.sage};font-weight:600;font-size:15px;margin-bottom:6px">${t.correct}</div>
            <div style="font-size:15px;line-height:1.4;margin-bottom:8px">${q.explain}</div>
            <div style="font-size:13px;color:${C.sec}">${q.cite}</div>
          </div>
          <button class="tealbtn" style="margin-top:18px">${t.next}</button>
        </div>
      </div>
    `, rtl);
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
           <button style="flex:1;background:transparent;border:1px solid ${C.clay};color:${C.clay};border-radius:12px;padding:14px;font-size:16px;font-weight:600">${t.again}</button>
           <button style="flex:1;background:${C.teal};border:none;color:#fff;border-radius:12px;padding:14px;font-size:16px;font-weight:600">${t.gotIt}</button>
         </div>`
      : `<div style="text-align:center;font-size:13px;color:${C.sec};margin-top:16px">${t.tapToReveal}</div>`;
    return page(`
      ${statusbar()}
      <div class="navbar"><div class="back">${arrow} ${t.flashcards}</div><div class="mid">${quiz.banks[0].title}</div></div>
      <div class="body" style="display:flex;flex-direction:column;padding:20px 22px">
        <div style="text-align:center;font-size:13px;color:${C.sec};margin-bottom:18px">${t.cardProgress(2, quiz.banks[0].questions.length)}</div>
        <div style="background:${C.deep};border-radius:16px;min-height:300px;display:flex;align-items:center;justify-content:center;text-align:center;padding:28px">
          ${cardInner}
        </div>
        ${controls}
      </div>
    `, rtl);
  }

  function timedStart() {
    const q = examBank.questions[0];
    const choices = q.options.map(o => `<div class="choice"><span>${o}</span><span class="ic" style="color:${C.ter}">○</span></div>`).join('');
    return page(`
      ${statusbar()}
      <div class="navbar"><div class="back" style="justify-content:space-between;display:flex;width:100%">${arrow} ${name} <span style="color:${C.sec};font-weight:600;font-variant-numeric:tabular-nums">30:00</span></div><div class="mid">${t.examTitle}</div></div>
      <div class="body" style="overflow:hidden">
        <div style="padding:8px 6px">
          <div style="font-size:13px;color:${C.sec};margin-bottom:14px">${t.questionProgress(1, 25)}</div>
          <div style="font-size:17px;font-weight:600;line-height:1.35;margin-bottom:20px">${q.q}</div>
          ${choicesBlock(choices)}
        </div>
      </div>
    `, rtl);
  }

  function timedActive() {
    const q = examBank.questions[1] || examBank.questions[0];
    const choices = q.options.map((o, i) => i === 1
      ? `<div class="choice" style="border-color:${C.teal}"><span>${o}</span><span class="ic" style="color:${C.teal}">◉</span></div>`
      : `<div class="choice"><span>${o}</span><span class="ic" style="color:${C.ter}">○</span></div>`).join('');
    return page(`
      ${statusbar()}
      <div class="navbar"><div class="back" style="justify-content:space-between;display:flex;width:100%">${arrow} ${t.exam} <span style="color:${C.clay};font-weight:700;font-variant-numeric:tabular-nums">0:48</span></div><div class="mid">${t.examTitle}</div></div>
      <div class="body" style="overflow:hidden">
        <div style="padding:8px 6px">
          <div style="font-size:13px;color:${C.sec};margin-bottom:14px">${t.questionProgress(12, 25)}</div>
          <div style="font-size:17px;font-weight:600;line-height:1.35;margin-bottom:20px">${q.q}</div>
          ${choicesBlock(choices)}
          <button class="tealbtn" style="margin-top:20px">${t.next}</button>
        </div>
      </div>
    `, rtl);
  }

  function results() {
    const banks = quiz.banks.slice(0, 6);
    const tots = [4, 5, 3, 4, 5, 4], cors = [4, 4, 3, 3, 5, 3];
    const rows = banks.map((b, i) =>
      `<div class="row"><span style="font-size:16px">${b.title}</span><span style="color:${C.sec};font-variant-numeric:tabular-nums">${cors[i]}/${tots[i]}</span></div>`).join('');
    return page(`
      ${statusbar()}
      <div class="navbar"><div class="back">${arrow} ${name}</div><div class="mid">${t.results}</div></div>
      <div class="body">
        <div class="card" style="margin-top:6px">
          <div style="display:flex;padding:22px 8px">
            ${stat('82%', t.score)}${stat('22/25', t.resultCorrect)}${stat(t.pass, t.result, C.sage)}
          </div>
        </div>
        <div class="section-hdr">${t.byTopic}</div>
        <div class="card">${rows}</div>
      </div>
    `, rtl);
  }

  function lessons() {
    const m = gs.modules[0];
    const rows = m.lessons.slice(0, 6).map(l =>
      `<div class="row" style="align-items:flex-start"><div class="lead"><span class="t" style="font-weight:600">${l.title}</span><span class="s" style="line-height:1.4">${l.objective}</span></div></div>`).join('');
    return page(`
      ${statusbar()}
      <div class="navbar"><div class="back">${arrow} ${name}</div><div class="mid">${m.title}</div></div>
      <div class="body">
        <div class="card" style="margin-top:6px"><div style="padding:14px 16px;font-size:15px;color:${C.sec};line-height:1.45">${m.summary}</div></div>
        <div class="card" style="margin-top:14px">${rows}</div>
      </div>
    `, rtl);
  }

  // Scenario question prompt = leading blocks whose lines are all
  // speaker-prefixed (verbatim of ScenarioSimulatorView.isScenario).
  function scenarioParts(q) {
    const blocks = q.q.split('\n\n');
    if (blocks.length < 2) return null;
    const transcript = [];
    for (const b of blocks) {
      const lines = b.split('\n').filter(Boolean);
      if (lines.length && lines.every((l) => /^[A-Z0-9 /]{1,12}:/.test(l))) transcript.push(...lines);
      else return transcript.length ? { transcript, question: b } : null;
    }
    return null;
  }

  function scenarioSim() {
    let pick = null;
    for (const b of quiz.banks) for (const q of b.questions) {
      const parts = scenarioParts(q);
      if (parts) { pick = { q, parts }; break; }
    }
    if (!pick) return null;
    const { q, parts } = pick;
    const lines = parts.transcript.map((l) => {
      const i = l.indexOf(':');
      return `<div style="margin-bottom:8px;line-height:1.45"><span style="color:${C.sage};font-weight:700">${l.slice(0, i + 1)}</span><span>${l.slice(i + 1)}</span></div>`;
    }).join('');
    const badges = ['A', 'B', 'C', 'D'];
    const choices = q.options.map((o, i) =>
      `<div class="choice" style="justify-content:flex-start;gap:12px"><span style="flex:none;width:26px;height:26px;border-radius:13px;border:1.5px solid ${C.mist};color:${C.sec};font-size:14px;font-weight:700;display:flex;align-items:center;justify-content:center">${badges[i]}</span><span>${o}</span></div>`).join('');
    return page(`
      ${statusbar()}
      <div class="navbar"><div class="back">${arrow} ${name}</div><div class="mid">${t.simTitle}</div></div>
      <div class="body" style="overflow:hidden">
        <div style="padding:8px 6px">
          <div style="display:flex;align-items:center;gap:10px;margin-bottom:16px">
            <span style="font-size:13px;color:${C.sec}">${t.questionProgress(3, 10)}</span>
            <span style="flex:1;height:6px;border-radius:3px;background:${C.mist};overflow:hidden;display:block"><span style="display:block;width:30%;height:100%;border-radius:3px;background:${C.teal}"></span></span>
          </div>
          <div style="background:${C.deep};border:1px solid ${C.mist};border-radius:12px;padding:14px 14px 6px;margin-bottom:16px">
            <div style="font-size:11px;font-weight:700;letter-spacing:0.08em;color:${C.teal};margin-bottom:10px">◉ ${t.transcript}</div>
            <div style="font-size:15px">${lines}</div>
          </div>
          <div style="font-size:17px;font-weight:600;line-height:1.35;margin-bottom:20px">${parts.question}</div>
          ${choicesBlock(choices)}
        </div>
      </div>
    `, rtl);
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
  // Only present when the module ships scenario content (today: ELPT's
  // quiz-extra.json). captions.js marks the shot optional, so other modules
  // skip it automatically.
  const hasScenario = quiz.banks.some((b) => b.questions.some((q) => scenarioParts(q)));
  if (hasScenario) set['11-scenario-sim'] = scenarioSim;
  return set;
}

module.exports = { buildScreens };
