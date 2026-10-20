# Iron Crowns — Sorani strategy web campaign

A separate React/TypeScript web game. The Godot/Android game elsewhere in this repository is untouched.

## Run

Node 22.12+ is required by the test tooling.

```sh
cd web
npm ci
cp .env.example .env.local
npm run dev -- --host 0.0.0.0 --port 5173
npm test
npm run build
```

Deploy `web/dist` to an HTTPS static host with SPA fallback to `index.html`. Add that origin to Supabase's allowed auth redirect URLs for production. The existing project already allows the Arena `*.e2b.app` preview and localhost. Only the publishable key belongs in Vite/browser configuration; never add a service-role key.

## Implemented

- Sorani RTL UI and bundled Vazirmatn font; strings in `src/i18n.ts`.
- Seeded 128×128 simplex Canvas world, 3 factions with 3 towns and 5 villages each, 6 neutral camps, terrain-weighted A* roads/travel, persistent fog, minimap jumping, drag/pinch/wheel smooth zoom.
- Hero name/level/gold, 5 troop types with costs, strength and upkeep; town-only recruitment.
- Town-only supply/demand market for grain/wood/iron/cloth, buy/sell spread, cargo. Grain and wood can be unloaded into castle resources.
- Lazy-loaded R3F castle with 10 building types, grid placement and valid/invalid ghost preview; animated instanced workers/trees/smoke, clamped orbit/zoom/pan and two-finger rotation.
- Daily production, upkeep, food consumption, tax/ale popularity changes and income scaling. Passing a day at the castle is an explicit action; otherwise only travel advances time.
- Automatic encounters with short 3D army visualization, deterministic strength-based losses and loot. Reloading an unfinished battle waits for Continue, then resumes the visualization; resolution is idempotent.
- Low/Medium/High quality stored locally per identity and in the user's profile when signed in. 3D rendering capped to 24/30/45 FPS, capped DPR, no real-time shadows. Hidden tabs stop simulation/render ticks.
- Tutorial, Continue/New Game, responsive navigation, settings and top-20 leaderboard.

## Connected Supabase

Applied `supabase/001_strategy.sql` to the connected project `cbkddsztcivllpwzflkx`.

The project already had a profiles table for another app. Existing fields, data and policies were preserved; `iron_quality` and a restricted self-insert policy were added. The checked-in migration is intended for this existing project (it assumes `public.profiles(id, username)` exists), not a destructive replacement schema.

- `saves`: one JSONB save per user, owner-only read/write/delete, server-maintained update timestamp.
- `leaderboard`: public read, owner-only mutations, indexed descending score.
- RLS is enabled on profiles, saves and leaderboard and the deployed policies were inspected.
- Email/password signup and login use Supabase Auth, with email confirmation still enabled.
- Guest saves and authenticated saves are kept under separate localStorage keys. Cloud writes are serialized, run every 60 seconds and on visibility loss; pagehide uses a small keepalive request plus synchronous local backup.
- Page-close cloud writes are **best effort**, as browsers cannot guarantee network delivery after termination. Local backup and later autosave are the recovery path. Concurrent multi-device editing is not a collaborative merge system; use one active device per campaign.
- Real email confirmation delivery and two-account browser auth/RLS integration were not exercised. Default Supabase SMTP can impose recipient/rate restrictions; configure a production mail provider before public launch. No existing auth settings were weakened or email confirmation disabled.
- Scores are client-calculated in this MVP. RLS prevents editing another user's row, not submitting an inflated personal score. Server-authoritative scoring/anti-cheat belongs before a competitive release.

## Structure

- `game/data`: units, goods, buildings, world and balance/quality constants.
- `game/engine`: pure simulation and isolated persistence/auth provider.
- `components/2d`: Canvas map and pointer gestures.
- `components/3d`: lazy scene modules; reusable primitive building models, instancing and camera controls.
- `routes`: map, castle, party, market, leaderboard.

## Validation

- TypeScript + production Vite build: pass; 3D scene is emitted as a separate lazy chunk.
- 40 simulation/world/content/migration tests: pass (faction counts, travel, demand/spread, town restrictions, construction/costs, daily economy, battle idempotency, cargo unloading, malformed saves).
- Browser smoke (`tests/browser.mjs`): desktop and 390px mobile layout, recruitment, buying, actual 3D grid placement, day advancement, quality, local restore, unfinished battle continuation and result persistence. Zero page errors/no mobile horizontal overflow in the successful run.
- All npm dependencies audited with no reported vulnerabilities at implementation time.
- Browser script uses the npm-distributed Sparticuz Chromium binary. On a minimal Linux image, its bundled `al2023.tar.br` NSS/NSPR libraries may need extracting and adding to `LD_LIBRARY_PATH`. This is test tooling only, never shipped to the browser.

