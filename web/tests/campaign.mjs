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
try {
  const page = await browser.newPage({
    viewport: { width: 1440, height: 1000 },
  });
  const errors = [];
  page.on("pageerror", (e) => errors.push(e.message));
  await page.addInitScript(() => {
    window.__localTones = 0;
    const original = AudioContext.prototype.createOscillator;
    AudioContext.prototype.createOscillator = function () {
      window.__localTones++;
      return original.call(this);
    };
  });
  await page.goto("http://127.0.0.1:5173");
  await page.getByRole("button", { name: "گەشتێکی نوێ", exact: true }).click();
  await page.getByRole("button", { name: "داخستن", exact: true }).click();
  await page.locator('a[href="/campaign"]').first().click();
  await page
    .getByRole("button", { name: "فێربە", exact: true })
    .first()
    .click();
  await page.getByRole("button", { name: "کڕین 180", exact: true }).click();
  await page.getByRole("button", { name: "بەکاری بهێنە", exact: true }).click();
  await page.getByRole("button", { name: "گفتوگۆ", exact: true }).click();
  await page.getByRole("button", { name: "دەنگۆ", exact: true }).click();
  await page.getByRole("button", { name: "دەربارەی میر", exact: true }).click();
  await page
    .getByRole("button", { name: "پەیمان وەربگرە", exact: true })
    .first()
    .click();
  const read = () =>
    page.evaluate(() => JSON.parse(localStorage.getItem("iron-web-v1-guest")));
  const s = await read();
  if (
    s.schemaVersion !== 3 ||
    s.campaign.skills.leadership !== 1 ||
    s.campaign.equipped.weapon !== "sword" ||
    s.campaign.contracts.length !== 1 ||
    s.campaign.memory.history.length < 4
  )
    throw Error("Campaign UI failed");
  await page
    .getByRole("button", { name: "ڕاگەیاندنی جەنگ", exact: true })
    .first()
    .click();
  if (
    !(await page
      .getByRole("button", { name: "گفتوگۆ", exact: true })
      .isDisabled())
  )
    throw Error("War did not close tavern");
  await page
    .getByRole("button", { name: "ئاشتی بکە: ١٥٠ زێڕ", exact: true })
    .click();
  await page.getByRole("button", { name: "ڕێکخستنەکان", exact: true }).click();
  const settings = page.getByRole("dialog", { name: "ڕێکخستنەکان" });
  await settings.getByRole("button", { name: "سەخت", exact: true }).click();
  await settings
    .getByRole("button", { name: "دەنگ چالاک بکە", exact: true })
    .click();
  await page.waitForTimeout(1500);
  if ((await page.evaluate(() => window.__localTones)) < 1)
    throw Error("Local audio graph produced no notes");
  if (
    (await page.evaluate(() => localStorage.getItem("iron-audio-muted"))) !==
    "false"
  )
    throw Error("Audio toggle failed");
  await settings
    .getByRole("button", { name: "بێدەنگ بکە", exact: true })
    .click();
  await settings.getByRole("button", { name: "داخستن", exact: true }).click();
  await mkdir("test-results", { recursive: true });
  await page.screenshot({
    path: "test-results/campaign-desktop.png",
    fullPage: true,
  });
  await page.setViewportSize({ width: 390, height: 844 });
  await page.screenshot({
    path: "test-results/campaign-mobile.png",
    fullPage: true,
  });
  if (
    await page.evaluate(() => document.documentElement.scrollWidth > innerWidth)
  )
    throw Error("Campaign mobile overflow");
  await page.goto("http://127.0.0.1:5173");
  await page.getByRole("button", { name: "بەردەوام بە", exact: true }).click();
  await page.locator('a[href="/campaign"]').last().click();
  const restored = await read();
  if (
    restored.campaign.difficulty !== "hard" ||
    restored.campaign.contracts.length !== 1
  )
    throw Error("Campaign save roundtrip failed");
  // Arrival fixture: contract completion must still run through the production UI action.
  await page.addInitScript(async () => {
    const s = JSON.parse(localStorage.getItem("iron-web-v1-guest"));
    if (!s?.campaign.contracts.length) return;
    const { getWorld } = await import("/src/game/engine/worldgen.ts");
    const q = s.campaign.contracts[0],
      town = getWorld(s.worldSeed).settlements[q.target];
    s.hero = { x: town.x, y: town.y };
    s.cargo[q.good] = q.amount;
    s.path = [];
    s.destination = null;
    localStorage.setItem("iron-web-v1-guest", JSON.stringify(s));
  });
  await page.goto("http://127.0.0.1:5173");
  await page.getByRole("button", { name: "بەردەوام بە", exact: true }).click();
  await page.locator('a[href="/campaign"]').last().click();
  await page
    .getByRole("button", { name: "پشکنینی پەیمانەکان", exact: true })
    .click();
  if ((await read()).campaign.completed !== 1)
    throw Error("Delivery UI completion failed");
  console.log(
    JSON.stringify({
      errors,
      skills: true,
      equipment: true,
      contracts: true,
      diplomacy: true,
      audioToggle: true,
      difficulty: true,
      saveReload: true,
      mobileOverflow: false,
    }),
  );
  if (errors.length) process.exitCode = 1;
} finally {
  await browser.close();
}
