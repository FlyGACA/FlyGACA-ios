# docs/ — index

Why docs live here and at the repo root: `scripts/sync-content.sh` never touches `docs/`, the
root, or `.github/` — so **repo-native writing is safe only in those places**. Everything under
`apple/` is either wiped or overwritten by a `--all` sync. That gives this repo's documentation
three tiers; know which one you're editing.

## Repo-native — edit freely here

| Doc | What it is |
| --- | --- |
| [`RUNBOOK-ios-release.md`](./RUNBOOK-ios-release.md) | **Start here.** The end-to-end release path from this repo's point of view — sync → generate → test → build → sign → TestFlight — plus the reconciliation map over the snapshot runbooks below. |
| [`PORTAL-RUNSHEET-wave1.md`](./PORTAL-RUNSHEET-wave1.md) | The click-ordered Apple portal + App Store Connect runsheet for Wave 1 — every value pre-filled from the repos (App IDs, profile names, the ten secrets, per-app record fields, ready-to-paste review notes). |
| `README.md` | This index. |

The root suite (`CAUSE.md`, `ROADMAP.md`, `MIGRATION.md`, `SEO-PLAN.md`,
`THE-BOOK-OF-FLY-GACA.md`, `CONTRIBUTING.md`) is repo-native too — the root
[`README.md`](../README.md) has the full map.

## Monorepo-authored snapshots — do not hand-edit

Imported verbatim from the `FlyGACA/FlyGACA-app` monorepo and written from *its* point of view
(they reference `build-ios-content.mjs` and `npm run ios:icons`, which don't exist here). A sync
run doesn't overwrite them, but keep them byte-identical to the monorepo copies anyway — that's
what keeps them diffable. All reconciliation lives in
[`RUNBOOK-ios-release.md`](./RUNBOOK-ios-release.md), not in edits to these files.

| Doc | What it covers |
| --- | --- |
| [`RUNBOOK-ios-signing.md`](./RUNBOOK-ios-signing.md) | Code signing & TestFlight — the full why + troubleshooting. |
| [`RUNBOOK-ios-signing-CHECKLIST.md`](./RUNBOOK-ios-signing-CHECKLIST.md) | The condensed do-this-in-order signing checklist (ten secrets, profile names). Carries no "Note (this repo)" banner — treat it as monorepo-authored anyway. |
| [`RUNBOOK-ios-firebase.md`](./RUNBOOK-ios-firebase.md) | The one Firebase project (`flygaca-app`) behind all six apps; §4a's Sign in with Apple grouping is load-bearing. |
| [`RUNBOOK-ios-xcodebuild.md`](./RUNBOOK-ios-xcodebuild.md) | Build/CI/troubleshooting reference, incl. "Adding a New iOS App". Its "Phase Roadmap" numbering diverges from `apple/ARCHITECTURE.md` §5 — the architecture doc wins. |

## Sync-overwritten — edit in the monorepo, never here

`apple/ARCHITECTURE.md` (the blueprint) and `apple/README.md` (the Mac setup) are replaced
verbatim by every `sync-content.sh --all` run. An edit made here dies on the next sync — change
them in the monorepo's `apple/` tree and sync them over.
