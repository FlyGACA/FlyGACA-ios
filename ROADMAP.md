# Roadmap — ay2m/FlyGACA (the native iOS family)

What's next for the Fly GACA iOS apps. The extraction from the web monorepo is **complete** —
this repo generates, builds, tests and archives its apps (ELPT, AIP) on its own. This file looks
**forward** and is the **single source of truth for open work in this repo**; the extraction
history lives in [`MIGRATION.md`](./MIGRATION.md) (history only — no open items are tracked
there).

> **Paused: the licence-exam modules.** PPL, CPL, IR and ATPL are on hold pending a strategic
> decision, and were removed from this repo on 2026-08-10 — targets, xcconfigs, bundled content,
> icons, npm scripts, CI matrices and the screenshot sets. Nothing is lost: they live in git
> history, their App Store metadata repos are intact and marked parked, and their web study
> packs are untouched and still selling at `flygaca.com/study/packs/*`. Restoring one is a
> revert of that commit plus its Apple-portal steps. Until then the family is **ELPT + AIP**,
> and no roadmap item below covers a paused module.

## How to read this

- **Now / Next / Later** are horizon buckets, not date commitments — priorities shift as Apple
  processing, content review and the web roadmap move.
- Each item is tagged **[product]** (something users get), **[platform]** (infra, signing, CI,
  release plumbing) or **[docs]** (contributor/reader-facing writing).
- Shipped items stay visible as ~~strikethrough~~ + **Done.** with a date, rather than being
  deleted.
- Precedence, so this file never becomes a second source of truth: `apple/ARCHITECTURE.md` §5
  owns the engineering *phase design* (Phases 1–4, owned here — not restated in this file; Phase
  4, PlatformLive, is the big one below). `docs/RUNBOOK-ios-xcodebuild.md`
  carries its own differently numbered "Phase Roadmap" — a known divergent snapshot; where they
  disagree, `ARCHITECTURE.md` wins. The family lineup and wave plan stay canonical in the
  monorepo's `docs/APPS-FAMILY-ROADMAP.md`; each app's store-listing milestones live in its own
  metadata repo (`FlyGACA/ELPT`, `FlyGACA/AIP`). This file wins only for "what this repo does
  next".

## Now — light the path to TestFlight

- **[platform] Sign-in-with-Apple primary App ID — decided in the docs, not yet done in the
  portal.** The capability was removed from `apple/Apps/Shared/App.entitlements` in 2026-08 and
  the registered App IDs don't carry it, so nothing is blocked today. The primary is
  **`com.flygaca.elpt`** with AIP grouped under it, and every doc now says so —
  `docs/RUNBOOK-ios-firebase.md` §4a (the click-path), `docs/PORTAL-RUNSHEET-wave1.md` §1.2 and
  `docs/RUNBOOK-ios-release.md`; the old `com.flygaca.ppl` designation is recorded as moot, since
  no Apple user identifier was ever issued under it. What remains is the **portal work itself**
  when sign-in ships: enable the capability on both App IDs, group AIP under ELPT, regenerate the
  profiles.
