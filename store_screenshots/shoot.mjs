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

const CHROME = 'C:/Program Files/Google/Chrome/Application/chrome.exe';
const BASE = 'http://localhost:8099/index.html';
const OUT_ROOT = 'C:/Projects/MeneerWitApp/store_screenshots';

const DEVICES = [
  // 428x926 logical @ DSF 3 => 1284x2778 physical (iPhone 6.5"/6.7").
  {
    dir: 'appstore',
    viewport: { width: 428, height: 926, deviceScaleFactor: 3, isMobile: true, hasTouch: true },
  },
  // 1024x1366 logical @ DSF 2 => 2048x2732 physical (iPad Pro 12.9"/13").
  {
    dir: 'appstore_ipad',
    viewport: { width: 1024, height: 1366, deviceScaleFactor: 2, isMobile: true, hasTouch: true },
  },
];

// `clicks` (optional, keyed by device dir) taps a list of points after load, as
// fractions of the viewport, waiting `wait` ms after each. The card reveal
// needs two: "Bekijk kaart" to get past the name-entry step, then the card
// itself to flip it face up (the flip animation runs 700ms). Both sit at a
// different height per device because the form is vertically centered.
const SHOTS = [
  { name: '1_home', shot: 'home' },
  {
    name: '2_card_reveal',
    shot: 'reveal',
    clicks: {
      appstore: [
        { fx: 0.5, fy: 0.602, wait: 1200 }, // "Bekijk kaart"
        { fx: 0.5, fy: 0.468, wait: 1800 }, // flip the card face up
      ],
      appstore_ipad: [
        { fx: 0.5, fy: 0.568, wait: 1200 },
        { fx: 0.5, fy: 0.478, wait: 1800 },
      ],
    },
  },
  { name: '3_hint', shot: 'hint' },
  { name: '4_voting', shot: 'vote' },
  // The winner confetti runs for 5s; wait it out so no stray specks land on
  // the text.
  { name: '5_game_over', shot: 'gameover', settle: 11000 },
  { name: '6_leaderboard', shot: 'leaderboard' },
];

const sleep = (ms) => new Promise((r) => setTimeout(r, ms));

// A fresh browser per device with a single reused page: heavy CanvasKit pages
// exhaust the browser after ~10 page creations otherwise.
for (const { dir, viewport } of DEVICES) {
  const browser = await puppeteer.launch({
    executablePath: CHROME,
    headless: 'new',
    args: ['--no-sandbox', '--hide-scrollbars'],
  });
  const page = await browser.newPage();
  await page.setViewport(viewport);
  for (const { name, shot, clicks, settle } of SHOTS) {
    await page.goto(`${BASE}?shot=${shot}`, { waitUntil: 'networkidle2', timeout: 60000 });
    // Let Flutter finish first frame + fonts.
    await sleep(settle ?? 5000);
    for (const c of (clicks && clicks[dir]) || []) {
      await page.mouse.click(c.fx * viewport.width, c.fy * viewport.height);
      await sleep(c.wait);
    }
    const out = `${OUT_ROOT}/${dir}/${name}.png`;
    await page.screenshot({ path: out, type: 'png' });
    console.log(`saved ${dir}/${name}.png`);
  }
  await browser.close();
}

console.log('done');
