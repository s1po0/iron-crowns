import { z } from "zod";
import type { GameState } from "./simulation";
import { getWorld } from "./worldgen";
import { t, num } from "../../i18n";
import {
  effectLimits,
  campaignRules as rules,
  difficulties,
  equipment,
  skills,
  type Item,
  type Skill,
} from "../data/progression";
import {
  content,
  pick,
  draw,
  personalities,
  type ContentContext,
  type ContentKind,
  type Effect,
  type ContentMemory,
} from "./content";
const integer = z.number().int().min(0).max(10000000);
const contractSchema = z
  .object({
    id: z.string().max(80),
    type: z.enum(["deliver", "hunt", "escort"]),
    target: integer.max(23),
    faction: integer.max(2),
    good: z.enum(["grain", "wood", "iron", "cloth"]),
    amount: integer.min(1).max(12),
    reward: integer.min(30).max(300),
    deadline: integer,
    baseline: integer,
    text: z.string().max(1000),
  })
  .strict();
export const campaignSchema = z
  .object({
    skills: z
      .object({
        leadership: integer.max(10),
        trade: integer.max(10),
        combat: integer.max(10),
      })
      .strict(),
    points: integer,
    inventory: z
      .array(z.enum(["sword", "axe", "mail", "plate", "banner"]))
      .max(5),
    equipped: z
      .object({
        weapon: z.enum(["sword", "axe"]).nullable(),
        armor: z.enum(["mail", "plate"]).nullable(),
        banner: z.literal("banner").nullable(),
      })
      .strict(),
    relations: z.tuple([
      z.number().int().min(-100).max(100),
      z.number().int().min(-100).max(100),
      z.number().int().min(-100).max(100),
    ]),
    lords: z.tuple([
      z.enum(personalities),
      z.enum(personalities),
      z.enum(personalities),
    ]),
    difficulty: z.enum(["easy", "normal", "hard"]),
    contracts: z.array(contractSchema).max(3),
    offersTaken: z.array(z.string().max(80)).max(5000),
    completed: integer,
    banditKills: integer,
    starvation: integer,
    end: z.enum(["victory", "defeat"]).nullable(),
    memory: z
      .object({
        rng: z.number().int().min(0).max(4294967295),
        history: z.array(z.string().max(1000)).max(20),
        recentTags: z.array(z.string().max(32)).max(20),
        log: z.array(z.string().max(1000)).max(12),
      })
      .strict(),
  })
  .strict();
export type Campaign = z.infer<typeof campaignSchema>;
export function newCampaign(seed: number, level = 1): Campaign {
  return {
    skills: { leadership: 0, trade: 0, combat: 0 },
    points: level * rules.pointsPerLevel,
    inventory: [],
    equipped: { weapon: null, armor: null, banner: null },
    relations: [0, 0, 0],
    lords: [
      personalities[seed % 4],
      personalities[(seed + 1) % 4],
      personalities[(seed + 2) % 4],
    ],
    difficulty: "normal",
    contracts: [],
    offersTaken: [],
    completed: 0,
    banditKills: 0,
    starvation: 0,
    end: null,
    memory: {
      rng: (seed ^ 0x731abc) >>> 0,
      history: [],
      recentTags: [],
      log: [],
    },
  };
}
export function validCampaign(s: GameState) {
  const parsed = campaignSchema.safeParse(s.campaign);
  if (!parsed.success) return false;
  const c = parsed.data;
  return (
    c.points + Object.values(c.skills).reduce((a, b) => a + b, 0) ===
      s.level * rules.pointsPerLevel &&
    new Set(c.inventory).size === c.inventory.length &&
    Object.values(c.equipped).every(
      (i) => i === null || c.inventory.includes(i),
    ) &&
    new Set(c.contracts.map((q) => q.id)).size === c.contracts.length &&
    c.contracts.every(
      (q) =>
        getWorld(s.worldSeed).settlements[q.target]?.kind === "town" &&
        getWorld(s.worldSeed).settlements[q.target]?.faction === q.faction &&
        c.offersTaken.includes(q.id),
    )
  );
}
export const atTown = (s: GameState) =>
  getWorld(s.worldSeed).settlements.find(
    (p) => p.kind === "town" && Math.hypot(p.x - s.hero.x, p.y - s.hero.y) < 20,
  );
export const atWar = (s: GameState, faction: number) =>
  s.campaign.relations[faction] <= -30;
export const gearBonus = (s: GameState) =>
  Object.values(s.campaign.equipped).reduce(
    (sum, id) => sum + (id ? equipment[id].bonus : 0),
    0,
  );
