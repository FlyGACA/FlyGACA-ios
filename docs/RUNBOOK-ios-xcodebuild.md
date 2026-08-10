# iOS xcodebuild Automation Runbook

> **Note (this repo):** this runbook is shared with the [FlyGACA-app](https://github.com/FlyGACA/FlyGACA-app) monorepo, where the content
> bundler (`scripts/build-ios-content.mjs`), the pack catalog (`src/lib/prepCatalog.ts`)
> and the icon generator (`npm run ios:icons`) live. In this repo the per-app `Content/`
> folders and icons are committed snapshots — refresh them with `bash scripts/sync-content.sh`
> pointed at a FlyGACA-app clone. Everything else applies here unchanged.


## Overview

This runbook documents how to build, test, and manage the FlyGACA native iOS app family using automated npm scripts and the xcodebuild wrapper. The family is **ELPT** and **AIP**; both generate, build, and archive from the same shared shell. The licence-exam modules (PPL, CPL, IR, ATPL) are **paused** and no longer present in this repo — see `ROADMAP.md`.

## Quick Start

### Environment Setup

1. **Install Xcode Command Line Tools** (if not already installed):
   ```bash
   xcode-select --install
   ```

2. **Install XcodeGen** (generates the gitignored Xcode project from `apple/project.yml`):
   ```bash
   brew install xcodegen
   ```

3. **Verify prerequisites**:
   ```bash
   npm run ios:info
   ```

### Running Tests

```bash
# Run Swift Package tests once
npm run ios:test

# Watch mode (re-runs tests on file changes)
npm run ios:test:watch
```

### Local Builds

#### Debug Builds (default)
```bash
# Build individual apps
npm run ios:build:elpt
npm run ios:build:aip

# Build every app
npm run ios:build:all
```

#### Release Builds
```bash
# Build individual apps in Release configuration
npm run ios:build:release:elpt  # …:aip

# Build every app in Release
npm run ios:build:release:all
```

### Cleaning Up

```bash
# Remove build artifacts
npm run ios:clean
```

## How It Works

### Architecture

```
package.json (npm ios:* scripts)
    ↓
scripts/native/xcodebuild-wrapper.sh
    ├─→ Check prerequisites (Xcode, Swift, Node.js)
    ├─→ Generate Xcode project (xcodegen ← apple/project.yml)
    ├─→ Generate content (build-ios-content.mjs)
    └─→ Invoke xcodebuild with correct scheme/configuration
```

### The Wrapper Script

`scripts/native/xcodebuild-wrapper.sh` is the core orchestration tool. It:

1. **Validates prerequisites** — Checks for Xcode, Swift, and Node.js
2. **Generates the project** — Runs `xcodegen generate` against `apple/project.yml` (the project itself is gitignored)
3. **Generates content** — Runs `scripts/build-ios-content.mjs` to filter the regulatory corpus by module
4. **Builds the app** — Invokes `xcodebuild` with the correct scheme and configuration
5. **Reports status** — Provides clear success/error messages with timing

**Arguments:**
```bash
xcodebuild-wrapper.sh <app|all|info> [debug|release] [scheme-override]
```

- `app`: `elpt`, `aip`, or `all`
- `config`: `debug` (default) or `release`
- `scheme-override`: Optional Xcode scheme name (advanced)

**Release environment flags** (used by CI; all optional):

| Env var | Effect |
|---|---|
| `FG_BUILD_NUMBER` | Overrides `CURRENT_PROJECT_VERSION` (CI passes `github.run_number`) |
| `FG_SIGNED_RELEASE=1` | Signed archive + `.ipa` export (requires `APPLE_TEAM_ID`; cert/profile must be installed) |
| `FG_PROVISIONING_PROFILE` | Overrides the profile name (default `FlyGACA <SCHEME> AppStore`) |
| `FG_UPLOAD_TESTFLIGHT=1` | Uploads the exported `.ipa` via `xcrun altool` (requires ASC API key env — see `RUNBOOK-ios-signing.md`) |

Debug builds and default (unsigned) release archives run with code signing
disabled — no Apple account needed locally or in CI.

### Content Generation

Before each build, the wrapper calls `scripts/build-ios-content.mjs --app <module>`:

- Filters the shared regulatory corpus by module (ELPT scenarios, AIP content, etc.)
- Validates all quiz banks (no empty questions, valid answer indexes)
- **Exits with error if validation fails** — this prevents invalid builds

### Xcode Project Structure (XcodeGen)

The Xcode project is **generated from `apple/project.yml`** (XcodeGen) and is
gitignored — `npm run ios:generate` recreates it any time. The generated project has:

- **Shared build settings** in `apple/Apps/Shared/App-Shared.xcconfig`
  - iOS 17+ deployment target, Swift 5 language mode
  - Version (`MARKETING_VERSION`) + build number (`CURRENT_PROJECT_VERSION`)
  - App Group entitlement (`Apps/Shared/App.entitlements`), app icon set name

- **Per-app configuration** in `apple/Apps/<Module>/<Module>.xcconfig`
  - Bundle ID (e.g., `com.flygaca.elpt`)
  - Module ID (`FG_MODULE_ID`, the pack id from `src/lib/prepCatalog.ts` —
    `elp`, `aip`) — injected at build time
  - Display name

- **Shared code** in `apple/Apps/Shared/FlyGACAApp.swift`
  - Root SwiftUI entrypoint
  - Every app in the family reuses this shell; only module ID differs

- **Per-app resources**: `Apps/<Module>/Content/` ships as a blue folder
  reference (the app reads it as a `Content/` directory in the bundle) and
  `Apps/<Module>/Assets.xcassets` holds the app icon.

## Common Tasks

### Adding a New iOS App (e.g. IFR)

AIP is the worked example — the smallest complete app (xcconfig, `Content/`, icon,
`project.yml` target).

1. **Create module structure**:
   ```bash
   mkdir -p apple/Apps/IFR
   cp apple/Apps/AIP/AIP.xcconfig apple/Apps/IFR/IFR.xcconfig
   # Edit IFR.xcconfig:
   #   FG_MODULE_ID = <the pack id from src/lib/prepCatalog.ts>
   #   PRODUCT_BUNDLE_IDENTIFIER = com.flygaca.ifr
   ```

2. **Register the app** in `scripts/build-ios-content.mjs`'s `APPS` map and in
   `scripts/native/gen-app-icons.mjs`'s `APPS` map (Xcode target dir, on-icon
   label, a Falcon accent colour), then generate its content + icon:
   ```bash
   node scripts/build-ios-content.mjs --app ifr   # → apple/Apps/IFR/Content/
   node scripts/native/gen-app-icons.mjs --app ifr # → Assets.xcassets + AppIcon
   ```
   (The icon step also creates the `Assets.xcassets` scaffolding — no manual copy.)

