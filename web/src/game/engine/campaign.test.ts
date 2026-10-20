import { describe, it, expect } from "vitest";
import {
  newGame,
  validSave,
  strength,
  price,
  upkeep,
  advanceDay,
  resolveBattle,
  tick,
  move,
  trade,
} from "./simulation";
import {
  train,
  buyEquipment,
  equip,
  diplomacy,
  atWar,
  offers,
  acceptContract,
  claimContracts,
  applyEffects,
  checkCampaign,
  setDifficulty,
  converse,
  campaignDay,
} from "./campaign";
import {
  content,
  validatePacks,
  pick,
  type ContentMemory,
  type ContentContext,
} from "./content";
import { migrateSave } from "./migrations";
import { getWorld, center } from "./worldgen";
const ctx: ContentContext = {
  faction: 0,
  personality: "honorable",
  mood: "hopeful",
  relation: "peace",
  day: 7,
  level: 3,
  popularity: 80,
  values: {
    hero: "ئارام",
    town: "بەردەش",
    faction: "پەیمان",
    day: "٧",
    good: "دانەوێڵە",
    amount: "٣",
    reward: "١٠٠",
  },
};
const memory = (): ContentMemory => ({
  rng: 123,
  history: [],
  recentTags: [],
  log: [],
});
describe("local content packs", () => {
  it("ships at least ten validated entries in every category", () => {
    expect(content.issues).toEqual([]);
    for (const pool of Object.values(content.entries))
      expect(pool.length).toBeGreaterThanOrEqual(10);
  });
  it("skips broken JSON, envelopes, unsafe effects, code and duplicate entries without throwing", () => {
    const result = validatePacks({
      bad: "{",
      badEnvelope: { kind: "travel", entries: [] },
      pack: {
        schemaVersion: 1,
        kind: "travel",
        entries: [
          { id: "ok", text: "باش", effects: [{ type: "food", value: 20 }] },
          { id: "ok", text: "دووبارە" },
          {
            id: "large",
            text: "خراپ",
            effects: [{ type: "gold", value: 9999 }],
          },
          { id: "code", text: "خراپ", execute: "alert(1)" },
          { id: "type", text: "خراپ", effects: [{ type: "run", value: 1 }] },
          { id: "place", text: "{unknown}" },
        ],
      },
    });
    expect(result.entries.travel).toHaveLength(1);
    expect(result.issues).toHaveLength(7);
  });
  it("uses saved randomness, fills placeholders and suppresses the last twenty rendered lines", () => {
    const pool = {
      ...content.entries,
      rumors: Array.from({ length: 25 }, (_, i) => ({
        id: `line-${i}`,
        text: `{hero} لە {town} ${i}`,
      })),
    };
    const a = memory(),
      b = memory();
    for (let i = 0; i < 70; i++) {
      const old = [...a.history],
        e = pick("rumors", ctx, a, pool);
      expect(e).not.toBeNull();
      expect(old).not.toContain(a.log[0]);
      pick("rumors", ctx, b, pool);
      expect(a).toEqual(b);
      expect(a.log[0]).toContain("ئارام لە بەردەش");
      expect(a.history.length).toBeLessThanOrEqual(20);
    }
    expect(pick("rumors", ctx, a, pool)).toEqual(pick("rumors", ctx, b, pool));
  });
  it("filters all context axes and stays silent rather than repeating exhausted entries", () => {
    const pool = {
      ...content.entries,
      tavern: [
        {
          id: "match",
          text: "{hero}",
          context: {
            factions: [0],
            personality: "honorable" as const,
            mood: "hopeful" as const,
            relation: "peace" as const,
            minDay: 7,
            maxDay: 9,
            minLevel: 3,
            minPopularity: 70,
            maxPopularity: 90,
            recentTag: "harvest",
            excludeRecentTag: "plague",
          },
        },
      ],
    };
    const m = memory();
    expect(pick("tavern", ctx, m, pool)).toBeNull();
    m.recentTags = ["harvest"];
    expect(pick("tavern", { ...ctx, relation: "war" }, m, pool)).toBeNull();
    expect(pick("tavern", ctx, m, pool)?.id).toBe("match");
    expect(pick("tavern", ctx, m, pool)).toBeNull();
  });
  it("automatically discovers new raw JSON filenames in the same validation path", () => {
    const result = validatePacks({
      "custom/new-pack.json": JSON.stringify({
        schemaVersion: 1,
        kind: "rumors",
        entries: [{ id: "custom", text: "هەواڵێکی نوێ" }],
      }),
    });
    expect(result.entries.rumors[0].id).toBe("custom");
  });
});
describe("hero, diplomacy and contracts", () => {
  it("spends points once, earns two per level, and changes strength, trade and upkeep", () => {
    let s = newGame("hero");
    const base = strength(s),
      cost = price(s, 0, "iron");
    s = train(s, "combat");
    expect(strength(s)).toBeGreaterThan(base);
    s = train(s, "trade");
    expect(price(s, 0, "iron")).toBeLessThanOrEqual(cost);
    expect(train(s, "leadership")).toBe(s);
    s.victories = 1;
    s.party.cavalry = 30;
    s.battle = 3;
    s = resolveBattle(s);
    expect(s.level).toBe(2);
    expect(s.campaign.points).toBe(2);
    s.result = null;
    const pay = upkeep(s);
    s = train(s, "leadership");
    expect(upkeep(s)).toBeLessThan(pay);
    expect(validSave(s)).toBe(true);
  });
  it("requires buying gear and equipping it, replaces slots and prevents duplicate purchases", () => {
    let s = newGame("gear");
    const base = strength(s);
    expect(equip(s, "sword")).toBe(s);
    s = buyEquipment(s, "sword");
    expect(strength(s)).toBe(base);
    s = equip(s, "sword");
    expect(strength(s)).toBeGreaterThan(base);
    expect(buyEquipment(s, "sword")).toBe(s);
    s.resources.gold = 500;
    s = buyEquipment(s, "axe");
    s = equip(s, "axe");
    expect(s.campaign.equipped.weapon).toBe("axe");
    s = equip(s, "axe");
    expect(strength(s)).toBe(base);
    expect(validSave(s)).toBe(true);
  });
  it("war closes trade/taverns and peace costs gold", () => {
    let s = diplomacy(newGame("war"), 0, true);
    expect(atWar(s, 0)).toBe(true);
    expect(trade(s, 0, "grain", true)).toBe(s);
    expect(offers(s)).toEqual([]);
    expect(converse(s, "tavern")).toBe(s);
    const gold = s.resources.gold;
    s = diplomacy(s, 0, false);
    expect(s.resources.gold).toBe(gold - 150);
    expect(atWar(s, 0)).toBe(false);
    expect(offers(s).length).toBe(3);
  });
  it("delivery consumes cargo only at target and rewards exactly once", () => {
    let s = newGame("delivery");
    const offer = offers(s).find((o) => o.entry.quest?.type === "deliver")!;
    s = acceptContract(s, offer.id);
    const q = s.campaign.contracts[0];
    s.cargo[q.good] = q.amount;
    const gold = s.resources.gold;
    s = claimContracts(s);
    expect(s.campaign.contracts).toHaveLength(1);
    s.hero = center(getWorld(s.worldSeed).settlements[q.target].tile);
    s = claimContracts(s);
    expect(s.resources.gold).toBe(gold + q.reward);
    expect(s.cargo[q.good]).toBe(0);
    expect(s.campaign.completed).toBe(1);
    expect(claimContracts(s).resources.gold).toBe(s.resources.gold);
    expect(validSave(s)).toBe(true);
  });
  it("hunt requires a new bandit win, not a patrol win", () => {
    let s = newGame("hunt");
    const offer = offers(s).find((o) => o.entry.quest?.type === "hunt")!;
    s = acceptContract(s, offer.id);
    s.party.cavalry = 50;
    s.battle = 0;
    s = resolveBattle(s);
    expect(s.campaign.contracts).toHaveLength(1);
    s.result = null;
    s.battle = 3;
    s = resolveBattle(s);
    expect(s.campaign.contracts).toHaveLength(0);
    expect(s.campaign.completed).toBe(1);
  });
  it("escort completes on arrival and fails after battle loss, low guard count or deadline", () => {
    const setup = () => {
      const s = newGame("escort"),
        o = offers(s).find((o) => o.entry.quest?.type === "escort")!;
      return acceptContract(s, o.id);
    };
    let s = setup();
    s.hero = center(
      getWorld(s.worldSeed).settlements[s.campaign.contracts[0].target].tile,
    );
    s = claimContracts(s);
    expect(s.campaign.completed).toBe(1);
    s = setup();
    s.party = { peasant: 1, archer: 0, swordsman: 0, spearman: 0, cavalry: 0 };
    s = claimContracts(s);
    expect(s.campaign.contracts).toHaveLength(0);
    expect(s.campaign.completed).toBe(0);
    s = setup();
    s.day = 100;
    s = claimContracts(s);
    expect(s.campaign.contracts).toHaveLength(0);
    s = setup();
    s.battle = 3;
    s.enemies[3].strength = 10000;
    s = resolveBattle(s);
    expect(s.campaign.contracts).toHaveLength(0);
  });
  it("blocks duplicate offers and respects difficulty lock after first day", () => {
    let s = newGame("limits");
    const o = offers(s)[0];
    s = acceptContract(s, o.id);
    expect(acceptContract(s, o.id)).toBe(s);
    s = setDifficulty(s, "hard");
    expect(s.campaign.difficulty).toBe("hard");
    s.day = 2;
    expect(setDifficulty(s, "easy")).toBe(s);
  });
});
describe("events, end conditions and schema 3", () => {
  it("applies only bounded effects and clamps resources/relations", () => {
    const s = newGame("event");
    s.resources.gold = 0;
    s.popularity = 99;
    applyEffects(
      s,
      [
        { type: "gold", value: -150 },
        { type: "food", value: 80 },
        { type: "popularity", value: 15 },
        { type: "troops", value: 4 },
        { type: "relation", value: -20 },
      ],
      1,
    );
    expect(s.resources.gold).toBe(0);
    expect(s.popularity).toBe(100);
    expect(s.campaign.relations[1]).toBe(-20);
    applyEffects(s, [{ type: "gold", value: 999999 }], 0);
    expect(s.resources.gold).toBe(0);
  });
  it("travel/castle events are deterministic across a reload", () => {
    let a = newGame("events"),
      b = structuredClone(a);
    for (let i = 0; i < 30; i++) {
      campaignDay(a, i % 2 ? "castle" : "travel", true);
      campaignDay(b, i % 2 ? "castle" : "travel", true);
      a.day++;
      b.day++;
      b = JSON.parse(JSON.stringify(b));
    }
    expect(a).toEqual(b);
    expect(a.campaign.memory.log.length).toBeGreaterThan(0);
  });
  it("ends victorious campaigns and freezes travel, economy and skills", () => {
    let s = newGame("victory");
    s.victories = 6;
    s.campaign.completed = 3;
    s.resources.gold = 2000;
    checkCampaign(s);
    expect(s.campaign.end).toBe("victory");
    expect(move(s, { x: 100, y: 100 })).toBe(s);
    expect(advanceDay(s)).toBe(s);
    expect(train(s, "combat")).toBe(s);
    expect(tick(s, 0.1)).toBe(s);
  });
  it("defeats campaigns from unrest, starvation or day limit", () => {
    for (const cause of ["unrest", "starvation", "time"]) {
      const s = newGame("defeat");
      if (cause === "unrest") s.popularity = 0;
      if (cause === "starvation") s.campaign.starvation = 4;
      if (cause === "time") s.day = 181;
      checkCampaign(s);
      expect(s.campaign.end).toBe("defeat");
    }
  });
  it("migrates phase 1.5 without changing terrain, travel, fog or economy", () => {
    const s = newGame("old");
    s.level = 4;
    const old = { ...s, schemaVersion: 2, campaign: undefined };
    const loaded = migrateSave(old);
    expect(loaded.status).toBe("migrated");
    expect(loaded.state?.schemaVersion).toBe(3);
    expect(loaded.state?.campaign.points).toBe(8);
    expect(loaded.state?.resources).toEqual(old.resources);
    expect(loaded.state?.hero).toEqual(old.hero);
    expect(loaded.state?.explored).toEqual(old.explored);
    expect(validSave(loaded.state)).toBe(true);
  });
  it("rejects corrupted campaign state instead of silently resetting it", () => {
    const s = newGame("bad");
    s.campaign.points = 100;
    expect(migrateSave(s).status).toBe("unsupported");
    const b = newGame("bad");
    b.campaign.equipped.weapon = "sword";
    expect(validSave(b)).toBe(false);
  });
});

