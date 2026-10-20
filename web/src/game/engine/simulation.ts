import {
  newCampaign,
  validCampaign,
  gearBonus,
  atWar,
  campaignDay,
  settleContracts,
  checkCampaign,
  type Campaign,
} from "./campaign";
import { pick } from "./content";
import { context } from "./campaign";
import { difficulties, campaignRules } from "../data/progression";
import { units, type Unit } from "../data/units";
import { goods, type Good } from "../data/goods";
import {
  buildings,
  GRID,
  type Building,
  type Resources,
} from "../data/buildings";
import { WORLD, rules, MAP, terrainCost } from "../data/world";
import {
  getWorld,
  center,
  tileAt,
  findPath,
  walkable,
  reveal,
} from "./worldgen";
export type Point = { x: number; y: number };
export type GameState = {
  version: 1;
  schemaVersion: 3;
  campaign: Campaign;
  generatorVersion: 1;
  worldSeed: number;
  explored: string;
  path: number[];
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
    kind: "patrol" | "bandit";
    home: number;
    route: number[];
    think: number;
    patrolStep: number;
    baseStrength: number;
  }[];
  battle: number | null;
  result: { won: boolean; losses: number; loot: number } | null;
  lastBattleDay: number;
  revision: number;
};
export function newGame(
  name: string,
  seed: number = MAP.defaultSeed,
): GameState {
  const world = getWorld(seed),
    settlements = world.settlements,
    hero = center(settlements[0].tile);
  return {
    version: 1,
    schemaVersion: 3,
    campaign: newCampaign(seed >>> 0),
    generatorVersion: 1,
    worldSeed: seed >>> 0,
    explored: reveal("0".repeat(MAP.size * MAP.size), hero),
    path: [],
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
    hero,
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
    enemies: settlements
      .filter(
        (p) => p.kind === "camp" || p.id === 2 || p.id === 10 || p.id === 18,
      )
      .map((p, id) => ({
        id,
        ...center(p.tile),
        strength: 35 + id * 9,
        baseStrength: 35 + id * 9,
        alive: true,
        home: p.id,
        kind: p.kind === "camp" ? "bandit" : "patrol",
        route: [],
        think: 0,
        patrolStep: 0,
      })),
    battle: null,
    result: null,
    lastBattleDay: 0,
    revision: 0,
  };
}
export const count = (s: GameState) =>
  Object.values(s.party).reduce((a, b) => a + b, 0);
export const upkeep = (s: GameState) =>
  Math.floor(
    Object.entries(s.party).reduce(
      (a, [u, n]) => a + n * units[u as Unit].upkeep,
      0,
    ) *
      (1 - s.campaign.skills.leadership * 0.025),
  );
export const strength = (s: GameState) =>
  Object.entries(s.party).reduce(
    (a, [u, n]) => a + n * units[u as Unit].strength,
    0,
  ) *
  (s.buildings.some((b) => b.type === "barracks") ? 1.1 : 1) *
  (1 + s.campaign.skills.combat * 0.03 + gearBonus(s));
export const townAt = (s: GameState) =>
  getWorld(s.worldSeed).settlements.find(
    (p) =>
      p.kind === "town" &&
      !atWar(s, p.faction) &&
      Math.hypot(p.x - s.hero.x, p.y - s.hero.y) < WORLD.arrivalRadius,
  );
export const score = (s: GameState) =>
  Math.floor(
    s.victories * 100 + s.day * 10 + s.buildings.length * 20 + strength(s),
  );
