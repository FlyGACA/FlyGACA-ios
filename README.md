# Fly GACA — iOS App Family

*find it · study it · always verify against GACA*

<p>
  <a href="https://github.com/ay2m/FlyGACA/actions/workflows/ios.yml"><img src="https://img.shields.io/github/actions/workflow/status/ay2m/FlyGACA/ios.yml?style=for-the-badge&label=CI&labelColor=0a0e12&color=2d6e8a" alt="CI Status" /></a>
  <a href="LICENSE"><img src="https://img.shields.io/badge/license-MIT-8fc9a8?style=for-the-badge&labelColor=0a0e12" alt="License" /></a>
</p>

The native SwiftUI home of the Fly GACA study apps: **one shared Swift package
(`FlyGACAKit`), one App Store app per study module** — ELPT and AIP — sold
together via an App Store app bundle. Every app carries the same offline feature
set (study mode, quizzing, flashcards with spaced repetition, mock tests and
timed scored exam prep with analytics); a module is **data, not code**.

<p align="center">
  <img src="apple/Apps/ELPT/Assets.xcassets/AppIcon.appiconset/AppIcon-1024.png" alt="ELPT" width="64" />
  <img src="apple/Apps/AIP/Assets.xcassets/AppIcon.appiconset/AppIcon-1024.png" alt="AIP" width="64" />
  <br /><sub>ELPT · AIP</sub>
</p>

> The licence-exam modules (PPL, CPL, IR, ATPL) are **paused** pending a
> strategic decision and are not currently built or shipped from this repo. Their
> targets and content remain in git history; see [`ROADMAP.md`](ROADMAP.md).

