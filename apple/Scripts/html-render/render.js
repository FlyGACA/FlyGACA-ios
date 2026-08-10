const { chromium } = require('playwright-core');
const fs = require('fs');
const path = require('path');
const { buildScreens } = require('./screens');

const OUT = process.env.SCREENSHOT_OUT
  || path.resolve(__dirname, '../../../screenshots/raw');
// Point at any Chromium/Chrome via CHROME_PATH; otherwise let playwright-core
// resolve its own bundled browser. In this repo's dev container the pre-installed
// build lives at /opt/pw-browsers/chromium.
const CHROME = process.env.CHROME_PATH || undefined;

// The App Store family: one focused product per study module. Screenshots differ
// only by the module's own content + name (shared FeatureUI chrome).
const APPS = [
  { dir: 'ELPT', name: 'Fly GACA ELPT' },
  { dir: 'AIP', name: 'Fly GACA AIP' },
];

// App Store Connect portrait slots → logical viewport + scale = exact pixel size.
//   iphone-6.9 : 430×932 @3 → 1290×2796  (iPhone 15/16 Pro Max)
//   iphone-6.5 : 414×896 @3 → 1242×2688  (iPhone 11 Pro Max / XS Max)
//   ipad-13    : 1024×1366 @2 → 2048×2732 (iPad Pro 12.9")
const SLOTS = {
  'iphone-6.9': { width: 430, height: 932, scale: 3 },
  'iphone-6.5': { width: 414, height: 896, scale: 3 },
  'ipad-13': { width: 1024, height: 1366, scale: 2 },
};

(async () => {
  const browser = await chromium.launch(CHROME ? { executablePath: CHROME } : {});
  for (const app of APPS) {
    const screens = buildScreens(app);
    for (const [slot, spec] of Object.entries(SLOTS)) {
      const dir = path.join(OUT, app.dir, slot);
      fs.mkdirSync(dir, { recursive: true });
      const ctx = await browser.newContext({
        viewport: { width: spec.width, height: spec.height },
        deviceScaleFactor: spec.scale,
      });
      const pg = await ctx.newPage();
      for (const [name, fn] of Object.entries(screens)) {
        await pg.setContent(fn(), { waitUntil: 'networkidle' });
        const file = path.join(dir, `${name}.png`);
        await pg.screenshot({ path: file });
        const kb = (fs.statSync(file).size / 1024).toFixed(0);
        console.log(`  ✓ ${app.dir}/${slot}/${name}.png (${kb} KB)`);
      }
      await ctx.close();
    }
  }
  await browser.close();
  console.log('\nDone.');
})().catch(e => { console.error(e); process.exit(1); });
