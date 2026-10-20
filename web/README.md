# Iron Crowns — Phase 1.5 web campaign

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
- 17 simulation/world/migration tests: pass (faction counts, travel, demand/spread, town restrictions, construction/costs, daily economy, battle idempotency, cargo unloading, malformed saves).
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

`schemaVersion: 2`, `generatorVersion: 1`, `worldSeed`, tile routes, explored fog and AI state are stored **inside `game_state`**. The JSONB database schema and existing Supabase RLS do not need changes. Local and cloud hydration both pass through the same pure `migrateSave` boundary; localStorage retains the `iron-web-v1-<identity>` key so existing saves remain discoverable.

- Unversioned Phase 1 saves (or explicit schema 1) are validated against the original 1400×1000 world before conversion.
- Gold/resources, army, cargo, buildings, taxes/ale/popularity, day/time, level/victories and battle results are preserved. Existing stock IDs map to successor towns/villages. Three original enemy alive/strength values and a pending battle are retained.
- Coordinates cannot map directly onto a new island: hero relocates to the successor of the nearest old location; travel stops and vision starts around that location. Newly added settlements/patrols receive initial state. A Sorani notice explains relocation before Continue.
- Invalid JSON, malformed structures, unknown schema/generator versions and illegal routes offer New Game instead of crashing. Opening the recovery screen alone does not overwrite the unsupported save.
- Before replacement, original local data is copied to `iron-web-v1-<identity>-pre-schema2`; an incompatible/migrated cloud payload has a separate `-pre-schema2-cloud` backup. These first backups are retained, not continually overwritten. Storage-quota/private-mode restrictions can prevent backups; these are local recovery aids, not guaranteed archival storage.
- Typical saves remain well below the existing 200,000-byte limit. No bulk migration of other users' records, auth setting changes, or backend permission changes were performed.

Additional browser validation: `node tests/phase15.mjs` exercises legacy migration/backup, mobile pinch input, minimap/locate controls, and unsupported-version New Game recovery. It uses the Vite server at port 5173. Unit tests verify 32 different seeds, deterministic regeneration after cache eviction, all location spacing/road connectivity, weighted routes, impassable water, fog persistence, AI scaling, migrations and bad saves. Browser checks do not substitute for physical-device performance testing or live authenticated cloud/two-account RLS testing.
