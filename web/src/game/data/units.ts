export const units = {
  peasant: { cost: 12, upkeep: 1, strength: 2 },
  spearman: { cost: 30, upkeep: 2, strength: 5 },
  archer: { cost: 40, upkeep: 2, strength: 6 },
  swordsman: { cost: 65, upkeep: 3, strength: 9 },
  cavalry: { cost: 110, upkeep: 5, strength: 15 },
} as const;
export type Unit = keyof typeof units;
