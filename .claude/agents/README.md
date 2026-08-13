# Project subagents

Claude Code loads every `*.md` here as a project-scoped subagent (see
[the subagent docs](https://code.claude.com/docs/en/sub-agents)).

| Agent | Use it for |
| --- | --- |
| `swift-kit` | `apple/FlyGACAKit` — the target graph, engines, SwiftData, the shared shell |
| `parity-guard` | Read-only check that SRS / due dates / scoring / streaks still match the web |
| `ios-release` | Builds, signing, TestFlight, Firebase registration, CI, screenshots |

What these encode that a generic Swift agent cannot know: that engines never do
IO (which is why `swift test` needs no simulator); that `PlatformLive` does not
exist yet, so the `AppServices` mocks *are* the shipping product; that
`npm run ios:test` exits 0 even when tests fail, so you must run
`cd apple/FlyGACAKit && swift test` directly; that due dates must stay UTC
day-strings or progress drifts a day for every user in the Kingdom; that PPL /
CPL / IR / ATPL are paused and must not be restored; and that the App Group
mismatch is a **portal** fix, never an entitlements edit.

## Conventions

- `name` matches the filename; lowercase and hyphens only.
- `description` says when to delegate; reviewers say "use proactively".
- `parity-guard` is deliberately read-only and runs on a cheaper model — it
  returns findings about a contract, it does not rewrite the contract.
- Anything requiring the Apple Developer or Firebase console is reported as
  human-only rather than attempted.
