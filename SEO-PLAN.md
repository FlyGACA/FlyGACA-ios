# SEO-PLAN — App Store search (ASO) for the Fly GACA iOS family

The live, checkbox-tracked backlog for **store search visibility** of the six apps (PPL, ELPT,
AIP, CPL, IR, ATPL). This is the shared memory across ASO sessions — **update it as items
complete** (tick the box, add the date, note follow-ups). Authored 2026-08-04 against the six
metadata repos and the store strategy docs; nothing has been executed against App Store Connect
yet (no store records exist).

**Doc map.** This file owns the cross-app store-*search* strategy and nothing else. Web/AI
search for flygaca.com is owned by the monorepo's `SEO-PLAN.md` (+ the `flygaca-seo` skill) —
none of it is duplicated here. Store submission *mechanics* (lineup, pricing, App Store Connect
setup, review-survival, cross-promo rules) are owned by the monorepo's `docs/STORE-SUITE.md`.
The **shipping** listing strings live in the six metadata repos (`FlyGACA/PPL` … `FlyGACA/AIP`,
fastlane `deliver` layout, EN + AR, CI-gated by each repo's `check-metadata.mjs`) — adoption of
anything drafted here happens as PRs to those repos, never by editing this file into a copy
deck.

Status legend: `[x]` done · `[~]` partial (gap named) · `[ ]` not started.
Effort: S <½ day · M ~1 day · L multi-day.

---

## Phase 0 — Listing foundation

- [~] **0.1 Inventory the six listings against their repos (S).** Each metadata repo already
  carries the full bilingual field set (name, subtitle, description, keywords, release notes,
  URLs) plus committed screenshot sets (9 shots; PPL 10), CI-gated for locale parity and
  limits — verified repo-side 2026-08. *Gap:* no App Store Connect records exist yet, so
  nothing is live to audit store-side; re-run this inventory when the Wave 1 records are
  created (`docs/RUNBOOK-ios-release.md` §4).
- [x] **0.2 The character budget (S).** The limits every draft in this file must respect,
  counted in code points, per locale (both `en-US` and `ar-SA` serve the Saudi storefront):
  name 30 · subtitle 30 · keyword field 100 · promotional text 170 · description and release
  notes 4000. Enforced mechanically by each metadata repo's `check-metadata.mjs`. *Done
  2026-08-04 (documented; enforcement pre-existed).*
- [ ] **0.3 The truthfulness gate (S).** Listings must not promise banks the bundle lacks: as
  of 2026-08 the ELPT app bundles 1 of the web pack's 4 banks and AIP 2 of 3. Until the
  content sync lands (`ROADMAP.md` → Now), ELPT/AIP descriptions and release notes must
  describe the bundled content, not the web pack. Close this item when sync + copy agree.
- [x] **0.4 The naming system (S).** Display names are `Fly GACA <MODULE>` (already in the
  xcconfigs and Firebase registrations); bundle ids `com.flygaca.<module>`. ⚠️ Tooling trap:
  ELPT's *module id* is `elp` (the web pack id), not `elpt` — module ids are `ppl-exam`,
  `elp`, `aip`, `cpl`, `ir`, `atpl`. App Store *names* may extend beyond the brand prefix
  within 30 code points (e.g. an exam-term suffix) — drafts in 1.4. *Done 2026-08-04
  (system documented; per-app name suffixes remain part of 1.4).*
- [ ] **0.5 Locale posture (S).** Decide and record the primary-locale mapping for the six ASC
  records (likely `en-US` primary + `ar-SA` full localization — Arabic is a first-class
  listing, not a fallback; both locales are searchable on the Saudi storefront). Record the
  decision here and in the metadata repos' READMEs.

## Phase 1 — Keyword strategy (EN + AR)

No fabricated search-volume numbers anywhere in this file: Apple exposes no public keyword
volumes, so pools below are **hypotheses from the module subjects and bank vocabulary**, to be
validated against actual App Store search suggestions and post-launch App Analytics.

**Drafted pools — v1, applied to the six metadata PRs 2026-08-05.** Bank-grounded, packed to
≤100 code points, with words already in each app's name dropped (Apple indexes the name +
keywords as one set). These are the exact `keywords.txt` values pushed to each repo's
`claude/flygaca-docs-suite-2zmgmo` branch; refine against real App Store search suggestions
post-launch.

