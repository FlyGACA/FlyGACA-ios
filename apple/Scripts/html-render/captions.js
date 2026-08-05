// Marketing-caption layer for the App Store screenshot renderer.
//
// The base screens (screens.js) are faithful, caption-less recreations of the
// shipping SwiftUI views. For the store, each shot gets a value-prop caption
// band (Falcon palette) above the device, and the set is reordered value-prop
// first (hero -> scored exam -> results -> the study loop). render-store.js
// consumes this; the original render.js (raw screens) is left untouched.
//
// Captions localize per storefront locale (`en`, `ar`). The base screens do NOT
// localize — the shipping iOS UI is English-only (FlyGACAKit has no Arabic
// localization), so the Arabic set is Arabic/RTL *captions* over the real
// English app screens, never a fabricated Arabic UI.

const C = { night: '#0A0E12', sage: '#8FC9A8', white: '#FFFFFF', sec: 'rgba(235,240,245,0.55)', mist: '#1A2A38' };

const FONT = {
  en: "-apple-system,'SF Pro Display','Helvetica Neue',Arial,sans-serif",
  ar: "'SF Arabic','Geeza Pro','Noto Naskh Arabic',-apple-system,'Helvetica Neue',Arial,sans-serif",
};

// Compose one captioned shot: caption band on top, the real screen below in a
// device bezel, scaled to fit. W/H are the slot's logical pixels. opts.rtl lays
// the caption out right-to-left for Arabic (the embedded screen stays LTR).
function compose(screenDoc, head, sub, W, H, opts = {}) {
  const rtl = !!opts.rtl;
  const srcdoc = screenDoc.replace(/&/g, '&amp;').replace(/"/g, '&quot;');
  const capH = Math.round(H * 0.24);
  const s = (H - capH - Math.round(H * 0.05)) / H;
  const sw = Math.round(W * s), sh = Math.round(H * s);
  const headPx = Math.round(W * 0.077), subPx = Math.round(W * 0.038), padX = Math.round(W * 0.084);
  return `<!doctype html><html${rtl ? ' dir="rtl" lang="ar"' : ''}><head><meta charset="utf-8"><style>
    *{margin:0;padding:0;box-sizing:border-box;-webkit-font-smoothing:antialiased}
    html,body{width:${W}px;height:${H}px}
    body{background:${C.night};${rtl ? 'direction:rtl;' : ''}font-family:${rtl ? FONT.ar : FONT.en};
      color:${C.white};overflow:hidden;display:flex;flex-direction:column}
    .cap{height:${capH}px;flex:none;display:flex;flex-direction:column;justify-content:flex-end;
      ${rtl ? 'align-items:flex-end;text-align:right;' : ''}padding:0 ${padX}px ${Math.round(capH * 0.11)}px}
    .kl{width:${Math.round(W * 0.10)}px;height:${Math.round(W * 0.012)}px;background:${C.sage};
      border-radius:3px;margin-bottom:${Math.round(H * 0.021)}px}
    .cap h1{font-size:${headPx}px;line-height:${rtl ? '1.2' : '1.12'};font-weight:700;${rtl ? '' : 'letter-spacing:-0.02em;'}}
    .cap p{margin-top:${Math.round(H * 0.015)}px;font-size:${subPx}px;line-height:${rtl ? '1.5' : '1.4'};color:${C.sec};
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

// Shot order + shot-level captions per locale. `screen` names a key from
// buildScreens(); `name` is the output filename (numeric prefix = store order).
// The hero (01) is per-app; the rest are shared across apps.
const SHOTS = {
  '01-home':            { screen: '01-home',            hero: true },
  '02-timed-exam':      { screen: '08-timed-exam-timer',
    en: { head: 'Sit the real exam', sub: 'A timed mock under exam conditions — 30 minutes, 75% to pass.' },
    ar: { head: 'اختبر في ظروفٍ حقيقية', sub: 'محاكاة اختبار مؤقّتة — ٣٠ دقيقة، ونسبة النجاح ٧٥٪.' } },
  '03-results':         { screen: '09-mock-results',
    en: { head: 'Know when you’re ready', sub: 'Per-topic analytics and a pass score after every mock exam.' },
    ar: { head: 'اعرف متى تصبح جاهزاً', sub: 'تحليلات لكل موضوع ونتيجة نجاح بعد كل محاكاة اختبار.' } },
  '04-quiz-topics':     { screen: '02-quiz-banks',
    en: { head: 'Study by topic', sub: 'Focused question banks across the whole syllabus.' },
    ar: { head: 'ادرس حسب الموضوع', sub: 'بنوك أسئلة مركّزة تغطّي المنهج كاملاً.' } },
  '05-quiz-question':   { screen: '03-quiz-question',
    en: { head: 'Practice anywhere', sub: 'Work the bank fully offline — no signal needed.' },
    ar: { head: 'تدرّب في أي مكان', sub: 'استخدم البنك بالكامل ودون إنترنت.' } },
  '06-quiz-explained':  { screen: '04-quiz-answered',
    en: { head: 'Every answer, cited', sub: 'The correct choice, the why, and the exact GACAR Part and section.' },
    ar: { head: 'كل إجابة موثّقة', sub: 'الخيار الصحيح، والسبب، ومادة GACAR بالضبط.' } },
  '07-flashcard':       { screen: '05-flashcard-front',
    en: { head: 'Flashcards that stick', sub: 'Spaced repetition brings back what you’re about to forget.' },
    ar: { head: 'بطاقات تثبّت المعلومة', sub: 'التكرار المتباعد يعيد ما أوشكت على نسيانه.' } },
  '08-flashcard-answer': { screen: '06-flashcard-back',
    en: { head: 'Learn the reasoning', sub: 'Front and back — the rule and the reference, together.' },
    ar: { head: 'افهم السبب', sub: 'الوجه والظهر — القاعدة ومرجعها معاً.' } },
  '09-exam-start':      { screen: '07-timed-exam-start',
    en: { head: 'Exam conditions', sub: '25 questions, 30 minutes — one pass through, just like the day.' },
    ar: { head: 'ظروف اختبار حقيقية', sub: '٢٥ سؤالاً في ٣٠ دقيقة — محاولة واحدة، كما في يوم الاختبار.' } },
  '10-lessons':         { screen: '10-lessons-list', optional: true,
    en: { head: 'Ground school built in', sub: 'Structured lessons with an objective for every topic.' },
    ar: { head: 'دورة أرضية مدمجة', sub: 'دروس منظّمة بهدفٍ لكل موضوع.' } },
};
const ORDER = Object.keys(SHOTS);

// Per-app hero copy, per locale.
const HERO = {
  en: {
    PPL:  { head: 'The Saudi PPL exam,<br>in your pocket',  sub: 'The full question bank, offline — every answer cites the exact GACAR.' },
    CPL:  { head: 'The Saudi CPL exam,<br>in your pocket',  sub: 'Commercial-pilot theory, offline — every answer cites the exact GACAR.' },
    IR:   { head: 'The Saudi Instrument<br>Rating, mastered', sub: 'IFR rules and procedures, offline — every answer cites the exact GACAR.' },
    ATPL: { head: 'The Saudi ATPL exam,<br>in your pocket', sub: 'Airline-transport theory, offline — every answer cites the exact GACAR.' },
    ELPT: { head: 'Aviation English,<br>exam-ready',        sub: 'ICAO Level 4 prep — phraseology and comprehension, fully offline.' },
    AIP:  { head: 'The Saudi AIP,<br>made studyable',       sub: 'Aerodromes, airspace and charts — offline, and always cited.' },
  },
  ar: {
    PPL:  { head: 'رخصة الطيار الخاص السعودية،<br>في جيبك', sub: 'بنك الأسئلة كاملاً وبدون إنترنت — كل إجابة تستند إلى مادة GACAR بدقّة.' },
    CPL:  { head: 'رخصة الطيار التجاري السعودية،<br>في جيبك', sub: 'النظري التجاري كاملاً وبدون إنترنت — كل إجابة تستند إلى مادة GACAR.' },
    IR:   { head: 'تقدير الطيران الآلي السعودي،<br>بين يديك', sub: 'قواعد وإجراءات الطيران الآلي بدون إنترنت — كل إجابة تستند إلى مادة GACAR.' },
    ATPL: { head: 'رخصة طيار النقل الجوي السعودية،<br>في جيبك', sub: 'نظري النقل الجوي كاملاً وبدون إنترنت — كل إجابة تستند إلى مادة GACAR.' },
    ELPT: { head: 'الإنجليزية للطيران،<br>جاهزٌ للاختبار', sub: 'تحضير مستوى الإيكاو الرابع — المصطلحات والاستيعاب، بدون إنترنت.' },
    AIP:  { head: 'دليل الطيران السعودي (AIP)،<br>سهل الدراسة', sub: 'المطارات والمجال الجوي والخرائط — بدون إنترنت، وموثّقة دائماً.' },
  },
};

// Ordered captions for one app in one locale. lang: 'en' (default) | 'ar'.
function captionsFor(dir, lang = 'en') {
  const L = HERO[lang] ? lang : 'en';
  return ORDER.map((name) => {
    const shot = SHOTS[name];
    const copy = shot.hero ? (HERO[L][dir] || HERO[L].PPL) : shot[L];
    return { name, screen: shot.screen, optional: !!shot.optional, head: copy.head, sub: copy.sub };
  });
}

module.exports = { compose, captionsFor, SHOTS, HERO, rtlFor: (lang) => lang === 'ar' };
