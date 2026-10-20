export const effectLimits = {
  gold: [-150, 300],
  food: [-40, 80],
  popularity: [-15, 15],
  troops: [-3, 4],
  relation: [-20, 20],
} as const;
export const difficulties = {
  easy: { enemy: 0.8, event: 0.22 },
  normal: { enemy: 1, event: 0.32 },
  hard: { enemy: 1.25, event: 0.45 },
} as const;
export const skills = ["leadership", "trade", "combat"] as const;
export type Skill = (typeof skills)[number];
export const equipment = {
  sword: { slot: "weapon", price: 180, bonus: 0.08 },
  axe: { slot: "weapon", price: 320, bonus: 0.14 },
  mail: { slot: "armor", price: 240, bonus: 0.1 },
  plate: { slot: "armor", price: 480, bonus: 0.18 },
  banner: { slot: "banner", price: 260, bonus: 0.12 },
} as const;
export type Item = keyof typeof equipment;
export const campaignRules = {
  pointsPerLevel: 2,
  maxSkill: 10,
  peaceCost: 150,
  maxContracts: 3,
  contractDays: 18,
  victoryBattles: 6,
  victoryContracts: 3,
  victoryGold: 2000,
  maxDays: 180,
  starvationDays: 4,
  escortTroops: 5,
} as const;
