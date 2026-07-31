# CLAUDE.md

Guidance for AI coding assistants working in this repository.

## What this is

**ay2m/FlyGACA** is the native SwiftUI home of the Fly GACA study-app family: **one shared
Swift package (`FlyGACAKit`) plus one App Store app target per study module** — PPL, ELPT,
AIP, CPL, IR, ATPL — sold together via an App Store **app bundle**. Every app ships the
identical offline feature set (study mode, quizzing, flashcards with spaced repetition,
mock tests, timed scored exam sim with analytics). **A module is data, not code** — adding
an app means adding a `Content/` folder and a ~20-line Xcode target, never new Swift.

This repo has **no build step of its own for content or corpus** — it consumes both from
the web monorepo. Read `apple/ARCHITECTURE.md` (the why: target graph, data contracts, App
Store strategy) and `apple/README.md` (the how: Mac setup) before making non-trivial
changes; both are denser and more authoritative than this file for anything Swift-side.

### The Fly GACA repo family

| Repo | Holds |
|---|---|
| **ay2m/FlyGACA** (this repo) | Native iOS app family — FlyGACAKit + six app targets |
| `FlyGACA/FlyGACA-app` | flygaca.com — React/Vite PWA, Firebase backend, regulatory corpus + content pipelines. **Source of truth** for content (`public/data/`, `src/lib/prepCatalog.ts`) and for `scripts/build-ios-content.mjs` / `npm run ios:icons`, which this repo does not have. |
| `FlyGACA/Captain-Adel` | The AI flight-instructor service (captadel.com) |
| `FlyGACA/PPL` · `CPL` · `IR` · `ATPL` · `ELPT` · `AIP` | Per-app **App Store metadata repos** — store listing copy (EN/AR), screenshots, per-app roadmap. They hold **no source code**; they reference this repo's `apple/Apps/<Module>/` as the code home. If a task is "update the App Store description/screenshots for X", it belongs in that module's own repo, not here. |
| `FlyGACA/Office` | Business/governance/legal/finance docs |

`FlyGACA-app`'s own `apple/` folder is a legacy copy of this same tree; the monorepo README
says it is being retired in favor of this repo. Until then, content flows **monorepo → here**
one-way (`scripts/sync-content.sh`), never the reverse.

## Architecture (see `apple/ARCHITECTURE.md` for full detail)

**Stack:** Swift 5.9+, SwiftUI, SwiftData, iOS 17+ floor. MVVM with light Clean layering, as
**one local Swift package with multiple library targets** — no multi-package overhead.
Storage: SwiftData for user state; content is read-only JSON decoded into structs (the whole
corpus is ~158 KB, too small to justify a database).

### Target graph (`apple/FlyGACAKit/Package.swift`)

```
CoreModels (no deps)
  ├─ StudyEngines   (SRS, sessions, streaks, sampler, readiness — no IO)
  ├─ ContentKit     (bundled/cached content loading + remote refresh — no Firebase)
  └─ AppServices    (protocol seams + offline mocks)
       PersistenceKit (SwiftData @Model + StudyStore actor; deps: CoreModels, StudyEngines)
FeatureUI (deps: all of the above — every screen, incl. SingleModuleRootView)
PlatformLive (Phase 4, not yet built — Firebase/RevenueCat live only here)
```

Rules that keep this healthy — do not violate them:

- **Engines never do IO.** `StudySession` takes `now: Date` as a parameter; tests pass fixed
  dates. `swift test` needs no simulator, no SDK downloads.
- **Firebase/RevenueCat never leak upstream** of the not-yet-built `PlatformLive` target.
  Keeps the pure targets instant to build and every screen previewable via `AppServices` mocks.
- **UI talks to protocols** (`AuthProviding`, `EntitlementsProviding`, `ProgressSyncing`,
  `ChatClient` in `AppServices`), not concrete platform SDKs.

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
  fixes this at decode time by hashing `sha256("bankID|prompt")` → `Question.id`, while
  retaining `index`/`legacyKey` for progress parity across content refreshes.

