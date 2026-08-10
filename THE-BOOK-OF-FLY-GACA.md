# The Book of Fly GACA

**The whole family, one book.** · كتاب فلاي جاكا

> And the falcon was given two wings — one of steel, one of code — and was told:
> read every regulation, then teach it kindly, and always say where it is written.

*Edition 1 · Last reviewed: 2026-08-04*

---

## How to read this book

This is the **master reference for the entire Fly GACA universe** — ten repositories, three
product surfaces, one cause. It exists so that anyone (engineer, author, assistant) can hold
the whole system in their head before touching any part of it.

Three rules govern it:

1. **The Book describes; it does not govern.** Each repo's own `CLAUDE.md`, architecture docs
   and runbooks are authoritative for that repo. When the Book and a repo disagree, the repo
   is right and the Book is due for review.
2. **Descriptive books carry dates.** Anything that can drift (counts, statuses, CI shapes) is
   stamped *as of 2026-08-04*. The dates are the honesty mechanism — re-review is a standing
   [`ROADMAP.md`](./ROADMAP.md) item.
3. **The Tenets are the exception.** Book II states principles, not snapshots. Their canonical
   plain-language wording lives in [`CAUSE.md`](./CAUSE.md); they change only on purpose.

---

## Book I — The Universe

*In the beginning there was one repository, and it grew until it was ten.*

