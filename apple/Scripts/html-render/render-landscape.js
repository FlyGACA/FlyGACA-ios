const { chromium } = require('playwright-core');
const fs = require('fs');
const path = require('path');
const { screens } = require('./screens');

const OUT = process.env.SCREENSHOT_OUT
  || path.resolve(__dirname, '../../../screenshots/raw');
const CHROME = process.env.CHROME_PATH || undefined;

// Landscape viewports (swapped W/H). Screens that read well wide: quiz, exam.
const DEVICES = {
  iPhone15Pro: { width: 852, height: 393, scale: 3 },
  iPadPro:     { width: 1366, height: 1024, scale: 2 },
};
const LANDSCAPE_SCREENS = ['03-quiz-question', '04-quiz-answered', '08-timed-exam-timer'];

(async () => {
  const browser = await chromium.launch(CHROME ? { executablePath: CHROME } : {});
  for (const [device, spec] of Object.entries(DEVICES)) {
    const dir = path.join(OUT, device, 'landscape');
    fs.mkdirSync(dir, { recursive: true });
    const ctx = await browser.newContext({
      viewport: { width: spec.width, height: spec.height },
      deviceScaleFactor: spec.scale,
    });
    const page = await ctx.newPage();
    for (const name of LANDSCAPE_SCREENS) {
      await page.setContent(screens[name](), { waitUntil: 'networkidle' });
      const file = path.join(dir, `${name}-landscape.png`);
      await page.screenshot({ path: file });
      console.log(`  ✓ ${device}/landscape/${name}-landscape.png`);
    }
    await ctx.close();
  }
  await browser.close();
  console.log('\nDone.');
})().catch(e => { console.error(e); process.exit(1); });
