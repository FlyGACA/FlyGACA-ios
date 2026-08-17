# CLAUDE.md

Guidance for AI coding assistants working in this repository.

## What this is

**ay2m/FlyGACA** is the native SwiftUI home of the Fly GACA study-app family: **one shared
Swift package (`FlyGACAKit`) plus one App Store app target per study module** — ELPT and
AIP — sold together via an App Store **app bundle**. Every app ships the
identical offline feature set (study mode, quizzing, flashcards with spaced repetition,
mock tests, timed scored exam sim with analytics). **A module is data, not code** — adding
an app means adding a `Content/` folder and a ~20-line Xcode target, never new Swift.

> **The licence-exam modules are paused.** PPL, CPL, IR and ATPL were removed from this repo on
> 2026-08-10 pending a strategic decision — targets, xcconfigs, content, icons, scripts, CI
> matrices and screenshot sets. They live in git history only; their App Store metadata repos
> are intact and marked parked, and their **web** study packs are untouched and still selling.
> Do not re-add them, and do not "fix" a doc by restoring a six-app list. Restoring a module is
> a revert of that commit plus its Apple-portal steps — see `ROADMAP.md`.

This repo has **no build step of its own for content or corpus** — it consumes both from
the web monorepo. Read `apple/ARCHITECTURE.md` (the why: target graph, data contracts, App
Store strategy) and `apple/README.md` (the how: Mac setup) before making non-trivial
changes; both are denser and more authoritative than this file for anything Swift-side.

### The Fly GACA repo family

| Repo | Holds |
|---|---|
| **ay2m/FlyGACA** (this repo) | Native iOS app family — FlyGACAKit + the ELPT and AIP app targets |
| `FlyGACA/FlyGACA-app` | flygaca.com — React/Vite PWA, Firebase backend, regulatory corpus + content pipelines. **Source of truth** for content (`public/data/`, `src/lib/prepCatalog.ts`) and for `scripts/build-ios-content.mjs` / `npm run ios:icons`, which this repo does not have. |
| `FlyGACA/Captain-Adel` | The AI flight-instructor service (captadel.com) |
| `FlyGACA/ELPT` · `AIP` (shipping) · `PPL` · `CPL` · `IR` · `ATPL` (paused) | Per-app **App Store metadata repos** — store listing copy (EN/AR), screenshots, per-app roadmap. They hold **no source code**; they reference this repo's `apple/Apps/<Module>/` as the code home. If a task is "update the App Store description/screenshots for X", it belongs in that module's own repo, not here. |
| `FlyGACA/Office` | Business/governance/legal/finance docs |

**This repo is the sole home of the native app code.** The monorepo used to carry a duplicate
`apple/` mirror; it was **retired 2026-08** (`FlyGACA-app` no longer has an `apple/` tree). The
split: this repo owns all Swift + Xcode config (`FlyGACAKit`, `project.yml`, `apple/Scripts`,
`ARCHITECTURE.md`, `README.md`) and hand-edits them here; the monorepo stays the **source of
truth for content only** — its `build-ios-content.mjs` / `gen-app-icons.mjs` generate each app's
`Content/` + `Assets.xcassets` and `scripts/sync-content.sh` pulls them **monorepo → here**, never
the reverse. There is no longer an `--all` mode syncing Swift code (there is nothing upstream to
sync it from).

### The repo docs