Not included: player-controlled combat, sieges, full diplomacy, multiplayer, offline service-worker installation, production anticheat, or validated physical-phone frame rates. Low-poly visuals are intentionally built from primitives for this MVP.

## Phase 1.5 world and rendering

- `worldgen.ts` uses a persisted unsigned 32-bit seed and generator version 1. New Game chooses a random seed; tests/default legacy migration use 19071020. Never change this generator's output for existing seeds without a generator migration.
- Seven terrain types: water, plains, forest, hills, mountains, river, road. Movement costs are centralized in `game/data/world.ts`: road 0.6, plains 1, forest 1.8, hills 2.4, mountains 5.5; water/river are impassable. Rivers have dry crossing tiles at two latitudes. Roads never convert water into traversable terrain.
- All 30 locations have at least 8-tile separation and lie on connected land. A Prim spanning tree selects links and weighted A* routes each road. Four-neighbor paths cannot cut diagonally through water.
- Three faction patrols and six bandit parties patrol routes and chase within range; strength scales with hero level/day. Like Phase 1, campaign simulation (including patrols) pauses on arrival, during battle/results, and when explicitly paused. Castle day advancement remains an economy action, not a patrol simulation.
- Visible 16×16-tile chunks are cached with an LRU cap of 20/36/64 canvases. Minimum zoom adapts to viewport/quality to avoid regenerating more visible chunks than the cache can hold. The minimap can jump anywhere even at Low quality. Explored terrain persists; remembered terrain is dimmed and enemy parties are shown only within current vision.
- Layered terrain colors/biome edges, trees, mountain facets, water highlights, faction boundaries/banners, settlement labels and animated hero are drawn procedurally. Sorani SVG controls, parchment cards and 44px map touch targets use no external art.
- Castle stone, wood, thatch and ground canvas textures, gradient sky/fog, roofed towers, crenellations, animated banner cloth and workers traveling between buildings. High-only flickering torches are capped at two lights; no real-time shadows on any tier.
- Battle bodies/helmets/weapons/shields use instanced formations with attack swings, dust and arrow flights. Quality caps army figures at 18/30/48 per side and particles at 10/24/40. Effects are cosmetic; the original deterministic battle outcome calculation is unchanged.

## Versioned save migration

Phase 1.5 introduced `schemaVersion: 2` (now migrated to 3), `generatorVersion: 1`, `worldSeed`, tile routes, explored fog and AI state are stored **inside `game_state`**. The JSONB database schema and existing Supabase RLS do not need changes. Local and cloud hydration both pass through the same pure `migrateSave` boundary; localStorage retains the `iron-web-v1-<identity>` key so existing saves remain discoverable.

- Unversioned Phase 1 saves (or explicit schema 1) are validated against the original 1400×1000 world before conversion.
- Gold/resources, army, cargo, buildings, taxes/ale/popularity, day/time, level/victories and battle results are preserved. Existing stock IDs map to successor towns/villages. Three original enemy alive/strength values and a pending battle are retained.
- Coordinates cannot map directly onto a new island: hero relocates to the successor of the nearest old location; travel stops and vision starts around that location. Newly added settlements/patrols receive initial state. A Sorani notice explains relocation before Continue.
- Invalid JSON, malformed structures, unknown schema/generator versions and illegal routes offer New Game instead of crashing. Opening the recovery screen alone does not overwrite the unsupported save.
- Before replacement, original local data is copied to `iron-web-v1-<identity>-pre-schema2`; an incompatible/migrated cloud payload has a separate `-pre-schema2-cloud` backup. These first backups are retained, not continually overwritten. Storage-quota/private-mode restrictions can prevent backups; these are local recovery aids, not guaranteed archival storage.
- Typical saves remain well below the existing 200,000-byte limit. No bulk migration of other users' records, auth setting changes, or backend permission changes were performed.

Additional browser validation: `node tests/phase15.mjs` exercises legacy migration/backup, mobile pinch input, minimap/locate controls, and unsupported-version New Game recovery. It uses the Vite server at port 5173. Unit tests verify 32 different seeds, deterministic regeneration after cache eviction, all location spacing/road connectivity, weighted routes, impassable water, fog persistence, AI scaling, migrations and bad saves. Browser checks do not substitute for physical-device performance testing or live authenticated cloud/two-account RLS testing.

