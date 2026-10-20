# Iron Crowns — Phase 1 web MVP

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
- Canvas tile world, 3 factions, 6 towns, 9 villages, tap travel, time while moving, drag/pinch/wheel zoom.
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
- Nine simulation tests: pass (faction counts, travel, demand/spread, town restrictions, construction/costs, daily economy, battle idempotency, cargo unloading, malformed saves).
- Browser smoke (`tests/browser.mjs`): desktop and 390px mobile layout, recruitment, buying, actual 3D grid placement, day advancement, quality, local restore, unfinished battle continuation and result persistence. Zero page errors/no mobile horizontal overflow in the successful run.
- All npm dependencies audited with no reported vulnerabilities at implementation time.
- Browser script uses the npm-distributed Sparticuz Chromium binary. On a minimal Linux image, its bundled `al2023.tar.br` NSS/NSPR libraries may need extracting and adding to `LD_LIBRARY_PATH`. This is test tooling only, never shipped to the browser.

Not included: player-controlled combat, sieges, full diplomacy, procedural world generation, multiplayer, offline service-worker installation, production anticheat, or validated physical-phone frame rates. Low-poly visuals are intentionally built from primitives for this MVP.