export function context(s: GameState, faction?: number): ContentContext {
  const nearest = [...getWorld(s.worldSeed).settlements]
    .filter((p) => p.faction >= 0)
    .sort(
      (a, b) =>
        Math.hypot(a.x - s.hero.x, a.y - s.hero.y) -
        Math.hypot(b.x - s.hero.x, b.y - s.hero.y),
    )[0];
  faction ??= nearest.faction;
  const town = atTown(s) || nearest;
  return {
    faction,
    personality: s.campaign.lords[faction],
    mood: s.popularity < 40 ? "angry" : s.popularity >= 70 ? "hopeful" : "calm",
    relation: atWar(s, faction) ? "war" : "peace",
    day: s.day,
    level: s.level,
    popularity: s.popularity,
    values: {
      hero: s.name,
      town: t.settlementNames[town.id],
      faction: t.factionNames[faction],
      day: num(s.day),
      amount: "",
      good: "",
      reward: "",
    },
  };
}
function log(memory: ContentMemory, line: string) {
  memory.log = [line, ...memory.log].slice(0, 12);
}
export function applyEffects(s: GameState, effects: Effect[], faction: number) {
  for (const e of effects) {
    const bounds = effectLimits[e.type];
    if (
      !bounds ||
      !Number.isInteger(e.value) ||
      e.value < bounds[0] ||
      e.value > bounds[1] ||
      (e.faction !== undefined &&
        (!Number.isInteger(e.faction) || e.faction < 0 || e.faction > 2))
    )
      continue;
    if (e.type === "gold" || e.type === "food")
      s.resources[e.type] = Math.max(
        0,
        Math.min(10000000, s.resources[e.type] + e.value),
      );
    if (e.type === "popularity")
      s.popularity = Math.max(0, Math.min(100, s.popularity + e.value));
    if (e.type === "troops")
      s.party.peasant = Math.max(
        0,
        Math.min(10000000, s.party.peasant + e.value),
      );
    if (e.type === "relation") {
      const f = e.faction ?? faction;
      s.campaign.relations[f] = Math.max(
        -100,
        Math.min(100, s.campaign.relations[f] + e.value),
      );
    }
  }
}
export function checkCampaign(s: GameState) {
  const c = s.campaign;
  if (c.end) return;
  if (
    s.popularity === 0 ||
    c.starvation >= rules.starvationDays ||
    s.day > rules.maxDays
  )
    c.end = "defeat";
  else if (
    s.victories >= rules.victoryBattles &&
    c.completed >= rules.victoryContracts &&
    s.resources.gold >= rules.victoryGold
  )
    c.end = "victory";
  if (c.end) {
    s.destination = null;
    s.path = [];
  }
}
export function settleContracts(s: GameState) {
  const c = s.campaign,
    town = atTown(s),
    army = Object.values(s.party).reduce((a, b) => a + b, 0);
  c.contracts = c.contracts.filter((q) => {
    if (
      s.day > q.deadline ||
      (q.type === "escort" && army < rules.escortTroops)
    ) {
      log(c.memory, t.contractFailed);
      return false;
    }
    if (atWar(s, q.faction)) return true;
    const done =
      q.type === "hunt"
        ? c.banditKills > q.baseline
        : town?.id === q.target &&
          (q.type === "escort" || s.cargo[q.good] >= q.amount);
    if (!done) return true;
    if (q.type === "deliver") s.cargo[q.good] -= q.amount;
    s.resources.gold += q.reward;
    c.relations[q.faction] = Math.min(100, c.relations[q.faction] + 8);
    c.completed++;
    log(c.memory, t.contractCompleted + " " + num(q.reward));
    return false;
  });
  checkCampaign(s);
}
export function campaignDay(
  s: GameState,
  kind: "travel" | "castle",
  fed: boolean,
) {
  s.campaign.starvation = fed ? 0 : s.campaign.starvation + 1;
  const ctx = context(s);
  if (draw(s.campaign.memory) < difficulties[s.campaign.difficulty].event) {
    const e = pick(kind, ctx, s.campaign.memory);
    if (e) applyEffects(s, e.effects ?? [], ctx.faction);
  }
  settleContracts(s);
}
function change(s: GameState, fn: (n: GameState) => void) {
  if (s.campaign.end || s.battle !== null || s.result) return s;
  const n = structuredClone(s);
  fn(n);
  settleContracts(n);
  n.revision++;
  return n;
}
export function train(s: GameState, skill: Skill) {
  if (
    !skills.includes(skill) ||
    s.campaign.points < 1 ||
    s.campaign.skills[skill] >= rules.maxSkill
  )
    return s;
  return change(s, (n) => {
    n.campaign.skills[skill]++;
    n.campaign.points--;
  });
}
export function buyEquipment(s: GameState, id: Item) {
  const d = equipment[id];
  if (
    !d ||
    !atTown(s) ||
    atWar(s, atTown(s)!.faction) ||
    s.destination ||
    s.campaign.inventory.includes(id) ||
    s.resources.gold < d.price
  )
    return s;
  return change(s, (n) => {
    n.resources.gold -= d.price;
    n.campaign.inventory.push(id);
  });
}
export function equip(s: GameState, id: Item) {
  if (!s.campaign.inventory.includes(id)) return s;
  return change(s, (n) => {
    const slot = equipment[id].slot;
    Object.assign(n.campaign.equipped, {
      [slot]: n.campaign.equipped[slot] === id ? null : id,
    });
  });
}
export function diplomacy(s: GameState, faction: number, war: boolean) {
  if (
    !Number.isInteger(faction) ||
    faction < 0 ||
    faction > 2 ||
    atWar(s, faction) === war ||
    (!war && s.resources.gold < rules.peaceCost)
  )
    return s;
  return change(s, (n) => {
    if (!war) n.resources.gold -= rules.peaceCost;
    n.campaign.relations[faction] = war ? -60 : 0;
  });
}
export function setDifficulty(s: GameState, value: Campaign["difficulty"]) {
  if (
    s.day !== 1 ||
    s.destination ||
    s.victories ||
    s.campaign.completed ||
    !(value in difficulties)
  )
    return s;
  return change(s, (n) => {
    n.campaign.difficulty = value;
  });
}
export function converse(
  s: GameState,
  kind: Extract<ContentKind, "tavern" | "rumors" | "lords">,
) {
  const town = atTown(s);
  if (!town || s.destination || atWar(s, town.faction)) return s;
  return change(s, (n) => {
    const ctx = context(n);
    pick(
      kind,
      ctx,
      n.campaign.memory,
      kind === "lords"
        ? {
            ...content.entries,
            lords: content.entries.lords.filter(
              (e) => e.personality === ctx.personality,
            ),
          }
        : content.entries,
    );
  });
}
export function offers(s: GameState) {
  const town = atTown(s);
  if (!town || s.destination || atWar(s, town.faction) || s.campaign.end)
    return [];
  const targets = getWorld(s.worldSeed).settlements.filter(
    (p) => p.kind === "town" && p.id !== town.id && !atWar(s, p.faction),
  );
  if (!targets.length) return [];
  return (["deliver", "hunt", "escort"] as const).flatMap((type, i) => {
    if (
      type === "hunt" &&
      !s.enemies.some((e) => e.alive && e.kind === "bandit")
    )
      return [];
    const target = targets[(s.day + town.id + i) % targets.length],
      id = `${town.id}:${s.day}:${type}`;
    if (s.campaign.offersTaken.includes(id)) return [];
    const candidates = content.entries.quests
      .filter((e) => e.quest?.type === type)
      .flatMap((entry) => {
        const q = entry.quest!,
          ctx = context(s, target.faction);
        ctx.values = {
          ...ctx.values,
          town: t.settlementNames[target.id],
          amount: num(q.amount),
          good: t.goodNames[q.good],
          reward: num(q.reward),
        };
        return pick("quests", ctx, structuredClone(s.campaign.memory), {
          ...content.entries,
          quests: [entry],
        })
          ? [{ id, entry, target, ctx }]
          : [];
      });
    if (!candidates.length) return [];
    return [
      candidates[(s.worldSeed + s.day + town.id + i) % candidates.length],
    ];
  });
}
export function acceptContract(s: GameState, id: string) {
  const offer = offers(s).find((o) => o.id === id);
  if (
    !offer ||
    s.campaign.contracts.length >= rules.maxContracts ||
    (offer.entry.quest!.type === "escort" &&
      Object.values(s.party).reduce((a, b) => a + b, 0) < rules.escortTroops)
  )
    return s;
  return change(s, (n) => {
    const e = pick("quests", offer.ctx, n.campaign.memory, {
      ...content.entries,
      quests: [offer.entry],
    });
    if (!e) return;
    const q = e.quest!;
    n.campaign.offersTaken.push(id);
    n.campaign.contracts.push({
      id,
      type: q.type,
      target: offer.target.id,
      faction: offer.target.faction,
      good: q.good,
      amount: q.amount,
      reward: q.reward,
      deadline: n.day + rules.contractDays,
      baseline: n.campaign.banditKills,
      text: n.campaign.memory.log[0],
    });
  });
}
export function claimContracts(s: GameState) {
  return change(s, () => {});
}
