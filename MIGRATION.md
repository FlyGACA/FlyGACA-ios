# Migration tracker — `FlyGACA-app/apple/` → the standalone iOS home

This tracker records how **ay2m/FlyGACA became the dedicated repo for the Fly GACA native iOS
family**: the extraction of the `apple/` tree out of the `FlyGACA/FlyGACA-app` web monorepo into
a standalone home. It is **history only** — no open items are tracked here. Open work lives in
[`ROADMAP.md`](./ROADMAP.md); this file doubles as the changelog at stage granularity.

House rule (inherited from the monorepo's own `MIGRATION.md`): when reality moves on, annotate
the stage — don't rewrite it.

> **Annotation (2026-08-10).** Two things below are now history, not current state:
> 1. The stages describe **six** app targets — what was extracted. Four (PPL, CPL, IR, ATPL) have
>    since been **paused** and removed; the family now ships **ELPT + AIP**. Read "six apps" as a
>    historical count.
> 2. The stages describe the monorepo's `apple/` tree as a live parallel copy synced here (incl.
>    the `--all` mode and "monorepo-authored docs"). That mirror was **retired 2026-08**: the
>    monorepo deleted its `apple/` tree, this repo is now the sole home of the app code, and
>    `sync-content.sh` pulls only generated `Content/` + icons (no `--all`, no doc sync). The docs
>    once called "monorepo-authored" are owned here now.
>
> See [`ROADMAP.md`](./ROADMAP.md) for both.

## ✅ Stage 0 — the placeholder (2026-07-24)

- The repo was born as a throwaway Xcode starter (`80d47c0`): an `Untitled Project.xcodeproj`
  plus a stock `MyApp/ContentView.swift` — 392 lines, none of which survive. It existed to
  reserve the repo; the real content arrived four days later.

## ✅ Stage 1 — the extraction (2026-07-28, [#1](https://github.com/ay2m/FlyGACA/pull/1))

One commit (`8d6e395` — 109 files, +23,601/−392) turned the placeholder into the iOS family
repo, importing the monorepo's `apple/` tree wholesale and deleting the starter:

- **The kit:** `apple/FlyGACAKit` — `Package.swift` + the six library targets (`CoreModels`,
  `StudyEngines`, `ContentKit`, `PersistenceKit`, `AppServices`, `FeatureUI`) and the four test
  targets (10 files), including the web-parity vectors for spaced repetition and exam scoring.
- **The six app targets:** `apple/Apps/{PPL,ELPT,AIP,CPL,IR,ATPL}/` — per-app xcconfig (bundle
  id, module id, display name), `Assets.xcassets` icons, committed `Content/` snapshots — plus
  the one shared shell, `apple/Apps/Shared/FlyGACAApp.swift`, and `apple/project.yml` (XcodeGen;
  the Xcode project is generated, never committed).
- **CI:** `.github/workflows/ios.yml`, ported from the monorepo's iOS workflow minus what does
  not apply here — no content-validation job (this repo has no bundler) and no `npm ci` (zero JS
  dependencies).
- **The scripts:** `scripts/native/` (`ios-generate.sh`, `xcodebuild-wrapper.sh`,
  `ci-firebase-placeholder.sh`) and `scripts/sync-content.sh` — the one-way content pipe from a
  local `FlyGACA-app` clone into this repo's committed snapshots.
- **The docs:** `apple/ARCHITECTURE.md`, `apple/README.md` and the `docs/RUNBOOK-ios-*.md` set —
  all monorepo-authored, imported verbatim. Their monorepo point of view is a known artifact,
  annotated rather than rewritten (see [`docs/README.md`](./docs/README.md)).

## ✅ Stage 2 — release tooling (2026-07-28, [#2](https://github.com/ay2m/FlyGACA/pull/2))

- `ad933e2` (+534/−232): **store-side helpers** — `scripts/native/firebase-register-apps.sh`
  (scripts the six Firebase iOS app registrations + plist downloads),
  `scripts/native/set-signing-secrets.sh` (uploads the ten signing secrets from local files),
  and the per-app marketing-screenshot pipeline under `apple/Scripts/html-render/`.

## ✅ Stage 3 — identity & guidance (2026-07-31 → 2026-08-03, #3–#5)

- **Batch 3.1 — the front door** (`e3aa974`,
  [#3](https://github.com/ay2m/FlyGACA/pull/3)): root `README.md` gained the app-icon row, the
  CI/license badges and the repo-family table.
- **Batch 3.2 — assistant guidance** (`040fb40`, [#4](https://github.com/ay2m/FlyGACA/pull/4);
  refreshed by `606a43c`, [#5](https://github.com/ay2m/FlyGACA/pull/5)): root `CLAUDE.md` added,
  then rewritten against the repo's actual state — the sync boundary, the `ios:test` exit-0
  trap, the monorepo-authored-docs caveat, the Sign in with Apple provisioning blocker.

## ✅ Stage 4 — the repo docs suite (2026-08-04, this PR)

The gap this tracker ends on: until now, every doc here was either monorepo-authored or a
CLAUDE.md. This stage adds the repo-native suite:

- [`CAUSE.md`](./CAUSE.md) — why Fly GACA exists; the seven principles.
- [`ROADMAP.md`](./ROADMAP.md) — the single source of truth for open work in this repo.
- `MIGRATION.md` — this file.
- [`SEO-PLAN.md`](./SEO-PLAN.md) — App Store search (ASO) strategy for the six apps.
- [`THE-BOOK-OF-FLY-GACA.md`](./THE-BOOK-OF-FLY-GACA.md) — the whole-family reference: all ten
  repos, one book.
- [`CONTRIBUTING.md`](./CONTRIBUTING.md) — setup, testing, the sync boundary, PR expectations.
- [`docs/RUNBOOK-ios-release.md`](./docs/RUNBOOK-ios-release.md) — the end-to-end release path
  from *this* repo's point of view.
- [`docs/README.md`](./docs/README.md) — the docs index: repo-native vs monorepo-authored vs
  sync-overwritten.
- A `README.md` refresh (docs table, six-apps table, CI-trigger correction) and `CLAUDE.md`
  pointer updates.

## Migration complete — what remains

The extraction is done — this repo generates, builds, tests and archives all six apps with no
monorepo checkout present. What remains is **relationship**, not migration, and is tracked in
[`ROADMAP.md`](./ROADMAP.md):

- The monorepo still carries its own live `apple/` tree (a legacy copy of this one), and most of
  its docs still describe the iOS family as in-monorepo. Retiring that copy is the open
  cross-repo item; until then, content and the synced `apple/` files flow **one way** —
  monorepo → here, via `scripts/sync-content.sh` — never the reverse.
- The content bundler (`scripts/build-ios-content.mjs`) and `npm run ios:icons` deliberately do
  **not** exist here. That is the design, not a leftover: the corpus and the pack catalog are the
  monorepo's to own, and this repo commits snapshots.
- The committed snapshots lagged the web packs for a stretch (ELPT bundled 1 of the web's 4
  banks, AIP 2 of 3, as of early 2026-08); a reviewed `sync-content.sh` run closed the gap on
  2026-08-05. Snapshots are point-in-time by design — expect them to trail the corpus between
  syncs.
