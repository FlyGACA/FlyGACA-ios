# iOS Signing → TestFlight — copy-paste checklist

The condensed, do-this-in-order companion to
[`RUNBOOK-ios-signing.md`](./RUNBOOK-ios-signing.md) (read that for the why). This
activates the `ios-testflight` job in `.github/workflows/ios.yml` for the two
shipping apps (ELPT, AIP). Until the secrets exist the job is skipped and CI
stays green — nothing here is urgent. (The licence-exam modules are paused — see
`ROADMAP.md`.)

**Verified:** all nine secret names below match the workflow exactly, and the
`ios-testflight` matrix is `elpt · aip`. Everything below is your Apple work —
no CLI can create Apple certs/profiles/app records for you.

## A. Apple Developer portal — developer.apple.com/account

- [ ] **App Group** → Identifiers → App Groups → register `group.com.FlyGACA`.
- [ ] **App IDs** — two explicit IDs, each with **App Groups** enabled + `group.com.FlyGACA`:
  - [ ] `com.flygaca.elpt`
  - [ ] `com.flygaca.aip`
- [ ] **Distribution certificate** → create an **Apple Distribution** cert (CSR from Keychain
  Access). Export it **with its private key** as `Distribution.p12`, set a password → this becomes
  `P12_PASSWORD`.
- [ ] **Provisioning profiles** — two **App Store** profiles, one per App ID, using that cert,
  named **exactly** (names are load-bearing — CI passes them as `PROVISIONING_PROFILE_SPECIFIER`):
  - [ ] `FlyGACA ELPT AppStore`
  - [ ] `FlyGACA AIP AppStore`

## B. App Store Connect — appstoreconnect.apple.com

- [ ] **App records** — create two apps (paid-up-front), one per bundle id above. (Uploads fail
  with "No suitable application records found" until these exist.)
- [ ] **API key** → Users & Access → Integrations → App Store Connect API → Team Keys → generate a
  key with **App Manager** role. Note the **Key ID** + **Issuer ID**; download the `.p8` (**once
  only**).

## C. Create the GitHub secrets (on this repo — the one whose `ios.yml` consumes them)

Two ways — a helper script, or by hand.

**Helper (recommended):** put the four files somewhere and run —

```bash
export APPLE_TEAM_ID=XXXXXXXXXX APP_STORE_CONNECT_API_KEY_ID=XXXXXXXXXX \
       APP_STORE_CONNECT_API_ISSUER_ID=xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx \
       P12_PASSWORD='your-p12-password'
bash scripts/native/set-signing-secrets.sh \
  Distribution.p12 \
  FlyGACA_ELPT_AppStore.mobileprovision \
  FlyGACA_AIP_AppStore.mobileprovision \
  AuthKey_XXXXXXXXXX.p8
```

**By hand** (repo → Settings → Secrets and variables → Actions, or `gh secret set`). Base64-encode
binaries with `base64 -w0 <file>` (Linux) or `base64 -i <file>` (macOS):

| Secret | Content |
|---|---|
| `APPLE_TEAM_ID` | 10-char Team ID (Membership page) |
| `BUILD_CERTIFICATE_BASE64` | `Distribution.p12`, base64 |
| `P12_PASSWORD` | password chosen when exporting the `.p12` |
| `KEYCHAIN_PASSWORD` | any random string (temp CI keychain) |
| `PROVISIONING_PROFILE_ELPT_BASE64` | ELPT App Store profile, base64 |
| `PROVISIONING_PROFILE_AIP_BASE64` | AIP App Store profile, base64 |
| `APP_STORE_CONNECT_API_KEY_ID` | the API key's Key ID |
| `APP_STORE_CONNECT_API_ISSUER_ID` | the Issuer ID (UUID) |
| `APP_STORE_CONNECT_API_KEY_BASE64` | the `.p8`, base64 |

## D. First run

- [ ] Push to `main` (or `workflow_dispatch` the iOS workflow). `check-signing` now outputs
  `enabled=true` and `ios-testflight` runs for elpt/aip.
- [ ] After Apple processing (~5–15 min/build), builds appear under each app's TestFlight tab.

## Adding another app later

Repeat A–C for the new bundle id (App ID + `FlyGACA <APP> AppStore` profile +
`PROVISIONING_PROFILE_<APP>_BASE64` secret), then add its `{app, scheme}` entry to the
`ios-testflight` matrix in `.github/workflows/ios.yml`.

See [`RUNBOOK-ios-signing.md`](./RUNBOOK-ios-signing.md) → Troubleshooting for the common errors
(missing cert, profile/cert mismatch, alpha-channel icon, duplicate build number).
