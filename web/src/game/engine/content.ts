import { z } from "zod";
import { effectLimits } from "../data/progression";
export const kinds = [
  "tavern",
  "rumors",
  "quests",
  "travel",
  "castle",
  "lords",
  "battle",
] as const;
export type ContentKind = (typeof kinds)[number];
export const personalities = [
  "honorable",
  "greedy",
  "bold",
  "cautious",
] as const;
export const moods = ["calm", "hopeful", "angry"] as const;
const effectSchema = z
  .object({
    type: z.enum(["gold", "food", "popularity", "troops", "relation"]),
    value: z.number().int(),
    faction: z.number().int().min(0).max(2).optional(),
  })
  .strict()
  .refine(
    (e) =>
      e.value >= effectLimits[e.type][0] &&
      e.value <= effectLimits[e.type][1] &&
      (e.type === "relation" || e.faction === undefined),
  );
export const entrySchema = z
  .object({
    id: z.string().regex(/^[a-z0-9_-]{1,64}$/),
    text: z
      .string()
      .min(1)
      .max(600)
      .refine((s) =>
        [...s.matchAll(/\{([^{}]+)\}/g)].every((m) =>
          [
            "town",
            "hero",
            "faction",
            "amount",
            "good",
            "reward",
            "day",
          ].includes(m[1]),
        ),
      ),
    context: z
      .object({
        factions: z.array(z.number().int().min(0).max(2)).max(3).optional(),
        personality: z.enum(personalities).optional(),
        mood: z.enum(moods).optional(),
        relation: z.enum(["war", "peace"]).optional(),
        minDay: z.number().int().min(1).max(10000000).optional(),
        maxDay: z.number().int().min(1).max(10000000).optional(),
        minLevel: z.number().int().min(1).max(10000000).optional(),
        minPopularity: z.number().min(0).max(100).optional(),
        maxPopularity: z.number().min(0).max(100).optional(),
        recentTag: z.string().max(32).optional(),
        excludeRecentTag: z.string().max(32).optional(),
      })
      .strict()
      .refine(
        (c) =>
          (c.minDay ?? 1) <= (c.maxDay ?? Infinity) &&
          (c.minPopularity ?? 0) <= (c.maxPopularity ?? 100),
      )
      .optional(),
    tag: z
      .string()
      .regex(/^[a-z0-9_-]{1,32}$/)
      .optional(),
    personality: z.enum(personalities).optional(),
    effects: z.array(effectSchema).max(4).optional(),
    quest: z
      .object({
        type: z.enum(["deliver", "hunt", "escort"]),
        good: z.enum(["grain", "wood", "iron", "cloth"]),
        amount: z.number().int().min(1).max(12),
        reward: z.number().int().min(30).max(300),
      })
      .strict()
      .optional(),
  })
  .strict();
export type ContentEntry = z.infer<typeof entrySchema>;
export type Effect = z.infer<typeof effectSchema>;
export type ContentPack = {
  schemaVersion: 1;
  kind: ContentKind;
  entries: ContentEntry[];
};
export type ContentContext = {
  faction: number;
  personality: (typeof personalities)[number];
  mood: (typeof moods)[number];
  relation: "war" | "peace";
  day: number;
  level: number;
  popularity: number;
  values: Record<string, string>;
};
export type ContentMemory = {
  rng: number;
  history: string[];
  recentTags: string[];
  log: string[];
};
const envelope = z
  .object({
    schemaVersion: z.literal(1),
    kind: z.enum(kinds),
    entries: z.array(z.unknown()).max(10000),
  })
  .strict();
export function validatePacks(files: Record<string, unknown>) {
  const entries: Record<ContentKind, ContentEntry[]> = {
    tavern: [],
    rumors: [],
    quests: [],
    travel: [],
    castle: [],
    lords: [],
    battle: [],
  };
  const issues: string[] = [];
  const ids = new Set<string>();
  for (const [file, value] of Object.entries(files).sort(([a], [b]) =>
    a.localeCompare(b),
  )) {
    let raw: unknown = value;
    if (typeof raw === "string") {
      try {
        raw = JSON.parse(raw);
      } catch {
        issues.push(`${file}: invalid JSON`);
        continue;
      }
    }
    const pack = envelope.safeParse(raw);
    if (!pack.success) {
      issues.push(`${file}: invalid envelope`);
      continue;
    }
    for (const candidate of pack.data.entries) {
      const entry = entrySchema.safeParse(candidate);
      if (!entry.success) {
        issues.push(`${file}: invalid entry`);
        continue;
      }
      const e = entry.data,
        key = `${pack.data.kind}:${e.id}`;
      if (
        ids.has(key) ||
        (pack.data.kind === "quests" && !e.quest) ||
        (pack.data.kind !== "quests" && e.quest) ||
        (pack.data.kind === "lords" && !e.personality) ||
        (!!e.effects && !["travel", "castle"].includes(pack.data.kind))
      ) {
        issues.push(`${file}: duplicate or wrong kind`);
        continue;
      }
      ids.add(key);
      entries[pack.data.kind].push(e);
    }
  }
  return { entries, issues };
}
// Raw imports allow malformed JSON to be skipped at runtime rather than breaking Vite's JSON parser.
const files = import.meta.glob("../data/content/**/*.json", {
  eager: true,
  query: "?raw",
  import: "default",
});
export const content = validatePacks(files);
if (content.issues.length)
  console.warn("Skipped invalid local content:", content.issues);
export function draw(memory: ContentMemory) {
  memory.rng = (Math.imul(memory.rng, 1664525) + 1013904223) >>> 0;
  return memory.rng / 4294967296;
}
export function fill(text: string, values: Record<string, string>) {
  return text.replace(/\{([^{}]+)\}/g, (_, key: string) => values[key] ?? "");
}
export function pick(
  kind: ContentKind,
  ctx: ContentContext,
  memory: ContentMemory,
  pool = content.entries,
): ContentEntry | null {
  const eligible = pool[kind].filter((e) => {
    const c = e.context || {};
    return (
      (!c.factions || c.factions.includes(ctx.faction)) &&
      (!c.personality || c.personality === ctx.personality) &&
      (!c.mood || c.mood === ctx.mood) &&
      (!c.relation || c.relation === ctx.relation) &&
      ctx.day >= (c.minDay ?? 1) &&
      ctx.day <= (c.maxDay ?? Infinity) &&
      ctx.level >= (c.minLevel ?? 1) &&
      ctx.popularity >= (c.minPopularity ?? 0) &&
      ctx.popularity <= (c.maxPopularity ?? 100) &&
      (!c.recentTag || memory.recentTags.includes(c.recentTag)) &&
      (!c.excludeRecentTag ||
        !memory.recentTags.includes(c.excludeRecentTag)) &&
      !memory.history.includes(fill(e.text, ctx.values))
    );
  });
  if (!eligible.length) return null;
  const entry = eligible[Math.floor(draw(memory) * eligible.length)],
    line = fill(entry.text, ctx.values);
  memory.history = [...memory.history, line].slice(-20);
  memory.log = [line, ...memory.log].slice(0, 12);
  if (entry.tag)
    memory.recentTags = [...memory.recentTags, entry.tag].slice(-20);
  return entry;
}
