# Contributing

Thanks for helping build the Fly GACA iOS family. This is the short version — the deep
statutes live in [`CLAUDE.md`](./CLAUDE.md) (conventions & gotchas) and
[`THE-BOOK-OF-FLY-GACA.md`](./THE-BOOK-OF-FLY-GACA.md) (the whole-family picture).

## Setup

- A Mac with **Xcode 16+** (the generated project uses the Xcode 16 format; Xcode 15 refuses
  it). `node` must be on PATH for the build scripts.
- There is **no `npm install`** — `package.json` is a zero-dependency script dispatcher.
- `npm run ios:generate` → XcodeGen produces `apple/FlyGACA.xcodeproj` (generated, never
  committed). Pick a scheme (ELPT or AIP) and run; everything works fully offline.

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

**This repo owns its Swift code, Xcode config and all its docs.** Only each app's `Content/` +
`Assets.xcassets` come from the monorepo, generated there and written straight into this repo by
`bash scripts/sync-content.sh` (the monorepo's `apple/` mirror was retired 2026-08; there is no
`--all` mode). Therefore:

- **Kit/Swift, shared shell, `project.yml`, `apple/Scripts`, the `apple/` docs** → change **here**.
- **Content (quiz banks, module manifests) and icons** → change the corpus / `prepCatalog.ts` in
  the [monorepo](https://github.com/FlyGACA/FlyGACA-app), then `sync-content.sh` here (review the
  diff before committing). Don't hand-edit `Content/` or `Assets.xcassets` — a sync overwrites them.
- **Store listing copy, keywords, screenshots** → the app's own metadata repo
  (`FlyGACA/ELPT`, `FlyGACA/AIP`), not here.

## Branches, PRs, CI

- PRs target `main`. A push to a feature branch runs **nothing**; opening the PR fires
  `swift-test`, `xcodegen-validate` and the macOS debug matrix over every app
  (`fail-fast: true` — one real failure cancels the rest).
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