This repo is the dedicated iOS workspace. The blueprint is
[`apple/ARCHITECTURE.md`](apple/ARCHITECTURE.md); the 10-minute Mac setup is
[`apple/README.md`](apple/README.md) (written from the monorepo's point of view —
see [Content](#content-committed-snapshots) below for how content works *here*).

## The docs

| Doc | What it is |
| --- | --- |
| [`CAUSE.md`](CAUSE.md) | Why Fly GACA exists — the mission and the seven principles |
| [`ROADMAP.md`](ROADMAP.md) | Open work in this repo — the single source of truth for what's next |
| [`MIGRATION.md`](MIGRATION.md) | How the iOS family moved out of the web monorepo (history only) |
| [`SEO-PLAN.md`](SEO-PLAN.md) | App Store search (ASO) strategy for the shipping apps |
| [`THE-BOOK-OF-FLY-GACA.md`](THE-BOOK-OF-FLY-GACA.md) | The whole-family reference — all ten repos, one book |
| [`CONTRIBUTING.md`](CONTRIBUTING.md) | Setup, testing, the sync boundary, PR expectations |
| [`docs/`](docs/README.md) | Runbooks — the repo-native release path + the monorepo-authored set, and which is which |
| [`apple/ARCHITECTURE.md`](apple/ARCHITECTURE.md) | The engineering blueprint (monorepo-synced — edit it there, not here) |
| [`CLAUDE.md`](CLAUDE.md) | Conventions & gotchas for AI-assisted work |

## Quickstart (Mac, Xcode 16+)

```bash
npm run ios:generate        # XcodeGen → apple/FlyGACA.xcodeproj (installs xcodegen if missing)
open apple/FlyGACA.xcodeproj
# pick a scheme (ELPT, AIP) and run — fully offline

npm run ios:test            # swift test — FlyGACAKit unit + web-parity suites
npm run ios:build:elpt      # headless debug build (also: aip / all)
```

The Xcode project is **generated, never committed** — `apple/project.yml` is the
source of truth. The package has zero external dependencies, so `swift build` /
`swift test` need no simulator and no SDK downloads.

> [!IMPORTANT]
> When you need a real verdict, run `cd apple/FlyGACAKit && swift test` directly —
> the `npm run ios:test` alias prints "Swift not available; skipping iOS tests"
> and **exits 0 even when tests fail**.

## The apps

| App | Bundle id | Module id | Banks · questions (bundled, 2026-08) |
| --- | --- | --- | --- |
| ELPT | `com.flygaca.elpt` | `elp` | 5 · 191 |
| AIP | `com.flygaca.aip` | `aip` | 3 · 113 |

Mind the asymmetry: ELPT's module id is `elp`, not `elpt`. ELPT's count includes
the scenario bank in `quiz-extra.json`.

The four licence-exam modules — PPL (`ppl-exam`), CPL (`cpl`), IR (`ir`) and ATPL
(`atpl`) — are **paused**: their targets, xcconfigs and bundled content were
removed from this repo and live only in git history. Their App Store metadata
repos are untouched and marked parked. See [`ROADMAP.md`](ROADMAP.md).

## Layout

```
apple/
  ARCHITECTURE.md      the why — target graph, data contracts, App Store strategy
  README.md            the how — Mac setup, adding the next app
  project.yml          XcodeGen spec (one ~20-line target per app)
  FlyGACAKit/          the shared package: CoreModels · StudyEngines · ContentKit ·
                       PersistenceKit · AppServices · FeatureUI (+ full test suite)
  Apps/
    Shared/            FlyGACAApp.swift — THE app shell, shared by every target
    ELPT/ AIP/         per-app xcconfig (bundle id, module id, display name),
                       Assets.xcassets (app icon), Content/ (bundled module data)
  AppleTests/          simulator screenshot tests
  Scripts/             marketing screenshot pipeline (simulator + HTML fallback)
scripts/
  native/              ios-generate.sh · xcodebuild-wrapper.sh (build/archive/TestFlight)
  sync-content.sh      refresh content + icons from a FlyGACA-app clone (see below)
docs/                  RUNBOOK-ios-release (repo-native) + the monorepo-authored
                       RUNBOOK-ios-* set — docs/README.md indexes which is which
```

## Content: committed snapshots

Each app ships a `Content/` folder (`module.json`, `quiz.json`, plus ground
school and reading paths where the pack has them). The **source of truth for
content stays in the [FlyGACA-app](https://github.com/FlyGACA/FlyGACA-app)
monorepo** — the regulatory corpus (`public/data/`) and the pack catalog
(`src/lib/prepCatalog.ts`). In this repo the `Content/` folders are committed
snapshots. To refresh them (and the app icons, which are generated by the
monorepo's `npm run ios:icons`):

```bash
# with a FlyGACA-app clone next to this repo (or pass its path)
bash scripts/sync-content.sh [path-to-FlyGACA-app] [--all]
```

`--all` also syncs `FlyGACAKit/`, the shared shell, `project.yml` and the apple
docs, keeping the whole `apple/` tree tracking the monorepo. While
`FlyGACA-app/apple/` still exists there, treat the monorepo as canonical and
sync **monorepo → here**; once this repo is proven as the iOS home, the
monorepo copy can be retired.

## CI

`.github/workflows/ios.yml` (ported from the monorepo's iOS workflow) runs on
pushes to `main`, PRs targeting `main`, and manual dispatch — a push to a feature
branch runs nothing. The jobs: `swift test` for FlyGACAKit — including the
cross-platform parity vectors for spaced repetition and exam scoring; keep them
green — an `xcodegen generate` validation of `apple/project.yml`, and unsigned
debug builds of every app on macOS runners. Pushes to `main` additionally
produce unsigned release archives; the TestFlight upload job stays skipped until
the signing secrets exist (`docs/RUNBOOK-ios-signing.md`). A green
`build-summary` covers tests and debug builds only — release/TestFlight failures
don't turn it red. The end-to-end path:
[`docs/RUNBOOK-ios-release.md`](docs/RUNBOOK-ios-release.md).

## The Fly GACA repos

| Repo | What it holds |
| --- | --- |
| **[ay2m/FlyGACA](https://github.com/ay2m/FlyGACA)** (this repo) | Native iOS app family — FlyGACAKit + the ELPT and AIP app targets |
| [FlyGACA/FlyGACA-app](https://github.com/FlyGACA/FlyGACA-app) | flygaca.com — web app (React/Vite PWA), Firebase backend, regulatory corpus + content pipelines |
| [FlyGACA/Captain-Adel](https://github.com/FlyGACA/Captain-Adel) | Captain Adel — the AI flight-instructor service (captadel.com + the brain behind chat) |
| [FlyGACA/ELPT](https://github.com/FlyGACA/ELPT) · [AIP](https://github.com/FlyGACA/AIP) | Per-app App Store homes — store metadata (EN/AR), screenshots, per-app roadmap |
| [FlyGACA/PPL](https://github.com/FlyGACA/PPL) · [CPL](https://github.com/FlyGACA/CPL) · [IR](https://github.com/FlyGACA/IR) · [ATPL](https://github.com/FlyGACA/ATPL) | App Store homes for the **paused** licence-exam modules — metadata retained, nothing shipping |
| [FlyGACA/Office](https://github.com/FlyGACA/Office) | The business operating system — strategy, governance, legal, finance, GTM docs |

The app lineup and wave plan live in the monorepo's
`docs/APPS-FAMILY-ROADMAP.md`; per-app store listings live in each app's repo.

## Contribute

[`CONTRIBUTING.md`](CONTRIBUTING.md) has the short version — setup, the direct
`swift test` rule, and where each kind of change belongs (monorepo vs metadata
repos vs here). The whole-family picture is
[`THE-BOOK-OF-FLY-GACA.md`](THE-BOOK-OF-FLY-GACA.md).

## Disclaimer

**Fly GACA is an independent educational platform.** It is not affiliated with, endorsed by, or operated by the General Authority of Civil Aviation (GACA) or the Government of the Kingdom of Saudi Arabia. The official and authoritative source for all civil aviation regulations, publications, and aeronautical information is always GACA. Always verify against the latest official GACA publication at gaca.gov.sa.

<div dir="rtl">

**فلاي جاكا منصة تعليمية مستقلة.** وهي غير تابعة للهيئة العامة للطيران المدني (GACA) ولا معتمدة منها ولا تُديرها، كما أنها لا تمثّل حكومة المملكة العربية السعودية. المصدر الرسمي والمعتمد لجميع لوائح الطيران المدني ومنشوراته ومعلوماته الجوية هو GACA دائمًا. تحقّق دائمًا من أحدث منشور رسمي صادر عن GACA على gaca.gov.sa.

</div>

## License

[MIT](LICENSE) © BDA Company International (شركة بدع الدولية), operating as Fly GACA.

<p align="center"><sub>صُنع في السعودية 🇸🇦 · Made in Saudi Arabia</sub></p>
