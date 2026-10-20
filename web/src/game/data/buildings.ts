export type Resources = {
  wood: number;
  stone: number;
  food: number;
  gold: number;
};
export const buildings = {
  keep: {
    wood: 80,
    stone: 100,
    gold: 120,
    production: { gold: 12 },
    height: 2.6,
    color: "#b0a28a",
  },
  woodcutter: {
    wood: 20,
    stone: 5,
    gold: 15,
    production: { wood: 12 },
    height: 0.8,
    color: "#977453",
  },
  quarry: {
    wood: 25,
    stone: 0,
    gold: 20,
    production: { stone: 10 },
    height: 0.6,
    color: "#8d9690",
  },
  farm: {
    wood: 15,
    stone: 0,
    gold: 10,
    production: { food: 18 },
    height: 0.3,
    color: "#a49650",
  },
  granary: {
    wood: 35,
    stone: 10,
    gold: 25,
    production: { food: 4 },
    height: 1.2,
    color: "#b29560",
  },
  stockpile: {
    wood: 20,
    stone: 10,
    gold: 10,
    production: { wood: 3, stone: 3 },
    height: 0.5,
    color: "#88715b",
  },
  barracks: {
    wood: 45,
    stone: 30,
    gold: 50,
    production: {},
    height: 1.3,
    color: "#9e8a71",
  },
  wall: {
    wood: 0,
    stone: 8,
    gold: 2,
    production: {},
    height: 1.2,
    color: "#929c96",
  },
  tower: {
    wood: 10,
    stone: 25,
    gold: 15,
    production: {},
    height: 2.1,
    color: "#a5aaa0",
  },
  gate: {
    wood: 20,
    stone: 20,
    gold: 20,
    production: {},
    height: 1.7,
    color: "#a49479",
  },
};
export type Building = keyof typeof buildings;
export const GRID = 12;
