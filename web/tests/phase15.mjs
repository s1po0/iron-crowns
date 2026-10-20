import { chromium as playwright } from "@playwright/test";
import chromium from "@sparticuz/chromium";
const browser = await playwright.launch({
  executablePath: await chromium.executablePath(),
  args: chromium.args.filter(
    (a) => a !== "--single-process" && a !== "--in-process-gpu",
  ),
  headless: true,
});
const errors = [];
const page = await browser.newPage({
  viewport: { width: 390, height: 844 },
  hasTouch: true,
});
page.on("pageerror", (e) => errors.push(e.message));
await page.goto("http://127.0.0.1:5173");
const old = await page.evaluate(async () => {
  const { newGame } = await import("/src/game/engine/simulation.ts");
  const s = newGame("پاشەکەوتی کۆن");
  delete s.schemaVersion;
  delete s.generatorVersion;
  delete s.worldSeed;
  delete s.explored;
  delete s.path;
  s.hero = { x: 300, y: 370 };
  s.destination = { x: 690, y: 430 };
  s.enemies = [
    { id: 0, x: 500, y: 350, strength: 48, alive: true },
    { id: 1, x: 900, y: 700, strength: 75, alive: false },
    { id: 2, x: 1110, y: 250, strength: 95, alive: true },
  ];
  s.resources.gold = 1234;
  s.level = 4;
  return s;
});
await page.addInitScript(
  (s) => localStorage.setItem("iron-web-v1-guest", JSON.stringify(s)),
  old,
);
await page.reload();
await page.getByText(/پاشەکەوتەکەت نوێ کرایەوە/).waitFor();
await page.getByRole("button", { name: "بەردەوام بە", exact: true }).click();
const saved = await page.evaluate(() =>
  JSON.parse(localStorage.getItem("iron-web-v1-guest")),
);
if (
  saved.schemaVersion !== 3 ||
  saved.resources.gold !== 1234 ||
  saved.level !== 4 ||
  saved.destination !== null
)
  throw Error("Legacy browser migration failed");
const backup = await page.evaluate(() =>
  JSON.parse(localStorage.getItem("iron-web-v1-guest-pre-schema3")),
);
if (backup.schemaVersion !== undefined)
  throw Error("Original legacy backup missing");
await page.getByRole("button", { name: "داخستن", exact: true }).click();
const map = page.locator(".map-canvas > canvas").first();
await map.scrollIntoViewIfNeeded();
const box = await map.boundingBox();
const cdp = await page.context().newCDPSession(page);
const x = box.x + box.width * 0.5,
  y = box.y + Math.min(180, box.height * 0.5);
await cdp.send("Input.dispatchTouchEvent", {
  type: "touchStart",
  touchPoints: [
    { x: x - 30, y, id: 1 },
    { x: x + 30, y, id: 2 },
  ],
});
await cdp.send("Input.dispatchTouchEvent", {
  type: "touchMove",
  touchPoints: [
    { x: x - 60, y, id: 1 },
    { x: x + 60, y, id: 2 },
  ],
});
await cdp.send("Input.dispatchTouchEvent", {
  type: "touchEnd",
  touchPoints: [],
});
await page.getByRole("button", { name: "شوێنی من", exact: true }).click();
await page.locator(".world-minimap").click({ position: { x: 50, y: 50 } });
await page.getByRole("button", { name: "شوێنی من", exact: true }).click();
await page.evaluate(async () => {
  const { getWorld } = await import("/src/game/engine/worldgen.ts");
  const s = JSON.parse(localStorage.getItem("iron-web-v1-guest"));
  const w = getWorld(s.worldSeed);
  if (w.settlements.length !== 30 || w.tiles.length !== 16384)
    throw Error("Incorrect procedural map");
});
await page.screenshot({
  path: "test-results/phase15-touch.png",
  fullPage: true,
});
const bad = await browser.newPage({ viewport: { width: 390, height: 844 } });
bad.on("pageerror", (e) => errors.push(e.message));
await bad.addInitScript(() =>
  localStorage.setItem(
    "iron-web-v1-guest",
    JSON.stringify({ schemaVersion: 999, marker: "preserve me" }),
  ),
);
await bad.goto("http://127.0.0.1:5173");
await bad.getByText(/ئەم پاشەکەوتە ناگونجێت/).waitFor();
if (await bad.getByRole("button", { name: "بەردەوام بە", exact: true }).count())
  throw Error("Continue shown for invalid save");
const before = await bad.evaluate(() =>
  JSON.parse(localStorage.getItem("iron-web-v1-guest")),
);
if (before.schemaVersion !== 999)
  throw Error("Corrupt save overwritten without consent");
await bad.getByRole("button", { name: "گەشتێکی نوێ", exact: true }).click();
const recovered = await bad.evaluate(() => ({
  state: JSON.parse(localStorage.getItem("iron-web-v1-guest")),
  backup: JSON.parse(localStorage.getItem("iron-web-v1-guest-pre-schema3")),
}));
if (
  recovered.state.schemaVersion !== 3 ||
  recovered.backup.marker !== "preserve me"
)
  throw Error("New Game recovery/backup failed");
console.log(
  JSON.stringify({
    errors,
    legacyMigration: true,
    originalBackup: true,
    touchPinch: true,
    minimap: true,
    futureSchemaRecovery: true,
  }),
);
await browser.close();
if (errors.length) process.exit(1);
