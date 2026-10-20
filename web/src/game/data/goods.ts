export const goods = {
  grain: { price: 8, resource: "food", yield: 4 },
  wood: { price: 12, resource: "wood", yield: 1 },
  iron: { price: 24 },
  cloth: { price: 30 },
} as const;
export type Good = keyof typeof goods;
