import { chromium as playwright } from "@playwright/test";
import chromium from "@sparticuz/chromium";
import { mkdir } from "node:fs/promises";
const browser = await playwright.launch({
  executablePath: await chromium.executablePath(),
  args: [
    ...chromium.args.filter(
      (a) => a !== "--single-process" && a !== "--in-process-gpu",
    ),
    "--enable-webgl",
    "--use-gl=angle",
    "--use-angle=swiftshader",
    "--enable-unsafe-swiftshader",
  ],
  headless: true,
});
const page = await browser.newPage({
  viewport: { width: 1440, height: 1000 },
  deviceScaleFactor: 1,
});
page.setDefaultTimeout(60000);
const errors = [];
page.on("pageerror", (e) => errors.push(e.message));
await page.addInitScript(() =>
  localStorage.setItem("iron-quality-guest", "low"),
);
await page.goto("http://127.0.0.1:5173");
await page.waitForTimeout(2000);
await mkdir("test-results", { recursive: true });
await page.screenshot({ path: "test-results/map-desktop.png", fullPage: true });
await page.getByRole("button", { name: "گەشتێکی نوێ", exact: true }).click();
await page.getByRole("button", { name: "داخستن", exact: true }).click();
await page.getByRole("link", { name: "بازاڕ", exact: true }).first().click();
await page.getByRole("button", { name: /کڕین/ }).first().click();
await page.getByRole("link", { name: "سوپاکەم", exact: true }).first().click();
await page
  .getByRole("button", { name: /دامەزراندن/ })
  .first()
  .click();
await page.getByRole("link", { name: "قەڵاکەم", exact: true }).first().click();
await page.waitForTimeout(5000);
await page.screenshot({
  path: "test-results/castle-desktop.png",
  fullPage: true,
});
const ground = await page.locator(".castle-viewport canvas").boundingBox();
await page.mouse.click(
  ground.x + ground.width * 0.54,
  ground.y + ground.height * 0.62,
);
await page.getByRole("button", { name: "بنیاتی بنێ", exact: true }).click();
await page
  .getByRole("button", { name: "تێپەڕاندنی یەک ڕۆژ", exact: true })
  .click();
for (const name of ["مامناوەند", "بەرز", "نزم"]) {
  await page.getByRole("button", { name: "ڕێکخستنەکان", exact: true }).click();
  await page
    .getByRole("dialog", { name: "ڕێکخستنەکان" })
    .getByRole("button", { name, exact: true })
    .click();
  await page.getByRole("button", { name: "داخستن", exact: true }).click();
  await page.waitForTimeout(1000);
  if (name === "بەرز")
    await page.screenshot({
      path: "test-results/castle-high.png",
      fullPage: true,
    });
}
await page
  .getByRole("link", { name: "نەخشەی جیهان", exact: true })
  .first()
  .click();
await page.screenshot({ path: "test-results/map-playing.png", fullPage: true });
const local = await page.evaluate(() =>
  JSON.parse(localStorage.getItem("iron-web-v1-guest")),
);
if (
  local.day !== 2 ||
  local.party.peasant !== 9 ||
  local.cargo.grain !== 1 ||
  local.buildings.length !== 4
)
  throw Error("Economy actions not persisted");
await page.setViewportSize({ width: 390, height: 844 });
await page.screenshot({ path: "test-results/map-mobile.png", fullPage: true });
const overflow = await page.evaluate(
  () => document.documentElement.scrollWidth > innerWidth,
);
if (overflow) throw Error("Mobile horizontal overflow");
await page.reload();
await page.waitForTimeout(1000);
await page.getByRole("button", { name: "بەردەوام بە", exact: true }).click();
// Reproducible encounter fixture, still resolved through the normal UI/timer.
await page.addInitScript(() => {
  const s = JSON.parse(localStorage.getItem("iron-web-v1-guest"));
  s.destination = null;
  s.path = [];
  s.battle = 0;
  s.party.cavalry = 10;
  localStorage.setItem("iron-web-v1-guest", JSON.stringify(s));
});
await page.reload();
await page.waitForTimeout(1000);
await page.getByRole("button", { name: "بەردەوام بە", exact: true }).click();
await page
  .getByRole("button", { name: "گەڕانەوە بۆ نەخشە", exact: true })
  .waitFor({ timeout: 15000 });
await page.screenshot({
  path: "test-results/battle-mobile.png",
  fullPage: true,
});
await page
  .getByRole("button", { name: "گەڕانەوە بۆ نەخشە", exact: true })
  .click();
const resolved = await page.evaluate(() =>
  JSON.parse(localStorage.getItem("iron-web-v1-guest")),
);
if (resolved.victories !== 1 || resolved.result !== null)
  throw Error("Battle did not resolve/persist once");
console.log(
  JSON.stringify({
    errors,
    local: {
      day: local.day,
      peasant: local.party.peasant,
      grain: local.cargo.grain,
    },
    mobileOverflow: overflow,
  }),
);
await browser.close();
if (errors.length) process.exit(1);
