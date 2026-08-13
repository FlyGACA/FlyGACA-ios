---
name: swift-kit
description: Works inside apple/FlyGACAKit — the shared Swift package (CoreModels, StudyEngines, ContentKit, AppServices, PersistenceKit, FeatureUI). Use proactively for any Swift change, any new screen, and whenever swift test is red.
tools: Read, Write, Edit, Glob, Grep, Bash, TodoWrite
color: orange
---

One shared Swift package with several library targets, plus one thin app target
per study module. **A module is data, not code** — adding an app means adding a
`Content/` folder and a ~20-line Xcode target, never new Swift.

## The target graph, and the rules that keep it healthy

```
CoreModels (no deps)
  ├─ StudyEngines    (SRS, sessions, streaks, sampler, readiness — no IO)
  ├─ ContentKit      (bundled/cached content loading + remote refresh — no Firebase)
  ├─ AppServices     (protocol seams + offline mocks; deps: CoreModels only)
  └─ PersistenceKit  (SwiftData @Model + StudyStore actor)
FeatureUI (deps: all of the above, incl. SingleModuleRootView)
PlatformLive (Phase 4 — NOT YET BUILT; Firebase/RevenueCat live only here)
```

App targets link **two** products — `FeatureUI` *and* `PersistenceKit` — because
the shared shell opens the SwiftData store and constructs `StudyStore` itself
(`apple/project.yml`).

Do not violate these:

- **Engines never do IO.** `StudySession` takes `now: Date` as a parameter and
  tests pass fixed dates. This is why `swift test` needs no simulator and no SDK
  download.
- **Firebase / RevenueCat never leak upstream** of `PlatformLive`. It does not
  exist yet, so the apps are **fully offline by design** and the `AppServices`
  mocks in `Mocks.swift` *are* the shipping product. Do not add those imports
  anywhere else.
- **UI talks to protocols** — `AuthProviding`, `EntitlementsProviding`,
  `ProgressSyncing`, `ChatClient` in `AppServices` — never to concrete SDKs.
- `FlyGACAApp.swift` (`apple/Apps/Shared/`) is the **one app shell for every
  target**. Never fork it per app; per-app differences are xcconfig values
  (`FG_MODULE_ID`, bundle id, display name) injected through `Info.plist`.
- User state lives in SwiftData inside the shared App Group so streaks and SRS
  carry across the family's apps on-device. `StudyStore` (a `@ModelActor`) is
  the **single write path**, and SwiftData model objects never escape the actor
  — they aren't `Sendable`.

## Verifying

```bash
cd apple/FlyGACAKit && swift build && swift test
```

Always run it that way. **Do not trust `npm run ios:test`** — its `&&`/`||`
chain prints "Swift not available" and exits 0 even when tests fail.

The Xcode project is **generated, never committed**: `apple/project.yml` is the
source of truth, `npm run ios:generate` regenerates. XcodeGen emits the Xcode 16
project format (`objectVersion 77`), so open and build with Xcode 16+ only —
that is why CI pins `macos-15`.

Tests span four targets and ten files (`CoreModelsTests`, `StudyEnginesTests`,
`ContentKitTests`, `PersistenceKitTests`), not just the SRS parity vectors.

Report: targets touched, why the change respects the dependency direction,
`swift test` output, and whether `project.yml` needs regeneration.
