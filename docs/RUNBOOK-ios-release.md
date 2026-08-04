# RUNBOOK — iOS release, end to end (ay2m/FlyGACA)

The release path **from this repo's point of view**: refresh content → generate → test → build →
sign → TestFlight. The four sibling runbooks in this folder are monorepo-authored snapshots
(see [`README.md`](./README.md)); they hold the deep procedures and are linked from each step —
but where they conflict with what is actually runnable here, **this file and the root
`CLAUDE.md` win** (the [Reconciliation map](#reconciliation-map) at the bottom lists every known
conflict).

## What lives where

- `scripts/sync-content.sh` — the only way content/icons enter this repo (one-way, monorepo →
  here). There is **no** `scripts/build-ios-content.mjs` and no `npm run ios:icons` here.
- `scripts/native/ios-generate.sh` — XcodeGen → `apple/FlyGACA.xcodeproj` (generated, never
  committed).
- `scripts/native/xcodebuild-wrapper.sh` — the orchestrator behind every `npm run ios:build:*`:
  prerequisites → `xcodegen generate` → content (snapshot fallback, see step 1) → `xcodebuild`.
- `scripts/native/ci-firebase-placeholder.sh` — writes placeholder `GoogleService-Info.plist`
  files in CI (the real ones are gitignored).
- `scripts/native/firebase-register-apps.sh` / `set-signing-secrets.sh` — one-time setup
  helpers ([`RUNBOOK-ios-firebase.md`](./RUNBOOK-ios-firebase.md),
  [`RUNBOOK-ios-signing-CHECKLIST.md`](./RUNBOOK-ios-signing-CHECKLIST.md)).
- `.github/workflows/ios.yml` — the one workflow; seven jobs: `swift-test`,
  `xcodegen-validate`, `check-signing`, `ios-build` (6-app debug matrix), `ios-build-release`,
  `ios-testflight`, `build-summary`.
- Build products land under `apple/.build/` (archives, dSYMs, IPAs) — `npm run ios:clean` does
  **not** touch it.
- Ten GitHub secrets gate signing — names and creation steps in
  [`RUNBOOK-ios-signing-CHECKLIST.md`](./RUNBOOK-ios-signing-CHECKLIST.md).

## 0. Preconditions

- A Mac with **Xcode 16+** — XcodeGen emits the Xcode 16 project format (`objectVersion 77`),
  which Xcode 15 refuses. CI pins `macos-15` runners for the same reason.
- `node` on PATH — `xcodebuild-wrapper.sh` hard-requires it even though this repo has no
  bundler for node to run.
- No Apple account needed for anything unsigned: debug builds and release *archives* run with
  `CODE_SIGNING_ALLOWED=NO`.

## 1. Refresh content (when the web packs moved)

```bash
# with a FlyGACA-app clone next to this repo (default ../FlyGACA-app), or pass its path
bash scripts/sync-content.sh [path-to-FlyGACA-app]          # Content/ + Assets.xcassets only
bash scripts/sync-content.sh [path-to-FlyGACA-app] --all    # + the whole synced apple/ tree
```

- Default mode **deletes and replaces** `apple/Apps/*/Content` and `apple/Apps/*/Assets.xcassets`.
- `--all` additionally deletes and replaces `apple/FlyGACAKit/{Sources,Tests}`,
  `apple/Apps/Shared/`, each app's `.xcconfig`, `apple/AppleTests/`, `apple/Scripts/`, and
  overwrites `apple/project.yml`, `apple/FlyGACAKit/Package.swift`, `apple/ARCHITECTURE.md`
  and `apple/README.md`. **Always review the diff before committing a sync.**
- If you skip this step, builds still work: the wrapper detects the absent bundler and logs
  "Content bundler not in this repo — building with the committed Content/ snapshot". Expected,
  not a bug.
- Known skew as of 2026-08: ELPT bundles 1 of the web's 4 banks, AIP 2 of 3 — a sync run closes
  it ([`../ROADMAP.md`](../ROADMAP.md)).

## 2. Generate & test

```bash
npm run ios:generate                       # XcodeGen → apple/FlyGACA.xcodeproj
cd apple/FlyGACAKit && swift test          # run this DIRECTLY — see below
```

Run `swift test` directly, not `npm run ios:test`: the npm alias's `&&…||` chain prints "Swift
not available; skipping iOS tests" and **exits 0 even when tests fail**. The suite (4 targets,
10 files) includes the web-parity vectors for SRS and exam scoring — they are the
cross-platform contract and gate everything else in CI.

## 3. Build

```bash
npm run ios:build:ppl              # debug; also elpt aip cpl ir atpl / all
npm run ios:build:release:ppl      # unsigned .xcarchive + dSYM extraction (also :all)
```

Both run through `xcodebuild-wrapper.sh` with `CODE_SIGNING_ALLOWED=NO` — reproducing locally
what CI's `ios-build` / `ios-build-release` jobs do.

## 4. Sign & upload — CI is the path

Signed builds and TestFlight uploads happen **in CI only** (`ios-testflight` job), never from a
laptop. To activate the lane:

1. Complete the Apple-side setup and create the **ten secrets** —
   [`RUNBOOK-ios-signing-CHECKLIST.md`](./RUNBOOK-ios-signing-CHECKLIST.md) is the in-order
   list; [`RUNBOOK-ios-signing.md`](./RUNBOOK-ios-signing.md) is the why + troubleshooting.
