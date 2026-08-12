# Third-Party Notices — vendored Claude Code skills

This directory contains skills vendored from third-party, community-maintained sources. They are
developer tooling for Claude Code only; they are not part of any shipped product and are never
served to end users.

## diagram-design

- **Project:** diagram-design — "editorial diagrams your designer won't hate"
- **Author:** Cathryn Lavery (@cathrynlavery)
- **Source:** https://github.com/cathrynlavery/diagram-design
- **License:** MIT (upstream `LICENSE` retained at `.claude/skills/diagram-design/LICENSE`)
- **Pinned upstream commit:** `4da4dfb80b1f3d2f11678726b0db58c33c1d7e9d` (v2.2.0)

### What was vendored

The whole skill — `SKILL.md`, all 30 `references/`, `assets/` (4 templates + 94 worked examples +
the 55-icon sheet), and `scripts/` — plus the three slash commands (`/export-diagram`,
`/import-drawio`, `/import-mermaid`) at `.claude/commands/`. The commands resolve the skill through
`../skills/diagram-design/…`, which keeps working because `commands/` and `skills/` stay siblings
under `.claude/`.

Not vendored: the upstream `.claude-plugin/` and `.codex-plugin/` manifests (this is a vendored
skill, not an installed plugin), `docs/screenshots/`, the repo-root `scripts/` test + lint harness,
and `scripts/fixtures/` (referenced by two reference docs only to say which sample file a worked
example was generated from — not needed at runtime).

### The `scripts/` exception, and why it was made

The existing convention in this file is that upstream `scripts/` are **excluded** to avoid
introducing unreviewed third-party executables. That exclusion is **deliberately widened here**,
because `references/import-drawio.md` and `references/import-mermaid.md` both invoke these two
scripts directly and the commands explicitly forbid reading a `.drawio` file without them —
dropping them would ship two visibly broken commands.

They were reviewed before vendoring (2,141 lines across two files):

- **Imports are stdlib only** — `argparse`, `base64`, `zlib`, `struct`, `re`, `json`, `html`,
  `dataclasses`, `pathlib`, `typing`, `xml.etree.ElementTree`, and `urllib.parse.unquote`
  (string decoding, *not* a network call).
- **No** `subprocess`, `os.system`, `os.popen`, `eval`, `exec`, `__import__`, `pickle`, or socket /
  HTTP client of any kind. No writes outside an explicit `--out` path.
- Both are pure parsers: they decode a diagram file to a normalized JSON structure on stdout. The
  module docstring's own claim — *"this script never makes a design decision"* — matches the code.

One residual note: they parse untrusted XML via `xml.etree.ElementTree`. Modern CPython does not
resolve external entities there, so this is not an XXE vector, but a hostile `.drawio` could still
be a decompression or deeply-nested-input hazard. Treat `.drawio` files from outside the org the way
you'd treat any untrusted input.

### Brand skin — this is a local modification

Upstream ships a neutral editorial skin (white-smoke paper, jet-black ink, atomic-tangerine accent,
Instrument Serif / Geist / Geist Mono) and `SKILL.md` §0 is a first-run gate that refuses to emit
default-skinned diagrams into a branded project. That gate is **pre-satisfied**, so the skill is
usable on first run without an onboarding detour. Two files carry the delta:

1. **`references/style-guide.md`** — the declared single source of truth for tokens. Retokenized to
   the **Falcon palette**: ivory paper, falcon-night ink,
   `--falcon-teal` as `accent` (the brand primary, so a diagram reads as Fly GACA at a glance), and
   `--falcon-gold` as `link` (the heritage accent the brand reserves for sparing use, which suits
   external/API arrows). Canonical source is `src/styles/tokens.css` in the Fly GACA app; if that
   file changes, mirror it here.
2. **`assets/template.html`, `template-dark.html`, `template-full.html`** — the scaffolds the skill
   copies to start a diagram. Their `:root` custom properties *and* the literal hex values inside
   their SVG bodies were both retokenized; `template-terminal.html` keeps its fixed terminal palette
   (the style guide states that skin is opt-in and unaffected by brand onboarding) but follows the
   font change.

**Typography was changed for a correctness reason, not taste.** Upstream's display and sans faces
(Instrument Serif, Geist) have **no Arabic coverage**. Every Fly GACA surface is bilingual EN/AR, so
an Arabic node label would fall back mid-diagram or render as tofu. The display face is now
**Cairo** (already the brand's Arabic/heading face), sans is **Inter**, mono is **JetBrains Mono**.
This knowingly overrides upstream's *"Never JetBrains Mono as a blanket 'dev' font"* rule — here it
is not a generic dev default, it is the declared brand mono. The intent behind that rule (mono is
for technical content only) is preserved in full.

**The 94 `assets/example-*.html` files were deliberately left byte-identical to upstream.** They are
reference for *layout and structure*, which is what the `type-*.md` docs cite them for — not colour.
Keeping them pristine means a future upstream re-sync is a clean diff, with our delta confined to
the style guide and the four templates.

### Updating from upstream

`.claude/settings.json` registers the upstream repo as a Claude Code marketplace, so
`/plugin install diagram-design@diagram-design` pulls the latest version. It is **registered but not
enabled** on purpose: enabling it alongside the vendored copy puts two skills named
`diagram-design` on the path. Use the plugin to review what changed upstream, then port the delta
into the vendored copy — re-applying the brand skin above — rather than running both.

### Fly GACA iOS guardrail

Diagrams are **documentation artifacts** for `apple/ARCHITECTURE.md`, the `docs/RUNBOOK-ios-*` set,
and design reviews. Nothing here enters `FlyGACAKit` or any app target, so the dependency rules that
matter in this repo are untouched — the package still has zero external dependencies, and
`swift build` / `swift test` are unaffected.

The palette mirrors `FlyGACAKit/Sources/FeatureUI/Theme.swift`. That file is the authority for
in-app colour; if the two ever disagree, `Theme.swift` wins and the style guide here is corrected.
