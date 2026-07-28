# HTML Screenshot Renderer (Mac-free)

A fallback that renders **marketing mockups** of the FlyGACA app screens without
Xcode or a simulator. It recreates each screen as HTML/CSS using the **exact
Falcon palette** (`FlyGACAKit/Sources/FeatureUI/Theme.swift`) and the **real
bundled GACAR content** (`Apps/PPL/Content/*.json`), then rasterizes at native
device resolutions with Playwright + Chromium.

Use this when you need presentable App-Store/website images and don't have a Mac
handy. For pixel-exact captures of the shipping SwiftUI build, use the simulator
path instead (`apple/Scripts/capture-screenshots.sh`).

## What it produces

10 portrait screens × 2 devices + 3 landscape screens × 2 devices = **26 PNGs**:

- iPhone 15 Pro — 1179×2556
- iPad Pro 12.9" — 2048×2732

Output lands in `screenshots/raw/<device>/<orientation>/`.

## Run

```bash
# From repo root. Needs a Chromium/Chrome and playwright-core.
npm i -D playwright-core        # or: npm i (uses the repo's @playwright/test)

# Optional: point at a specific browser binary
export CHROME_PATH=/path/to/chromium   # e.g. $(npx playwright install chromium && ...)

node apple/Scripts/html-render/render.js            # portrait set
node apple/Scripts/html-render/render-landscape.js  # landscape set
```

Environment overrides:

- `CHROME_PATH` — Chromium/Chrome executable. Unset → playwright-core's bundled build.
- `SCREENSHOT_OUT` — output dir (default `screenshots/raw`).

## Files

- `screens.js` — one function per screen, returning a full HTML document. Colors
  are copied verbatim from `Theme.swift`; content is read live from
  `Apps/PPL/Content/{quiz,groundschool}.json`, so screenshots update when the
  content does.
- `render.js` — portrait renderer (all 10 screens, both devices).
- `render-landscape.js` — landscape renderer (quiz + exam screens).

## Keeping it faithful

`screens.js` mirrors the SwiftUI views:

| Screen fn | SwiftUI source |
| --- | --- |
| `home` | `ModuleHomeView.swift` |
| `quizBanks`, `quizQuestion`, `quizAnswered` | `QuizView.swift` + `Components.swift` (`ChoiceRow`) |
| `flashcard` | `FlashcardView.swift` |
| `timedStart`, `timedActive` | `QuizView.swift` + `ExamTimerView.swift` |
| `results` | `Components.swift` (`SessionResultView`, `ResultStat`) |
| `lessons` | `ModuleHomeView.swift` (`LessonListScreen`) |

When a view changes (layout, colors, copy), update the matching function here so
the mockups don't drift from the app.