3. **Register the target** in `apple/project.yml` (three lines) — must come after
   step 2, since the target template references `Apps/IFR/Assets.xcassets`:
   ```yaml
   IFR:
     templates: [FlyGACAApp]
   ```

4. **Add matching `ios:build:ifr` / `ios:build:release:ifr` npm scripts**, extend
   `scripts/native/xcodebuild-wrapper.sh` (`APPS` array + `build_app()` case +
   `main()` case), and add the app to the `content-validation` / `ios-build`
   matrices in `.github/workflows/ios.yml`. Then generate + build:
   ```bash
   npm run ios:generate
   npm run ios:build:ifr
   ```
   (TestFlight signing needs an extra `ios-testflight` matrix entry + Apple
   provisioning secret — see `docs/RUNBOOK-ios-signing.md`.)

### Debugging a Failed Build

1. **Check prerequisites**:
   ```bash
   npm run ios:info
   ```

2. **Verify content generation**:
   ```bash
   node scripts/build-ios-content.mjs --app elpt
   # Should complete without error
   ```

3. **Check Xcode project structure**:
   ```bash
   # Verify project exists
   ls -la apple/FlyGACA.xcodeproj
   
   # List available schemes
   xcodebuild -project apple/FlyGACA.xcodeproj -list
   ```

4. **Run xcodebuild directly** (if script fails):
   ```bash
   xcodebuild \
     -project apple/FlyGACA.xcodeproj \
     -scheme ELPT \
     -configuration Debug \
     -derivedDataPath apple/.build \
     -arch arm64 \
     -sdk iphoneos \
     build
   ```

### Cleaning Specific App Cache

```bash
# Swift Package cache
rm -rf apple/FlyGACAKit/.build

# Xcode derived data (all FlyGACA)
rm -rf ~/Library/Developer/Xcode/DerivedData/*FlyGACA*

# Or use npm shortcut
npm run ios:clean
```

### Running Tests with Coverage

```bash
# In the Swift Package directory
cd apple/FlyGACAKit
swift test --enable-code-coverage

# Generate coverage report (macOS Xcode only)
xcrun llvm-cov show -instr-profile .build/debug/codecov/default.profdata \
  .build/debug/FlyGACAKitPackageTests.xctest/Contents/MacOS/FlyGACAKitPackageTests
```

### Release Builds & dSYM Symbols

Release builds are automatically created on every push to `main` by the CI workflow.

**Local Release Build:**
```bash
npm run ios:build:release:elpt
```

This creates:
- XCArchive: `apple/.build/ELPT-Release.xcarchive`
- dSYM symbols: `apple/.build/dSYMs/ELPT.app.dSYM`

Local release archives are **unsigned** by default. Signed archives + `.ipa`
export + TestFlight upload are CI-only, driven by the `FG_SIGNED_RELEASE` /
`FG_UPLOAD_TESTFLIGHT` env flags — see `docs/RUNBOOK-ios-signing.md`.

