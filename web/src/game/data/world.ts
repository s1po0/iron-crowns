export const WORLD = {
  width: 1400,
  height: 1000,
  heroSpeed: 62,
  daySeconds: 14,
  encounterRadius: 28,
  arrivalRadius: 40,
  enemySpeed: 14,
};
export const factions = [
  { id: 0, color: "#739d8c", at: [290, 300] },
  { id: 1, color: "#c9a56b", at: [720, 510] },
  { id: 2, color: "#b67f73", at: [1100, 420] },
];
export const settlements = [
  { x: 300, y: 370 },
  { x: 180, y: 570 },
  { x: 190, y: 280 },
  { x: 410, y: 490 },
  { x: 320, y: 680 },
  { x: 690, y: 430 },
  { x: 770, y: 700 },
  { x: 550, y: 540 },
  { x: 620, y: 760 },
  { x: 820, y: 330 },
  { x: 1070, y: 390 },
  { x: 1140, y: 650 },
  { x: 980, y: 240 },
  { x: 1000, y: 570 },
  { x: 1230, y: 460 },
].map((p, i) => ({
  ...p,
  id: i,
  faction: Math.floor(i / 5),
  kind: i % 5 < 2 ? "town" : "village",
}));
export const rules = {
  startingGold: 650,
  startingWood: 180,
  startingStone: 140,
  startingFood: 100,
  foodPerTroop: 0.25,
  baseFood: 3,
  baseTax: 8,
  aleCost: 3,
  encounterGraceDays: 1,
  battleSeconds: 6,
  gridCapacity: 144,
  autosaveMs: 60000,
};
export const qualitySettings = {
  low: { fps: 24, dpr: 1, workers: 6, trees: 50 },
  medium: { fps: 30, dpr: 1.4, workers: 12, trees: 90 },
  high: { fps: 45, dpr: 1.8, workers: 20, trees: 140 },
};
export type Quality = keyof typeof qualitySettings;