User state lives in SwiftData, App Group `group.com.flygaca.study` (shared by every app in
the family on-device, so streaks/SRS carry across apps). `StudyStore` (a `@ModelActor`) is
the single write path; SwiftData model objects never escape the actor (they aren't `Sendable`).

## Content: committed snapshots, not generated here

Each app ships `apple/Apps/<App>/Content/` (`module.json`, `quiz.json`, plus
`groundschool.json` / `paths-index.json` where the pack has them). **This repo does not
contain the content bundler** (`scripts/build-ios-content.mjs`) — that script, the
regulatory corpus (`public/data/`), and the pack catalog (`src/lib/prepCatalog.ts`) all live
in the `FlyGACA-app` monorepo. Here, `Content/` folders (and the per-app icons, generated by
the monorepo's `npm run ios:icons`) are **committed snapshots**, refreshed by:

```bash
# with a FlyGACA-app clone next to this repo (default ../FlyGACA-app), or pass its path
bash scripts/sync-content.sh [path-to-FlyGACA-app] [--all]
```

Default mode syncs the six `Content/` + `Assets.xcassets` folders only. `--all` additionally
syncs `FlyGACAKit/{Sources,Tests}`, `Apps/Shared/`, each app's `.xcconfig`, `AppleTests/`,
`apple/Scripts/`, `project.yml`, `ARCHITECTURE.md` and `apple/README.md` — i.e. the whole
`apple/` tree tracking the monorepo verbatim. Always review the diff before committing a sync.

Because the bundler is absent here, `scripts/native/xcodebuild-wrapper.sh` falls back to
building from the committed `Content/` snapshot when `scripts/build-ios-content.mjs` isn't
found (it only exists in the monorepo checkout) — this is expected, not a bug.

**Note:** `apple/README.md` and the `docs/RUNBOOK-ios-*.md` files are themselves synced
verbatim from the monorepo and are written from *its* point of view — they reference
`node scripts/build-ios-content.mjs` and `npm run ios:icons` as if present here. They are
not; use `scripts/sync-content.sh` instead when those docs say to regenerate content/icons.

## Build & test commands (verified against `package.json`)

```bash
npm run ios:generate            # XcodeGen → apple/FlyGACA.xcodeproj (installs xcodegen via brew/mint if missing)
npm run ios:test                # cd apple/FlyGACAKit && swift test (no-op with a message if swift is unavailable)
npm run ios:test:watch          # swift test --watch
npm run ios:build:<app>         # debug build; <app> = ppl|elpt|aip|cpl|ir|atpl
npm run ios:build:all           # debug build, all six
npm run ios:build:release:<app> # unsigned release archive (.xcarchive) + dSYM extraction
npm run ios:build:release:all
npm run ios:clean               # rm -rf FlyGACAKit/.build + Xcode DerivedData for FlyGACA
npm run ios:info                # print environment (Xcode/Swift versions, available commands)
npm run ios:screenshots         # node apple/Scripts/html-render/render.js — Mac-free marketing mockups
npm run firebase:register       # scripts/native/firebase-register-apps.sh — registers the six Firebase iOS apps
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

`scripts/native/xcodebuild-wrapper.sh <app|all|info> [debug|release]` is the orchestrator
behind every `ios:build:*` script: checks prerequisites → `xcodegen generate` → content
generation (or snapshot fallback, see above) → `xcodebuild`. Release env flags it honors
(CI-only): `FG_BUILD_NUMBER`, `FG_SIGNED_RELEASE=1` (+ `APPLE_TEAM_ID`),
`FG_PROVISIONING_PROFILE`, `FG_UPLOAD_TESTFLIGHT=1` (+ App Store Connect API key env). Debug
builds and unsigned release archives run with `CODE_SIGNING_ALLOWED=NO` — no Apple account
needed locally.

## CI (`.github/workflows/ios.yml`)

One workflow, adapted from the monorepo's iOS workflow (no content-validation job — this
repo has no bundler; no `npm ci` — thin `package.json`, zero deps). Jobs, all on
`macos-15` unless noted:

- **swift-test** — `cd apple/FlyGACAKit && swift test`. Gates everything else.
- **xcodegen-validate** — installs XcodeGen, `xcodegen generate`, lists schemes.
- **check-signing** (`ubuntu-latest`) — turns presence of `BUILD_CERTIFICATE_BASE64` +
  `APP_STORE_CONNECT_API_KEY_ID` secrets into an `enabled` output (secrets can't be read in a
  job-level `if:`), gating `ios-testflight`.
- **ios-build** — matrix of all six apps, debug, on every push/PR. Writes a placeholder
  `GoogleService-Info.plist` first (`scripts/native/ci-firebase-placeholder.sh`) since the
  real plists are secrets, not committed. Artifacts retained 7 days.
- **ios-build-release** — all six apps, unsigned release archive, only on push to `main`.
  Artifacts (`.xcarchive` + dSYMs) retained 14/30 days.
- **ios-testflight** — **Wave 1 only** (`ppl`, `elpt`, `aip` — matrix is explicit, not derived
  from the six-app list), only on `main` push and only when `check-signing` says secrets
  exist. Imports cert + provisioning profile into a temp keychain, builds signed, exports
  `.ipa`, uploads via `xcrun altool`, cleans up the keychain. Wave 2 (CPL/IR/ATPL) build and
  archive in CI but are **not yet signed/uploaded** — see the runbook to add one.
- **build-summary** (`ubuntu-latest`) — rolls up pass/fail into the job summary.

## Signing, Firebase, and screenshots — where to look, don't improvise

These are one-time human/console setup, not something to script from first principles:

- **Signing / TestFlight** — `docs/RUNBOOK-ios-signing.md` (full walkthrough) +
  `docs/RUNBOOK-ios-signing-CHECKLIST.md` (condensed checklist). Wave-1-only scope
  (`com.flygaca.ppl/.elpt/.aip`); manual signing (no Xcode-managed signing in CI) because the
  App Group entitlement rules out wildcard provisioning profiles. Ten named GitHub secrets;
  `scripts/native/set-signing-secrets.sh` uploads them from local files via `gh secret set`
  (defaults to `REPO=ay2m/FlyGACA`). Provisioning profile names are load-bearing (`FlyGACA
  <APP> AppStore` — passed as `PROVISIONING_PROFILE_SPECIFIER`).
- **Firebase** — `docs/RUNBOOK-ios-firebase.md`. One Firebase project (`flygaca-app`) backs
  all six bundle ids; `npm run firebase:register` (`scripts/native/firebase-register-apps.sh`)
  scripts the six app registrations + plist downloads (idempotent, never overwrites without
  `FORCE=1`). Sign in with Apple provider setup + APNs key remain manual (no API covers
  Apple's provider/portal). **Grouping the six App IDs under one primary
  (`com.flygaca.ppl`) is load-bearing** — without it, one Apple user signing into two family
  apps gets two different Apple-issued identifiers and two separate Firebase accounts,
  breaking the shared-account model the App Group is built for. `GoogleService-Info.plist`
  files are gitignored (`apple/Apps/*/GoogleService-Info.plist`) but not secret — they ship
  inside the app binary; access is enforced by Firestore rules + App Check, not file secrecy.
  They're declared `optional: true` in `project.yml` so generation/unsigned builds work
  without them.
- **Screenshots** — two independent pipelines under `apple/Scripts/`:
  - `apple/Scripts/html-render/` (`render.js` portrait, `render-landscape.js` landscape) —
    Mac-free HTML/CSS mockups via Playwright + Chromium, styled from the real
    `FeatureUI/Theme.swift` palette and reading live from `Apps/PPL/Content/*.json`. Run via
    `npm run ios:screenshots`. Use this when there's no Mac available or for marketing/App
    Store copy needing quick iteration.
  - `apple/Scripts/capture-screenshots.sh` + `process-screenshots.sh` — real simulator
    captures (pixel-exact, needs a Mac + Xcode). `AppleTests/ScreenshotTests.swift` documents
    the intended `XCUITest` snapshot flow but is **not yet wired into `apple/project.yml`**
    (`testTargets: []` on every target) — it can't run via `xcodebuild test` today.

## Conventions & gotchas worth knowing before editing

- **PlatformLive doesn't exist yet** (Phase 4 of the roadmap in `ARCHITECTURE.md` §5). Until
  it lands, the apps are fully offline by design and `AppServices` mocks (`Mocks.swift`) *are*
  the shipping product — do not add Firebase/RevenueCat imports anywhere else.
- **`FlyGACAApp.swift` (`apple/Apps/Shared/`) is the one app shell for all six targets.**
  Never fork it per app; per-app differences are xcconfig values (`FG_MODULE_ID`, bundle id,
  display name) injected via `Info.plist`, not code.
- **Adding a new module app is a data/config change, not a Swift change**: new pack entry in
  the monorepo's `prepCatalog.ts` → `Content/` synced here → a 3-line `apple/project.yml`
  target + a small `.xcconfig` → `npm run ios:generate`. CPL/IR/ATPL are the worked example.
- **XcodeGen emits the Xcode 16 project format** (`objectVersion 77`) — open/build with Xcode
  16+ only; CI pins `macos-15` runners for this reason.
- **`docs/RUNBOOK-ios-*.md` and `apple/README.md` are monorepo-authored** (each carries a note
  banner to this effect) and describe tools this repo doesn't ship
  (`build-ios-content.mjs`, `npm run ios:icons`). When they conflict with what's actually
  runnable here, trust `scripts/sync-content.sh` and this file.
- Per-app bundle ids follow `com.flygaca.<lowercase module>`; module ids (`FG_MODULE_ID`,
  e.g. `ppl-exam`, `elp`, `aip`, `cpl`, `ir`, `atpl`) are the pack ids from the monorepo's
  `prepCatalog.ts` and must match exactly — verify with the loop in
  `docs/RUNBOOK-ios-firebase.md` §2 if plists ever look swapped.
- No `node_modules`/JS dependencies beyond the optional Playwright screenshot renderer —
  `package.json` exists purely as an npm-script dispatcher for the shell/Swift tooling above.

## Disclaimer (mirrors every other Fly GACA surface — do not reword)

Fly GACA is an independent educational platform, not affiliated with, endorsed by, or
operated by GACA or the Government of Saudi Arabia. GACA (gaca.gov.sa) is always the
authoritative source; the apps cite it and defer to it.
