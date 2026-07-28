const { chromium } = require('playwright-core');
const fs = require('fs');
const path = require('path');
const { screens } = require('./screens');

const OUT = process.env.SCREENSHOT_OUT
  || path.resolve(__dirname, '../../../screenshots/raw');
// Point at any Chromium/Chrome via CHROME_PATH; otherwise let playwright-core
// resolve its own bundled browser.
const CHROME = process.env.CHROME_PATH || undefined;

// Native logical viewports (deviceScaleFactor gives Retina pixel output).
const DEVICES = {
  iPhone15Pro: { width: 393, height: 852, scale: 3 },   // -> 1179×2556
  iPadPro:     { width: 1024, height: 1366, scale: 2 },  // -> 2048×2732
};

(async () => {
  const browser = await chromium.launch(CHROME ? { executablePath: CHROME } : {});
  for (const [device, spec] of Object.entries(DEVICES)) {
    const dir = path.join(OUT, device, 'portrait');
    fs.mkdirSync(dir, { recursive: true });
    const ctx = await browser.newContext({
      viewport: { width: spec.width, height: spec.height },
      deviceScaleFactor: spec.scale,
    });
    const page = await ctx.newPage();
    for (const [name, fn] of Object.entries(screens)) {
      await page.setContent(fn(), { waitUntil: 'networkidle' });
      const file = path.join(dir, `${name}.png`);
      await page.screenshot({ path: file });
      const px = fs.statSync(file).size;
      console.log(`  ✓ ${device}/portrait/${name}.png (${(px/1024).toFixed(0)} KB)`);
    }
    await ctx.close();
  }
  await browser.close();
  console.log('\nDone.');
})().catch(e => { console.error(e); process.exit(1); });