**In CI (GitHub Actions):**
- Release builds run as a separate matrix job (only on main branch)
- XCArchives uploaded with 14-day retention
- dSYM files extracted and stored separately (30-day retention)
- All artifacts tagged with commit SHA for traceability
- When signing secrets are configured, the `ios-testflight` job additionally
  produces signed `.ipa`s (30-day retention) and uploads them to TestFlight

**Using dSYM for Crash Analysis:**

Once crash reporting is integrated (Sentry/Crashlytics), dSYM files enable:
- Stack trace symbolication (convert addresses → source lines)
- Crash reporting tool integration (Sentry, Crashlytics, etc.)
- Performance profiling with meaningful function names

dSYM files are stored in GitHub Actions artifacts and can be downloaded for local debugging:
```bash
# Download from GitHub Actions artifact
# Then use lldb to load symbols:
lldb <binary>
target symbols add <path-to-dSYM>/Contents/Resources/DWARF/<binary-name>
```

## CI/CD Integration

See [`.github/workflows/ios.yml`](#) for the GitHub Actions workflow that:

- **Phase 2:** Runs `npm run ios:test` on every push (Swift tests, no simulator)
- **Phase 2:** Builds every app in a parallel matrix (debug builds, 7-day retention)
- **Phase 3:** Creates XCArchives for release builds on `main` branch pushes
- **Phase 3:** Extracts and stores dSYM symbols (30-day retention) for crash reporting
- **Phase 3:** Tags all release artifacts with git commit SHA for traceability
- **Phase 4:** Generates the Xcode project in CI (XcodeGen) so builds are real
- **Phase 4:** Signs, exports, and uploads the shipping apps (ELPT/AIP) to
  TestFlight on `main` pushes — once the signing secrets exist (`ios-testflight`
  job, gated by `check-signing`; see `docs/RUNBOOK-ios-signing.md`).

**Artifact Retention:**
- Debug builds: 7 days (PR + main)
- Release XCArchives: 14 days (main only)
- dSYM symbols: 30 days (main only)
- Signed `.ipa`s: 30 days (main only, signing secrets required)

The workflow is triggered by:
- Push to `main` branch (all jobs, including release builds)
- All pull requests (debug builds only)
- Manual `workflow_dispatch`

## Troubleshooting

### "Xcode Command Line Tools not installed"

```bash
xcode-select --install
```

### "xcodebuild: error: Unable to find a matching provisioning profile"

Local builds run with code signing disabled, so this shouldn't appear locally.
In the `ios-testflight` CI job it means the provisioning profile secret doesn't
match the bundle ID or certificate — see the troubleshooting section of
`docs/RUNBOOK-ios-signing.md`.

### "Content generation failed for elpt"

Check the corpus files are present:
```bash
ls content/regulations/*.md
node scripts/build-ios-content.mjs --app elpt
```

### Build takes >5 minutes on first run

First build includes Swift Package resolution. Subsequent builds are faster (~1-2 min).

Optimize:
```bash
# Pre-warm the cache
cd apple/FlyGACAKit && swift build && cd ../..
```

### "No matching schemes found" error

Regenerate the project and list the schemes:
```bash
npm run ios:generate
xcodebuild -project apple/FlyGACA.xcodeproj -list
```

Expected output:
```
Information about project "FlyGACA":
    Schemes:
        ELPT
        AIP
```

If a scheme is missing, check its target entry in `apple/project.yml`.

## Phase Roadmap

### Phase 1 ✅ (Complete)
- Local npm scripts for build/test
- xcodebuild wrapper orchestration
- Content generation integration

### Phase 2 ✅ (Complete)
- GitHub Actions CI/CD matrix workflow
- Parallel builds of the whole app family (ELPT, AIP)
- Swift test integration in CI
- Security compliance (explicit permissions blocks)

### Phase 3 ✅ (Complete)
- Release builds on `main` branch (conditional on main push)
- XCArchive creation for Release configuration
- dSYM extraction and 30-day retention
- Tagged artifacts with git commit SHA

### Phase 4 ✅ (Signing & TestFlight slice complete)
- XcodeGen project generation (`apple/project.yml`) — CI builds are real
- Self-managed code signing on **GitHub Actions** (not Xcode Cloud): temp
  keychain + manual signing, activated by repo secrets
  (`docs/RUNBOOK-ios-signing.md`)
- `.ipa` export + TestFlight upload via the App Store Connect API
- Still to come (the platform half of Phase 4, see `apple/ARCHITECTURE.md` §5):
  `PlatformLive` target (Firebase Auth + App Check), Keychain Sharing, Sign in
  with Apple, crash reporting integration

## Support

For questions or issues:
1. Check this runbook
2. Check `apple/README.md` for project setup
3. Review `scripts/native/xcodebuild-wrapper.sh` comments
4. Check CI logs in `.github/workflows/ios.yml`
