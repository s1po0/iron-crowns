import { units, type Unit } from "../data/units";
import { goods, type Good } from "../data/goods";
import {
  buildings,
  GRID,
  type Building,
  type Resources,
} from "../data/buildings";
import { WORLD, rules, settlements } from "../data/world";
export type Point = { x: number; y: number };
export type GameState = {
  version: 1;
  name: string;
  level: number;
  resources: Resources;
  day: number;
  elapsed: number;
  hero: Point;
  destination: Point | null;
  party: Record<Unit, number>;
  cargo: Record<Good, number>;
  supplies: Record<number, Record<Good, number>>;
  buildings: { type: Building; x: number; z: number }[];
  popularity: number;
  tax: number;
  ale: boolean;
  victories: number;
  enemies: {
    id: number;
    x: number;
    y: number;
    strength: number;
    alive: boolean;
  }[];
  battle: number | null;
  result: { won: boolean; losses: number; loot: number } | null;
  lastBattleDay: number;
  revision: number;
};
export function newGame(name: string): GameState {
  return {
    version: 1,
    name,
    level: 1,
    resources: {
      gold: rules.startingGold,
      wood: rules.startingWood,
      stone: rules.startingStone,
      food: rules.startingFood,
    },
    day: 1,
    elapsed: 0,
    hero: { x: 300, y: 370 },
    destination: null,
    party: { peasant: 8, spearman: 3, archer: 2, swordsman: 0, cavalry: 0 },
    cargo: { grain: 0, wood: 0, iron: 0, cloth: 0 },
    supplies: Object.fromEntries(
      settlements.map((s) => [
        s.id,
        { grain: 35 + s.id * 3, wood: 45, iron: 25, cloth: 20 },
      ]),
    ),
    buildings: [
      { type: "keep", x: 5, z: 5 },
      { type: "farm", x: 3, z: 7 },
      { type: "woodcutter", x: 8, z: 3 },
    ],
    popularity: 70,
    tax: 1,
    ale: false,
    victories: 0,
    enemies: [
      { id: 0, x: 500, y: 350, strength: 45, alive: true },
      { id: 1, x: 900, y: 610, strength: 90, alive: true },
      { id: 2, x: 1100, y: 800, strength: 140, alive: true },
    ],
    battle: null,
    result: null,
    lastBattleDay: 0,
    revision: 0,
  };
}
export const count = (s: GameState) =>
  Object.values(s.party).reduce((a, b) => a + b, 0);
export const upkeep = (s: GameState) =>
  Object.entries(s.party).reduce(
    (a, [u, n]) => a + n * units[u as Unit].upkeep,
    0,
  );
export const strength = (s: GameState) =>
  Object.entries(s.party).reduce(
    (a, [u, n]) => a + n * units[u as Unit].strength,
    0,
  ) * (s.buildings.some((b) => b.type === "barracks") ? 1.1 : 1);
export const townAt = (s: GameState) =>
  settlements.find(
    (p) =>
      p.kind === "town" &&
      Math.hypot(p.x - s.hero.x, p.y - s.hero.y) < WORLD.arrivalRadius,
  );
export const score = (s: GameState) =>
  Math.floor(
    s.victories * 100 + s.day * 10 + s.buildings.length * 20 + strength(s),
  );