| App | `en-US` keywords | `ar-SA` keywords |
| --- | --- | --- |
| PPL | private pilot,gaca,gacar,aviation,vfr,controlled airspace,air law,navigation,meteorology | طيران,رخصة طيار,الطيار الخاص,gaca,gacar,قواعد الطيران البصري,مجال جوي,قانون الطيران,ملاحة جوية |
| CPL | commercial pilot,gaca,gacar,aviation,flight operations,aircraft performance,air law,navigation | طيران,رخصة تجارية,الطيار التجاري,gaca,gacar,عمليات الطيران,أداء الطائرة,قانون الطيران,ملاحة جوية |
| IR | instrument rating,gaca,gacar,aviation,ifr,instrument approach,procedures,holding patterns,navigation | طيران آلي,التقدير الآلي,gaca,gacar,ifr,إجراءات آلية,الاقتراب الآلي,ملاحة جوية,مجال جوي,أرصاد جوية |
| ATPL | airline transport pilot,gaca,gacar,aviation,part 121,airline operations,aircraft performance,air law | نقل جوي,رخصة النقل الجوي,gaca,gacar,part 121,عمليات الخطوط الجوية,أداء الطائرة,أرصاد متقدمة |
| ELPT | icao level 4,radiotelephony,aviation phraseology,atc communication,radio calls,plain language,pilots | icao,المستوى الرابع,لغة الطيران,اللاسلكي,المصطلحات الجوية,اتصالات المراقبة,استيعاب سماعي,سلم التقييم |
| AIP | eaip,sans,aerodromes,controlled airspace,ais,notam,aviation charts,navigation aids,route information | eaip,دليل الطيران السعودي,المجال الجوي,notam,خرائط الطيران,وسائل الملاحة,الأدلة الجوية,sans,مطار |

**Allocation matrix (1.3).** Each app owns its certificate head term; shared terms are placed to
minimize sibling collision:

- `gaca` + `gacar` — kept in all six (each targets its own GACAR certificate; legitimately core).
- `aviation` / `طيران` — the licence apps (PPL·CPL·IR·ATPL) only; AIP and ELPT lead with their
  own domain (aeronautical-information, aviation-English) instead of the generic term.
- Shared ground-school long-tail — `navigation`/`ملاحة جوية`, `meteorology`/`أرصاد`,
  `flight planning`/`تخطيط الطيران`, `human factors`/`عوامل بشرية` — spread so no two apps lead
  with the identical secondary terms.
- Certificate heads — `private pilot`, `commercial pilot`, `instrument rating`,
  `airline transport pilot`, `icao level 4`, `eaip` — each unique to exactly one app.
- The broadest family terms (e.g. "Saudi pilot exam", "GACA study") are reserved for the eventual
  **bundle** listing (3.2), not spent inside any single app.

- [~] **1.1 English seed pools per app (M).** Draft ~15 terms per app from its corpus scope.
  Starting hypotheses: PPL — GACA PPL, Saudi private pilot, GACAR, air law, VFR, airspace;
  CPL — commercial pilot exam, GACAR Part 61/119/135, performance; IR — instrument rating,
  IFR, procedures, GACAR Part 97; ATPL — ATPL theory, airline transport, GACAR Part 121;
  ELPT — aviation English, ELPT, SAELPT, ICAO level 4, phraseology; AIP — Saudi AIP,
  aerodromes, charts, airspace, NOTAM-adjacent study terms. Kingdom-context terms (GACA,
  GACAR, Saudi) are the differentiator — generic global terms ("pilot exam") are secondary.
- [~] **1.2 Arabic seed pools per app (M).** First-class, not translated word-for-word: pool
  the terms Saudi cadets actually search (e.g. رخصة الطيار الخاص، رخصة الطيار التجاري، اختبار
  الطيران، الطيران المدني، أسئلة اختبار الطيران). Source terminology from the corpus's Arabic
  layer and the family glossary; validate against Arabic App Store suggestions.
- [~] **1.3 The family allocation matrix (S).** Six sibling apps must not compete for the same
  head terms: assign each shared term (GACA exam, Saudi pilot, GACAR, طيران) to exactly one
  app's keyword field, and record the matrix here. The bundle listing (3.2) is the eventual
  home for the broadest family terms.
- [~] **1.4 Subtitle + keyword-field drafts, six apps × two locales (M).** Keyword fields
  drafted + shipped to the six metadata PRs 2026-08-05 (validated ≤100 cp by
  `check-metadata.mjs`); subtitles left as-is this pass. Within the 0.2
  budgets, subtitle carrying the strongest non-name terms, keyword field packed
  comma-separated without repeating name/subtitle words (Apple ignores duplicates). Deliver as
  PRs to the six metadata repos; their CI enforces limits and EN/AR parity.
