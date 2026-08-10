# Apple portal runsheet — ELPT · AIP

> **⏸ Status update, 2026-08-10 — PPL is paused.** This runsheet was written for a
> three-app Wave 1 (PPL · ELPT · AIP). PPL has since been paused along with CPL, IR and
> ATPL (see [`../ROADMAP.md`](../ROADMAP.md)), so **do the PPL rows only if that decision
> is reversed**. The PPL values are **kept, not deleted** — they record real portal state
> that still exists at Apple:
>
> - An App Store Connect record exists: *Saudi PPL Exam Prep*, Apple ID `6798457189`,
>   SKU `ppl`, state *Prepare for Submission*. Leave it parked — an unsubmitted record
>   costs nothing and holds the name.
> - `com.flygaca.ppl` was designated the Sign-in-with-Apple **primary App ID**. That
>   designation is moot today: the capability was removed from
>   `apple/Apps/Shared/App.entitlements` in 2026-08 and the App IDs never carried it, so
>   no Apple user identifier was ever issued under it. If sign-in ships, make
>   **`com.flygaca.elpt`** the primary instead (§1.2, §4b).
> - A `FlyGACA PPL AppStore` profile and the `PROVISIONING_PROFILE_PPL_BASE64` secret are
>   now orphaned. Harmless; delete at leisure.

Every value below is pre-filled from this repo and the metadata repos
(`FlyGACA/ELPT` · `AIP`, plus the parked `FlyGACA/PPL`), in click order, so the portal
session needs no improvisation. Companions: [`RUNBOOK-ios-signing.md`](./RUNBOOK-ios-signing.md) (the why +
troubleshooting), [`RUNBOOK-ios-signing-CHECKLIST.md`](./RUNBOOK-ios-signing-CHECKLIST.md)
(the boxes this expands), [`RUNBOOK-ios-firebase.md`](./RUNBOOK-ios-firebase.md) (§4a Sign
in with Apple).

Value tags: **✅ verified from the repos** · **🟡 RECOMMENDED** (nothing recorded — confirm
as you click) · **🔵 DECIDE** at the portal.

## 0. Before you start

- You need: the Apple Developer account (Account Holder or Admin), a **Mac with Keychain
  Access** (for the CSR and the `.p12` export), roughly 45–60 minutes, and — for §4's
  one-shot helper — the `gh` CLI authenticated (web UI works as the fallback).
- **Ordering warning (load-bearing):** enable **Sign in with Apple** on the App IDs
  *before* creating the provisioning profiles — enabling a capability invalidates existing
  profiles (`RUNBOOK-ios-firebase.md` §4a). The signing checklist's section A alone doesn't
  mention this.
- Scope is Wave 1 only: `com.flygaca.ppl` / `.elpt` / `.aip`. Wave 2 repeats the loop
  later (§7).

## 1. Apple Developer portal — [developer.apple.com/account](https://developer.apple.com/account)

All under **Certificates, Identifiers & Profiles**.

**1.1 App Group** — Identifiers → App Groups → register:
`group.com.flygaca.study` ✅ (this is why wildcard App IDs are impossible — wildcards can't
carry the App Groups capability).

**1.2 App IDs** — three explicit App IDs, each with **both** capabilities:

| App ID | Capabilities | Sign in with Apple setting |
| --- | --- | --- |
| ⏸ `com.flygaca.ppl` | App Groups → `group.com.flygaca.study` · Sign In with Apple | paused module — was the primary; see the banner |
| `com.flygaca.elpt` ✅ | App Groups → `group.com.flygaca.study` | **Enable as a primary App ID** (replaces PPL) |
| `com.flygaca.aip` ✅ | same | **Group with an existing primary** → `com.flygaca.elpt` |

