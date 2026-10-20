import { describe, it, expect } from "vitest";
import {
  getWorld,
  findPath,
  neighbors,
  tileAt,
  walkable,
  reveal,
  center,
} from "./worldgen";
import { MAP, TERRAIN, legacySettlements } from "../data/world";
import { newGame, move, tick, validSave } from "./simulation";
import { migrateSave, parseSave } from "./migrations";
import { type LegacyState, validLegacySave } from "./legacySave";
function legacy() {
  const s = newGame("old");
  const supplies = Object.fromEntries(
    legacySettlements.map((p) => [
      p.id,
      { grain: 30, wood: 40, iron: 15, cloth: 20 },
    ]),
  );
  return {
    version: 1,
    name: s.name,
    level: 4,
    resources: s.resources,
    day: 7,
    elapsed: 2,
    hero: { x: 300, y: 370 },
    destination: { x: 690, y: 430 },
    party: s.party,
    cargo: s.cargo,
    supplies,
    buildings: s.buildings,
    popularity: 62,
    tax: 1,
    ale: true,
    victories: 6,
    enemies: [
      { id: 0, x: 500, y: 350, strength: 48, alive: true },
      { id: 1, x: 900, y: 700, strength: 75, alive: false },
      { id: 2, x: 1110, y: 250, strength: 95, alive: true },
    ],
    battle: null,
    result: null,
    lastBattleDay: 3,
    revision: 120,
  } as LegacyState;
}
describe("seeded campaign", () => {
  it("is reproducible across cache eviction", () => {
    const a = getWorld(17).tiles.slice();
    for (let i = 30; i < 34; i++) getWorld(i);
    expect(getWorld(17).tiles).toEqual(a);
    expect(getWorld(18).tiles).not.toEqual(a);
  });
  it("places thirty spaced, road-connected locations on 32 different seeds", () => {
    for (const seed of [
      MAP.defaultSeed,
      0,
      1,
      4294967295,
      ...Array.from({ length: 28 }, (_, i) => i * 10937 + 97),
    ]) {
      const w = getWorld(seed);
      expect(w.tiles).toHaveLength(16384);
      expect(new Set(w.base).size).toBe(6);
      expect(w.settlements).toHaveLength(30);
      for (let f = 0; f < 3; f++) {
        expect(
          w.settlements.filter((p) => p.faction === f && p.kind === "town"),
        ).toHaveLength(3);
        expect(
          w.settlements.filter((p) => p.faction === f && p.kind === "village"),
        ).toHaveLength(5);
      }
      expect(w.settlements.filter((p) => p.kind === "camp")).toHaveLength(6);
      const roads = {
        tiles: w.tiles.map((v) => (v === TERRAIN.road ? v : TERRAIN.water)),
      };
      for (const a of w.settlements) {
        expect(
          findPath(roads, w.settlements[0].tile, a.tile).length,
        ).toBeGreaterThan(0);
        for (const b of w.settlements)
          if (a !== b)
            expect(
              Math.hypot((a.x - b.x) / 24, (a.y - b.y) / 24),
            ).toBeGreaterThanOrEqual(MAP.spacing);
      }
    }
  }, 20000);
  it("prefers a longer fast road over mountains, rejects water", () => {
    const tiles = new Uint8Array(16384);
    for (let x = 1; x <= 7; x++) {
      tiles[128 + x] = TERRAIN.road;
      tiles[256 + x] = TERRAIN.mountains;
    }
    tiles[257] = tiles[263] = TERRAIN.plains;
    const path = findPath({ tiles }, 257, 263);
    expect(path).toContain(132);
    expect(path).not.toContain(260);
    expect(findPath({ tiles }, 257, 0)).toEqual([]);
    for (let i = 1; i < path.length; i++)
      expect(neighbors(path[i - 1])).toContain(path[i]);
  });
  it("persists fog and terrain-respecting scaled patrol movement", () => {
    let s = newGame("patrol");
    s.level = 5;
    s.campaign.points = 10;
    s.lastBattleDay = 10000;
    const w = getWorld(s.worldSeed),
      destination = w.settlements[15];
    const initial = s.explored,
      enemy = { ...s.enemies[0] };
    s = move(s, destination);
    for (let i = 0; i < 300; i++) s = tick(s, 0.1);
    expect(validSave(s)).toBe(true);
    expect(s.enemies[0].strength).toBeGreaterThan(enemy.strength);
    expect(
      Math.hypot(s.enemies[0].x - enemy.x, s.enemies[0].y - enemy.y),
    ).toBeGreaterThan(0);
    expect(s.explored.split("1").length).toBeGreaterThan(
      initial.split("1").length,
    );
    for (const e of s.enemies) expect(walkable(w, tileAt(e))).toBe(true);
    expect(reveal(s.explored, s.hero)).toBe(s.explored);
    expect(migrateSave(JSON.parse(JSON.stringify(s))).state).toEqual(s);
    const water = w.tiles.findIndex((v) => v === TERRAIN.water);
    expect(move(s, center(water))).toBe(s);
  });
});
describe("schema migration and recovery", () => {
  it("preserves legacy economy/progression/castle/stocks with safe relocation", () => {
    const old = legacy();
    expect(validLegacySave(old)).toBe(true);
    const { state: s, status } = migrateSave(old);
    expect(status).toBe("migrated");
    expect(validSave(s)).toBe(true);
    for (const key of [
      "resources",
      "party",
      "cargo",
      "buildings",
      "level",
      "victories",
      "popularity",
      "tax",
      "ale",
      "day",
    ])
      expect(s![key as keyof typeof s]).toEqual(old[key as keyof LegacyState]);
    expect(s!.supplies[8]).toEqual(old.supplies[5]);
    expect(s!.destination).toBeNull();
    expect(s!.enemies[1].alive).toBe(false);
    expect(old.destination).not.toBeNull();
  });
  it("preserves a pending encounter and result through migration", () => {
    const old = legacy();
    old.battle = 2;
    expect(migrateSave(old).state?.battle).toBe(2);
    old.battle = null;
    old.result = { won: true, losses: 2, loot: 40 };
    expect(migrateSave(old).state?.result).toEqual(old.result);
  });
  it("rejects future schemas/generators, malformed JSON, invalid routes and corrupt structures", () => {
    expect(parseSave("{").status).toBe("unsupported");
    expect(parseSave(null).status).toBe("empty");
    for (const bad of [
      { ...newGame("x"), schemaVersion: 99 },
      { ...newGame("x"), generatorVersion: 99 },
      { ...newGame("x"), path: [-1] },
      { ...newGame("x"), explored: "" },
      { ...legacy(), resources: null },
      { ...newGame("x"), enemies: null },
    ])
      expect(migrateSave(bad).status).toBe("unsupported");
  });
  it("keeps normal saves below the JSONB limit and accepts same-version roundtrips", () => {
    const s = newGame("save");
    expect(JSON.stringify(s).length).toBeLessThan(200000);
    expect(parseSave(JSON.stringify(s)).state).toEqual(s);
  });
});