const copy = (s: GameState) => structuredClone(s);
function daily(s: GameState, kind: "travel" | "castle" = "castle") {
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
  campaignDay(s, kind, fed);
}
export function advanceDay(state: GameState) {
  if (state.campaign.end || state.battle !== null || state.result) return state;
  const s = copy(state);
  daily(s);
  checkCampaign(s);
  s.revision++;
  return s;
}
function followRoute(
  point: Point,
  route: number[],
  world: ReturnType<typeof getWorld>,
  speed: number,
  dt: number,
) {
  let budget = dt;
  while (route.length && budget > 0) {
    const next = route[0];
    if (!walkable(world, next)) {
      route.length = 0;
      return;
    }
    const target = center(next),
      dx = target.x - point.x,
      dy = target.y - point.y,
      d = Math.hypot(dx, dy),
      rate = speed / terrainCost[world.tiles[next]],
      step = Math.min(d, rate * budget);
    if (d > 0) {
      point.x += (dx / d) * step;
      point.y += (dy / d) * step;
    }
    budget -= d / rate;
    if (d <= step + 0.001) route.shift();
    else break;
  }
}
function patrols(s: GameState, dt: number) {
  const world = getWorld(s.worldSeed);
  for (const e of s.enemies) {
    if (!e.alive) continue;
    const hostile =
      e.kind === "bandit" || atWar(s, world.settlements[e.home].faction);
    e.think -= dt;
    if (e.think <= 0) {
      e.think = MAP.patrolThink;
      e.strength = Math.round(
        (e.baseStrength * (1 + 0.18 * (s.level - 1)) +
          Math.min(40, s.day * 0.4)) *
          difficulties[s.campaign.difficulty].enemy,
      );
      const chase =
        hostile && Math.hypot(e.x - s.hero.x, e.y - s.hero.y) < MAP.aggro;
      if (chase || !e.route.length) {
        const home = world.settlements[e.home];
        const choices = world.settlements
          .filter((p) => p.id !== home.id)
          .sort(
            (a, b) =>
              Math.hypot(a.x - home.x, a.y - home.y) -
              Math.hypot(b.x - home.x, b.y - home.y),
          );
        const goal = chase
          ? tileAt(s.hero)
          : e.patrolStep++ % 2 === 0
            ? choices[(e.patrolStep + e.id) % 3].tile
            : home.tile;
        e.route = findPath(world, tileAt(e), goal).slice(
          1,
          MAP.maxEnemyRoute + 1,
        );
      }
    }
    followRoute(e, e.route, world, WORLD.enemySpeed, dt);
    if (
      hostile &&
      Math.hypot(s.hero.x - e.x, s.hero.y - e.y) < WORLD.encounterRadius &&
      s.day - s.lastBattleDay >= rules.encounterGraceDays
    ) {
      s.battle = e.id;
      pick("battle", context(s), s.campaign.memory);
      s.destination = null;
      s.path = [];
      break;
    }
  }
}
export function tick(state: GameState, dt: number): GameState {
  if (
    state.campaign.end ||
    !state.destination ||
    state.battle !== null ||
    state.result ||
    !Number.isFinite(dt) ||
    dt <= 0
  )
    return state;
  const s = copy(state),
    world = getWorld(s.worldSeed);
  dt = Math.min(dt, 0.2);
  followRoute(s.hero, s.path, world, WORLD.heroSpeed, dt);
  if (!s.path.length) s.destination = null;
  s.explored = reveal(s.explored, s.hero);
  s.elapsed += dt;
  while (s.elapsed >= WORLD.daySeconds) {
    s.elapsed -= WORLD.daySeconds;
    daily(s, "travel");
  }
  settleContracts(s);
  if (!s.campaign.end) patrols(s, dt);
  checkCampaign(s);
  s.revision++;
  return s;
}
export function move(state: GameState, p: Point): GameState {
  if (
    state.campaign.end ||
    state.battle !== null ||
    state.result ||
    !Number.isFinite(p.x) ||
    !Number.isFinite(p.y) ||
    p.x < 0 ||
    p.y < 0 ||
    p.x >= WORLD.width ||
    p.y >= WORLD.height
  )
    return state;
  const world = getWorld(state.worldSeed),
    path = findPath(world, tileAt(state.hero), tileAt(p));
  if (!path.length) return state;
  // Include the current tile center when between nodes to keep routes on land.
  return {
    ...state,
    path,
    destination: center(path[path.length - 1]),
    revision: state.revision + 1,
  };
}
export function price(s: GameState, id: number, g: Good, buy = true) {
  return Math.max(
    1,
    Math.round(
      goods[g].price *
        (0.65 + 40 / (s.supplies[id]?.[g] + 20)) *
        (buy
          ? 1 - s.campaign.skills.trade * 0.005
          : 0.8 + s.campaign.skills.trade * 0.004),
    ),
  );
}
export function trade(state: GameState, id: number, g: Good, buy: boolean) {
  if (
    state.campaign.end ||
    state.result ||
    townAt(state)?.id !== id ||
    state.destination ||
    state.battle !== null
  )
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
  checkCampaign(s);
  s.revision++;
  return s;
}
export function recruit(state: GameState, u: Unit) {
  if (
    state.campaign.end ||
    state.result ||
    !townAt(state) ||
    state.destination ||
    state.battle !== null ||
    state.resources.gold < units[u].cost
  )
    return state;
  const s = copy(state);
  s.resources.gold -= units[u].cost;
  s.party[u]++;
  checkCampaign(s);
  s.revision++;
  return s;
}
export function canBuild(s: GameState, b: Building, x: number, z: number) {
  const cost = buildings[b];
  return (
    !s.campaign.end &&
    s.battle === null &&
    !s.result &&
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
  checkCampaign(s);
  s.revision++;
  return s;
}
export function resolveBattle(state: GameState) {
  if (state.campaign.end || state.battle === null) return state;
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
    const before = s.level;
    s.level = Math.max(s.level, 1 + Math.floor(s.victories / 2));
    s.campaign.points += (s.level - before) * campaignRules.pointsPerLevel;
    if (enemy.kind === "bandit") s.campaign.banditKills++;
    s.resources.gold += loot;
  } else {
    s.campaign.contracts = s.campaign.contracts.filter(
      (q) => q.type !== "escort",
    );
    s.resources.gold = Math.floor(s.resources.gold * 0.75);
    s.hero = center(getWorld(s.worldSeed).settlements[0].tile);
    s.path = [];
    s.destination = null;
  }
  s.result = { won, losses, loot };
  s.lastBattleDay = s.day;
  s.battle = null;
  settleContracts(s);
  checkCampaign(s);
  checkCampaign(s);
  s.revision++;
  return s;
}
function validShape(v: unknown): v is GameState {
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
      s.schemaVersion === 3 &&
      validCampaign(s) &&
      s.generatorVersion === 1 &&
      integer(s.worldSeed, 0, 4294967295) &&
      typeof s.explored === "string" &&
      s.explored.length === MAP.size * MAP.size &&
      /^[01]+$/.test(s.explored) &&
      Array.isArray(s.path) &&
      s.path.length <= MAP.size * MAP.size &&
      s.path.every((id) => integer(id, 0, MAP.size * MAP.size - 1)) &&
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
          Object.prototype.hasOwnProperty.call(buildings, b.type) &&
          integer(b.x, 0, GRID - 1) &&
          integer(b.z, 0, GRID - 1),
      ) &&
      new Set(s.buildings.map((b) => `${b.x}:${b.z}`)).size ===
        s.buildings.length &&
      !!s.supplies &&
      getWorld(s.worldSeed).settlements.every(
        (p) =>
          s.supplies[p.id] &&
          Object.keys(goods).every((k) => integer(s.supplies[p.id][k as Good])),
      ) &&
      Array.isArray(s.enemies) &&
      s.enemies.length === 9 &&
      s.enemies.every(
        (e, i) =>
          e &&
          e.id === i &&
          point(e) &&
          integer(e.strength, 1) &&
          typeof e.alive === "boolean" &&
          integer(e.home, 0, 29) &&
          (e.kind === "patrol" || e.kind === "bandit") &&
          integer(e.baseStrength, 1) &&
          Number.isFinite(e.think) &&
          integer(e.patrolStep) &&
          Array.isArray(e.route) &&
          e.route.length <= MAP.maxEnemyRoute &&
          e.route.every((id) => integer(id, 0, MAP.size * MAP.size - 1)),
      ) &&
      (s.battle === null || integer(s.battle, 0, 8)) &&
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
  if (
    state.campaign.end ||
    state.battle !== null ||
    state.result ||
    !("resource" in good) ||
    state.cargo[g] <= 0
  )
    return state;
  const s = copy(state);
  s.cargo[g]--;
  s.resources[good.resource] += good.yield;
  checkCampaign(s);
  s.revision++;
  return s;
}

export function validSave(v: unknown): v is GameState {
  if (!validShape(v)) return false;
  const w = getWorld(v.worldSeed);
  const validRoute = (from: Point, path: number[]) => {
    let prev = tileAt(from);
    for (const id of path) {
      if (!walkable(w, id)) return false;
      const d =
        Math.abs((id % MAP.size) - (prev % MAP.size)) +
        Math.abs(Math.floor(id / MAP.size) - Math.floor(prev / MAP.size));
      if (d > 1) return false;
      prev = id;
    }
    return true;
  };
  return (
    walkable(w, tileAt(v.hero)) &&
    validRoute(v.hero, v.path) &&
    v.enemies.every((e) => walkable(w, tileAt(e)) && validRoute(e, e.route)) &&
    (v.destination === null
      ? v.path.length === 0
      : v.path.length > 0 &&
        tileAt(v.destination) === v.path[v.path.length - 1]) &&
    (v.battle === null || v.enemies[v.battle].alive)
  );
}