Every doc in this repo is now natively owned here (nothing is sync-overwritten anymore):
`CAUSE.md` (mission + the seven principles), `ROADMAP.md` (open work in this repo —
single source of truth), `MIGRATION.md` (the extraction history), `SEO-PLAN.md` (App Store
search / ASO for the shipping apps), `THE-BOOK-OF-FLY-GACA.md` (the whole-family reference — all
ten repos; descriptive, dated, each repo's own docs govern), `CONTRIBUTING.md`,
`docs/RUNBOOK-ios-release.md` (the end-to-end release path), the rest of the `docs/RUNBOOK-ios-*`
set, `docs/CORPUS-SIGNING.md` (the Ed25519 contract for remote content),
`docs/PORTAL-RUNSHEET-wave1.md` (the Apple-portal checklist), and `docs/README.md` (the doc
index). These originated as copies of the monorepo's versions,
but after the `apple/` mirror's retirement (2026-08) they are the real source, edited here.

`.claude/agents/` defines three subagents scoped to this repo — **swift-kit** (anything inside
`apple/FlyGACAKit`), **parity-guard** (the cross-platform study semantics below) and
**ios-release** (builds, signing, TestFlight, CI, screenshots); `agents/README.md` says when each
is the right one.

One caveat on cross-repo links: the monorepo lost its `docs/` tree in 2026-08, so pointers from
here into `FlyGACA-app/docs/…` (e.g. `APPS-FAMILY-ROADMAP.md`, referenced from `ROADMAP.md`) no
longer resolve. Content generation itself is unaffected — `scripts/build-ios-content.mjs`,
`gen-app-icons.mjs`, `public/data/` and `src/lib/prepCatalog.ts` are all still there.

## Architecture (see `apple/ARCHITECTURE.md` for full detail)

**Stack:** Swift 5.9+ tools (the xcconfig's `SWIFT_VERSION = 5.0` is the *language mode*, not the
toolchain; `Package.swift` also declares `.macOS(.v14)` so the package builds/tests from the CLI),
SwiftUI, SwiftData, iOS 17+ floor. MVVM with light Clean layering, as
**one local Swift package with multiple library targets** — no multi-package overhead.
Storage: SwiftData for user state; content is read-only JSON decoded into structs (~150 KB of
committed `Content/` across the two apps — still far too small to justify a database).

### Target graph (`apple/FlyGACAKit/Package.swift`)

```
CoreModels (no deps)
  ├─ StudyEngines    (SRS, sessions, streaks, sampler, readiness — no IO)
  ├─ ContentKit      (bundled/cached content loading + signed remote refresh)
  ├─ AppServices     (protocol seams + offline mocks; deps: CoreModels only)
  └─ PersistenceKit  (SwiftData @Model + StudyStore actor;
                      deps: CoreModels, StudyEngines, AppServices)
PlatformLive (live impls of the AppServices protocols;
              deps: CoreModels, AppServices, PersistenceKit)
FeatureUI (deps: all of the above — every screen, incl. SingleModuleRootView)
```

**PlatformLive now exists** (it was "Phase 4, not yet built" until recently) —
`Sources/PlatformLive/` holds `FirebaseAuthService`, `FirebaseProgressSync` (writes the web app's
`users/{uid}/progress/summary` contract), `CaptainAdelSSEClient` (SSE against
`https://flygaca.com/api/chat`), `MoyasarPaymentService` (Mada / Apple Pay / card, SAR) and
`PlatformLiveFactory`, with `Tests/PlatformLiveTests/`. Two things about it are easy to get wrong:

- It is written **against the REST/SSE endpoints over `URLSession`, with no SPM dependencies** —
  `FlyGACAKit` still has **zero external dependencies**, so `swift build`/`swift test` stay
  instant. Do not "finish" it by adding firebase-ios-sdk or purchases-ios without a deliberate
  decision; `apple/ARCHITECTURE.md` §5 and `Package.swift`'s header comment still describe the
  older SDK-based plan and are stale on this point.
- **Nothing injects it yet.** `FeatureUI` declares the dependency but no source file imports it,
  and the app shell links only `FeatureUI` + `PersistenceKit`. The shipping apps still run
  entirely on the `AppServices` mocks and are offline by design; wiring PlatformLive into a
  composition root is open work, not done work.

App targets link **two** products, not one: `FeatureUI` *and* `PersistenceKit` (the shared shell
opens the SwiftData store and constructs `StudyStore` itself — `apple/project.yml`).

Rules that keep this healthy — do not violate them:

- **Engines never do IO.** `StudySession` takes `now: Date` as a parameter; tests pass fixed
  dates. `swift test` needs no simulator, no SDK downloads.
- **Platform integrations never leak upstream** of `PlatformLive`. Keeps the pure targets instant
  to build and every screen previewable via `AppServices` mocks.
- **UI talks to protocols** (`AuthProviding`, `EntitlementsProviding`, `ProgressSyncing`,
  `ChatClient`, `PaymentProviding` in `AppServices`), not concrete platform SDKs.
- **Remote content is signed or refused.** `ContentKit`'s `ContentRefresher` can pull
  `quiz.json` from flygaca.com, but `CorpusSignatureVerifier` requires a valid detached Ed25519
  signature (`quiz.json.sig`, CryptoKit) and **fails closed** — a missing/bad signature, or a
  missing `FGCorpusPublicKey` in `Info.plist`, throws and leaves the existing cache untouched.
  See `docs/CORPUS-SIGNING.md`; don't add a bypass for local testing.
- **The UI chrome is bilingual, the content is not.** `FeatureUI/Localization.swift` +
  `Resources/{en,ar}.lproj/Localizable.strings` resolve through `Bundle.module`; questions and
  banks stay English (they are generated in the monorepo, not translated here).

### Cross-platform parity — do not break silently

These semantics are shared with the web app (`FlyGACA-app`); users move between platforms:

- **SRS** = a literal port of `src/calc/study/srs.ts`: boxes 0–5, intervals
  `[0, 1, 3, 7, 14, 30]` days, correct promotes (capped), wrong resets to 0, unseen always
  due, mastered = box ≥ 3. Parity vectors: `apple/FlyGACAKit/Tests/StudyEnginesTests/LeitnerTests.swift`.
- **Due dates are UTC day-strings** (`yyyy-mm-dd`, string compare) — a `Calendar.current`
  port would drift a day near midnight.
- **Exam scoring**: `percent = round(correct/total × 100)`, `passed = percent ≥ passMark`
  (default 25 q / 30 min / 75%, per-pack overrides), auto-submit at 0:00, unanswered = wrong.
- **Streak**: web `nextStreak` — same day unchanged, consecutive +1, gap resets.
- The web has **no stable question ids** (progress keyed by array index); `CoreModels`
  fixes this at decode time by hashing `sha256("bankID|prompt")` (first 16 hex chars) →
  `Question.id`, while
  retaining `index`/`legacyKey` for progress parity across content refreshes.

User state lives in SwiftData, in a shared App Group (shared by every app in the family on-device,
so streaks/SRS carry across apps). `StudyStore` (a `@ModelActor`) is the single write path;
SwiftData model objects never escape the actor (they aren't `Sendable`).

> ⚠️ **App Group id — docs now match the code; the Apple portal still needs checking.** The id is
> **`group.com.FlyGACA`**, and all three places that decide it agree:
> `apple/Apps/Shared/App.entitlements`, `App-Shared.xcconfig`'s `FG_APP_GROUP`, and
> `PersistenceKit/Persistence.swift`'s `appGroupID`. Eight docs used to say
> `group.com.flygaca.study` instead (this file, `CAUSE.md`, `THE-BOOK-OF-FLY-GACA.md`,
> `apple/README.md`, `apple/ARCHITECTURE.md`, and three runbooks) — all corrected to the code's
> value, since the code is what ships and no code change was made.
>
> **What is still open is external:** `docs/PORTAL-RUNSHEET-wave1.md` previously recorded
> `group.com.flygaca.study` as already registered in the Apple Developer portal. If that is true,
> a profile built from it won't grant what the app requests and the signed build fails — App
> Groups can't be renamed, so `group.com.FlyGACA` must be registered and reassigned on both App
> IDs. Nothing has reached TestFlight, so there is no on-device data to migrate: it is a
> portal-only fix. Don't "resolve" this by editing the entitlements back.

## Content: committed snapshots, generated in the monorepo

Each app ships `apple/Apps/<App>/Content/` (`module.json`, `quiz.json`, plus
`groundschool.json` / `paths-index.json` — no current module ships those two; the loaders
treat them as optional). Snapshots can lag the web packs as the corpus moves — a
`sync-content.sh` run closes any gap (last full sync 2026-08-05: ELPT and AIP in step with the
monorepo catalog; ELPT additionally bundles a scenario bank in `quiz-extra.json`).
**This repo owns its Swift code but NOT the content bundler** — `build-ios-content.mjs` /
`gen-app-icons.mjs`, the regulatory corpus (`public/data/`), and the pack catalog
(`src/lib/prepCatalog.ts`) all live in the `FlyGACA-app` monorepo, which stays the source of
truth for content. Here, `Content/` folders and the per-app icons are **committed snapshots**,
refreshed by:

```bash
# with a FlyGACA-app clone next to this repo (default ../FlyGACA-app), or pass its path
bash scripts/sync-content.sh [path-to-FlyGACA-app]
```

That shells into the monorepo and runs its generators with `--out apple/Apps` so they write
`Content/` + `Assets.xcassets` **straight into this repo** — no intermediate copy, no `--all`
mode. (Before the mirror's retirement, `--all` also copied the Swift code from the monorepo's
`apple/` tree; that tree is gone and this repo hand-owns its Swift now, so the mode was removed.)
Always review the diff before committing a sync.

`scripts/native/xcodebuild-wrapper.sh` builds from the committed `Content/` snapshot (the bundler
isn't present here — it lives in the monorepo) — this is expected, not a bug.

## Build & test commands (verified against `package.json`)

```bash
npm run ios:generate            # scripts/native/ios-generate.sh: XcodeGen → apple/FlyGACA.xcodeproj
                                #   (installs xcodegen via brew/mint if missing)
npm run ios:test                # cd apple/FlyGACAKit && swift test — CAUTION: the &&/|| chain prints
                                #   "Swift not available" and exits 0 even when tests FAIL; run
                                #   `cd apple/FlyGACAKit && swift test` directly to see real red
npm run ios:test:watch          # swift test --watch
npm run ios:build:<app>         # debug build; <app> = elpt|aip
npm run ios:build:all           # debug build, every app
npm run ios:build:release:<app> # unsigned release archive (.xcarchive) + dSYM extraction
npm run ios:build:release:all
npm run ios:clean               # rm -rf FlyGACAKit/.build + Xcode DerivedData for FlyGACA (does NOT
                                #   touch apple/.build/, where archives/dSYMs/IPAs land)
npm run ios:info                # print environment + the available commands
npm run ios:screenshots         # apple/Scripts/html-render/render.js — Mac-free mockups, PORTRAIT only
                                #   (landscape: node apple/Scripts/html-render/render-landscape.js)
npm run firebase:register       # scripts/native/firebase-register-apps.sh — registers the Firebase iOS apps
npm run sync:content            # bash scripts/sync-content.sh (same as calling the script directly)
```

The Xcode project (`apple/FlyGACA.xcodeproj`) is **generated, never committed**;
`apple/project.yml` is the source of truth (gitignored: `apple/FlyGACA.xcodeproj/`,
`apple/.build/`, `apple/FlyGACAKit/.build/`). `FlyGACAKit` has zero external dependencies, so
`swift build`/`swift test` need no simulator or SDK downloads — always the fastest way to
verify a Swift-side change:

```bash
cd apple/FlyGACAKit && swift build && swift test
```

`scripts/native/xcodebuild-wrapper.sh <app|all|info> [debug|release] [scheme-override]` is the
orchestrator behind every `ios:build:*` script: checks prerequisites (it hard-requires a `node`
binary on PATH even though this repo has no bundler for node to run) → `xcodegen generate` →
content generation (or snapshot fallback, see above) → `xcodebuild`. Release env flags it honors
(CI-only): `FG_BUILD_NUMBER`, `FG_SIGNED_RELEASE=1` (+ `APPLE_TEAM_ID`),
`FG_PROVISIONING_PROFILE`, `FG_UPLOAD_TESTFLIGHT=1` (+ App Store Connect API key env). Debug
builds and unsigned release archives run with `CODE_SIGNING_ALLOWED=NO` — no Apple account
needed locally.

## CI (`.github/workflows/ios.yml`)

One workflow, adapted from the monorepo's iOS workflow (no content-validation job — this
repo has no bundler; no `npm ci` — thin `package.json`, zero deps). Triggers are pushes to
`main`, PRs **targeting** `main`, and `workflow_dispatch` — a push to a feature branch runs
nothing. Both event triggers carry `paths-ignore: ['**.md', 'docs/**']`, so a docs-only PR runs
**no jobs at all** and shows zero checks; that's the configuration working, not a stuck queue.
Jobs, all on `macos-15` unless noted:

- **swift-test** — `cd apple/FlyGACAKit && swift test`. Gates everything else.
- **xcodegen-validate** — installs XcodeGen, `xcodegen generate`, lists schemes.
- **check-signing** (`ubuntu-latest`) — turns presence of `BUILD_CERTIFICATE_BASE64` +
  `APP_STORE_CONNECT_API_KEY_ID` secrets into an `enabled` output (secrets can't be read in a
  job-level `if:`), gating `ios-testflight`.
- **ios-build** — matrix of every app, debug (`fail-fast: true` — one app's failure cancels
  the other). Writes a placeholder
  `GoogleService-Info.plist` first (`scripts/native/ci-firebase-placeholder.sh`) since the
  real plists are secrets, not committed. Artifacts retained 7 days.
- **ios-build-release** — every app, unsigned release archive, only on push to `main`.
  Artifacts (`.xcarchive` + dSYMs) retained 14/30 days.
- **ios-testflight** — `elpt` and `aip` (matrix is explicit, not derived from the app list),
  only on `main` push and only when `check-signing` says secrets exist. Imports cert + provisioning profile into a temp keychain, builds signed, exports
  `.ipa`, uploads via `xcrun altool`, cleans up the keychain. Adding an app to this lane needs
  an App ID, a profile and a `PROVISIONING_PROFILE_<APP>_BASE64` secret — see the runbook.
- **build-summary** (`ubuntu-latest`) — rolls up pass/fail into the job summary. It `needs`
  only swift-test/xcodegen-validate/ios-build — a failed release or TestFlight job does
  **not** turn it red.

## Signing, Firebase, and screenshots — where to look, don't improvise

These are one-time human/console setup, not something to script from first principles:

- **Signing / TestFlight** — `docs/RUNBOOK-ios-signing.md` (full walkthrough) +
  `docs/RUNBOOK-ios-signing-CHECKLIST.md` (condensed checklist). Scope is
  `com.flygaca.elpt/.aip`; manual signing (no Xcode-managed signing in CI) because the
  App Group entitlement rules out wildcard provisioning profiles. Nine named GitHub secrets;
  `scripts/native/set-signing-secrets.sh` uploads them from local files via `gh secret set`
  (defaults to `REPO=ay2m/FlyGACA` — note this repo's actual remote is
  `FlyGACA/FlyGACA-ios`, so pass `REPO=` explicitly). Provisioning profile names are
  load-bearing (`FlyGACA <APP> AppStore` — passed as `PROVISIONING_PROFILE_SPECIFIER`). Note
  `apple/Apps/Shared/App.entitlements` **no longer declares Sign in with Apple** (removed
  2026-08) — the shipping apps are paid-up-front and fully offline, so signing needs only the
  App Group. Re-adding it means enabling the capability on every App ID and regenerating the
  profiles.
- **Firebase** — `docs/RUNBOOK-ios-firebase.md`. One Firebase project (`flygaca-app`) backs
  both bundle ids; `npm run firebase:register` (`scripts/native/firebase-register-apps.sh`)
  scripts the app registrations + plist downloads (idempotent, never overwrites without
  `FORCE=1`). Sign in with Apple provider setup + APNs key remain manual (no API covers
  Apple's provider/portal). **If sign-in ever ships, grouping the App IDs under one primary is
  load-bearing** — without it, one Apple user signing into two family apps gets two different
  Apple-issued identifiers and two separate Firebase accounts, breaking the shared-account
  model the App Group is built for. That primary is **`com.flygaca.elpt`** — every doc now says
  so (`RUNBOOK-ios-firebase.md` §4a, `PORTAL-RUNSHEET-wave1.md` §1.2,
  `RUNBOOK-ios-release.md`), and the old `com.flygaca.ppl` designation is recorded as moot: the
  App IDs never carried the capability, so no Apple user identifier was issued under it. Only the
  portal work is outstanding.
  `GoogleService-Info.plist`
  files are gitignored (`apple/Apps/*/GoogleService-Info.plist`) but not secret — they ship
  inside the app binary; access is enforced by Firestore rules + App Check, not file secrecy.
  They're declared `optional: true` in `project.yml` so generation/unsigned builds work
  without them.
- **Screenshots** — two independent pipelines under `apple/Scripts/`:
  - `apple/Scripts/html-render/` (`render.js` portrait — what `npm run ios:screenshots` runs —
    `render-landscape.js` landscape, by hand) —
    Mac-free HTML/CSS mockups via Playwright + Chromium. The per-screen work lives in
    `screens.js` (one function per screen, palette copied verbatim from
    `FeatureUI/Theme.swift`, content read live from `Apps/<App>/Content/*.json`); its README
    documents the output contract and a screen-fn ↔ SwiftUI-source parity table to update
    when a view changes. Use this when there's no Mac available or for marketing/App
    Store copy needing quick iteration.
  - `apple/Scripts/capture-screenshots.sh` + `process-screenshots.sh` — real simulator
    captures (pixel-exact, needs a Mac + Xcode). `AppleTests/ScreenshotTests.swift` documents
    the `XCUITest` snapshot flow and is wired into `apple/project.yml` as `AppleTests`
    (`testTargets: [AppleTests]`).

## Conventions & gotchas worth knowing before editing

- **The apps still ship on mocks.** `PlatformLive` exists and is tested, but nothing injects it
  (see above), so `AppServices`'s `Mocks.swift` *is* the shipping product and the apps are fully
  offline by design. Keep any new platform integration inside `PlatformLive`.
- **`FlyGACAApp.swift` (`apple/Apps/Shared/`) is the one app shell for every target.**
  Never fork it per app; per-app differences are xcconfig values (`FG_MODULE_ID`, bundle id,
  display name) injected via `Info.plist`, not code.
- **Adding a new module app is a data/config change, not a Swift change**: new pack entry in
  the monorepo's `prepCatalog.ts` → `Content/` synced here → a 3-line `apple/project.yml`
  target + a small `.xcconfig` → `npm run ios:generate`. AIP is the worked example.
- **XcodeGen emits the Xcode 16 project format** (`objectVersion 77`) — open/build with Xcode
  16+ only; CI pins `macos-15` runners for this reason. `apple/project.yml`'s own comment is
  authoritative, and `apple/README.md:1` now agrees (it used to say "Xcode 15+").
- **`docs/RUNBOOK-ios-*.md`, `apple/ARCHITECTURE.md` and `apple/README.md` are now natively
  owned here** (they began as copies of the monorepo's, but the `apple/` mirror was retired
  2026-08, so this is the real source — edit them here). A couple still describe the *content*
  bundler (`build-ios-content.mjs`, `npm run ios:icons`) as if present in this repo; it isn't —
  it lives in the monorepo and `scripts/sync-content.sh` invokes it. `docs/RUNBOOK-ios-release.md`
  is the release path; `docs/README.md` indexes the set. `docs/RUNBOOK-ios-xcodebuild.md` is the
  build/CI/troubleshooting reference (incl. "Adding a New iOS App") — but its Phase Roadmap
  numbers phases differently from `ARCHITECTURE.md` §5: its "Phase 4 ✅" is the signing/TestFlight
  slice, **not** PlatformLive.
- **Tests span 5 targets / 11 files** — `CoreModelsTests` (ModuleManifest, QuizDecode),
  `StudyEnginesTests` (Leitner, Readiness, Sampler, Session, Streak), `ContentKitTests`
  (ContentLoader, ContentRefresher), `PersistenceKitTests` (StudyStore) and `PlatformLiveTests`
  — not just the SRS parity vectors.
- **License:** MIT, © BDA Company International, operating as Fly GACA.
- Per-app bundle ids follow `com.flygaca.<lowercase module>`; module ids (`FG_MODULE_ID`,
  e.g. `elp`, `aip`) are the pack ids from the monorepo's
  `prepCatalog.ts` and must match exactly — verify with the loop in
  `docs/RUNBOOK-ios-firebase.md` §2 if plists ever look swapped.
- No `node_modules`/JS dependencies beyond the optional Playwright screenshot renderer —
  `package.json` exists purely as an npm-script dispatcher for the shell/Swift tooling above.

## Disclaimer (mirrors every other Fly GACA surface — do not reword)

Fly GACA is an independent educational platform, not affiliated with, endorsed by, or
operated by GACA or the Government of Saudi Arabia. GACA (gaca.gov.sa) is always the
authoritative source; the apps cite it and defer to it.