- ~~**[platform] Create the signing secrets and the store records.**~~ **Done 2026-08-16.**
  Run [#69](https://github.com/ay2m/FlyGACA-ios/actions/runs/31916879238) signed, exported and
  uploaded both apps — so the App Group, both App IDs, the distribution cert, both
  `FlyGACA <APP> AppStore` profiles, the App Store Connect API key and the nine GitHub secrets
  all exist and work end to end. `1.0.0 (69)` is in TestFlight for ELPT and AIP.
- **[platform] Finish the App Store Connect records so testers can install.** Builds reach
  TestFlight but installs fail with *"The requested app is not available or doesn't exist"* —
  an App Store lookup failure, not a build problem. Outstanding on the records themselves:
  **Pricing and Availability** (no price point and no territories are set — `SAR 79` per app per
  `apple/ARCHITECTURE.md` §4) and the **age-rating questionnaire** (4+, all-"None"). Triage
  order, including the tester-account check that comes first, is
  [`docs/PORTAL-RUNSHEET-wave1.md`](./docs/PORTAL-RUNSHEET-wave1.md) §5.1. Portal-only work —
  nothing in this repo changes.
- ~~**[product] Close the content skew.**~~ **Done 2026-08-05**: a reviewed `sync-content.sh`
  run brought ELPT to 4 banks and AIP to 3, and refreshed the grown question sets (validated:
  bankIds ⇔ banks, exam config unchanged). Store listings and bundles agree
  ([`SEO-PLAN.md`](./SEO-PLAN.md) item 0.3). ELPT bundles a 5th scenario bank on top.
- ~~**[platform] Register the Firebase iOS apps.**~~ **Done 2026-08-15.** Registered `com.flygaca.elpt` and `com.flygaca.aip` in Firebase project `flygaca-app` and generated `GoogleService-Info.plist` files for both apps (`docs/RUNBOOK-ios-firebase.md`).
- ~~**[docs] Author the repo docs suite.**~~ **Done 2026-08-04** (this PR): `CAUSE.md`,
  `ROADMAP.md`, `MIGRATION.md`, `SEO-PLAN.md`, `THE-BOOK-OF-FLY-GACA.md`, `CONTRIBUTING.md`,
  `docs/RUNBOOK-ios-release.md`, `docs/README.md`, a README refresh and CLAUDE.md pointers.

## Next — the store shelf

- ~~**[platform] Wire `AppleTests/ScreenshotTests.swift` into the project.**~~ **Done 2026-08-15.**
  Wired `AppleTests` as a `bundle.ui-testing` target in `apple/project.yml` with `testTargets: [AppleTests]`
  in the target templates.
- **[product] Ship the store listings.** The listing copy, keywords and screenshots live
  in the ELPT and AIP metadata repos and ship from there (fastlane `deliver` layout); tracked here only
  as the family gate — an app without its listing can't leave TestFlight. Strategy:
  [`SEO-PLAN.md`](./SEO-PLAN.md).
- **[platform] ~~Localize the app (EN + AR).~~ Done 2026-08-05.** FeatureUI's UI chrome now
  ships bilingual — a `Loc` bundle resolver over `Resources/{en,ar}.lproj` (34 keys) — and every
  app advertises `CFBundleLocalizations = [en, ar]`, so iOS serves Arabic (and SwiftUI mirrors
  RTL) on an Arabic device: first-class for the `ar-SA` storefront. Content stays English
  (monorepo-generated). Details + the monorepo mirror are in [`SEO-PLAN.md`](./SEO-PLAN.md)'s
  session log. Remaining follow-up: re-render the Arabic screenshots over the real Arabic UI.
- **[platform] Keep the parity vectors tracking the web.** If the web's SRS / exam-scoring /
  streak contracts move (`src/calc/study/srs.ts` and friends in the monorepo), extend
  `apple/FlyGACAKit/Tests/StudyEnginesTests/` in the same change that syncs the port — the
  vectors are the cross-platform contract, not decoration.

## Later — the platform phase and the long shelf

- ~~**[platform] PlatformLive**~~ **Done 2026-08-15.** Implemented `PlatformLive` library target in `apple/FlyGACAKit` (`FirebaseAuthService`, `FirebaseProgressSync` targeting `users/{uid}/progress/summary`, `CaptainAdelSSEClient` streaming SSE, and unit test suite `PlatformLiveTests`).
- **[product] The app bundle.** "Saudi Pilot Study Pack" — the paid App Store bundle (Apple
  allows up to 10 apps) once both apps are live, with completing-the-bundle credit for users who
  already bought one. Pricing: SAR 79 per app, SAR 139 for the app bundle (`apple/ARCHITECTURE.md` §4).
- **[product] Wave 3 modules.** FOI (`foi`), AGI (`agi`), Dispatcher, AME and the rest — each
  enters the monorepo's `prepCatalog.ts` first, then becomes a `Content/` folder + a small
  xcconfig + a 3-line `apple/project.yml` target here. A module is data, not code.
- **[platform] ~~Retire the monorepo's legacy `apple/` copy.~~ Done 2026-08-10.** The era of two
  trees is over: `FlyGACA-app` deleted its `apple/` mirror, this repo is the sole home of the app
  code, and `sync-content.sh` lost its `--all` mode. The monorepo keeps only the content
  generators (`build-ios-content.mjs` / `gen-app-icons.mjs`), which now write straight into this
  repo's `apple/Apps` via `--out`. All `apple/` docs and Swift/config are hand-owned here now.
- ~~**[platform] Consider path filters for `ios.yml`.**~~ **Done 2026-08-15.** Added `paths-ignore` for `**.md` and `docs/**` on `push` and `pull_request` triggers in `.github/workflows/ios.yml`.
- **[docs] Re-review `THE-BOOK-OF-FLY-GACA.md`'s dated stamps** whenever any repo's shape
  moves — the Book describes, it does not govern, and its "Last reviewed" dates are the honesty
  mechanism.

## How we ship (Definition of Done)

- `cd apple/FlyGACAKit && swift test` green — run it directly; `npm run ios:test` exits 0 even
  when tests fail.
- Only `apple/Apps/*/Content` + `Assets.xcassets` are generated (in the monorepo, via
  `sync-content.sh`) — don't hand-edit those; a content change belongs in the monorepo's corpus /
  `prepCatalog.ts`. **Everything else under `apple/` (FlyGACAKit, `project.yml`, `Apps/Shared`,
  the xcconfigs, `AppleTests`, `apple/Scripts`, the `apple/` docs) is owned here — edit it here.**
- The disclaimer is never reworded, anywhere. Copy it verbatim from `README.md` if a new
  surface needs it.
- `CLAUDE.md` stays true: if a change makes it stale, the same PR updates it.