2. Mind the two load-bearing Apple-portal details:
   - Provisioning profile names are **exact**: `FlyGACA <APP> AppStore` (passed as
     `PROVISIONING_PROFILE_SPECIFIER`). Manual signing is deliberate — the App Group
     entitlement rules out wildcard profiles.
   - `apple/Apps/Shared/App.entitlements` already declares **Sign in with Apple**; the
     capability must be enabled on all six App IDs — grouped under the primary
     `com.flygaca.ppl` — before the next signed build, or provisioning fails
     ([`RUNBOOK-ios-firebase.md`](./RUNBOOK-ios-firebase.md) §4a).
3. `check-signing` turns the secrets' presence into an `enabled` output; when true, a push to
   `main` (or `workflow_dispatch`) builds signed and uploads via `xcrun altool`. The matrix is
   **Wave 1 only and explicit**: `ppl · elpt · aip`.

The wrapper's CI-only env flags, for reading the workflow: `FG_BUILD_NUMBER`,
`FG_SIGNED_RELEASE=1` (+ `APPLE_TEAM_ID`), `FG_PROVISIONING_PROFILE`, `FG_UPLOAD_TESTFLIGHT=1`
(+ the App Store Connect API key env).

## 5. What fires when

| Event | What runs |
| --- | --- |
| Push to a feature branch | **Nothing.** Triggers are `main`-only. |
| PR targeting `main` | `swift-test` + `xcodegen-validate` + `ios-build` (6-app debug matrix, `fail-fast: true` — one app's failure cancels the other five) + `build-summary`. No path filters: even a docs-only PR fires the full macOS matrix. |
| Push to `main` | All of the above + `ios-build-release` (unsigned archives) + `ios-testflight` (only if `check-signing` says the secrets exist). |
| `workflow_dispatch` | Same as a `main` push, on demand. |

Two caveats worth memorizing:

- Concurrency group `ios-${{ github.ref }}` with `cancel-in-progress: true` — a second push to
  the same branch cancels the in-flight run.
- **A green `build-summary` does not mean anything shipped**: it `needs` only
  `swift-test` / `xcodegen-validate` / `ios-build`, so a failed release archive or TestFlight
  upload never turns it red. Check those jobs directly.

## 6. Adding a Wave 2 app (CPL / IR / ATPL) to TestFlight

Per the checklist's closing section: repeat the Apple-portal loop for the new bundle id (App ID
with App Group **and Sign in with Apple**, `FlyGACA <APP> AppStore` profile,
`PROVISIONING_PROFILE_<APP>_BASE64` secret, paid App Store Connect record), then add the
`{app, scheme}` entry to the `ios-testflight` matrix in `.github/workflows/ios.yml`. Content
gate first, though: Wave 2 banks are GACAR-cited drafts until reviewed
([`../ROADMAP.md`](../ROADMAP.md) → Next).

## Reconciliation map

Where a monorepo-authored doc says X, in this repo do Y:

| The synced doc says | Here, the truth is |
| --- | --- |
| `node scripts/build-ios-content.mjs` / `npm run ios:icons` regenerate content/icons (`apple/README.md`, several runbooks) | Neither exists here — `bash scripts/sync-content.sh` is the only refresh path (step 1) |
| `apple/README.md`: "Mac + Xcode 15+" | Xcode **16+** — `apple/project.yml`'s objectVersion-77 comment is authoritative |
| `RUNBOOK-ios-xcodebuild.md` "Phase Roadmap": "Phase 4 ✅" | That's its own numbering for the signing/TestFlight slice — **not** `apple/ARCHITECTURE.md` §5's Phase 4 (PlatformLive, unbuilt) |
| `npm run ios:info` help text advertises `npm run ios:icons` | Stale — the script only exists in the monorepo |
| `AppleTests/ScreenshotTests.swift` implies a runnable XCUITest flow (and cites a `SCREENSHOTS.md`) | Not wired: `apple/project.yml` has `testTargets: []`; the cited `SCREENSHOTS.md` doesn't exist in this repo |
| `apple/ARCHITECTURE.md` §3 lists three test directories | Four exist — `PersistenceKitTests` too (4 targets / 10 files) |

## Troubleshooting

- **Missing `GoogleService-Info.plist`** — expected until Firebase setup: the plists are
  gitignored and `optional: true` in `project.yml`; CI writes placeholders
  (`ci-firebase-placeholder.sh`). The apps run fully offline without them.
- **`xcodegen` not found** — `npm run ios:generate` installs it (Homebrew, falling back to
  Mint); manual: `brew install xcodegen`.
- **Wrapper aborts asking for `node`** — install Node; the prerequisite check is unconditional
  even though no bundler runs here.
- **Five matrix jobs "cancelled"** — `fail-fast: true`: find the one app that actually failed;
  the rest were collateral.
- **Provisioning fails on a signed build** — usual suspects in order: Sign in with Apple not
  enabled/grouped on the App ID (§4a above), profile name not exactly `FlyGACA <APP> AppStore`,
  cert/profile mismatch. Deeper table: [`RUNBOOK-ios-signing.md`](./RUNBOOK-ios-signing.md) →
  Troubleshooting (also covers the alpha-channel icon and duplicate-build-number upload
  rejections).
- **"No suitable application records found" on upload** — the paid App Store Connect record for
  that bundle id doesn't exist yet (checklist §B).