Grouping is load-bearing: Apple issues its user identifier per App-ID *group*, so ungrouped
apps would split one person into two Firebase accounts when sign-in ships. Set it now, before
the first release. (When Wave 2's App IDs are created they join the same group — §7.)

**1.3 Distribution certificate** — Certificates → **＋** → **Apple Distribution** (CSR made
in Keychain Access → Certificate Assistant). Then in Keychain, export the certificate
**together with its private key** as `Distribution.p12`; the export password you choose
becomes the `P12_PASSWORD` secret in §4.

**1.4 Provisioning profiles** — Profiles → **＋** → **App Store** distribution, one per App
ID, using the 1.3 certificate. The names must be **exactly** these (CI passes them as
`PROVISIONING_PROFILE_SPECIFIER`):

| Profile name (exact) | App ID |
| --- | --- |
| `FlyGACA PPL AppStore` ✅ | `com.flygaca.ppl` |
| `FlyGACA ELPT AppStore` ✅ | `com.flygaca.elpt` |
| `FlyGACA AIP AppStore` ✅ | `com.flygaca.aip` |

Download the three `.mobileprovision` files — §4 needs them.

## 2. App Store Connect — [appstoreconnect.apple.com](https://appstoreconnect.apple.com) → My Apps → ＋

Create three **paid-up-front** iOS app records (uploads fail with *"No suitable application
records found"* until they exist). The listing copy itself — descriptions, keywords,
promotional text, screenshots — ships later from each metadata repo's fastlane `deliver`
layout; **don't hand-enter it now**. Record creation needs only:

> **Status — 2026-08-06:** all three records now exist in App Store Connect (Saudi PPL Exam
> Prep · Saudi AIP Study · Saudi ELPT Prep — iOS 1.0, *Prepare for Submission*), so the
> "create the records" step is done and §6's App Store ID field is unblocked. The ✅ values
> below are the actual App Store Connect values read off the records. PPL's SKU came out as
> the bare `ppl` (not the `flygaca-ppl-ios` first recommended); the ELPT/AIP SKU + Apple ID
> rows stay 🟡 until their App Information screens are read off the portal.

| Field | PPL | ELPT | AIP |
| --- | --- | --- | --- |
| Platform | iOS | iOS | iOS |
| Bundle ID | `com.flygaca.ppl` ✅ | `com.flygaca.elpt` ✅ | `com.flygaca.aip` ✅ |
| Name — en-US (≤30) | Saudi PPL Exam Prep ✅ | Saudi ELPT Prep (SAELPT) ✅ | Saudi AIP Study ✅ |
| Name — ar-SA | تحضير اختبار PPL ✅ | تحضير اختبار ELPT ✅ | حزمة AIP السعودية ✅ |
| Subtitle — en-US | GACAR-cited PPL written prep ✅ | Aviation English proficiency ✅ | Aeronautical info, GEN & ENR ✅ |
| Subtitle — ar-SA | تحضير نظري لرخصة الطيار الخاص ✅ | إجادة الإنجليزية للطيران ✅ | معلومات جوية للمطارات السعودية ✅ |
| SKU | `ppl` ✅ | `elpt` 🟡 | `aip` 🟡 |
| Apple ID (App Store ID) | `6798457189` ✅ | 🟡 read it off the record | 🟡 read it off the record |
| Primary language | **en-US**, then add **ar-SA as a full localization** 🟡 — the SEO-PLAN 0.5 posture: Arabic is a first-class listing, not a fallback; both locales are searchable on the Saudi storefront | same | same |
| Category | **Education** 🟡 (secondary: Reference 🟡 — no category is recorded anywhere in the repos) | Education 🟡 | Education 🟡 |
| Price | 🔵 the Apple price point nearest the web's **SAR 39** pack (`apple/ARCHITECTURE.md` §4: paid-up-front mirroring the web price; no exact tier is recorded — pick it here, same for all three) | 🔵 | 🔵 |
| Age rating | **4+** via an all-"None" questionnaire 🟡 (study app: no mature content, no unrestricted web, no user-generated content) | same | same |
| Privacy nutrition labels | **Data Not Collected** 🟡 — fully offline, no accounts, no analytics, no tracking. Revisit if telemetry ever ships | same | same |
| Export compliance | already answered in-binary ✅ — `ITSAppUsesNonExemptEncryption = NO` (`apple/Apps/Shared/App-Shared.xcconfig`), so no per-build prompt | same | same |
| Support URL | `https://flygaca.com/support?app=ppl-exam` ✅ | `https://flygaca.com/support?app=elp` ✅ | `https://flygaca.com/support?app=aip` ✅ |
| Marketing URL | `https://flygaca.com/study/packs/ppl-exam` ✅ | `https://flygaca.com/study/packs/elp` ✅ | `https://flygaca.com/study/packs/aip` ✅ |
| Privacy Policy URL | `https://flygaca.com/privacy` ✅ | same | same |

## 3. Review notes — ready to paste (App Review Information)

Shared template (swap the **[PER-APP LINE]**); the disclaimer sentence pair is the family's
canonical wording — do not reword it:

> This is a fully offline educational study app: no account, no sign-in, and no server
> connection. All features are available immediately on install, so no demo credentials are
> needed for review. The interface is bilingual (English and Arabic, RTL-mirrored); study
> content is in English, the language of Saudi aviation examinations. **[PER-APP LINE]**
> Fly GACA is an independent educational platform, not affiliated with, endorsed by, or
> operated by GACA or the Government of Saudi Arabia. GACA (gaca.gov.sa) is always the
> authoritative source; the apps cite it and defer to it. On our app family (Guideline
> 4.3(b)): we publish one focused study app per Saudi certificate or rating — the same
> model as ASA Prepware's or Gleim's per-certificate apps. The apps share an engine, but
> each bundles a distinct corpus for a distinct candidate audience, with distinct names,
> subtitles, keywords and icons.

Per-app lines (bank/question counts are the current bundled content, post the 2026-08-05
sync — **not** the stale `13/1/2` figures in older notes):

| App | [PER-APP LINE] |
| --- | --- |
| PPL | This app prepares candidates for the Saudi Private Pilot Licence written exam — 13 question banks, 514 cited practice questions, plus ground-school lessons. |
| ELPT | This app prepares candidates for the Saudi Aviation English Language Proficiency Test (SAELPT) — 4 question banks, 151 cited practice questions. |
| AIP | This app covers the Saudi AIP (GEN/ENR sections) and airspace — 3 question banks, 113 cited practice questions. |

## 4. ASC API key + the ten GitHub secrets

**4.1 API key** — Users & Access → Integrations → App Store Connect API → **Team Keys** →
Generate. Role: **App Manager**. Record the **Key ID** and the **Issuer ID** (UUID), and
download `AuthKey_<KEYID>.p8` — Apple allows that download **once**.

**4.2 One-shot helper** (from this repo; needs `gh auth status` to pass; sets all ten
secrets on `ay2m/FlyGACA`):

```bash
export APPLE_TEAM_ID=XXXXXXXXXX APP_STORE_CONNECT_API_KEY_ID=XXXXXXXXXX \
       APP_STORE_CONNECT_API_ISSUER_ID=xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx \
       P12_PASSWORD='your-p12-password'
bash scripts/native/set-signing-secrets.sh \
  Distribution.p12 \
  FlyGACA_PPL_AppStore.mobileprovision \
  FlyGACA_ELPT_AppStore.mobileprovision \
  FlyGACA_AIP_AppStore.mobileprovision \
  AuthKey_XXXXXXXXXX.p8
```

File order is fixed (p12 · ppl · elpt · aip · p8). `KEYCHAIN_PASSWORD` defaults to a
random string; `REPO` defaults to `ay2m/FlyGACA`. Your 10-char **Team ID** is on the
portal's Membership page.

**4.3 Manual fallback** — repo → Settings → Secrets and variables → Actions (base64 files
with `base64 -w0 <file>` on Linux, `base64 -i <file>` on macOS):

| Secret (exact name `ios.yml` consumes) | Value |
| --- | --- |
| `BUILD_CERTIFICATE_BASE64` | base64 of `Distribution.p12` |
| `P12_PASSWORD` | the 1.3 export password |
| `KEYCHAIN_PASSWORD` | any random string (temp CI keychain) |
| `PROVISIONING_PROFILE_PPL_BASE64` | base64 of `FlyGACA_PPL_AppStore.mobileprovision` |
| `PROVISIONING_PROFILE_ELPT_BASE64` | base64 of `FlyGACA_ELPT_AppStore.mobileprovision` |
| `PROVISIONING_PROFILE_AIP_BASE64` | base64 of `FlyGACA_AIP_AppStore.mobileprovision` |
| `APP_STORE_CONNECT_API_KEY_ID` | the 4.1 Key ID |
| `APP_STORE_CONNECT_API_ISSUER_ID` | the 4.1 Issuer ID (UUID) |
| `APP_STORE_CONNECT_API_KEY_BASE64` | base64 of `AuthKey_<KEYID>.p8` |
| `APPLE_TEAM_ID` | 10-char Team ID (Membership page) |

## 5. First run + verification

- Push to `main` (or run the iOS workflow via **workflow_dispatch**). `check-signing` now
  outputs `enabled=true`, and `ios-testflight` signs and uploads **ppl · elpt · aip** (the
  matrix is explicit — Wave 2 is not in it yet).
- Apple processing is ~5–15 min per build; builds then appear under each app's
  **TestFlight** tab in App Store Connect. The build number is the GitHub run number —
  shared across the trio, unique per app record, which is all Apple requires.
- If a leg goes red, `RUNBOOK-ios-signing.md`'s troubleshooting covers the usual suspects:
  cert/keychain (`set-key-partition-list`), profile–certificate mismatch, altool error 1091
  (icon alpha channel), duplicate build number, and *"No suitable application records
  found"* (a §2 record is missing).

## 6. Appendix — Firebase console half (not needed for the offline v1)

- **Register the iOS apps**: `npm run firebase:register` (idempotent), or console →
  Project settings → Your apps → **Add app → iOS** once per bundle id. The "App Store ID"
  field can stay blank until §2's records exist.
- **Apple provider** (needed only when PlatformLive ships sign-in): Authentication →
  Sign-in method → **Apple** → Enable. Native-only sign-in needs just the toggle; the
  Services ID + Sign in with Apple key (portal → Keys — the `.p8` downloads once) are
  additionally required for web sign-in **and for token revocation**, which Apple mandates
  once accounts (and 5.1.1 account deletion) exist.
- **APNs auth key** — ⚠️ no procedure is recorded anywhere in this repo; these steps are
  authored fresh here, verify against the consoles: portal → Keys → **＋** → enable
  **Apple Push Notifications service (APNs)** → download the `.p8` (once) → Firebase →
  Project settings → **Cloud Messaging** → the iOS app → upload the key with its Key ID +
  Team ID. Only needed when push reminders ship.

## 7. Paused modules (PPL · CPL · IR · ATPL) — only if the pause is lifted

These four modules are on hold; nothing here is scheduled work. If a module is restored,
the code side is a revert of the 2026-08-10 removal commit, then per app: portal App ID
(+ the App Group capability, **grouped under `com.flygaca.elpt`** if sign-in is live by
then) → `FlyGACA <APP> AppStore` profile → `PROVISIONING_PROFILE_<APP>_BASE64` secret → add
its `{app, scheme}` entry to the `ios-testflight` matrix in `.github/workflows/ios.yml` →
paid ASC record (each metadata repo is already CI-green with screenshots; PPL's ASC record
already exists — see the banner).
