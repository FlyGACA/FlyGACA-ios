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
