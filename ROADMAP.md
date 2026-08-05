# Roadmap — ay2m/FlyGACA (the native iOS family)

What's next for the Fly GACA iOS apps. The extraction from the web monorepo is **complete** —
this repo generates, builds, tests and archives all six apps (PPL, ELPT, AIP, CPL, IR, ATPL) on
its own. This file looks **forward** and is the **single source of truth for open work in this
repo**; the extraction history lives in [`MIGRATION.md`](./MIGRATION.md) (history only — no open
items are tracked there).

## How to read this

- **Now / Next / Later** are horizon buckets, not date commitments — priorities shift as Apple
  processing, content review and the web roadmap move.
- Each item is tagged **[product]** (something users get), **[platform]** (infra, signing, CI,
  release plumbing) or **[docs]** (contributor/reader-facing writing).
- Shipped items stay visible as ~~strikethrough~~ + **Done.** with a date, rather than being
  deleted.
- Precedence, so this file never becomes a second source of truth: `apple/ARCHITECTURE.md` §5
  owns the engineering *phase design* (Phases 1–4; it is monorepo-synced, so it is never
  restated here — Phase 4, PlatformLive, is the big one below). `docs/RUNBOOK-ios-xcodebuild.md`
  carries its own differently numbered "Phase Roadmap" — a known divergent snapshot; where they
  disagree, `ARCHITECTURE.md` wins. The family lineup and wave plan stay canonical in the
  monorepo's `docs/APPS-FAMILY-ROADMAP.md`; each app's store-listing milestones live in its own
  metadata repo (`FlyGACA/PPL` … `FlyGACA/AIP`). This file wins only for "what this repo does
  next".

## Now — light the Wave 1 path to TestFlight

- **[platform] Enable Sign in with Apple on all six App IDs.** The shared entitlements file
  (`apple/Apps/Shared/App.entitlements`) already declares Sign in with Apple alongside the App
  Group, so the next *signed* build fails provisioning until the capability is enabled — and
  grouped under the primary App ID (`com.flygaca.ppl`) — in the Apple portal.
  `docs/RUNBOOK-ios-firebase.md` §4a has the click-path. Blocker for everything below.
- **[platform] Create the signing secrets and the Wave 1 store records.** Work through
  `docs/RUNBOOK-ios-signing-CHECKLIST.md`: App Group + three App IDs + a distribution cert +
  three App Store profiles (named `FlyGACA <APP> AppStore` — the names are load-bearing), three
  paid-up-front App Store Connect records, the App Store Connect API key, then the ten GitHub
  secrets (`scripts/native/set-signing-secrets.sh`). That flips `check-signing` to
  `enabled=true`, and the `ios-testflight` job starts uploading ppl · elpt · aip on pushes to
  `main`.
- **[product] Close the content skew.** The committed snapshots lag the web packs — ELPT bundles
  1 of the web's 4 banks, AIP 2 of 3 (per the monorepo catalog as of 2026-08). Run
  `bash scripts/sync-content.sh <path-to-FlyGACA-app>`, review the diff, commit. Store listings
  must not promise banks the bundle lacks ([`SEO-PLAN.md`](./SEO-PLAN.md) item 0.3).
- **[platform] Register the six Firebase iOS apps.** `npm run firebase:register` (idempotent)
  against the `flygaca-app` project, then the manual half: the Sign in with Apple provider and
  the APNs key (`docs/RUNBOOK-ios-firebase.md`). Needed before PlatformLive, harmless to do
  early — the plists are gitignored and `optional: true` in `apple/project.yml`.
- ~~**[docs] Author the repo docs suite.**~~ **Done 2026-08-04** (this PR): `CAUSE.md`,
  `ROADMAP.md`, `MIGRATION.md`, `SEO-PLAN.md`, `THE-BOOK-OF-FLY-GACA.md`, `CONTRIBUTING.md`,
  `docs/RUNBOOK-ios-release.md`, `docs/README.md`, a README refresh and CLAUDE.md pointers.

## Next — Wave 2 and the store shelf

- **[product] Wave 2 (CPL, IR, ATPL) from draft to shippable.** Their banks are GACAR-cited
  *drafts* pending review to house style (the monorepo's `docs/STUDY-CONTENT-REVIEW.md` defines
  what that means). Review lands in the monorepo → synced here → then the signing checklist's
  "Adding CPL / IR / ATPL later" loop (App ID + profile + secret + an entry in the
  `ios-testflight` matrix in `.github/workflows/ios.yml` — the matrix is explicit, not derived
  from the six-app list).
- **[platform] Wire `AppleTests/ScreenshotTests.swift` into the project.** The shared target
  template in `apple/project.yml` has `testTargets: []`, so the XCUITest snapshot flow can't run
  via `xcodebuild test` today. Wiring it is a `project.yml` change — coordinate with the
  monorepo, since `--all` syncs overwrite `project.yml`.
- **[product] Ship the Wave 1 store listings.** The listing copy, keywords and screenshots live
  in the six metadata repos and ship from there (fastlane `deliver` layout); tracked here only
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

- **[platform] PlatformLive** — `apple/ARCHITECTURE.md` §5 Phase 4: Firebase Auth + App Check,
  upload-only progress sync (`users/{uid}/progress/summary`, the same doc the web writes), the
  Captain Adel SSE client, remote content refresh + SRS reconcile, RevenueCat only if the
  free-tier fallback is ever wanted. Firebase/RevenueCat imports stay quarantined in this one
  target.
- **[product] The app bundle.** "Saudi Pilot Study Pack" — the paid App Store bundle (Apple
  allows up to 10 apps) once Wave 1 is live, with completing-the-bundle credit for users who
  already bought one. Pricing mirrors the web's SAR 39 packs (`apple/ARCHITECTURE.md` §4).
- **[product] Wave 3 modules.** FOI (`foi`), AGI (`agi`), Dispatcher, AME and the rest — each
  enters the monorepo's `prepCatalog.ts` first, then becomes a `Content/` folder + a small
  xcconfig + a 3-line `apple/project.yml` target here. A module is data, not code.
- **[platform] Retire the monorepo's legacy `apple/` copy.** Ends the era of two trees; after
  it, `--all` syncs stop meaning "track the monorepo verbatim" and the synced `apple/` docs
  become editable here. Cross-repo decision — coordinate, don't improvise.
- **[platform] Consider path filters for `ios.yml`.** Today a docs-only PR fires the full
  six-app macOS matrix. Cheap to add once the workflow is otherwise stable; not worth a CI edit
  before the signing lane is proven.
- **[docs] Re-review `THE-BOOK-OF-FLY-GACA.md`'s dated stamps** whenever any repo's shape
  moves — the Book describes, it does not govern, and its "Last reviewed" dates are the honesty
  mechanism.

## How we ship (Definition of Done)

- `cd apple/FlyGACAKit && swift test` green — run it directly; `npm run ios:test` exits 0 even
  when tests fail.
- Nothing hand-edited inside the sync-owned zones (`apple/Apps/*/Content`, `Assets.xcassets`,
  and under `--all`: `FlyGACAKit/{Sources,Tests}`, `Apps/Shared`, the per-app xcconfigs,
  `AppleTests`, `apple/Scripts`, `project.yml`, `apple/ARCHITECTURE.md`, `apple/README.md`) —
  those changes belong in the monorepo first.
- The disclaimer is never reworded, anywhere. Copy it verbatim from `README.md` if a new
  surface needs it.
- `CLAUDE.md` stays true: if a change makes it stale, the same PR updates it.
