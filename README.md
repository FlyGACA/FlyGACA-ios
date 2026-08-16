<div align="center">

# 📱 Fly GACA — Native iOS App Family

### The native SwiftUI flight deck for Saudi civil aviation

*_find it · study it · always verify against GACA_*

<p>
  <a href="https://github.com/ay2m/FlyGACA/actions/workflows/ios.yml"><img src="https://img.shields.io/github/actions/workflow/status/ay2m/FlyGACA/ios.yml?style=for-the-badge&label=CI&labelColor=0a0e12&color=2d6e8a" alt="CI Status" /></a>
  <a href="apple/FlyGACAKit/Package.swift"><img src="https://img.shields.io/badge/Swift-5.9%2B-F05138?style=for-the-badge&logo=swift&logoColor=white&labelColor=0a0e12" alt="Swift 5.9+" /></a>
  <a href="apple/project.yml"><img src="https://img.shields.io/badge/iOS-17%2B-2d6e8a?style=for-the-badge&logo=apple&logoColor=white&labelColor=0a0e12" alt="iOS 17+" /></a>
  <a href="LICENSE"><img src="https://img.shields.io/badge/license-MIT-8fc9a8?style=for-the-badge&labelColor=0a0e12" alt="License" /></a>
</p>

<p align="center">
  <img src="apple/Apps/ELPT/Assets.xcassets/AppIcon.appiconset/AppIcon-1024.png" alt="ELPT" width="64" />
  &nbsp;&nbsp;&nbsp;&nbsp;
  <img src="apple/Apps/AIP/Assets.xcassets/AppIcon.appiconset/AppIcon-1024.png" alt="AIP" width="64" />
  <br /><sub><b>ELPT · AIP App Store Targets</b></sub>
</p>

</div>

---

## 📌 Overview

