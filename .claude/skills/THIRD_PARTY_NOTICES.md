# Third-Party Notices — vendored Claude Code skills

This directory contains skills vendored from third-party, community-maintained sources. They are
developer tooling for Claude Code only; they are not part of any shipped product and are never
served to end users.

## Anthropic-Cybersecurity-Skills

- **Project:** Anthropic-Cybersecurity-Skills (a community project — **not affiliated with
  Anthropic PBC**, despite the name)
- **Author:** Mahipal Jangra (@mukul975)
- **Source:** https://github.com/mukul975/Anthropic-Cybersecurity-Skills
- **License:** Apache License 2.0 (each vendored skill folder retains its upstream `LICENSE`)
- **Pinned upstream commit:** `4c0b700ac5d280ba46695062077f0fe922ce3602`

### What was vendored, and why these

Upstream ships 817 skills across 29 domains. Only a defensive subset matching this repo's real
security surface was taken — Ed25519 corpus signing, Apple code signing, and the CI that holds the
signing secrets. The other domains (malware analysis, forensics, OT/ICS, red teaming) have no
bearing on a SwiftUI study app and were **not** vendored.

| Vendored skill | Maps to in this repo |
| --- | --- |
| `implementing-digital-signatures-with-ed25519` | `ContentKit/CorpusSignatureVerifier.swift`, `scripts/sign-corpus.sh`, `docs/CORPUS-SIGNING.md` |
| `implementing-code-signing-for-artifacts` | manual signing, provisioning profiles, `.ipa` export (`docs/RUNBOOK-ios-signing.md`) |
| `securing-github-actions-workflows` | `.github/workflows/ios.yml` — nine signing secrets, temp keychain, TestFlight upload |
| `performing-ios-app-security-assessment` | whole-app review, including App Group shared storage |
| `testing-mobile-api-authentication` | `PlatformLive`'s REST calls to Firestore / Captain Adel / Moyasar |

`exploiting-insecure-data-storage-in-mobile` was considered and **dropped**: it is attacker-framed,
and the shipping apps run fully offline on the `AppServices` mocks, storing only study progress —
no credentials. `performing-ios-app-security-assessment` covers the same MASVS-STORAGE ground.
### What was intentionally omitted

For each vendored skill, only `SKILL.md`, `references/**`, and the upstream `LICENSE` were copied.
The bundled `scripts/` and `assets/` were **deliberately excluded** to avoid introducing unreviewed
third-party executables — every one of the 817 upstream skills ships a `scripts/` directory. If a
skill's workflow refers to a helper script, consult the pinned upstream commit above rather than
running anything from here.

### Updating from upstream

`.claude/settings.json` registers the upstream repo as a Claude Code marketplace, so
`/plugin install cybersecurity-skills@anthropic-cybersecurity-skills` pulls the full 817-skill set
on demand. It is **registered but not enabled** on purpose: enabling it alongside these vendored
copies would put two skills of each vendored name on the path. Use the plugin to review what
changed upstream, or to reach a skill outside the curated set, then port any delta into the
vendored copy rather than running both.

### Fly GACA guardrail

These skills are **advisory developer tooling**. Where any of them conflicts with this repo's
`CLAUDE.md` conventions, **CLAUDE.md wins** — in particular: the remote-corpus verifier **fails
closed** and must not be relaxed to "fix" a refresh failure; networking and platform SDKs never leak
upstream of `PlatformLive`, so a skill recommending a security SDK does not license adding one to
`CoreModels` or `FeatureUI`; and the App Group id `group.com.FlyGACA` is settled in code and the
portal — do not "harden" it by editing the entitlements.

`performing-ios-app-security-assessment` and `testing-mobile-api-authentication` are written for
penetration-testing engagements. Use them **only against this project's own apps and backends**.