## Campaign systems and local content (save schema 3)

Open **پاڵەوان و پەیمانەکان** from navigation for skills, equipment, diplomacy, tavern offers and the journal.

- Two spendable skill points at level 1 and two per subsequent level. Leadership reduces wages by 2.5% per rank, Trade improves buy/sell prices without removing the market spread, Combat adds 3% army strength per rank. Each skill caps at 10. Migrated heroes receive points for their existing level.
- Five purchasable inventory items, with separate weapon/armor/banner slots. Only equipped items contribute to the army-strength multiplier. Gear purchases require a peaceful town, enough gold and no duplicate ownership; switching equipment is free.
- Three persisted relation scores. At -30 or below a faction is at war: its patrols can attack, and its towns reject trade/recruitment/tavern actions. Declaration sets -60; peace costs 150 gold and returns the score to 0. Contract rewards and events can alter relations.
- Three simultaneous tavern contracts: deliver goods from cargo, win a new battle against bandits (patrol victories do not count), or escort an abstract caravan to another peaceful town. Contracts have 18-day deadlines, gold rewards and +8 destination faction relation; each town/day/type offer can be accepted once. Escorts need five troops and fail on battle loss, guard shortage or timeout. No separate caravan agent is simulated. Hunt navigation points toward the nearest living bandit party.
- Seeded daily travel/castle events include harvest, plague, raid, gifts, shortages and recruitment. They apply only validated bounded gold/food/popularity/peasant/relation effects. Chance per simulated day: Easy 22%, Normal 32%, Hard 45%. Like prior phases, travel advances campaign time; castle day advancement is explicit.
- Difficulty is adjustable during day 1 before victories/completed contracts (and only while stopped), then locked. Enemy strength multipliers: 0.8/1/1.25. This setting is saved.
- Victory: 6 battles won, 3 contracts completed and 2,000 gold simultaneously. Defeat: popularity reaches zero, four consecutive unfed days, or day 181. Ended campaigns stop simulation and offer New Game; a battle result is shown before the campaign-end dialog.
- Procedurally synthesized Web Audio pentatonic background music and short construction/coin/battle/result effects, generated locally. Muted by default; enable in Settings with a user gesture. Preference persists locally, hidden tabs suspend audio, and unsupported audio browsers continue silently. No music assets, CDN or audio-generation API.
- Tutorial now explains skills, gear, contracts, diplomacy, events and end conditions.

### Adding/replacing authored content

See [`src/game/data/content/FORMAT.md`](src/game/data/content/FORMAT.md) for the full typed/schema-validated pack format, placeholders, bounds and context filters. Seven JSON files contain **76 Sorani seed entries**, at least ten per category. Recursive Vite raw imports discover new filenames without code changes. Rebuild the static deployment after dropping in packs; there is no runtime remote-content service. Invalid files/entries are skipped at startup, not executed. The last 20 rendered lines are excluded across categories; no eligible fresh line means silence, not a forced repetition.

The content engine has **no external service or API calls**. Existing optional Supabase authentication, saves and leaderboard remain as before; no backend migration or permission changes are needed for this update.

### Save migration and verification

Current saves use `schemaVersion: 3` with a typed `campaign` object holding skills/points, inventory/equipment, relations/personalities, difficulty, contracts, end state, seeded content RNG/history and journal. Schema-2 migration preserves world seed, terrain, explored fog, in-flight route, enemies, economy and pending battles; it adds the new systems without moving the hero. Original Phase-1 saves still use the documented static-map relocation. Local/cloud boundaries share migration and invalid/future saves still offer safe New Game recovery. New backups use `-pre-schema3` / `-pre-schema3-cloud`; older `-pre-schema2` backups are not removed.

40 unit tests cover the old economy/world tests plus content validation, deterministic non-repetition/context, bounded effects, skills/gear, peaceful/hostile patrols, all three contracts, difficulty, end conditions and both older save versions. `tests/campaign.mjs` covers desktop/390px UI actions, equipment, diplomacy, contracts, settings, local audio oscillator creation, reload and delivery completion; `tests/browser.mjs` and `tests/phase15.mjs` continue to cover prior systems/recovery. Real-device performance, subjective audio quality and authenticated cloud/two-account checks are still not certified by headless tests.
