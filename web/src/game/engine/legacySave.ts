import { units, type Unit } from "../data/units";
import { goods, type Good } from "../data/goods";
import {
  buildings,
  GRID,
  type Building,
  type Resources,
} from "../data/buildings";
import { legacySettlements as settlements } from "../data/world";
const WORLD = { width: 1400, height: 1000, daySeconds: 14 };
export type Point = { x: number; y: number };
export type LegacyState = {
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
export function validLegacySave(v: unknown): v is LegacyState {
  try {
    if (!v || typeof v !== "object") return false;
    const s = v as LegacyState,
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
          Object.prototype.hasOwnProperty.call(buildings, b.type) &&
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