The **Fly GACA iOS App Family** is the native SwiftUI counterpart to [flygaca.com](https://flygaca.com). It implements a modular architecture built around **one shared Swift package (`FlyGACAKit`)** and **individual App Store targets** for each study module:

- **ELPT** (`com.flygaca.elpt`) — English Language Proficiency exam prep.
- **AIP** (`com.flygaca.aip`) — Aeronautical Information Publication study deck.

Every target delivers a 100% offline-capable feature set (spaced-repetition flashcards, timed mock exams, quiz banks, ground school reading paths, and exam analytics). Data persistence is powered by **SwiftData**, with shared user progress across targets managed via an App Group.

> [!NOTE]
> The four licence-exam targets (**PPL**, **CPL**, **IR**, **ATPL**) are **paused** pending strategic review. Their code, targets, and question data remain preserved in git history and their metadata repos remain intact; see [`ROADMAP.md`](ROADMAP.md).

---

## 📂 Repository Documentation

| Document | Purpose & Contents |
| --- | --- |
| [`apple/ARCHITECTURE.md`](apple/ARCHITECTURE.md) | **Engineering Blueprint** — Target graph, SwiftData contracts, App Group configuration |
| [`apple/README.md`](apple/README.md) | **Mac Setup Guide** — Detailed developer setup and target generation walkthrough |
| [`CAUSE.md`](CAUSE.md) | **Mission & Principles** — Why Fly GACA exists and our 7 core principles |
| [`ROADMAP.md`](ROADMAP.md) | **Active Work & Backlog** — Single source of truth for upcoming feature releases |
| [`MIGRATION.md`](MIGRATION.md) | **Monorepo Separation** — Historical log of iOS code extraction from web monorepo |
| [`SEO-PLAN.md`](SEO-PLAN.md) | **ASO Strategy** — App Store Search Optimization for ELPT and AIP targets |
| [`THE-BOOK-OF-FLY-GACA.md`](THE-BOOK-OF-FLY-GACA.md) | **Ecosystem Reference** — Cross-repository manual mapping all 10 Fly GACA repos |
| [`CONTRIBUTING.md`](CONTRIBUTING.md) | **Contributor Guide** — Testing conventions, sync boundary rules, PR standards |
| [`docs/`](docs/README.md) | **Runbooks Index** — Release execution (`RUNBOOK-ios-release`), signing, TestFlight |

---

## ⚡ Quickstart (Mac, Xcode 16+)

```bash
# 1. Generate Xcode project from XcodeGen specification
npm run ios:generate        # Generates apple/FlyGACA.xcodeproj (installs xcodegen if missing)

# 2. Open project in Xcode
open apple/FlyGACA.xcodeproj
# Select target (ELPT or AIP) and run on simulator or device (fully offline)

# 3. Test FlyGACAKit package directly
cd apple/FlyGACAKit && swift test

# 4. Headless build verification
npm run ios:build:elpt      # Headless debug build for ELPT (or: aip / all)
```

> [!IMPORTANT]
> **Testing Directive:** When verifying changes, run `cd apple/FlyGACAKit && swift test` directly. The root `npm run ios:test` wrapper may skip Swift execution if environment paths are missing.

---

## 📱 App Target Lineup

| Target | Bundle ID | Module ID | Bundled Content Snapshot |
| --- | --- | --- | --- |
| **ELPT** | `com.flygaca.elpt` | `elp` | 5 question banks · 191 questions + scenario bank |
| **AIP** | `com.flygaca.aip` | `aip` | 3 question banks · 113 questions |

*Note: ELPT utilizes module identifier `elp` internally.*

---

## 🏗 Directory & Package Architecture

```
apple/
├── ARCHITECTURE.md      # Architectural blueprint & target graph
├── project.yml          # XcodeGen specification (defines target per app)
├── FlyGACAKit/          # 📦 Shared Swift Package
│   ├── Sources/
│   │   ├── CoreModels/       # Data entities & schema definitions
│   │   ├── StudyEngines/     # Spaced repetition, scoring & timer logic
│   │   ├── ContentKit/       # JSON content parsing & validation
│   │   ├── PersistenceKit/   # SwiftData container & App Group sync
│   │   ├── AppServices/      # Haptics, notifications & audio
│   │   └── FeatureUI/        # Shared SwiftUI views & design components
│   └── Tests/                # Comprehensive unit & cross-platform parity tests
├── Apps/
│   ├── Shared/          # Shared FlyGACAApp.swift app entry point
│   ├── ELPT/            # ELPT xcconfig, Assets.xcassets & Content/ JSON
│   └── AIP/             # AIP xcconfig, Assets.xcassets & Content/ JSON
scripts/
├── native/              # Build wrappers (ios-generate.sh, xcodebuild-wrapper.sh)
└── sync-content.sh      # Content refresh script from FlyGACA-app monorepo
docs/                    # Release runbooks (RUNBOOK-ios-release, signing, etc.)
```

---

## 🔄 Content Synchronization

Content files (`module.json`, `quiz.json`, ground school decks) in `apple/Apps/*/Content/` are committed snapshots. The **authoritative source of truth for content** is the [FlyGACA-app](https://github.com/FlyGACA/FlyGACA-app) monorepo.

To pull updated content snapshots into this repository:

```bash
# Refresh content from a local FlyGACA-app clone
bash scripts/sync-content.sh ../FlyGACA-app
```

---

## ⚙️ Continuous Integration (CI)

The CI pipeline (`.github/workflows/ios.yml`) validates every PR and push to `main`:

1. **Unit & Parity Tests:** Executes `swift test` across `FlyGACAKit`, testing spaced-repetition math and scoring parity against the web app.
2. **XcodeGen Validation:** Verifies that `apple/project.yml` compiles into a valid `.xcodeproj`.
3. **Headless Builds:** Builds unsigned debug binaries for all targets on macOS GitHub runners.

---

## 🌐 The Fly GACA Repository Ecosystem

| Repository | Role & Description |
| --- | --- |
| **[ay2m/FlyGACA](https://github.com/ay2m/FlyGACA)** (this repo) | Native iOS app family — `FlyGACAKit` package + ELPT and AIP App Store targets |
| [FlyGACA/FlyGACA-app](https://github.com/FlyGACA/FlyGACA-app) | flygaca.com — React 19 + Vite 8 PWA web app, Firebase backend (`me-central1`), content pipelines |
| [FlyGACA/Captain-Adel](https://github.com/FlyGACA/Captain-Adel) | Captain Adel — AI flight instructor service (`captadel.com`), RAG engine behind chat |
| [FlyGACA/Office](https://github.com/FlyGACA/Office) | Business operating system — strategy, governance, legal, finance, KSA compliance, HR & GTM docs |
| [FlyGACA/ELPT](https://github.com/FlyGACA/ELPT) · [AIP](https://github.com/FlyGACA/AIP) | App Store metadata repos — store listing copy, screenshots, per-app roadmap |
| [FlyGACA/PPL](https://github.com/FlyGACA/PPL) · [CPL](https://github.com/FlyGACA/CPL) · [IR](https://github.com/FlyGACA/IR) · [ATPL](https://github.com/FlyGACA/ATPL) | App Store metadata repos for paused exam modules |

---

## ⚖️ Disclaimer & License

**Fly GACA is an independent educational platform.** It is not affiliated with, endorsed by, or operated by the General Authority of Civil Aviation (GACA) or the Government of the Kingdom of Saudi Arabia. The official source for all civil aviation regulations is always GACA ([gaca.gov.sa](https://gaca.gov.sa)).

<div dir="rtl">

**فلاي جاكا منصة تعليمية مستقلة.** وهي غير تابعة للهيئة العامة للطيران المدني (GACA) ولا معتمدة منها ولا تُديرها. المصدر الرسمي والمعتمد لجميع لوائح الطيران المدني هو GACA دائمًا.

</div>

Distributed under the **MIT License**. See [`LICENSE`](LICENSE) for details.

<p align="center"><sub><b>صُنع في السعودية 🇸🇦 · Made in Saudi Arabia</b></sub></p>
