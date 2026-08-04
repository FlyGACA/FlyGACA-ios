# Contributing

Thanks for helping build the Fly GACA iOS family. This is the short version — the deep
statutes live in [`CLAUDE.md`](./CLAUDE.md) (conventions & gotchas) and
[`THE-BOOK-OF-FLY-GACA.md`](./THE-BOOK-OF-FLY-GACA.md) (the whole-family picture).

## Setup

- A Mac with **Xcode 16+** (the generated project uses the Xcode 16 format; Xcode 15 refuses
  it). `node` must be on PATH for the build scripts.
- There is **no `npm install`** — `package.json` is a zero-dependency script dispatcher.
- `npm run ios:generate` → XcodeGen produces `apple/FlyGACA.xcodeproj` (generated, never
  committed). Pick a scheme (PPL … ATPL) and run; everything works fully offline.

## Testing

```bash
cd apple/FlyGACAKit && swift build && swift test
```

> [!IMPORTANT]
> Run `swift test` **directly**. The `npm run ios:test` alias prints "Swift not available;
> skipping iOS tests" and **exits 0 even when tests fail** — never trust it as a gate.

The suite (4 targets, 10 files) includes the **web-parity vectors** for spaced repetition and
exam scoring. They are the cross-platform contract with the web app — if your change breaks
one, the fix is almost never "update the vector"; it's aligning with the web semantics or
changing both platforms together.

## The sync boundary — where your change belongs

Content and the shared Swift tree flow **one way**: monorepo → here, via
`bash scripts/sync-content.sh`. A `--all` sync deletes-and-replaces
`apple/FlyGACAKit/{Sources,Tests}`, `apple/Apps/Shared/`, the per-app xcconfigs,
`apple/AppleTests/`, `apple/Scripts/`, and overwrites `apple/project.yml`,
`apple/ARCHITECTURE.md` and `apple/README.md`; the default mode replaces every
`apple/Apps/*/Content` and `Assets.xcassets`. Therefore:

- **Kit/Swift, shared shell, content, icons, the synced apple/ docs** → change in the
  [monorepo](https://github.com/FlyGACA/FlyGACA-app) first, then sync here (review the diff
  before committing it).
- **Store listing copy, keywords, screenshots** → the app's own metadata repo
  (`FlyGACA/PPL` … `FlyGACA/AIP`), not here.
- **Repo-native docs, scripts under `scripts/`, CI, root files** → here. New docs go at the
  repo root or `docs/` (sync never touches them — see [`docs/README.md`](./docs/README.md)).

## Branches, PRs, CI

- PRs target `main`. A push to a feature branch runs **nothing**; opening the PR fires
  `swift-test`, `xcodegen-validate` and the six-app macOS debug matrix (`fail-fast: true` —
  one real failure cancels the other five).
- Keep PRs scoped; a sync commit is its own PR, reviewed as a diff, not mixed with feature
  work.

## Docs rules

- **The disclaimer is never reworded.** If a new surface needs it, copy the EN+AR block
  verbatim from [`README.md`](./README.md#disclaimer).
- **Keep `CLAUDE.md` true**: if your change makes it stale, the same PR updates it. Same for
  the dated stamps in `THE-BOOK-OF-FLY-GACA.md`.

## License

MIT © BDA Company International (شركة بدع الدولية), operating as Fly GACA — contributions are
accepted under the same license.