describe("campaign integration boundaries", () => {
  it("keeps peaceful patrols non-hostile, while wartime patrols trigger encounters", () => {
    const setup = () => {
      const s = newGame("border");
      const w = getWorld(s.worldSeed);
      s.hero = center(w.settlements[s.enemies[0].home].tile);
      s.lastBattleDay = 0;
      return move(s, s.hero);
    };
    let peace = setup();
    peace = tick(peace, 0.1);
    expect(peace.battle).toBeNull();
    let war = setup();
    war.campaign.relations[0] = -60;
    war = tick(war, 0.1);
    expect(war.battle).toBe(0);
    expect(war.campaign.memory.log.length).toBe(1);
  });
  it("scales encounters by selected difficulty without changing the saved terrain", () => {
    const setup = (difficulty: "easy" | "hard") => {
      let s = newGame("difficulty");
      s = setDifficulty(s, difficulty);
      s = move(s, getWorld(s.worldSeed).settlements[1]);
      return tick(s, 0.1);
    };
    const easy = setup("easy"),
      hard = setup("hard");
    expect(hard.enemies[3].strength).toBeGreaterThan(easy.enemies[3].strength);
    expect(hard.worldSeed).toBe(easy.worldSeed);
  });
  it("keeps the daily market spread non-profitable even at maximum Trade", () => {
    const s = newGame("trader");
    s.level = 5;
    s.campaign.points = 0;
    s.campaign.skills.trade = 10;
    for (const g of ["grain", "wood", "iron", "cloth"] as const)
      for (const stock of [0, 1, 20, 120]) {
        s.supplies[0][g] = stock;
        expect(price(s, 0, g, true)).toBeGreaterThanOrEqual(
          price(s, 0, g, false),
        );
      }
    expect(validSave(s)).toBe(true);
  });
  it("retains an in-flight phase 1.5 route and a pending battle on migration", () => {
    const start = newGame("migrant"),
      travel = move(start, getWorld(start.worldSeed).settlements[1]);
    const old = { ...travel, schemaVersion: 2, campaign: undefined };
    const migrated = migrateSave(old).state!;
    expect(migrated.path).toEqual(travel.path);
    expect(migrated.destination).toEqual(travel.destination);
    const pending = { ...old, destination: null, path: [], battle: 3 };
    expect(migrateSave(pending).state?.battle).toBe(3);
  });
  it("keeps a long campaign payload below the existing JSONB limit", () => {
    const s = newGame("storage");
    s.campaign.offersTaken = Array.from(
      { length: 4860 },
      (_, i) =>
        `${i % 24}:${Math.floor(i / 27) + 1}:${["deliver", "hunt", "escort"][i % 3]}`,
    );
    s.campaign.memory.history = Array(20).fill("هەواڵێکی کوردی ".repeat(25));
    s.campaign.memory.log = s.campaign.memory.history.slice(0, 12);
    const bytes = new TextEncoder().encode(JSON.stringify(s)).byteLength;
    expect(bytes).toBeLessThan(180000);
    expect(validSave(s)).toBe(true);
  });
});
