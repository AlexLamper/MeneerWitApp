import puppeteer from 'puppeteer-core';

const CHROME = 'C:\\Program Files\\Google\\Chrome\\Application\\chrome.exe';
const BASE = 'http://localhost:8099/index.html';

// 360x640 logical @ DSF 3 => 1080x1920 physical (9:16, >=1080 each side).
const VIEWPORT = { width: 360, height: 640, deviceScaleFactor: 3, isMobile: true, hasTouch: true };

const SHOTS = [
  { name: '1_home',        shot: 'home' },
  { name: '2_card_reveal', shot: 'reveal' },
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

for (const { name, shot } of SHOTS) {
  const page = await browser.newPage();
  await page.setViewport(VIEWPORT);
  await page.goto(`${BASE}?shot=${shot}`, { waitUntil: 'networkidle2', timeout: 60000 });
  // Let Flutter finish first frame + fonts.
  await sleep(3500);
  const out = `C:\\Projects\\MeneerWitApp\\store_screenshots\\${name}.png`;
  await page.screenshot({ path: out, type: 'png' });
  console.log(`saved ${name}.png`);
  await page.close();
}

await browser.close();
console.log('done');
