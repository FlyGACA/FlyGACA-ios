// App Store screenshot renderer — captioned + reordered (value-prop first).
// Wraps the faithful base screens (screens.js) with marketing caption bands
// (captions.js) and emits the store sequence. The raw renderer (render.js) is
// unchanged; this is the set that ships to the per-app metadata repos.
//
//   node apple/Scripts/html-render/render-store.js                 # en captions
//   CAPTION_LANG=ar node apple/Scripts/html-render/render-store.js # ar/RTL captions
//   CHROME_PATH=/path/to/chrome  SCREENSHOT_OUT=/tmp/out  node …/render-store.js
//
// CAPTION_LANG only changes the caption band; the embedded app screens are the
// same English UI in every locale (the shipping app is English-only).
const { chromium } = require('playwright-core');
const fs = require('fs');
const path = require('path');
const { buildScreens } = require('./screens');
const { compose, captionsFor, rtlFor } = require('./captions');

const OUT = process.env.SCREENSHOT_OUT || path.resolve(__dirname, '../../../screenshots/store');
const CHROME = process.env.CHROME_PATH || undefined;
const LANG = process.env.CAPTION_LANG || 'en';
const RTL = rtlFor(LANG);

const APPS = [
  { dir: 'PPL', name: 'Fly GACA PPL' },
  { dir: 'ELPT', name: 'Fly GACA ELPT' },
  { dir: 'AIP', name: 'Fly GACA AIP' },
  { dir: 'CPL', name: 'Fly GACA CPL' },
  { dir: 'IR', name: 'Fly GACA IR' },
  { dir: 'ATPL', name: 'Fly GACA ATPL' },
];
const SLOTS = {
  'iphone-6.9': { width: 430, height: 932, scale: 3 },
  'iphone-6.5': { width: 414, height: 896, scale: 3 },
  'ipad-13': { width: 1024, height: 1366, scale: 2 },
};

(async () => {
  const browser = await chromium.launch(CHROME ? { executablePath: CHROME } : {});
  for (const app of APPS) {
    const raw = buildScreens(app);
    const plan = captionsFor(app.dir, LANG).filter((s) => !s.optional || raw[s.screen]);
    for (const [slot, spec] of Object.entries(SLOTS)) {
      const dir = path.join(OUT, app.dir, slot);
      fs.mkdirSync(dir, { recursive: true });
      const ctx = await browser.newContext({
        viewport: { width: spec.width, height: spec.height },
        deviceScaleFactor: spec.scale,
      });
      const pg = await ctx.newPage();
      for (const s of plan) {
        const html = compose(raw[s.screen](), s.head, s.sub, spec.width, spec.height, { rtl: RTL });
        await pg.setContent(html, { waitUntil: 'load' });
        const file = path.join(dir, `${s.name}.png`);
        await pg.screenshot({ path: file });
        console.log(`  ✓ ${app.dir}/${slot}/${s.name}.png`);
      }
      await ctx.close();
    }
  }
  await browser.close();
  console.log('\nStore screenshots written under', OUT);
})().catch((e) => { console.error(e); process.exit(1); });
