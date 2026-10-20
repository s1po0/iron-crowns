import { newGame, validSave, type GameState } from "./simulation";
import { validLegacySave } from "./legacySave";
import { MAP, legacySettlements } from "../data/world";
import { getWorld, center, reveal } from "./worldgen";
export type LoadResult = {
  state: GameState | null;
  status: "empty" | "current" | "migrated" | "unsupported";
};
/** Pure, versioned JSON migration. No old data is overwritten by merely opening the app. */
export function migrateSave(input: unknown): LoadResult {
  if (input === null || input === undefined)
    return { state: null, status: "empty" };
  if (validSave(input))
    return { state: structuredClone(input), status: "current" };
  if (!input || typeof input !== "object")
    return { state: null, status: "unsupported" };
  const version = (input as { schemaVersion?: number }).schemaVersion;
  if ((version !== undefined && version !== 1) || !validLegacySave(input))
    return { state: null, status: "unsupported" };
  const next = newGame(input.name, MAP.defaultSeed),
    world = getWorld(next.worldSeed),
    old = structuredClone(input);
  // Preserve the entire economy, castle and hero progression. Static-map coordinates
  // cannot describe the new terrain: relocate to the nearest old location's successor.
  for (const key of [
    "level",
    "resources",
    "day",
    "elapsed",
    "party",
    "cargo",
    "buildings",
    "popularity",
    "tax",
    "ale",
    "victories",
    "result",
    "lastBattleDay",
    "revision",
  ] as const)
    Object.assign(next, { [key]: old[key] });
  const newId = (id: number) =>
    Math.floor(id / 5) * 8 + [0, 1, 3, 4, 5][id % 5];
  for (const p of legacySettlements)
    next.supplies[newId(p.id)] = old.supplies[p.id];
  const nearest = [...legacySettlements].sort(
    (a, b) =>
      Math.hypot(a.x - old.hero.x, a.y - old.hero.y) -
      Math.hypot(b.x - old.hero.x, b.y - old.hero.y),
  )[0];
  next.hero = center(world.settlements[newId(nearest.id)].tile);
  next.explored = reveal("0".repeat(MAP.size * MAP.size), next.hero);
  next.path = [];
  next.destination = null;
  old.enemies.forEach((e, i) => {
    Object.assign(next.enemies[i], {
      alive: e.alive,
      strength: e.strength,
      baseStrength: e.strength,
    });
  });
  next.battle = old.battle;
  next.revision++;
  return validSave(next)
    ? { state: next, status: "migrated" }
    : { state: null, status: "unsupported" };
}
export function parseSave(raw: string | null): LoadResult {
  if (raw === null) return { state: null, status: "empty" };
  try {
    return migrateSave(JSON.parse(raw));
  } catch {
    return { state: null, status: "unsupported" };
  }
}