const copy = (s: GameState) => structuredClone(s);
function daily(s: GameState) {
  s.day++;
  const r = s.resources;
  for (const b of s.buildings)
    for (const [key, val] of Object.entries(buildings[b.type].production))
      r[key as keyof Resources] += val;
  const demand = Math.ceil(count(s) * rules.foodPerTroop + rules.baseFood);
  const fed = r.food >= demand;
  r.food = Math.max(0, r.food - demand);
  const ale = s.ale && r.gold >= rules.aleCost;
  if (ale) r.gold -= rules.aleCost;
  s.popularity = Math.max(
    0,
    Math.min(
      100,
      s.popularity +
        (fed ? 3 : -12) +
        (ale ? 4 : 0) -
        (s.tax === 2 ? 7 : s.tax === 1 ? 2 : 0),
    ),
  );
  r.gold = Math.max(
    0,
    r.gold +
      Math.floor((rules.baseTax * (s.tax + 1) * s.popularity) / 100) -
      upkeep(s),
  );
  if (r.gold === 0 && count(s) > 1) {
    for (const u of Object.keys(units) as Unit[])
      if (s.party[u] > 0) {
        s.party[u]--;
        break;
      }
  }
  for (const stock of Object.values(s.supplies))
    for (const g of Object.keys(goods) as Good[])
      stock[g] = Math.min(120, stock[g] + 2);
}
export function advanceDay(state: GameState) {
  if (state.battle !== null || state.result) return state;
  const s = copy(state);
  daily(s);
  s.revision++;
  return s;
}
export function tick(state: GameState, dt: number): GameState {
  if (!state.destination || state.battle !== null || state.result) return state;
  const s = copy(state);
  dt = Math.min(dt, 0.2);
  const dx = s.destination!.x - s.hero.x,
    dy = s.destination!.y - s.hero.y,
    d = Math.hypot(dx, dy),
    step = Math.min(d, WORLD.heroSpeed * dt);
  if (d > 0) {
    s.hero.x += (dx / d) * step;
    s.hero.y += (dy / d) * step;
  }
  if (d <= step + 0.1) s.destination = null;
  s.elapsed += dt;
  while (s.elapsed >= WORLD.daySeconds) {
    s.elapsed -= WORLD.daySeconds;
    daily(s);
  }
  for (const e of s.enemies) {
    if (!e.alive) continue;
    const d = Math.hypot(s.hero.x - e.x, s.hero.y - e.y);
    if (d < 180 && d > 0) {
      e.x += ((s.hero.x - e.x) / d) * WORLD.enemySpeed * dt;
      e.y += ((s.hero.y - e.y) / d) * WORLD.enemySpeed * dt;
    }
    if (
      d < WORLD.encounterRadius &&
      s.day - s.lastBattleDay >= rules.encounterGraceDays
    ) {
      s.battle = e.id;
      s.destination = null;
      break;
    }
  }
  s.revision++;
  return s;
}
export function move(state: GameState, p: Point) {
  if (state.battle !== null || state.result) return state;
  return {
    ...state,
    destination: {
      x: Math.max(60, Math.min(WORLD.width - 60, p.x)),
      y: Math.max(90, Math.min(WORLD.height - 80, p.y)),
    },
    revision: state.revision + 1,
  };
}
export function price(s: GameState, id: number, g: Good, buy = true) {
  return Math.max(
    1,
    Math.round(
      goods[g].price *
        (0.65 + 40 / (s.supplies[id]?.[g] + 20)) *
        (buy ? 1 : 0.8),
    ),
  );
}
export function trade(state: GameState, id: number, g: Good, buy: boolean) {
  if (townAt(state)?.id !== id || state.destination || state.battle !== null)
    return state;
  const s = copy(state),
    p = price(s, id, g, buy);
  if (buy) {
    if (s.resources.gold < p || s.supplies[id][g] < 1) return state;
    s.resources.gold -= p;
    s.cargo[g]++;
    s.supplies[id][g]--;
  } else {
    if (s.cargo[g] < 1) return state;
    s.resources.gold += p;
    s.cargo[g]--;
    s.supplies[id][g]++;
  }
  s.revision++;
  return s;
}
export function recruit(state: GameState, u: Unit) {
  if (
    !townAt(state) ||
    state.destination ||
    state.battle !== null ||
    state.resources.gold < units[u].cost
  )
    return state;
  const s = copy(state);
  s.resources.gold -= units[u].cost;
  s.party[u]++;
  s.revision++;
  return s;
}
export function canBuild(s: GameState, b: Building, x: number, z: number) {
  const cost = buildings[b];
  return (
    Number.isInteger(x) &&
    Number.isInteger(z) &&
    x >= 0 &&
    z >= 0 &&
    x < GRID &&
    z < GRID &&
    !s.buildings.some((v) => v.x === x && v.z === z) &&
    !(b === "keep" && s.buildings.some((v) => v.type === "keep")) &&
    s.resources.gold >= cost.gold &&
    s.resources.wood >= cost.wood &&
    s.resources.stone >= cost.stone
  );
}
export function build(state: GameState, b: Building, x: number, z: number) {
  if (!canBuild(state, b, x, z)) return state;
  const s = copy(state);
  for (const k of ["wood", "stone", "gold"] as const)
    s.resources[k] -= buildings[b][k];
  s.buildings.push({ type: b, x, z });
  s.revision++;
  return s;
}
export function resolveBattle(state: GameState) {
  if (state.battle === null) return state;
  const s = copy(state),
    enemy = s.enemies.find((e) => e.id === s.battle)!;
  const power = strength(s),
    won = power >= enemy.strength;
  const ratio = won
    ? Math.min(0.45, (enemy.strength / Math.max(power, 1)) * 0.35)
    : 0.65;
  let losses = 0;
  for (const u of Object.keys(units) as Unit[]) {
    const lost = Math.min(
      s.party[u],
      Math.floor(s.party[u] * ratio + (s.party[u] > 0 ? 0.35 : 0)),
    );
    s.party[u] -= lost;
    losses += lost;
  }
  const loot = won ? Math.round(enemy.strength * 1.7) : 0;
  if (won) {
    enemy.alive = false;
    s.victories++;
    s.level = 1 + Math.floor(s.victories / 2);
    s.resources.gold += loot;
  } else {
    s.resources.gold = Math.floor(s.resources.gold * 0.75);
    s.hero = { x: 300, y: 370 };
  }
  s.result = { won, losses, loot };
  s.lastBattleDay = s.day;
  s.battle = null;
  s.revision++;
  return s;
}
export function validSave(v: unknown): v is GameState {
  try {
    if (!v || typeof v !== "object") return false;
    const s = v as GameState,
      integer = (n: unknown, min = 0, max = 10000000) =>
        typeof n === "number" && Number.isInteger(n) && n >= min && n <= max;
    const point = (p: Point) =>
      !!p &&
      Number.isFinite(p.x) &&
      Number.isFinite(p.y) &&
      p.x >= 0 &&
      p.x <= WORLD.width &&
      p.y >= 0 &&
      p.y <= WORLD.height;
    return (
      s.version === 1 &&
      typeof s.name === "string" &&
      s.name.length <= 48 &&
      integer(s.level, 1) &&
      integer(s.day, 1) &&
      integer(s.revision) &&
      Number.isFinite(s.elapsed) &&
      s.elapsed >= 0 &&
      s.elapsed < WORLD.daySeconds &&
      point(s.hero) &&
      (s.destination === null || point(s.destination)) &&
      !!s.resources &&
      ["wood", "stone", "food", "gold"].every((k) =>
        integer(s.resources[k as keyof Resources]),
      ) &&
      !!s.party &&
      Object.keys(units).every((k) => integer(s.party[k as Unit])) &&
      !!s.cargo &&
      Object.keys(goods).every((k) => integer(s.cargo[k as Good])) &&
      Array.isArray(s.buildings) &&
      s.buildings.length <= GRID * GRID &&
      s.buildings.every(
        (b) =>
          b &&
          b.type in buildings &&
          integer(b.x, 0, GRID - 1) &&
          integer(b.z, 0, GRID - 1),
      ) &&
      new Set(s.buildings.map((b) => `${b.x}:${b.z}`)).size ===
        s.buildings.length &&
      !!s.supplies &&
      settlements.every(
        (p) =>
          s.supplies[p.id] &&
          Object.keys(goods).every((k) => integer(s.supplies[p.id][k as Good])),
      ) &&
      Array.isArray(s.enemies) &&
      s.enemies.length === 3 &&
      s.enemies.every(
        (e, i) =>
          e &&
          e.id === i &&
          point(e) &&
          integer(e.strength, 1) &&
          typeof e.alive === "boolean",
      ) &&
      (s.battle === null || integer(s.battle, 0, 2)) &&
      (s.result === null ||
        (typeof s.result.won === "boolean" &&
          integer(s.result.losses) &&
          integer(s.result.loot))) &&
      integer(s.popularity, 0, 100) &&
      integer(s.tax, 0, 2) &&
      typeof s.ale === "boolean" &&
      integer(s.victories) &&
      integer(s.lastBattleDay)
    );
  } catch {
    return false;
  }
}

export function unload(state: GameState, g: Good) {
  const good = goods[g];
  if (!("resource" in good) || state.cargo[g] <= 0) return state;
  const s = copy(state);
  s.cargo[g]--;
  s.resources[good.resource] += good.yield;
  s.revision++;
  return s;
}
