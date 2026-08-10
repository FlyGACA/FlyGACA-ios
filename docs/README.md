# docs/ — index

**Everything in this repo is now natively owned and hand-editable here.** The monorepo's `apple/`
mirror was retired 2026-08, and `scripts/sync-content.sh` no longer has an `--all` mode — it only
pulls generated `Content/` + `Assets.xcassets`. So the old three-tier "some docs are
sync-overwritten, edit them upstream" model is gone: edit any doc here freely.

## The iOS runbooks

| Doc | What it is |
| --- | --- |
| [`RUNBOOK-ios-release.md`](./RUNBOOK-ios-release.md) | **Start here.** The end-to-end release path — sync content → generate project → test → build → sign → TestFlight. |
| [`RUNBOOK-ios-signing.md`](./RUNBOOK-ios-signing.md) | Code signing & TestFlight — the full why + troubleshooting. |
| [`RUNBOOK-ios-signing-CHECKLIST.md`](./RUNBOOK-ios-signing-CHECKLIST.md) | The condensed do-this-in-order signing checklist (secrets, profile names). |
| [`RUNBOOK-ios-firebase.md`](./RUNBOOK-ios-firebase.md) | The one Firebase project (`flygaca-app`) behind every app; §4a's Sign in with Apple grouping matters only if sign-in ships, and names a paused module as primary — read it with `ROADMAP.md` in hand. |
| [`RUNBOOK-ios-xcodebuild.md`](./RUNBOOK-ios-xcodebuild.md) | Build/CI/troubleshooting reference, incl. "Adding a New iOS App". Its "Phase Roadmap" numbering diverges from `apple/ARCHITECTURE.md` §5 — the architecture doc wins. |
| [`PORTAL-RUNSHEET-wave1.md`](./PORTAL-RUNSHEET-wave1.md) | The click-ordered Apple portal + App Store Connect runsheet — every value pre-filled from the repos. Written for a three-app Wave 1; its PPL rows are annotated as paused. |
| `README.md` | This index. |

> These runbooks and `apple/ARCHITECTURE.md` / `apple/README.md` began as copies of the monorepo's
> versions and a couple still describe the *content* generators (`build-ios-content.mjs`,
> `npm run ios:icons`) as if they lived here — they live in the monorepo, and `sync-content.sh`
> invokes them. Everything else is accurate for this repo; fix drift in place.

The root suite (`CAUSE.md`, `ROADMAP.md`, `MIGRATION.md`, `SEO-PLAN.md`,
`THE-BOOK-OF-FLY-GACA.md`, `CONTRIBUTING.md`) is repo-native too — the root
[`README.md`](../README.md) has the full map.
