# Local Sorani content packs

Drop a **UTF-8 `.json` file anywhere in this folder or a subfolder**. Vite's recursive raw-import glob discovers it automatically: no registry/code edits, API, network lookup or external service. Restart/rebuild the static app to include new files in deployment (this is not a remote hot-update service).

All seven categories ship with at least ten placeholder seed entries, 76 in total. Replace/extend them with your own Sorani pack. Category names and field names are stable machine identifiers; displayed text is Sorani. UI labels remain in `src/i18n.ts`; authored narrative lives here.

## Envelope and types

```json
{
  "schemaVersion": 1,
  "kind": "travel",
  "entries": [
    {
      "id": "village-gift",
      "text": "خەڵکی {town} بەخێرهاتنی {hero}یان کرد و خۆراکیان پێشکەش کرد.",
      "context": { "relation": "peace", "minDay": 2, "minPopularity": 50 },
      "tag": "gift",
      "effects": [{ "type": "food", "value": 12 }]
    }
  ]
}
```

The executable schema and inferred TypeScript `ContentEntry`, `ContentPack`, `Effect`, `ContentKind` types are in `engine/content.ts` (Zod). They validate every file at module startup. Files are imported as **raw text**, so malformed JSON is skipped at runtime instead of crashing Vite's JSON parser. Bad envelopes are skipped; individual bad entries are skipped while valid siblings remain. Diagnostics go to the console. Unknown fields, duplicate IDs within a category (even across files), unknown placeholders, invalid effects, or code-like extra fields are rejected. Text is rendered as escaped React/Canvas text, never HTML or executable code. A missing/exhausted category produces no line, not a crash or a repeated fallback.

- `schemaVersion`: exactly `1` (content format, independent of save schema).
- `kind`: `tavern`, `rumors`, `quests`, `travel`, `castle`, `lords`, or `battle`.
- `entries`: array, max 10,000 per file.
- `id`: unique within its category, 1–64 lowercase ASCII letters, digits, underscores/hyphens.
- `text`: 1–600 characters, natural Kurdish Sorani. Supported placeholders: `{hero}`, `{town}`, `{faction}`, `{day}`, `{amount}`, `{good}`, `{reward}`. Amount/good/reward are populated for contracts; use the first four in ordinary narration.
- `tag`: optional recent-event tag, 1–32 lowercase ASCII letters/digits/underscores/hyphens.

## Optional context (all specified conditions must match)

| Field                            | Value                                     |
| -------------------------------- | ----------------------------------------- |
| `factions`                       | list of faction indices 0, 1, 2           |
| `personality`                    | `honorable`, `greedy`, `bold`, `cautious` |
| `mood`                           | `calm`, `hopeful`, `angry`                |
| `relation`                       | `war` or `peace`                          |
| `minDay`, `maxDay`               | positive integer campaign days            |
| `minLevel`                       | positive integer hero level               |
| `minPopularity`, `maxPopularity` | numbers between 0 and 100                 |
| `recentTag`                      | must be in the recent tag window          |
| `excludeRecentTag`               | must not be in that window                |

Lord personalities are assigned deterministically per faction from the world seed. Dialogues use that faction's personality, relationship, and castle mood (angry below 40 popularity, hopeful at 70+, otherwise calm). Travel uses the nearest faction settlement for regional context. Tavern content uses the current town; contracts use the destination faction/town. History, tags, RNG state and the latest journal lines are saved, so reload does not reroll them. `minLevel` and recent-tag entries may intentionally be unavailable at the beginning.

## Bounded effects: travel/castle only

`effects` is optional and has at most four entries. Each is `{ "type": "food", "value": 10 }`. All values are integers; no formulas, scripts, callbacks, URLs or arbitrary state paths.

| Type         | Minimum | Maximum | Applied to                       |
| ------------ | ------: | ------: | -------------------------------- |
| `gold`       |    -150 |     300 | treasury, floored at 0           |
| `food`       |     -40 |      80 | castle food, floored at 0        |
| `popularity` |     -15 |      15 | popularity, clamped 0–100        |
| `troops`     |      -3 |       4 | peasant count, floored at 0      |
| `relation`   |     -20 |      20 | relation score, clamped -100–100 |

Only `relation` accepts an optional `faction` field (0–2); otherwise the current context faction is used. Bounds are defined in `data/progression.ts` and enforced at validation and application. Resource/troop totals are capped at 10,000,000. Effects are rejected on dialogue/rumor/lord/battle/quest entries. There is no `eval`, dynamic function construction, or content-triggered network request.

## Quests and lords

Quest entries **require** a `quest` object; other kinds cannot have one:

```json
{
  "id": "grain-order",
  "text": "{amount} یەکە {good} بگەیەنە {town}؛ پاداشتەکەت {reward} زێڕە.",
  "quest": { "type": "deliver", "good": "grain", "amount": 4, "reward": 120 }
}
```

- Type: `deliver`, `hunt`, `escort`.
- Good: `grain`, `wood`, `iron`, `cloth` (retained but unused for hunts/escorts).
- Amount: 1–12 (delivery quantity; hunts always require one new bandit victory).
- Reward: 30–300 gold. Successful contracts also grant +8 destination faction relation.
- The engine chooses a different peaceful town, supplies all placeholders, caps active contracts at three, and gives an 18-day deadline. Daily town/type offer IDs cannot be accepted twice. A saved accepted contract is a snapshot, so later pack edits do not rewrite its promise.
- Escorts need five troops, complete upon arrival at the destination, and fail upon army loss/battle defeat/deadline. They are abstract campaign escorts, not separately simulated caravan agents.
- Lord entries require a top-level `personality` enum; their text describes that personality. The tavern's lord-description action selects descriptions matching the current faction lord.

## Selection and repetition

Selection is deterministic seeded selection among eligible entries. Last **20 rendered lines**, not just IDs, are excluded across categories. No-repeat history is independent of the 12-line visible journal. With fewer than 21 eligible unique lines, it is normal for a category to fall silent until other categories advance history. Recent tags use a separate last-20 tagged-entry window. Quest offers inspect a cloned RNG/history, so merely rerendering a screen does not consume randomness.

Run `npm test` from `web/`: content tests validate all shipped packs, malformed input, bounds, contextual filtering, deterministic reloads, non-repetition, and custom filenames. Runtime validation still runs in production; tests are not its replacement.
