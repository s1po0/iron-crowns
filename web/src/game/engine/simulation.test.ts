import { describe, it, expect } from "vitest";
import {
  newGame,
  advanceDay,
  trade,
  price,
  recruit,
  build,
  canBuild,
  tick,
  move,
  resolveBattle,
  validSave,
  strength,
  unload,
} from "./simulation";
import { getWorld, center, neighbors, walkable } from "./worldgen";
import { MAP } from "../data/world";
const settlements = getWorld(MAP.defaultSeed).settlements;
describe("phase one economy and strategy", () => {
  it("has three factions with three towns and five villages each", () => {
    for (let f = 0; f < 3; f++) {
      expect(
        settlements.filter((s) => s.faction === f && s.kind === "town"),
      ).toHaveLength(3);
      expect(
        settlements.filter((s) => s.faction === f && s.kind === "village"),
      ).toHaveLength(5);
    }
  });
  it("moves only while traveling and pauses on arrival", () => {
    let s = newGame("test");
    expect(tick(s, 0.1)).toBe(s);
    const target = center(
      neighbors(settlements[0].tile).find((id) =>
        walkable(getWorld(s.worldSeed), id),
      )!,
    );
    s = move(s, target);
    for (let i = 0; i < 20; i++) s = tick(s, 0.1);
    expect(s.destination).toBeNull();
    expect(s.hero.x).toBeCloseTo(target.x);
  });
  it("prices react to demand and spread prevents instant profit", () => {
    let s = newGame("test");
    const original = s.resources.gold,
      initial = price(s, 0, "grain");
    for (let i = 0; i < 10; i++) s = trade(s, 0, "grain", true);
    expect(price(s, 0, "grain")).toBeGreaterThan(initial);
    for (let i = 0; i < 10; i++) s = trade(s, 0, "grain", false);
    expect(s.resources.gold).toBeLessThan(original);
    expect(s.cargo.grain).toBe(0);
  });
  it("rejects remote trades and recruits and insufficient funds", () => {
    const s = newGame("test");
    s.hero = { x: 50, y: 50 };
    expect(trade(s, 0, "wood", true)).toBe(s);
    expect(recruit(s, "cavalry")).toBe(s);
    s.hero = center(settlements[0].tile);
    s.resources.gold = 0;
    expect(recruit(s, "cavalry")).toBe(s);
  });
  it("charges construction once and rejects occupied/outside cells", () => {
    const s = newGame("test"),
      n = build(s, "farm", 2, 2);
    expect(n.resources.wood).toBe(s.resources.wood - 15);
    expect(build(n, "farm", 2, 2)).toBe(n);
    expect(canBuild(s, "farm", -1, 2)).toBe(false);
    expect(canBuild(s, "keep", 1, 1)).toBe(false);
  });
  it("produces resources, charges upkeep and changes popularity", () => {
    const s = newGame("test"),
      n = advanceDay(s);
    expect(n.day).toBe(2);
    expect(n.resources.wood).toBeGreaterThan(s.resources.wood);
    expect(n.resources.food).toBeGreaterThan(s.resources.food);
    const hungry = newGame("test");
    hungry.buildings = [];
    hungry.resources.food = 0;
    hungry.tax = 2;
    expect(advanceDay(hungry).popularity).toBeLessThan(hungry.popularity);
  });
  it("battle resolution is single-shot and stronger troops win", () => {
    const s = newGame("test");
    s.party.cavalry = 20;
    s.battle = 0;
    expect(strength(s)).toBeGreaterThan(s.enemies[0].strength);
    const n = resolveBattle(s);
    expect(n.result?.won).toBe(true);
    expect(n.enemies[0].alive).toBe(false);
    expect(resolveBattle(n)).toBe(n);
    expect(s.battle).toBe(0);
  });
  it("transfers cargo to castle without duplicating goods", () => {
    let s = trade(newGame("test"), 0, "grain", true);
    const food = s.resources.food;
    s = unload(s, "grain");
    expect(s.resources.food).toBe(food + 4);
    expect(s.cargo.grain).toBe(0);
    expect(unload(s, "grain")).toBe(s);
  });
  it("rejects invalid save state", () => {
    expect(validSave(null)).toBe(false);
    expect(validSave({ version: 1 })).toBeFalsy();
    expect(validSave(newGame("test"))).toBe(true);
  });
});
