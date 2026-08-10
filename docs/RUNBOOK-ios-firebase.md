# RUNBOOK — iOS Firebase apps + Sign in with Apple

> **Note (this repo):** this runbook is shared with the [FlyGACA-app](https://github.com/FlyGACA/FlyGACA-app) monorepo, where the content
> bundler (`scripts/build-ios-content.mjs`), the pack catalog (`src/lib/prepCatalog.ts`)
> and the icon generator (`npm run ios:icons`) live. In this repo the per-app `Content/`
> folders and icons are committed snapshots — refresh them with `bash scripts/sync-content.sh`
> pointed at a FlyGACA-app clone. Everything else applies here unchanged.


The App Store apps share one Firebase project (`flygaca-app`), so Firebase needs **one
iOS app registration per bundle id** — and Sign in with Apple needs configuring
in two places that are easy to confuse. This is the console/portal half; it is manual by
nature (no API covers the Apple provider or the Apple Developer portal).

> **Shortcut for the registrations:** the app-registration + plist-download step can be
> scripted. After `npm i -g firebase-tools && firebase login`, run
> `npm run firebase:register` (`scripts/native/firebase-register-apps.sh`) — it creates the
> iOS apps for the bundle ids below and writes each `apple/Apps/<APP>/GoogleService-Info.plist`
> (git-ignored). The Sign in with Apple provider + APNs auth key below stay manual.

The app side is already wired: `apple/project.yml` copies each app's
`GoogleService-Info.plist` into its bundle, and `Apps/Shared/App.entitlements` carries
`com.apple.developer.applesignin`. Nothing here needs code changes.

## The apps

| Target | Bundle id | Display name |
| --- | --- | --- |
| ELPT | `com.flygaca.elpt` | Fly GACA ELPT |
| AIP | `com.flygaca.aip` | Fly GACA AIP |

The licence-exam modules (PPL, CPL, IR, ATPL) are **paused** and no longer build from this
repo — see `ROADMAP.md`. Any Firebase app registrations already created for their bundle ids
are harmless; leave them.

Identity lives in `apple/Apps/<Target>/<Target>.xcconfig`; that file is the source of
truth for the bundle id, not this table.

## 1. Register the iOS apps

Firebase Console → `flygaca-app` → Project settings → General → Your apps → **Add app →
iOS**, once per row above. App Store ID can stay blank until the app exists in App Store
Connect.

## 2. Add the `GoogleService-Info.plist` files

Download each app's plist as you register it and save it to its target folder:

```
apple/Apps/<Target>/GoogleService-Info.plist
```

The files are **not** interchangeable — each carries its own `CLIENT_ID`,
`GOOGLE_APP_ID`, and `BUNDLE_ID`. A swapped pair builds cleanly and fails at runtime, so
verify before moving on:

```bash
for a in ELPT AIP; do
  printf '%-6s ' "$a"
  plutil -extract BUNDLE_ID raw "apple/Apps/$a/GoogleService-Info.plist" 2>/dev/null || echo MISSING
done
```

Each line must read `com.flygaca.<lowercased target>`. Then regenerate:

```bash
npm run ios:generate
```

The plists are **committed**, like the public web config in `.env.example`. An iOS
config file ships inside the app binary and is not a secret — it identifies the project,
it doesn't authorize anything. Access is enforced by `firestore.rules` and App Check, not
by keeping this file private.

They are declared `optional: true` in `apple/project.yml`, so `ios:generate` and unsigned
local builds keep working on a checkout where they're absent.

## 3. Enable Apple in Firebase Authentication

Console → Authentication → Sign-in method → Add new provider → **Apple** → Enable. The
callback URL is:

```
https://flygaca-app.firebaseapp.com/__/auth/handler
```

For **native iOS only**, enabling the toggle is enough. The Services ID / Team ID / Key
ID / `.p8` fields (step 4b–4d) are additionally required for either of:

- Apple sign-in on the **web** app, or
- **token revocation** — not optional for App Store releases, since Apple requires apps
  offering Sign in with Apple to support account deletion.

## 4. Apple Developer portal

### 4a. Enable the capability on every App ID — and group them

Certificates, Identifiers & Profiles → Identifiers → each App ID → enable **Sign In with
Apple**. There is no callback-URL field here; that belongs on a Services ID (4b).

When configuring, Apple asks whether each App ID is a *primary* or is *grouped with an
existing primary*:

- `com.flygaca.elpt` → **Enable as a primary App ID**
- every other App ID → **Group with an existing primary App ID** → `com.flygaca.elpt`

> Earlier revisions of this runbook named `com.flygaca.ppl` as the primary. PPL is a **paused**
> module, so the primary is now ELPT. Nothing is stranded: Sign in with Apple was removed from
> `apple/Apps/Shared/App.entitlements` in 2026-08 and the registered App IDs never carried the
> capability, so no user identifier has been issued under the old primary.

**Grouping is load-bearing.** Apple issues its user identifier per App-ID group, so
without it one person signing into ELPT and then AIP arrives as two different Apple users
and lands on two separate Firebase accounts. That breaks the shared-account model the
family is built on — `Apps/Shared/App-Shared.xcconfig` declares a single App Group and
keychain (`group.com.flygaca.study`) precisely so streaks, SRS, and sign-in carry across
apps. Grouping retroactively re-identifies anyone who already signed in, so set it before
the first release.

Enabling a capability **invalidates existing provisioning profiles** — regenerate them
(`docs/RUNBOOK-ios-signing.md`). The app already ships the matching
`com.apple.developer.applesignin` entitlement, so a signed build before this step fails
provisioning.

### 4b. Create a Services ID (web sign-in / revocation only)

Identifiers → + → **Services IDs** → enable Sign In with Apple → Configure:

- Primary App ID: `com.flygaca.elpt`
- Domains and Subdomains: `flygaca-app.firebaseapp.com`
- Return URLs: `https://flygaca-app.firebaseapp.com/__/auth/handler`

### 4c. Create a Sign in with Apple key

Keys → + → enable **Sign In with Apple** → set the primary App ID → download the `.p8`.
**Apple allows that download once.** Record the Key ID and your Team ID.

### 4d. Fill the Firebase provider

Back in step 3's Apple provider, supply the Services ID, Team ID, Key ID, and `.p8`
contents.

## 5. Authorized domains (web only)

If Apple sign-in runs on the web, every serving origin must appear under Authentication →
Settings → Authorized domains. `docs/RUNBOOK-firebase.md` covers that failure mode
(`auth/unauthorized-domain`) and lists the origins to register.

## Verifying

```bash
npm run ios:generate     # succeeds with or without the plists present
npm run ios:build:elpt   # unsigned local build
```

In Xcode, each app's **Copy Bundle Resources** must list its own
`GoogleService-Info.plist` and no other app's. With the Firebase CLI authenticated,
`firebase apps:list IOS` should return every bundle id above.

## Related

- `docs/RUNBOOK-firebase.md` — web/Firestore side, authorized domains, auth triage
- `docs/RUNBOOK-ios-signing.md` — certificates, profiles, TestFlight
- `docs/RUNBOOK-ios-xcodebuild.md` — building without opening Xcode
- `apple/ARCHITECTURE.md` — where the platform layer fits
