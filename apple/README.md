# Fly GACA iOS — getting started (Mac + Xcode 15+)

One shared Swift package (`FlyGACAKit`), one App Store app per study module.
Read `ARCHITECTURE.md` for the why; this is the how.

## 1. Build and test the package (no Xcode project needed)

```bash
cd apple/FlyGACAKit
swift build
swift test
```

The package has zero external dependencies, so this is fast and needs no
simulator. The test suite includes the web-parity vectors for spaced repetition
and exam scoring — keep it green.

## 2. Refresh the per-app content

From the repo root (content comes verbatim from `public/data/` + the pack
catalog in `src/lib/prepCatalog.ts`):

```bash
node scripts/build-ios-content.mjs          # PPL, ELPT and AIP
node scripts/build-ios-content.mjs --app ppl
```

## 3. Generate the Xcode project (XcodeGen)

The project is **generated, never committed** — `apple/project.yml` is the source
of truth and `apple/FlyGACA.xcodeproj` is gitignored.

```bash
npm run ios:generate      # → apple/FlyGACA.xcodeproj (installs XcodeGen if missing)
open apple/FlyGACA.xcodeproj
```

`ios:generate` installs XcodeGen for you when it's missing (Homebrew, falling back
to Mint). If neither is available it prints how to install it — the one-liner is
`brew install xcodegen`.

The spec wires up, per app target (PPL, ELPT, AIP):

- `Apps/Shared/FlyGACAApp.swift` (the shared shell),
- `Apps/<App>/Content` as a **folder reference** (blue folder), so it ships as a
  `Content/` directory in the bundle,
- `Apps/<App>/Assets.xcassets` (app icon),
- the local `FlyGACAKit` package with its `FeatureUI` product linked,
- the target's xcconfig (`Apps/<App>/<App>.xcconfig`), which pins the module id,
  bundle id, display name, the shared `Apps/Shared/Info.plist` and the App Group
  entitlement (`Apps/Shared/App.entitlements` → `group.com.flygaca.study`).

Run any scheme. You should land on that module's home — banks, ground school,
flashcards, mock and timed exam — all offline. (The Sign in with Apple entitlement
is declared, but the sign-in flow itself joins later with Firebase — see
`docs/RUNBOOK-ios-firebase.md` for the console setup it needs.)

You can also build without opening Xcode: `npm run ios:build:ppl` (see
`docs/RUNBOOK-ios-xcodebuild.md`).

## 4. Add the next app (IFR, …)

Add a three-line target entry to `apple/project.yml`, create
`Apps/<App>/<App>.xcconfig` (module id + bundle id + display name), generate its
content (`node scripts/build-ios-content.mjs --app <app>`), add an
`Assets.xcassets`, and re-run `npm run ios:generate`. `FlyGACAApp.swift` is
shared — never edit it per app.

## What is deliberately NOT here yet

- Firebase/RevenueCat SDKs and the `PlatformLive` target — the platform half of
  Phase 4 (see ARCHITECTURE.md §5). Until then the apps run fully offline by
  design, and `AppServices` mocks stand in for the platform.
- The six `GoogleService-Info.plist` files. The *slot* exists —
  `apple/project.yml` copies `Apps/<App>/GoogleService-Info.plist` into each
  bundle, declared `optional` so generation and unsigned builds work without it —
  but registering the apps and downloading the files is manual console work:
  `docs/RUNBOOK-ios-firebase.md`. The plists are inert until the SDKs land above.
- Code signing lives only in CI (`docs/RUNBOOK-ios-signing.md`); local builds run
  unsigned and need no Apple account.
