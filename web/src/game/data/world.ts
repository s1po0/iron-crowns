export const WORLD = {
  width: 3072,
  height: 3072,
  heroSpeed: 105,
  daySeconds: 14,
  encounterRadius: 28,
  arrivalRadius: 20,
  enemySpeed: 30,
};
export const factions = [
  { id: 0, color: "#739d8c", at: [290, 300] },
  { id: 1, color: "#c9a56b", at: [720, 510] },
  { id: 2, color: "#b67f73", at: [1100, 420] },
];
export const legacySettlements = [
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

export const MAP = {
  size: 128,
  tile: 24,
  chunk: 16,
  defaultSeed: 19071020,
  generatorVersion: 1,
  spacing: 8,
  vision: 8,
  townsPerFaction: 3,
  villagesPerFaction: 5,
  camps: 6,
  patrolThink: 1.8,
  aggro: 240,
  maxEnemyRoute: 256,
} as const;
export const TERRAIN = {
  water: 0,
  plains: 1,
  forest: 2,
  hills: 3,
  mountains: 4,
  river: 5,
  road: 6,
} as const;
export const terrainCost = [Infinity, 1, 1.8, 2.4, 5.5, Infinity, 0.6];
export const terrainColors = [
  "#294a59",
  "#839071",
  "#536d56",
  "#8b8668",
  "#92958a",
  "#416c7c",
  "#b29d73",
];
export const renderBudget = {
  low: { chunks: 20, particles: 10, army: 18 },
  medium: { chunks: 36, particles: 24, army: 30 },
  high: { chunks: 64, particles: 40, army: 48 },
};
