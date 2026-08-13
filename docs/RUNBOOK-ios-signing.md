# iOS Code Signing & TestFlight Runbook

> **Note:** this runbook is owned here — the monorepo's `apple/` mirror was retired 2026-08, so
> this is the real source, not a synced copy. Only the CONTENT generators
> (`build-ios-content.mjs`, `npm run ios:icons`) + the corpus + `src/lib/prepCatalog.ts` live in
> the [FlyGACA-app](https://github.com/FlyGACA/FlyGACA-app) monorepo; the per-app `Content/`
> folders and icons are committed snapshots here, refreshed with `bash scripts/sync-content.sh`
> pointed at a FlyGACA-app clone. Everything else is native to this repo.


One-time human setup to activate the `ios-testflight` job in `.github/workflows/ios.yml`.
Until these secrets exist, the job is skipped and CI stays green — nothing breaks by
deferring this.

**Scope:** *signing* is wired for the two shipping apps (ELPT, AIP) under
`apple/` — not the Capacitor shell (`com.flygaca.app`). The licence-exam modules
(PPL, CPL, IR, ATPL) are **paused** and no longer exist in this repo — see
`ROADMAP.md`. To bring a new app into TestFlight, repeat Steps 1–3 below for it (a new App ID, an
`FlyGACA <APP> AppStore` profile, a `PROVISIONING_PROFILE_<APP>_BASE64` secret) and
add its `{app, scheme}` entry to the `ios-testflight` matrix in `.github/workflows/ios.yml`.

## How the pipeline works

```
push to main
  └─ check-signing (are BUILD_CERTIFICATE_BASE64 + APP_STORE_CONNECT_API_KEY_ID set?)
       └─ ios-testflight (matrix: elpt, aip) — only when secrets are present
            ├─ import cert + profile into a temp keychain (deleted after the run)
            ├─ xcodegen generate → signed xcodebuild archive
            ├─ xcodebuild -exportArchive → .ipa (kept as a CI artifact)
            └─ xcrun altool --upload-app → TestFlight
```

Signing is **manual** (no Xcode-managed signing in CI): an Apple Distribution
certificate + one App Store provisioning profile per app. The App Group
(`group.com.FlyGACA`) rules out wildcard profiles — wildcard App IDs cannot
carry the App Groups capability.

## Step 1 — Apple Developer portal

At [developer.apple.com](https://developer.apple.com/account) → Certificates, Identifiers & Profiles:

1. **App Group**: Identifiers → App Groups → register `group.com.FlyGACA`.
2. **App IDs**: register two explicit App IDs, each with the **App Groups**
   capability enabled and `group.com.FlyGACA` assigned:
   - `com.flygaca.elpt`
   - `com.flygaca.aip`
3. **Distribution certificate**: Certificates → create an **Apple Distribution**
   certificate (generate the CSR via Keychain Access on any Mac). Then in Keychain
   Access, export the certificate **with its private key** as a `.p12` and set a
   password (this becomes `P12_PASSWORD`).
4. **Provisioning profiles**: create two **App Store** distribution profiles, one
   per App ID, using that certificate, named **exactly**:
   - `FlyGACA ELPT AppStore`
   - `FlyGACA AIP AppStore`

   The names are load-bearing — the CI passes them as `PROVISIONING_PROFILE_SPECIFIER`
   and writes them into ExportOptions. (Override per-run with `FG_PROVISIONING_PROFILE`
   if you must rename.) Download both `.mobileprovision` files.

## Step 2 — App Store Connect

At [appstoreconnect.apple.com](https://appstoreconnect.apple.com):

1. **App records**: create the two apps (paid-up-front per `apple/ARCHITECTURE.md` §4),
   one per bundle ID above. **Uploads fail with "No suitable application records found"
   until these exist.**
2. **API key**: Users & Access → Integrations → App Store Connect API → Team Keys →
   generate a key with the **App Manager** role. Note the **Key ID** and **Issuer ID**,
   and download the `.p8` file — it can only be downloaded **once**.

## Step 3 — Create the GitHub secrets

Base64-encode the binary assets (on macOS; on Linux use `base64 -w0 <file>`):

```bash
base64 -i Distribution.p12 | pbcopy                     # → BUILD_CERTIFICATE_BASE64
base64 -i FlyGACA_ELPT_AppStore.mobileprovision | pbcopy # → PROVISIONING_PROFILE_ELPT_BASE64
base64 -i FlyGACA_AIP_AppStore.mobileprovision | pbcopy # → PROVISIONING_PROFILE_AIP_BASE64
base64 -i AuthKey_XXXXXXXXXX.p8 | pbcopy                # → APP_STORE_CONNECT_API_KEY_BASE64
```

Create every secret (repo → Settings → Secrets and variables → Actions, or `gh secret set <NAME>`):

| Secret | Content |
|---|---|
| `APPLE_TEAM_ID` | Your 10-character Team ID (Membership page) |
| `BUILD_CERTIFICATE_BASE64` | The Apple Distribution `.p12`, base64 |
| `P12_PASSWORD` | Password chosen when exporting the `.p12` |
| `KEYCHAIN_PASSWORD` | Any random string (temp CI keychain only) |
| `PROVISIONING_PROFILE_ELPT_BASE64` | App Store profile for `com.flygaca.elpt`, base64 |
| `PROVISIONING_PROFILE_AIP_BASE64` | App Store profile for `com.flygaca.aip`, base64 |
| `APP_STORE_CONNECT_API_KEY_ID` | The API key's Key ID |
| `APP_STORE_CONNECT_API_ISSUER_ID` | The Issuer ID (UUID) |
| `APP_STORE_CONNECT_API_KEY_BASE64` | The `.p8`, base64 |

## Step 4 — First run

Push to `main` (or trigger `workflow_dispatch` on the iOS workflow). `check-signing`
now outputs `enabled=true`, and `ios-testflight` runs for both apps. After Apple
finishes processing (typically 5–15 minutes per build), the builds appear under each
app's TestFlight tab.

Build numbers (`CFBundleVersion`) come from `github.run_number`, so they increase
monotonically and are shared across both apps — that's fine, uniqueness is
per-app in App Store Connect.

## Troubleshooting

- **"No signing certificate 'iOS Distribution' found"** — the `.p12` didn't import,
  or the `security set-key-partition-list` step is missing/failed (that's what lets
  `codesign` use the key non-interactively). Re-check `BUILD_CERTIFICATE_BASE64` and
  `P12_PASSWORD`.
- **"Provisioning profile ... doesn't include signing certificate"** — the profile was
  generated against a different certificate. Regenerate the profile with the current
  distribution cert and update the secret.
- **altool error 1091 / missing icon** — the asset catalog lost its 1024 marketing
  icon, or the PNG has an alpha channel. Regenerate a flattened icon.
- **"The bundle version must be higher than the previously uploaded version"** — a
  re-run of a failed workflow reuses `github.run_number`, so any app that already
  uploaded in the first attempt rejects the duplicate. Benign for the other apps
  (`fail-fast: false`); the next real push gets a fresh number.
- **"No suitable application records found"** — the app record doesn't exist in App
  Store Connect yet (Step 2.1).
- **"future Xcode project file format" errors** — XcodeGen emits the Xcode 16
  project format, so iOS jobs must run on an image whose default Xcode is 16+
  (currently `macos-15`). If a job needs a specific Xcode version, set
  `DEVELOPER_DIR: /Applications/Xcode_<version>.app` to a path present on the
  runner image.
- **If `altool` upload is ever removed**: switch ExportOptions `destination` from
  `export` to `upload` — `xcodebuild -exportArchive` then uploads directly (at the
  cost of no `.ipa` artifact).

## Placeholder app icons

The committed `Assets.xcassets` icons are generated by the monorepo's
`scripts/native/gen-app-icons.mjs` (run here via `bash scripts/sync-content.sh`) — the real Fly
GACA falcon mark (`public/brand/flygaca-mark.png`) on the shared Falcon night background, its
silhouette filled with a per-module duotone from one coherent "Desert & sky" heritage
palette (palm green / sky blue / sand gold / terracotta / deep teal / sunset clay), so
every app is the same brand mark in its own colourway. They're flattened 1024 px PNGs
with no alpha channel, so they pass App Store validation, but they're brand-system
placeholders (the real mark, recoloured), not final bespoke per-app artwork — swap in
real art before external distribution.