Fly GACA is an independent, educational platform and open regulatory library for Saudi civil
aviation, operated by **BDA Company International (شركة بدع الدولية)**. It is **not affiliated
with GACA** — the regulator, [gaca.gov.sa](https://gaca.gov.sa), is always the authority the
products cite and defer to. The public fronts are **flygaca.com** and **captadel.com**.

### The ten repositories

| Repo | Role |
| --- | --- |
| [FlyGACA/FlyGACA-app](https://github.com/FlyGACA/FlyGACA-app) | **The web monorepo** — flygaca.com: React/Vite PWA (library, tools, study, chat, accounts), the Firebase Functions backend (`functions/`), and the **source of truth** for the regulatory corpus (`public/data/`) and the pack catalog (`src/lib/prepCatalog.ts`), plus all content pipelines. |
| [FlyGACA/Captain-Adel](https://github.com/FlyGACA/Captain-Adel) | **The AI flight instructor** — captadel.com: one Node/Express service; the retrieval+answer brain (`src/brain/`) is the single source of truth and also powers Fly GACA's chat server-to-server. |
| [ay2m/FlyGACA](https://github.com/ay2m/FlyGACA) (this repo) | **The native iOS family** — one shared Swift package (`FlyGACAKit`) + one App Store app per study module: ELPT and AIP. The licence-exam modules (PPL, CPL, IR, ATPL) are paused. |
| [FlyGACA/ELPT](https://github.com/FlyGACA/ELPT) · [AIP](https://github.com/FlyGACA/AIP) · and the parked [PPL](https://github.com/FlyGACA/PPL) · [CPL](https://github.com/FlyGACA/CPL) · [IR](https://github.com/FlyGACA/IR) · [ATPL](https://github.com/FlyGACA/ATPL) | **The six store-metadata repos** — App Store Connect listing copy (EN + AR), screenshots, and a per-app roadmap. No source code; each names this repo's `apple/Apps/<Module>/` as the code home. Four are parked with their metadata retained. |
| [FlyGACA/Office](https://github.com/FlyGACA/Office) | **The operating documents** — strategy, governance, legal, finance, compliance, GTM, brand: the company's paperwork, not product code. Its contents are sensitive; product repos take from it only public-safe facts. |

### How content flows (one direction, always)

```
GACA publications (the authority — gaca.gov.sa)
        │  ported & normalized (monorepo pipelines: sync:gaca, data:normalize)
        ▼
FlyGACA-app  public/data/  +  src/lib/prepCatalog.ts     ← THE source of truth
        │                            │
        │ fetched at runtime         │ bundled per module (build-ios-content.mjs, monorepo-side)
        ▼                            ▼
  flygaca.com packs            FlyGACA-app/apple/…/Content
  Captain Adel corpus                │  bash scripts/sync-content.sh   (one-way, reviewed)
  (chunks → BM25/embeddings)         ▼
                               ay2m/FlyGACA  apple/Apps/*/Content/    ← committed snapshots
                                     │
                                     ▼
                                 the iOS apps (fully offline)
```

Nothing ever flows backward. This repo has **no bundler and no corpus** by design; the
monorepo's own `apple/` tree is a legacy copy of this one, pending retirement
([`MIGRATION.md`](./MIGRATION.md)). The metadata repos flow the other way entirely — copy
and screenshots out to App Store Connect — and the Office stands apart, feeding the product
repos only its canonical entity facts.

---

## Book II — The Tenets

*Seven principles, held everywhere. The plain wording lives in* [`CAUSE.md`](./CAUSE.md);
*these are the same laws, read aloud.*

1. **Independent and educational, not regulatory.** We are not GACA. We do not speak for GACA.
   We help people find and study the regulation; the regulation itself belongs to its author,
   and the arrow on every page points back to gaca.gov.sa.
2. **Citations or silence.** An answer that cannot name its Part and section is not an answer;
   it is a rumor. Captain Adel refuses before he guesses, and the refusal is the feature.
3. **Bilingual or it didn't ship.** Arabic is not a translation pass; it is half of every
   surface. The build fails when one language falls behind — by test, not by intention.
4. **Offline is a feature.** The signal ends at the apron; the studying does not. The web app
   degrades gracefully; the native apps assume nothing at all.
5. **In-Kingdom by default.** A student's questions and progress are personal data, and they
   stay under Saudi jurisdiction (PDPL). Regions are chosen in the Kingdom first, and only
   what is public may live elsewhere.
6. **Never paywall the regulations.** The law stays free to read, forever. What is sold is the
   toolchain around it — the packs, the tools, the apps — never the text of the rule.
7. **The disclaimer is a discipline.** One statement, verbatim, on every surface, in both
   languages. It is never reworded, never abbreviated, never a footnote.

---

## Book III — The Products

*One cause, three surfaces.* (Descriptive — as of 2026-08-04.)

### flygaca.com — the library and the flight deck

The web monorepo ships the open regulatory library (documents, charts, an aerodrome map, a
corpus change feed), the Captain Adel chat surface, a large flight-tools catalog of pure,
unit-tested calculators, a learn/guides hub, study tools (quiz, flashcards, ground school,
mock exam, exam-prep packs), pilot account features (currency, logbook, records), and the
commerce surfaces (pricing, schools, checkout) — a bilingual, RTL-first PWA that works
offline. Its backend (`functions/`, deployed in-Kingdom) is the gateway for chat, the
licensed `/v1/ask` API, and Moyasar billing, with every entitlement **server-owned**.

### Captain Adel — the instructor

One Express service, one brain. Two answer strategies: **agentic** (Gemini drives its own
retrieval/tool calls) and **retrieve-then-read** (BM25 retrieval runs in code; Arabic-capable
models answer only from the passages they are handed). Language routing sends
Arabic-dominant questions to Arabic providers; a **parity gate** blocks any provider from
auto-routing until it matches-or-beats the incumbent in both languages. Grounding is
cite-or-refuse. The same brain serves captadel.com and, server-to-server, Fly GACA's own chat
— two tenants, one truth.

### The apps — this repo

One shared Swift package, one ~20-line app target per module; **a module is data, not code**.
Every app carries the identical offline feature set: study mode, quizzing, flashcards with
spaced repetition, mock tests, and a timed, scored exam sim with analytics.

| App | Bundle id | Module id | Banks · questions (bundled, as of 2026-08) |
| --- | --- | --- | --- |
| ELPT | `com.flygaca.elpt` | `elp` | 5 · 191 *(incl. the scenario bank)* |
| AIP | `com.flygaca.aip` | `aip` | 3 · 113 |

Paused since 2026-08-10 and removed from the repo (git history keeps them): PPL (`ppl-exam`),
CPL (`cpl`), IR (`ir`), ATPL (`atpl`) — the licence written-exam modules. Their **web** study
packs are unaffected and still sell at `flygaca.com/study/packs/*`.

Future modules (FOI, AGI, Dispatcher, AME …) enter the monorepo's `prepCatalog.ts` first. The store strategy is paid-up-front apps plus an App Store bundle ("Saudi Pilot Study
Pack", up to 10 apps) — `apple/ARCHITECTURE.md` §4.

---

## Book IV — The Data

*The corpus is the reader's copy of the regulation — never the regulation itself. When the two
disagree, GACA wins, without argument.*

- **The corpus** lives in the monorepo (`public/data/`), ported from GACA publications and
  normalized by pipeline; the web fetches it at runtime (it never enters the JS bundle), and
  Captain Adel indexes it (BM25, optional embeddings). Packs are slices of it, declared in
  `src/lib/prepCatalog.ts`.
- **The snapshots** — each iOS app bundles its module's slice verbatim (`module.json`,
  `quiz.json`, plus ground school / reading paths where the pack has them): the wire schema
  *is* the web schema, so the platforms cannot drift structurally — and small enough that a
  database would be pure overhead.

### The parity scriptures

These semantics are shared web ↔ iOS; users move between platforms, so breaking one silently
is the gravest sin in the codebase. Each has a canonical source and a test that fails when the
platforms diverge:

| Contract | The law | Canonical source |
| --- | --- | --- |
| **SRS (Leitner)** | boxes 0–5; intervals `[0, 1, 3, 7, 14, 30]` days; correct promotes (capped), wrong resets to 0; unseen always due; mastered = box ≥ 3 | monorepo `src/calc/study/srs.ts`; vectors in `apple/FlyGACAKit/Tests/StudyEnginesTests/LeitnerTests.swift` |
| **Due dates** | UTC day-strings (`yyyy-mm-dd`, string compare) — a `Calendar.current` port would drift a day near midnight | same pair |
| **Exam scoring** | `percent = round(correct/total × 100)`; `passed = percent ≥ passMark`; defaults 25 q / 30 min / 75 %; per-pack overrides; auto-submit at 0:00; unanswered counts wrong | web mock exam ↔ `StudyEngines` |
| **Streak** | same day unchanged; consecutive day +1; gap resets | web `nextStreak` ↔ `Streaks` |
| **Question identity** | the web has no stable ids (progress keyed by array index); iOS mints `sha256("bankID|prompt")` → first 16 hex chars at decode time, keeping `index`/`legacyKey` for progress parity across refreshes | `CoreModels` |

User state on iOS lives in SwiftData inside the App Group `group.com.flygaca.study`, so
streaks, SRS and attempts are one story across every app on a device; `StudyStore` (a
`@ModelActor`) is the single write path. When PlatformLive lands, progress uploads to the same
Firestore document the web writes (`users/{uid}/progress/summary`) — one student, one record.

---

## Book V — The Commandments of the Codebase

*Each repo keeps its own law; these are the ones that must never be broken. The full statutes
live in each repo's `CLAUDE.md`.*

**Held everywhere:**

1. The disclaimer is never reworded — copy it verbatim or do not touch it.
2. Bilingual is mandatory: a string that ships in one language fails the gate (by test in the
   product repos, by checker in the metadata repos).
3. Generated things are not committed — the web's sitemap, this repo's Xcode project — with
   one deliberate inversion: the Office *does* commit its rendered PDFs, and its CI fails if
   they go stale.

**The web monorepo:**

4. Design tokens only; logical properties only — RTL mirrors by construction, never by hand.
5. Calculator math is pure and DOM-free (`src/calc/*`), and calculator state lives in the URL.
6. `users/{uid}.entitlement` is written only by Cloud Functions; the client reads it to gate
   UI and **never grants**. Every business rule lives in a pure `*-core.ts` module, and the
   client-side mirrors must match the server cores — a test enforces it.
7. All API surfaces stay under `/api/*` so every mirror host proxies to one origin and the
   strict CSP never widens.

**Captain Adel:**

8. The brain (`src/brain/`) stays portable and dependency-light — it is the single source of
   truth for two tenants.
9. Cite-or-refuse is the grounding law; quota fails open (a Firestore error never blocks a
   student); suspicious prompts are flagged and hardened against, not rejected.
10. No secrets in code — configuration is environment, always.

**This repo (the iOS family):**

11. Engines never do IO — `now: Date` is a parameter, and `swift test` needs no simulator.
12. Firebase/RevenueCat never leak upstream of PlatformLive; UI talks to `AppServices`
    protocols, and the offline mocks *are* the shipping product until Phase 4.
13. One app shell for every target — per-app difference is xcconfig data, never a Swift
    fork. A module is data, not code.
14. Content syncs one way, monorepo → here, and every sync diff is reviewed before commit.

**The metadata repos:**

15. Every field ships in `en-US` and `ar-SA` together, inside the code-point limits, or CI
    fails the PR. Module identity (bundle id, source, pack, bank count) is duplicated across
    three repos — change one, check the other two.

**The Office:**

16. Every content doc carries its front-matter and a fresh PDF, or CI fails. English is
    authoritative; the Arabic mirror follows. Its sensitive material is quoted elsewhere only
    to the minimum the task requires.

---

## Book VI — The Gates

*No repo ships on faith.* Every repo's CI, one table — as of 2026-08-04:

| Repo | The gate |
| --- | --- |
| FlyGACA-app | `npm run verify`: typecheck → lint → format → test (i18n parity included) → build → bundle budget (188 kB gz initial) → per-chunk perf budget. CI adds a coverage ratchet, a separate functions gate (`lint · test:coverage · build` in `functions/`), emulator-backed Firestore-rules tests, and Playwright e2e + a11y. Production deploys only via `deploy.yml`. |
| Captain-Adel | `smoke` + unit tests + `eval:dry` on every push/PR; the live eval suite (EN + AR citation/refusal/injection bars) runs weekly and gates provider changes via the parity harness. Deploy re-runs the gate, ships to Cloud Run (KSA region), health-checks `/health`. |
| ay2m/FlyGACA | `ios.yml`, seven jobs: `swift-test` (parity vectors — gates everything) → `xcodegen-validate` → per-app debug matrix (`fail-fast: true`) → release archives on `main` → secrets-gated TestFlight → `build-summary`. Caveat: the summary doesn't cover release/TestFlight failures — check those jobs directly. Triggers: push to `main`, PR to `main`, dispatch only. |
| ELPT · AIP · (parked: PPL · CPL · IR · ATPL) | `metadata.yml` runs `check-metadata.mjs` on every push/PR: required fields, EN/AR locale parity, code-point limits (30/30/100/170/4000), https-only URLs. |
| Office | `docs-check.yml`: YAML front-matter on every `.md`, plus a build-cache hash proving every doc's committed PDF is fresh (Markdown and HTML alike). |

---

## Book VII — The Glossary

- **GACA** — the General Authority of Civil Aviation: the Saudi regulator, the authority every
  product cites and defers to. Not us; never us.
- **GACAR** — the General Authority of Civil Aviation Regulations — the corpus (Parts and
  sections, e.g. "Part 61, §61.89").
- **AIP** — Aeronautical Information Publication (Saudi AIP: GEN/ENR sections, aerodromes,
  charts) — and the name of the study module covering it.
- **ELPT / SAELPT** — the (Saudi) Aviation English Language Proficiency Test; content targets
  the ICAO language-proficiency descriptors ("ICAO level 4"). The module's *pack id is `elp`* —
  the one place the app name and module id differ. Beware.
- **PDPL** — the Saudi Personal Data Protection Law; the reason hosting and model inference
  default in-Kingdom.
- **Pack / bank / question** — a pack is a study product (declared in `prepCatalog.ts`); a
  pack holds banks; a bank holds questions. The iOS module ids are the web pack ids: `elp`
  and `aip` today (`ppl-exam`, `cpl`, `ir`, `atpl` belong to the paused modules).
- **Wave** — the shipping cohorts of the app family. Wave 1 was PPL/ELPT/AIP and Wave 2
  CPL/IR/ATPL; with the licence modules paused the live cohort is ELPT/AIP, and the wave
  labels are now history rather than a plan.
- **Leitner / SRS** — the spaced-repetition system (Book IV); "mastered" means box ≥ 3.
- **App Group** — `group.com.flygaca.study`: the shared on-device container that makes the
  family feel like one product.
- **PlatformLive** — the not-yet-built iOS target where Firebase/RevenueCat will live;
  until then the apps are fully offline and the mocks are the product.
- **The bundle** — "Saudi Pilot Study Pack", the planned paid App Store bundle of the family.
- **Tenant** — Captain Adel's two framings of one brain: `captadel` (standalone) and
  `flygaca` (embedded in the library).
- **Retrieve-then-read** — retrieval runs in code; the model may cite only the passages it was
  handed. **Parity gate** — the eval harness a candidate model must pass (match-or-beat, EN
  *and* AR) before auto-routing may use it.
- **The Falcon theme** — the shared design language (tokens in the monorepo's `tokens.css`;
  mirrored in `FeatureUI/Theme.swift`; print form in the Office).
- **BDA Company International (شركة بدع الدولية)** — the operating company behind Fly GACA and
  Captain Adel.

---

## Book VIII — The Apocrypha (decisions not taken)

*Each was weighed, and set aside, and the reason recorded — so it is not re-litigated by
accident. (As of 2026-08-04; sources: the architecture docs and CLAUDE.md files of the product
repos.)*

1. **The wrapped web view.** The study family could have shipped as thin shells around the
   PWA. Set aside: the product *is* offline-first native feel — SwiftUI + bundled content,
   with the web's semantics ported and parity-tested instead.
2. **A database for content.** A few hundred KB of JSON per app does not need one. Content
   stays read-only structs; SwiftData holds only user state. (Realm was ruled out separately —
   its SDKs were deprecated upstream.)
3. **A multi-package Swift split.** One local package with six library targets gives strict
   dependency direction without the versioning overhead. Set aside until it hurts.
4. **Committing the Xcode project.** `project.yml` is the source of truth; the project is
   regenerated on demand. Merge conflicts in `.pbxproj` are a tax nobody pays here.
5. **Firebase in the pure targets.** Every SDK import waits in PlatformLive. The pure targets
   build instantly, test without a simulator, and preview on mocks.
6. **Per-app Swift.** Forking the shell per app was the obvious path and the wrong one: a module
   is a `Content/` folder and an xcconfig. The Swift never multiplies.
7. **Free apps with one-time IAP unlocks.** Apple's app bundles exclude one-time-IAP apps, so
   the family went paid-up-front (buying the app *is* the entitlement); free + auto-renewable
   subscription is the recorded fallback, entitlement then server-owned like the web.
8. **External dependencies in the kit.** Zero, deliberately — `swift build && swift test`
   needs no network, no simulator, no SDK downloads.
9. **A native Android family.** Not begun; the web monorepo's Capacitor shell carries Android.
   One native family at a time.
10. **Paywalling the corpus.** Rejected everywhere, permanently — Tenet 6. The apps sell the
    toolchain; the regulation stays free.

---

## Book IX — The Final Approach

### The reading map

| You want to… | Read |
| --- | --- |
| Understand *why* any of this exists | [`CAUSE.md`](./CAUSE.md) |
| See what this repo does next / its history | [`ROADMAP.md`](./ROADMAP.md) / [`MIGRATION.md`](./MIGRATION.md) |
| Build, test, ship an app from here | [`README.md`](./README.md) → [`docs/RUNBOOK-ios-release.md`](./docs/RUNBOOK-ios-release.md) (and [`docs/README.md`](./docs/README.md) for which runbook to trust) |
| Understand the iOS architecture deeply | `apple/ARCHITECTURE.md` (monorepo-synced) |
| Work on store listings / ASO | [`SEO-PLAN.md`](./SEO-PLAN.md), then the metadata repos |
| Touch the corpus, packs, web app, or backend | the monorepo — [FlyGACA/FlyGACA-app](https://github.com/FlyGACA/FlyGACA-app) (`CLAUDE.md`, `ROADMAP.md`, `docs/`) |
| Touch the AI instructor | [FlyGACA/Captain-Adel](https://github.com/FlyGACA/Captain-Adel) (`CLAUDE.md`, `evals/`) |
| Company / operating questions | [FlyGACA/Office](https://github.com/FlyGACA/Office) — minimum necessary, it is sensitive |

### The benediction

To the student: study anywhere, verify with GACA.
To the contributor: keep the tests green and the languages two.
To the assistant: cite the Part, or hold your peace.
And to the regulator belongs the regulation, always — we only keep a well-lit reading room.

**صُنع في السعودية 🇸🇦 · Made in Saudi Arabia**

### The last word

**Fly GACA is an independent educational platform.** It is not affiliated with, endorsed by, or operated by the General Authority of Civil Aviation (GACA) or the Government of the Kingdom of Saudi Arabia. The official and authoritative source for all civil aviation regulations, publications, and aeronautical information is always GACA. Always verify against the latest official GACA publication at gaca.gov.sa.

<div dir="rtl">

**فلاي جاكا منصة تعليمية مستقلة.** وهي غير تابعة للهيئة العامة للطيران المدني (GACA) ولا معتمدة منها ولا تُديرها، كما أنها لا تمثّل حكومة المملكة العربية السعودية. المصدر الرسمي والمعتمد لجميع لوائح الطيران المدني ومنشوراته ومعلوماته الجوية هو GACA دائمًا. تحقّق دائمًا من أحدث منشور رسمي صادر عن GACA على gaca.gov.sa.

</div>
