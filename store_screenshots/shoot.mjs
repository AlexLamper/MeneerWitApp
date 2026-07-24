// Captures App Store screenshots from the Flutter web build.
//
// Prerequisites:
//   1. flutter build web --release
//   2. Serve build/web on port 8099 (any static file server)
//   3. node store_screenshots/shoot.mjs   (needs puppeteer-core resolvable, and Chrome)
//
// Output PNGs contain an alpha channel; App Store Connect rejects that.
// Flatten them afterwards with store_screenshots/flatten.ps1.
import puppeteer from 'puppeteer-core';

const CHROME = 'C:\\Program Files\\Google\\Chrome\\Application\\chrome.exe';
const BASE = 'http://localhost:8099/index.html';

// 428x926 logical @ DSF 3 => 1284x2778 physical (accepted App Store size).
const VIEWPORT = { width: 428, height: 926, deviceScaleFactor: 3, isMobile: true, hasTouch: true };

// `clicks` are logical viewport coordinates tapped after load (e.g. to get
// past the name-entry step to the card itself).
const SHOTS = [
  { name: '1_home',        shot: 'home' },
  { name: '2_card_reveal', shot: 'reveal', clicks: [[214, 543]] },
  { name: '3_hint',        shot: 'hint' },
  { name: '4_voting',      shot: 'vote' },
  { name: '5_game_over',   shot: 'gameover' },
  { name: '6_leaderboard', shot: 'leaderboard' },
];

const sleep = (ms) => new Promise((r) => setTimeout(r, ms));

const browser = await puppeteer.launch({
  executablePath: CHROME,
  headless: 'new',
  args: ['--no-sandbox', '--hide-scrollbars'],
});

for (const { name, shot, clicks = [] } of SHOTS) {
  const page = await browser.newPage();
  await page.setViewport(VIEWPORT);
  await page.goto(`${BASE}?shot=${shot}`, { waitUntil: 'networkidle2', timeout: 60000 });
  // Let Flutter finish first frame + fonts.
  await sleep(4000);
  for (const [x, y] of clicks) {
    await page.mouse.click(x, y);
    await sleep(1500);
  }
  const out = `C:\\Projects\\MeneerWitApp\\store_screenshots\\appstore\\${name}.png`;
  await page.screenshot({ path: out, type: 'png' });
  console.log(`saved ${name}.png`);
  await page.close();
}

await browser.close();
console.log('done');