- [x] **1.5 The no-go rules (S).** Standing policy, applies to every draft: no competitor or
  third-party app names in keywords; nothing implying GACA affiliation or official status —
  the disclaimer discipline applies to metadata too (an app named or keyworded to read as
  "GACA official" violates both our principles and App Review); no keyword-stuffed names
  (Guideline 2.3.7). *Done 2026-08-04 (policy recorded).*

## Phase 2 — Conversion (what searchers see and tap)

- [x] **2.1 Screenshot narrative audit + captioned rebuild (M).** *Shipped 2026-08-05:* the
  audit below drove a full rebuild. Added `apple/Scripts/html-render/render-store.js` +
  `captions.js` — a captioned store renderer that wraps the faithful base screens with
  value-prop caption bands (Falcon palette) and emits the reordered set (hero → timed exam →
  results → study loop). Rendered all six apps × three device slots and pushed the new sets +
  refreshed README galleries to the metadata repos (fresh PRs). EN captions only; the ar-SA
  caption pass is the open follow-up (base screens are identical — only `head`/`sub` localize),
  and the change lives in this repo's `apple/Scripts/` (sync-owned) so the monorepo copy needs
  the same to stay in sync. Original audit, retained as the spec:
  by the Mac-free `apple/Scripts/html-render/` pipeline from real bundled content — portrait
  via `npm run ios:screenshots`). *Gap:* audit each set so the first three shots carry the
  value proposition unaided — offline everything, bilingual, real exam sim with analytics —
  since most viewers never swipe past them. Regenerate through the same pipeline; the shipped
  files live in the metadata repos.

  **Audit (2026-08-05).** All six apps ship the identical nine-shot sequence — `01-home ·
  02-quiz-banks · 03-quiz-question · 04-quiz-answered · 05-flashcard-front · 06-flashcard-back ·
  07-timed-exam-start · 08-timed-exam-timer · 09-mock-results` (PPL adds `10-lessons-list`).
  Findings:
  - **The order is a feature walkthrough, not a pitch.** The first three (home → quiz banks →
    a question) show *where you are* before *why it's worth buying*. The strongest
    differentiators — the timed, scored exam sim and its analytics/pass score (shots 7–9) —
    sit past the fold most searchers never swipe to.
  - **No marketing captions.** The shots read as raw screen captures; the gallery rewards a
    bold caption overlay per shot (the line that still lands at thumbnail size).
  - **Recommended first-3 (all apps):** (1) `home` re-cast as a hero with a value-prop caption
    — e.g. "Everything for the Saudi <cert> exam — offline"; (2) `08-timed-exam-timer` (the
    headline scored-sim moment); (3) `09-mock-results` (the analytics / pass proof). The study
    loop (quiz → flashcards) then follows as shots 4–8.
  - **Bilingual gap:** one rendered set serves both storefront locales; captions, once added,
    must be localized EN + AR or the Arabic gallery loses the message (ties to 0.5).
  - **Ownership:** the sequence + captions come from `apple/Scripts/html-render/screens.js` in
    this repo, then get copied into each metadata repo — so acting on this is a **pipeline
    change here** + a re-copy (the Phase-2 follow-up); this item is the audit itself.
- [ ] **2.2 Promotional-text rotation (S).** The 170-code-point field updates without app
  review: draft a small rotation (exam-season push, new-banks-landed, bundle launch) per app,
  both locales, stored in each metadata repo's `promotional_text.txt`.
- [ ] **2.3 The ratings moment (M).** Request a review at the passed-mock-exam moment (the
  natural high point) via StoreKit's review prompt. Product change in shared `FeatureUI` —
  lands in the monorepo first, syncs here (a `[product]` dependency, tracked in `ROADMAP.md`
  once scheduled); no dark patterns, never gate content on rating.
- [ ] **2.4 In-app events for exam seasons (M).** Post-launch: ASC in-app event cards around
  Saudi exam-calendar peaks. Needs live apps + event artwork; revisit after Wave 1 ships.

## Phase 3 — The family and the bundle

- [ ] **3.1 The 4.3(b) dossier (M).** Six sibling apps from one shell invite a spam/app-farm
  reading (Guideline 4.3(b)). Write the differentiation dossier *before* first review, ready
  to paste into Review notes: per-app distinct corpus slice (13/1/2/12/10/9 banks as bundled
  today), distinct certificate audience, distinct name/subtitle/keywords/icon, and the
  architecture defense — one shared engine, module-specific *content*, exactly the
  ASA-Prepware/Gleim category precedent. Mechanics context: monorepo `docs/STORE-SUITE.md`.
- [ ] **3.2 The bundle listing (S).** "Saudi Pilot Study Pack" — the paid app bundle (≤10
  apps) once Wave 1 is live, with completing-the-bundle credit. The bundle gets the broadest
  family search terms per the 1.3 matrix. Pricing/strategy: `apple/ARCHITECTURE.md` §4.
- [ ] **3.3 Cross-promo hygiene (S).** Family cross-references in descriptions + the developer
  page per STORE-SUITE's cross-promo rules — never keyword-squatting sibling terms (keeps 1.3
  honest).

## Phase 4 — The web ↔ store loop

Store visibility compounds with flygaca.com's search presence. Execution of 4.1–4.2 lives in
the **monorepo's** backlog (pointer items here — do not duplicate them into work):

- [ ] **4.1 Smart App Banners on pack pages (S, monorepo-owned).** `apple-itunes-app` meta on
  `flygaca.com/study/packs/<id>` once each app is live, deep-linking pack → its app.
- [ ] **4.2 `SoftwareApplication` JSON-LD on pack pages (S, monorepo-owned).** Store links +
  price into the pack pages' structured data, feeding web/AI search the store presence.
- [~] **4.3 Store URLs point home (S, metadata repos).** `support_url` / `marketing_url` /
  `privacy_url` are populated (https-enforced by each repo's CI). *Gap:* confirm each app's
  `marketing_url` targets its own pack page (`/study/packs/<pack-id>` — mind `ppl-exam` and
  `elp` ids), not the generic homepage.

## Explicitly deprioritized (2026 reality)

- **Apple Search Ads** — pre-revenue; revisit only after the bundle is live and organic
  baselines exist.
- **Google Play / Android** — there is no Android app in this repo (the web monorepo owns the
  Capacitor shells); nothing to optimize.
- **Paid ASO tooling / rank trackers** — no spend before there are live listings to track.
- **Everything web-SEO** — owned end-to-end by the monorepo's `SEO-PLAN.md`; this file never
  grows web items.

## Session log

- **2026-08-05** — Built + shipped the captioned screenshots (2.1 → done). Added the
  `render-store.js` + `captions.js` store renderer (caption bands + value-prop-first order),
  rendered all six apps × three device slots, and opened fresh PRs replacing each metadata
  repo's screenshot set + README gallery. EN only; ar-SA captions + the monorepo `apple/Scripts`
  re-sync remain open.
- **2026-08-05** — Started Phase 2. Audited the committed screenshot sets (identical nine-shot
  walkthrough across all six apps) and recorded findings in 2.1: the order leads with
  orientation instead of the value prop, there are no marketing captions, and the scored-sim +
  analytics shots (the strongest converters) sit past the fold. Proposed a value-prop-first
  first-3 (hero → timed exam → results) and flagged the EN/AR caption-localization gap.
  Implementation is a `screens.js` pipeline change + re-copy — the follow-up; 2.1 → partial.
- **2026-08-05** — Executed Phase 1 keyword drafts. Wrote bank-grounded `keywords.txt` (EN + AR)
  for all six apps, dropping name-duplicated words and filling the unused Arabic headroom; packed
  each to ≤100 code points and validated with every repo's `check-metadata.mjs`. Recorded the
  drafted pools + the allocation matrix (1.3) above and applied the same values as an `aso:` commit
  on each metadata repo's `claude/flygaca-docs-suite-2zmgmo` branch (joining the open draft PRs —
  PPL/CPL/IR/ATPL/ELPT/AIP #6). 1.1–1.4 → partial (drafted; adoption pending PR merge + `fastlane
  deliver`). Names/subtitles untouched. Still open: post-launch validation against real App Store
  suggestions, and the 0.5 primary-locale posture.
- **2026-08-04** — File authored as part of the repo docs suite (see `MIGRATION.md` Stage 4).
  Established the doc map, the character budgets (0.2), the naming system + `elp` trap (0.4),
  and the keyword no-go policy (1.5). Verified repo-side that all six metadata repos carry
  bilingual field sets + committed screenshot sets behind CI gates. Not executed: everything
  store-side — no ASC records exist yet (blocked on the signing/records checklist, tracked in
  `ROADMAP.md` → Now). Open questions carried forward: primary-locale posture (0.5), the
  allocation matrix (1.3), and whether ELPT's store name should surface "SAELPT" (1.4).
