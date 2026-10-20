# Iron Crowns
## Master Game Design Specification, Technical Architecture & Delivery Plan

**Version:** 0.1 — proposed baseline  
**Date:** 7 October 2026  
**Platform:** Android, landscape orientation  
**Audience:** Indie production, design, engineering, art, QA, and publishing  
**Status:** Design proposal, not an implemented feature list

> **Executive decision:** Build an offline-first, single-player sandbox action-strategy RPG using Unity, URP, and a selective ECS/Jobs/Burst battle simulation. Prove readable touch combat and sustained 50-unit performance before expanding to 100–120 active combatants. Ship a compact kingdom sandbox before adding a full generational dynasty simulation.

All numerical balance values, performance budgets, device requirements, staffing, and dates below are **initial targets to validate**, not measured results or promises. The current repository is a documentation baseline with no engine project. Notion and Linear are enabled for this conversation; no workspace pages, tasks, integrations, protection rules, or CI pipelines have been created by this specification.

### Contents
1. [Game overview & core loop](#1-game-overview--core-loop)
2. [Android performance & optimization](#2-android-performance--optimization-strategy)
3. [Mobile controls & UI/UX](#3-mobile-controls--uiux-design)
4. [Core gameplay systems](#4-core-gameplay-systems)
5. [Technical stack & architecture](#5-technical-stack--engine-selection)
6. [Project management & integrated workflow](#6-project-management--integrated-workflow)
7. [Release gates, risks & decisions](#7-release-gates-risks--decisions)

---

# 1. Game Overview & Core Loop

## 1.1 High-level concept

**Player fantasy:** Rise from a landless captain to a ruler by fighting alongside a personally recruited army, protecting trade, negotiating alliances, and governing a fragile realm.

Iron Crowns combines three interconnected layers:

- **Personal action:** Third-person melee, archery, and eventually mounted combat. The commander contributes meaningfully but cannot single-handedly defeat a disciplined army.
- **Army command:** Composition, morale, logistics, terrain, and readable formation orders determine battle outcomes.
- **Political strategy:** Control settlements, distribute fiefs, maintain legitimacy, manage supplies, and choose between conquest and negotiated influence.

Use Mount & Blade II: Bannerlord as a reference for the combination of systems, not as a source of copyrighted assets, code, dialogue, map layouts, faction identities, or UI. Establish an original setting, silhouette language, terminology, and audio identity. “Iron Crowns” is a working title pending naming and trademark review.

**Distinctive design identity:** Campaign supply contracts connect trade and military operations. A captain can gain political leverage by delivering grain during a siege, protecting a merchant corridor, or breaking a rival's supply chain—not only through combat victories.

## 1.2 Audience, sessions, and business assumptions

- Audience: Players who enjoy tactical action and persistent strategy but need mobile-readable controls and interruptible sessions.
- Micro-session: 2–5 minutes for trade, troop upgrades, settlement decisions, or a quest turn-in.
- Battle session: Approximately 5–10 minutes for a field battle; sieges split into roughly 8–12-minute stages.
- Campaign session: 15–30 minutes spanning multiple encounters.
- Business baseline: Premium game with a possible free tutorial/demo and later content expansions. No energy system, paid troop power, forced ads, or real-money loss on defeat.
- Offline play is primary. The campaign does not advance while the app is closed. Analytics and cloud saves are optional, separately consented services.
- Target broad teen fantasy violence, with non-graphic presentation; final rating requires submission to the relevant authorities.

## 1.3 Design pillars and boundaries

| Pillar | Practical rule | Validation question |
|---|---|---|
| A captain, not an action demigod | Skilled play creates local advantage; formations win wars | Can positioning beat higher personal damage? |
| Decisions readable on a phone | A few meaningful orders, clear silhouettes, explicit consequences | Can a new player issue Hold without instruction after the tutorial? |
| A connected sandbox | Losses, trade, recruitment, and politics share persistent state | Does a broken trade route matter to a garrison? |
| Defeat continues the story | Wounds, ransom, captivity, and lost territory replace routine game-over | Can a defeated player recover without grinding for hours? |
| Performance is gameplay | Unit count and fidelity are constrained by sustained device performance | Does the worst battle remain controllable after 20 minutes? |

**Non-goals at launch:** Multiplayer, MMO persistence, seamless continent-scale 3D traversal, fully destructible castles, hundreds of independently animated agents on every device, naval combat, user scripting, and a content library comparable in scale to a large PC production.

## 1.4 Core loop

```text
Overworld travel
  → discover opportunity / assess supplies and risk
  → quest, trade, recruit, negotiate
  → prepare army and choose terrain
  → real-time tactical battle or negotiated resolution
  → casualties, prisoners, loot, reputation, experience
  → replenish, upgrade, invest
  → acquire fiefs and political influence
  → new obligations, rivals, and larger strategic decisions
```

**Nested progression:**

1. Seconds: Read an attack, block, counter, reposition.
2. Minutes: Fix an enemy formation, flank, protect archers, force retreat.
3. Sessions: Complete a contract, improve army composition, build cash reserves.
4. Campaign: Become a mercenary, obtain vassalage, control a fief, contest succession, found a kingdom.

Every stage needs a non-combat alternative where credible: pay a toll, retreat, bribe, trade, negotiate ransom, or accept a political concession. Encounters pause the map and disclose party estimates, relevant terrain, and escape risks before commitment.

## 1.5 Scope ladder

| Stage | Included | Explicitly excluded |
|---|---|---|
| Technical prototype | One arena; 20/50/100/120-agent tests; melee/block; two formations; profiling HUD | Campaign, polished art, full economy |
| Vertical slice | One region, two rival factions, one town, two villages, one castle; one quest chain; 50 active agents; save/load; infantry and archers | Full politics, playable siege, dynasty |
| Launch candidate | Three compact factions; approximately 3 towns, 6 castles, 12 villages; bounded trade economy; recruitment trees; vassalage; fief management; one authored siege layout; cavalry if benchmark gate passes | Multi-generation simulation, complex siege destruction |
| Expansion | More siege layouts, richer diplomacy, generational dynasty, broader regions | Any feature without funded scope and profiling evidence |

These counts are ceilings for planning, not minimum content obligations. Avoid multiplying factions, scenes, weapons, and animations before the slice is fun.

## 1.6 Success criteria

- In a small representative playtest, at least 80% of participants complete movement, blocking, and a formation order without facilitator intervention after onboarding.
- Players can explain why they won or lost through terrain, morale, casualties, and supply—not hidden numerical bonuses.
- A complete travel → recruit → fight → recover loop works offline and survives suspend/resume.
- Launch performance and stability gates in Section 7 are met on the actual minimum device, not only in the editor.

---

# 2. Android Performance & Optimization Strategy

## 2.1 Define “large battle” precisely

An **active combatant** has authoritative movement, health, attack state, and damage eligibility. A **visible combatant** additionally has a rendered representation. A reserve soldier exists in the army roster but does not yet fight. Corpses and ambient crowds are not active combatants.

- Minimum-tier goal: 50 simultaneous active soldiers, both armies combined.
- Standard goal: 80–100 simultaneous active soldiers.
- High-end stretch: 120 simultaneous active soldiers, including supported cavalry; 100+ must be proved with representative equipment and effects.
- The player counts against the combatant cap. Horses are extra animation/physics work, so mounted agents carry an additional cost budget rather than being treated as free.
- Campaign armies may be much larger; reinforcements arrive through controlled, telegraphed reserve waves.

Visible agents must not become harmless merely because they are far away or off camera. Fidelity can change, but damage, morale, and positional consequences remain authoritative. Never silently remove live soldiers to recover frame rate.

## 2.2 Performance tiers and starting budgets

Choose quality through a device capability database plus a short representative benchmark. RAM or marketing chipset names alone are inadequate predictors. Test GPU family, drivers, bandwidth, heat, and sustained load.

| Budget | Minimum / mid-range | Standard | High-end stretch |
|---|---:|---:|---:|
| Provisional physical RAM | 6 GB | 8 GB | 8–12+ GB |
| Sustained frame-rate target | 30 fps | 30 fps | 60 fps only when validated; 30 fallback |
| Active combatant cap | 50 | 80–100 | 120 at 30 fps; 80–100 at 60 fps |
| Internal render scale | 0.65–0.85 | 0.75–1.0 | 0.8–1.0 |
| Total app PSS target in battle | ≤1.2 GB | ≤1.6 GB | ≤2.0 GB |
| GPU-resident textures estimate | ≤256 MB | ≤384 MB | ≤512 MB |
| Submitted triangles / frame | ≤450k | ≤750k | ≤1.2m |
| Draw calls, representative worst view | ≤150 | ≤220 | ≤300 |
| CPU critical path, p95 target | ≤24 ms | ≤24 ms | ≤12 ms at 60 fps |
| GPU time, p95 target | ≤26 ms | ≤26 ms | ≤13 ms at 60 fps |

CPU and GPU work overlap; **do not add their frame times as if all work were serial**. Job synchronization, presentation, and frame pacing must be inspected separately. Memory figures overlap across profilers; use Android PSS as a whole-process measurement rather than summing every tool's category.

Initial 30 fps CPU critical-path allocation: approximately 5 ms simulation, 3 ms navigation and sensing, 4 ms animation preparation, 4 ms rendering submission, 2 ms UI/input, and 6 ms reserve/synchronization. These are diagnostic allocations, not guaranteed independent buckets.

## 2.3 CPU and AI architecture

- Store battle agents in compact ECS components or contiguous arrays. Use Burst-compiled jobs for broadphase, steering, target scoring, morale accumulation, and formation-slot evaluation.
- Avoid one expensive `Update`, Animator, NavMeshAgent, and Rigidbody stack per soldier.
- Partition the battlefield into a uniform spatial grid. Query neighboring cells rather than all agents against all other agents.
- Run the authoritative battle simulation at a fixed 30 Hz. Render interpolated poses at 30 or 60 fps; player camera/input sampling occurs every rendered frame.
- Stagger strategic decisions: commanders at 2–5 Hz, formation decisions at 5–10 Hz, local target selection at 5–10 Hz, and close-contact collision/movement at 30 Hz.
- Low-frequency sensing must not delay an already active attack's collision checks. Interpolate presentation without inventing hits between simulation states.
- Use event-driven reevaluation for deaths, broken formations, changed orders, breached gates, and nearby threats.
- Budget path requests per tick, pool buffers, and avoid runtime LINQ or managed allocations in steady-state combat.

**Navigation:** Prebake terrain navigation. Plan paths at formation level; distribute slots and local steering to agents. Use shared corridors or flow fields where useful. Reserve individual pathfinding for stranded agents and obstacle recovery. Gates, ladders, and breaches are explicit portals with queue capacity and fallback behavior. Do not recompute a full path for every troop every frame.

**Combat collision:** Swept weapon segments/capsules against simplified hurt volumes, with spatial broadphase and per-swing hit deduplication. Projectiles use swept queries/substeps where required to avoid tunneling. Stable combat IDs prevent the same projectile or swing applying damage repeatedly. Do not run full rigid-body weapon collisions for all agents.

## 2.4 Animation, LOD, and rendering

**Prototype the actual render path early.** ECS simulation does not automatically make skinned characters cheap. Compare conventional skinned meshes with aggressively managed Animator updates against GPU-skinned/vertex-animation approaches for distant troops. Validate URP, chosen Entities packages, rig features, shadows, and hit-pose accuracy together before adopting a specialist renderer.

| LOD | Initial character mesh budget | Animation approach | Intended use |
|---|---:|---|---|
| LOD0 | 6–10k triangles, 35–55 deform bones | Full nearby pose and selected IK | Player and nearest soldiers |
| LOD1 | 2–4k triangles, 20–35 bones | Reduced update frequency with interpolation | Main formation mass |
| LOD2 | 500–1,200 triangles, 10–20 bones or validated GPU path | Shared/coarse pose sampling | Distant soldiers |
| LOD3 | Very low mesh / validated impostor | Minimal presentation | Background, not close combat |

- Select LOD by projected screen size, with hysteresis to avoid popping. Distances are tuned per camera and device.
- Count armor, weapons, shields, and mounts in the complete unit budget.
- Pool modular gear variants and share materials; use atlases, palette masks, or compatible texture arrays. Avoid unique materials per soldier.
- GPU instancing is straightforward for repeated static props, but animated characters need a verified compatible path. SRP Batcher lowers state-change cost; it does not magically merge all geometry into one draw call.
- Bake lighting for fixed battle scenes. Use one main directional light, restricted shadow distance, low cascade counts, and minimal additional realtime lights.
- Low tier: nearest-character shadows only or simplified contact/blob shadows. Disable costly screen-space effects, depth of field, volumetrics, and motion blur.
- Use simple opaque URP shaders; avoid layered transparency, excessive shader variants, large alpha-tested foliage coverage, and expensive per-pixel armor effects.
- Prefer ASTC on compatible targets; validate an ETC2-compatible fallback/package strategy. Generate mipmaps and stream appropriately. Limit 4K textures to exceptional, justified cases.
- Frustum and distance culling always apply. Baked occlusion is useful inside towns and castles; an open battlefield may offer little occlusion benefit. Benchmark its CPU/memory cost before enabling it globally.
- Limit ragdolls to a small nearby pool, then freeze or replace corpses. Initial caps: 4 live ragdolls and 20 visible corpses on minimum tier. Corpses may fade; living troops may not.
- Pool projectiles, dust, hit sparks, decals, and audio emitters. Cap particles and overdraw during cavalry charges and siege bottlenecks.

## 2.5 Dynamic scaling and thermal response

1. Sample CPU/GPU frame times using rolling windows; observe thermal status where supported.
2. Reduce cosmetic particles, shadow distance, and optional effects first.
3. Adjust render scale in small steps within tier bounds when GPU-bound; lowering resolution will not solve CPU-bound AI.
4. Reduce distant animation and discretionary sensing frequency within correctness constraints.
5. If a validated 60 fps mode cannot sustain its budget, switch to a paced 30 fps mode with clear settings feedback.
6. Reassess battle cap before the **next** battle, or delay future reserve waves symmetrically. Do not change existing active combatants or bias one army mid-fight.

Use a degradation window around 5–10 seconds and a longer recovery window around 30–60 seconds, with hysteresis. Thermal warnings may trigger faster reductions. Device state is advisory; do not try to override operating-system thermal protections. The user can select Battery, Balanced, or Performance mode; none bypass safety limits.

**Reserve fairness:** Allocate slots proportionally to committed forces, subject to a documented minimum share and cost budget. Spawn only at safe reinforcement zones, out of immediate player view where possible, with warnings and equal rules. Campaign auto-resolve uses the entire committed force, not the chosen graphics cap. Document that different battlefield caps can affect tactics and test for unacceptable outcome bias.

## 2.6 Profiling and evidence

- Tools: Unity Profiler/Profile Analyzer and Memory Profiler; Android GPU Inspector where supported; Perfetto and Android memory/thermal diagnostics; device-native vendor tooling when useful.
- Matrix: At least six real devices spanning Adreno and Mali GPUs, minimum/mid/high performance, supported OS versions, screen aspect ratios, and known problematic drivers.
- Scenarios: 50/100/120-agent melee pileup, arrows crossing a formation, cavalry charge, castle gate congestion, town entry, large inventory, save/load, and app resume.
- Run release-like IL2CPP builds for at least 20 minutes per thermal scenario, plus longer battery soaks. Editor numbers are not release evidence.
- Record build SHA, content version, device model, OS/driver, graphics API, quality, battery state, room conditions, peak PSS, thermal state, frame-time percentiles, and hitch counts.
- Target no managed allocation in steady-state combat hot paths. Investigate GC spikes and resource-upload hitches separately from mean fps.
- Example regression gates: No unexplained >10% p95 frame-time or peak-memory regression on a fixed baseline; 30 fps mode p95 presented frame interval ≤36 ms and p99 ≤50 ms during the benchmark, excluding explicitly measured loading screens.

---

# 3. Mobile Controls & UI/UX Design

## 3.1 Combat control layout

Landscape, thumb-first interface with resizable and movable controls. Essential touch targets should be at least approximately 48 dp after density conversion, with larger primary actions. Respect notches, system gesture regions, and safe areas.

| Input | Default behavior | Accessibility / alternative |
|---|---|---|
| Left floating stick | Move relative to camera | Fixed stick, sensitivity/dead-zone settings |
| Drag right-side camera area | Orbit camera | Invert axes, turn sensitivity, optional gyro |
| Tap attack | Contextual swing using selected direction | Assisted directional attack mode |
| Hold attack, drag, release | Preview left/right/overhead/thrust, then attack | Separate direction selector; no mandatory swipes |
| Hold block | Raise shield or directional weapon guard | Toggle block and auto-facing assistance |
| Tap dodge/step | Short stamina-cost reposition | Larger separate button; no mandatory double-tap |
| Tap target icon | Soft target focus | Free camera and manual targeting always available |
| Tap command button | Open formation command overlay | Persistent quick-order row |

Attack direction uses the attack control's local drag, not a swipe anywhere on screen. A touch beginning in a control remains owned by it until release/cancel, preventing attack gestures from moving the camera. Inventory and command overlays suppress underlying combat actions. Handle multitouch, dropped touch events, palm contact, and Android interruption explicitly.

**Melee model:** Three readable attack phases—wind-up, active, recovery. Starting windows: 180–350 ms wind-up and 250–500 ms recovery, varying by weapon. A roughly 100–150 ms input buffer improves responsiveness. Directional blocking rewards intent; assisted blocking provides a viable mobile default with a smaller precision advantage than manual play. Stamina prevents endless attacks and blocks but never disables basic movement.

Avoid competitive claims about frame-perfect timings until end-to-end latency is measured. Target p95 touch-to-visible-response below 120 ms on the minimum supported device, including the input/render pipeline.

## 3.2 Archery and mounted combat

- Tap ranged mode, hold draw, drag the aiming area, release the fire control to shoot; provide a visible cancel zone/button to avoid accidental firing.
- Reticle displays draw state, dispersion, and blocked line of fire. Projectile drop is readable, with tutorial practice targets.
- Optional low-strength aim friction helps thumb control. Never snap through cover or auto-lead hidden targets.
- Gyro is optional fine aiming, not required. Sensitivity and handedness settings persist per profile.
- Firing from horseback adds accuracy penalties based on speed and skill. Cavalry initially uses assisted steering, a clear speed control, and automatic obstacle slowdown rather than a separate complex driving interface.
- If mounted player combat fails readability or performance gates, launch with AI cavalry only or defer cavalry entirely; do not compromise core infantry combat to preserve scope.

## 3.3 Tactical battle interface

A command button opens an overlay and pauses the offline battle by default. An optional experienced-player mode slows time instead. No orders execute until confirmation; the same rule applies consistently to enemy simulation.

**Order flow:**
1. Select Infantry, Archers, Cavalry, or All from persistent formation chips.
2. Tap a quick order or choose a ground position on a tactical inset map.
3. For placement, drag an orientation arrow; optional width handles preview frontage.
4. Confirm; show a banner, formation destination, and audible acknowledgement.

| Order | Behavior | Tactical cost / feedback |
|---|---|---|
| Hold | Move to the specified location and defend slots | Agents may defend locally but do not pursue distant enemies |
| Advance | Maintain cohesion while closing on an enemy | Slower than an unstructured rush |
| Charge | Break positional discipline and engage | Faster commitment; vulnerable to counters |
| Shield Wall | Tight formation, frontal protection | Reduced speed; exposed flanks and rear |
| Loose | Increase spacing | Reduces missile clustering; weaker in melee |
| Follow | Formation trails the player | Must not trap the player in collision |
| Focus / Fire at Will | Prioritize a target group or use available targets | Show line-of-fire and ammo limits |
| Retreat | Withdraw toward an exit; assess pursuit losses | Confirmation and clear consequences |

All gestures have button alternatives. Invalid destinations show a reason and nearby valid placement. The formation HUD exposes strength, morale, ammunition, engaged status, and order. Color is reinforced with shapes and icons. Enemy information depends on visibility/scouting, not omniscient labels.

## 3.4 Overworld and management UI

- Tap a destination to preview route, travel time, supply consumption, and known danger; tap Travel to commit. Pinch to zoom; drag to pan. Gestures never automatically dispatch the army.
- Time controls: Pause, 1×, 2×, 4×. Threats, quests, depleted supplies, and approaching enemies pause travel according to user preferences.
- Inventory: Side-by-side player/merchant lists, category tabs, compare panel, bulk quantity buttons, capacity/coin projection, and final transaction confirmation.
- Troop screen: Role tabs and expandable upgrade trees. Show total upgrade cost, recurring wage change, mount/equipment requirements, and projected food days.
- Diplomacy: Relationship cards summarize attitude, leverage, current agreements, and the exact effect of a proposed action. Avoid burying essential rules in prose.
- Fief screen: A compact dashboard—food, security, loyalty, prosperity, garrison, net income—with trends and causal tooltips.
- Long lists use virtualization. No management screen should spawn UI objects for every item every frame.

## 3.5 Accessibility and onboarding

- Left-handed mirroring; independently movable action buttons; subtitle sizing; high-contrast text; color-vision-safe markers; reduced shake/flashes; adjustable haptics; hold/toggle alternatives.
- Avoid tiny nested menus, drag-only sorting, audio-only warnings, and time-limited dialogue decisions.
- Tutorials teach one action at a time through a training contract: movement → block → attack → recruit → Hold → flank → trade → recover.
- Provide a glossary, repeatable training arena, tooltips, and contextual assistance that can be dismissed permanently.
- Localize through stable string IDs and plural rules. Budget for expanded text and test right-to-left support if included in the launch language scope.
- Handle back navigation consistently: close subpanel → return to previous screen → pause/exit confirmation. Never discard pending purchases without warning.

---

# 4. Core Gameplay Systems

## 4.1 Overworld map and time

Use a stylized 3D map with settlements and moving party tokens; enter separate battle scenes for encounters. Strategic roads and terrain form a weighted navigation graph, with local free movement only where justified.

**Starting party-speed model:**

```text
speed = clamp(baseSpeed × terrain × road × weather × burden
              × fatigue × cohesion × mountedShare × scouting, minSpeed, maxSpeed)
```

All factors are dimensionless multipliers. Begin with base speed 4 map units/hour, road 1.15, forest 0.8, mountain 0.65, heavy burden 0.65–1.0, and mounted share 1.0–1.2. Normalize units to actual map scale before balancing. Terrain penalties apply to a route segment; do not multiply mutually exclusive terrain types together.

- Speed and scouting previews explain modifiers. Pack animals increase cargo capacity without converting foot soldiers into cavalry.
- Strategic simulation uses fixed game-time ticks and batched daily settlement updates. Resolve parties chronologically so higher time acceleration cannot skip encounters.
- During a battle the campaign clock is paused; commit a defined encounter duration afterward. This prevents unbounded offscreen simulation during action gameplay.
- Fog of war distinguishes unexplored terrain, last-known parties, and currently observed threats.

**Locations:**
- Villages produce food/raw materials and offer recruits; raids reduce output and relations, with a recovery path.
- Towns host markets, workshops, recruitment, quests, and political audiences.
- Castles control defensible routes, storage, military recruitment, and garrisons.
- Bandit hideouts increase local danger and attack caravans. Clearing one improves security temporarily; respawn requires suitable regional conditions, cooldown, and no visible pop-in.
- Camps provide rest and treatment but create ambush risk if scouting/security is poor.

## 4.2 Combat rules and encounter resolution

**Agent attributes:** Health, stamina, morale, armor by region, weapon proficiency, movement speed, attack/recovery timings, equipment, role, and formation membership.

Initial damage model:

```text
raw = weaponDamage × attackQuality × relativeSpeedFactor × hitRegionFactor
mitigated = raw × armorConstant / (armorConstant + effectiveArmor)
finalDamage = clamp(mitigated, configuredMinimum, configuredMaximum)
```

Effective armor depends on damage type and penetration. Bound relative-speed bonuses so mounts do not create arbitrary one-hit damage spikes. Shield facing and coverage are resolved before armor. Use a documented friendly-fire policy: baseline allies block melee movement and shots, but ranged friendly damage is reduced in default difficulty; simulation and player projectiles follow the same policy.

- Nearby casualties, flanking, command loss, and exhaustion reduce morale; leadership, reserves, secure flanks, and successful charges restore confidence.
- States: Steady → Shaken → Routing. Routing units stop ordinary attacks and flee to a valid exit; allow recovery only under explicit leadership/safety conditions.
- The player being incapacitated opens an overhead command/spectate mode if allied command remains; it does not instantly end a winning battle.
- Victory: Enemy rout, capture, destruction, or scenario objective. Retreat preserves survivors with pursuit risk computed from the actual exit situation.
- Outcome records distinguish dead, wounded, captured, escaped, and surviving soldiers. Rewards and roster changes commit exactly once using an encounter ID.
- Auto-resolve considers equipment, troop roles, numbers, morale, terrain, supplies, and seeded randomness. It must be tested against real battles to avoid systematically destroying elite troops or becoming a zero-risk optimal strategy.

## 4.3 Economy and trade

Start with approximately 12 commodities across food, raw materials, manufactured goods, and military supplies. Each town stores stock, production, consumption, target reserves, and recent transaction history.

```text
scarcity = clamp((targetStock - stock) / max(targetStock, 1), -1, 2)
referencePrice = clamp(basePrice × (1 + scarcityCoefficient × scarcity)
                       × securityFactor × eventFactor, floorPrice, ceilingPrice)
playerBuy = referencePrice × (1 + spread + applicableTax)
playerSell = referencePrice × (1 - spread - applicableFee)
```

Starting spread 8–15%; scarcity coefficient around 0.35. Ensure fees remain valid and quantities cannot produce negative money or stock. Bulk transactions integrate marginal stock/price changes rather than applying the first unit's quote to unlimited quantity. Show total cost before confirming.

**Daily model:** Production adds inventory; consumption removes it; caravans redistribute surplus; scarcity affects price; insecurity reduces production and route reliability. Bound shortage damage so one early raid cannot permanently destroy a faction's economy.

- Caravans are actual strategic parties with cargo, escorts, operating costs, and a destination utility score based on expected profit, travel time, and risk.
- Workshops consume explicit inputs and create outputs. Profit includes wages, transport, and taxation. Capacity and market demand prevent unlimited compounding.
- Troop wages are paid daily. Garrison upkeep adds food and local staffing costs; it is not a free storage loophole.
- Money faucets: Contracts, production value, carefully bounded NPC demand. Sinks: Wages, upkeep, repairs, upgrades, taxes, construction, and losses.
- Track aggregate currency, commodity flows, starvation, workshop profitability, and median player cash across seeded simulation runs.

**Illustrative early party:** 20 recruits at 2 coins/day plus 10 trained troops at 5 costs 90 coins/day before food. An approximately 300-coin contract funds only a few days, making supply planning visible. Validate this against real play speed; never require tedious repeated low-value trades to recover from one defeat.

Exploit tests: Buy/sell round trips, cross-market infinite arbitrage with no transport risk, free captive recruitment/resale, duplicate quest payouts, negative stacks, integer overflow, caravan teleportation, and saving during incomplete transactions.

## 4.4 Recruitment and progression

Recruitment depends on settlement population/recovery, faction relationship, security, and available military infrastructure. Recruitment pools replenish on campaign time, not app reopen.

```text
Recruit
 ├─ Footman → Spearman → Veteran Spearman / Shield Guard
 ├─ Skirmisher → Archer → Longbow Guard / Crossbow Specialist
 └─ Mounted Scout → Light Cavalry → Lancer / Mounted Skirmisher
```

This is a role framework; launch factions should share underlying systems and selectively vary branches rather than requiring completely unique animation sets.

| Tier | Upgrade XP, initial | Upgrade fee | Wage / day | Purpose |
|---|---:|---:|---:|---|
| Recruit | — | Recruitment fee 10 | 2 | Affordable manpower |
| Trained | 100 | 25 | 5 | Dependable role behavior |
| Veteran | 250 | 75 | 10 | Strong specialization |
| Elite | 500 | 180 plus equipment where required | 18 | Scarce, expensive force multiplier |

XP is earned from participation, surviving risk, objectives, and training—not exclusively last hits. Upgrades require an explicit confirmation and show the wage impact. Mounted upgrades consume an appropriate mount. Wounded troops occupy capacity and require treatment; permanently lost elites create decisions without making recovery hopeless.

Player development uses weapon, leadership, scouting, medicine, trade, and stewardship skills. Avoid dozens of microscopic passive bonuses. Each perk should change a decision or provide a clearly visible capability. Party size grows with leadership and reputation, but must remain compatible with reserve-wave battle limits.

## 4.5 Factions, vassalage, and politics

Each faction has a ruler, treasury, war goals, food security, military capacity, laws, and relationships. Each noble has personal loyalty, ambition, family/house identity, and fief interests.

**Career stages:** Independent captain → paid mercenary contract → sworn vassal → influential house → independent claimant/ruler.

- Mercenary contracts define duration, pay, enemy obligations, and penalties for early departure.
- Vassalage grants protection and political rights in exchange for levy, taxes, and military obligations.
- Fief awards use transparent scoring: contribution, claim, loyalty, existing holdings, and political bargaining. Show why the player did or did not receive a fief.
- Diplomacy includes peace, war, tribute, prisoner exchange, trade access, and bounded non-aggression agreements. Cooldowns and war exhaustion discourage constant flip-flopping.
- Faction AI selects strategic goals periodically, allocates a limited campaign budget, and evaluates supply before besieging. It cannot conjure armies or funds to counter the player unless an explicit difficulty modifier is disclosed.
- Prevent runaway conquest through logistics, unrest, defense costs, and political opposition—not invisible arbitrary rubber-banding.

## 4.6 Fief management and sieges

Fief statistics: Food reserves, loyalty, security, prosperity, tax burden, construction progress, and garrison readiness. Buildings unlock or improve bounded capabilities; only one major construction project runs at a time initially.

- High taxes improve short-term income but lower loyalty and growth.
- Overlarge garrisons drain supplies and money. Undermanned fiefs invite raids and unrest.
- Governors modify a few clear outcomes; launch implementation uses predefined policies instead of a complex citizen simulation.
- Siege preparation consumes days, provisions, and engineering resources. Defenders can sortie; relief armies may interrupt on the campaign layer before the assault begins.

**Mobile siege implementation:** One authored castle layout, fixed wall geometry, destructible gate state, bounded ladder/breach entry points, and stage objectives. Avoid voxel destruction and runtime global navmesh rebuilding.

1. Prepare: Choose supplies and assault approach.
2. Approach: Reach a gate/ladder while suppressing defenders.
3. Breach: Capture a foothold; spawn reserves using the same fairness rules as field battles.
4. Courtyard: Capture an objective or force a rout.

Portal occupancy, queue behavior, retreat paths, and stranded defenders require dedicated stress tests. Checkpoint between stages. Siege content only enters launch scope after the field battle and bottleneck benchmarks pass.

## 4.7 Dynasty and persistence

**Launch-lite:** Named houses, political kinship, succession candidates, and a designated heir represented through events. Calendar scale must allow succession to be meaningful without requiring hundreds of real-world hours. Do not promise simulated child development or a complete marriage market at launch.

**Later dynasty expansion:** Adult marriage alliances, inheritance laws, generational traits, rival claims, aging, death, regency, and playable succession. Design it as a separate simulation module with migrations for existing saves.

**Save contract:**
- Autosave before battle, after committed results, and after major campaign transactions; maintain rotating recovery slots and explicit manual saves outside unsafe transition moments.
- Pause and checkpoint on Android backgrounding; do not assume the OS will allow a long final save callback.
- Store periodic stable checkpoints. For interrupted battles, restore a validated resumable snapshot or offer an explicitly disclosed restart from the pre-battle checkpoint. Launch may use restart if exact mid-battle serialization is too costly.
- Version the schema; support migrations and preserve the prior valid save. Persist stable IDs and numeric state, never runtime pointers or scene object references.

---

# 5. Technical Stack & Engine Selection

## 5.1 Unity versus Unreal

| Criterion | Unity + URP + selective DOTS | Unreal Engine 5 + Mass Entity |
|---|---|---|
| Indie iteration | C# tooling; accessible mobile workflows | Strong C++/Blueprint pipeline; heavier build/editor workflows |
| Mobile rendering | URP supports a deliberately lean pipeline | Use a validated mobile renderer; desktop feature defaults are not a mobile strategy |
| Crowd simulation | Entities, Jobs, and Burst support data-oriented work | Mass processors/fragments support data-oriented work |
| Character presentation | ECS rendering, rigging, and hybrid boundaries require prototyping | Mass representation, animation, and gameplay integration require prototyping |
| Combat/navigation | Custom systems still required | Custom systems still required; Mass is not a complete battle solution |
| Team fit | Recommended for a small C#-capable Android team | Viable for a team already expert in Unreal mobile/C++ |
| Risk | Package compatibility and hybrid synchronization | Complexity, package size, shader/build cost, mobile feature constraints |

**Recommendation:** Select a supported Unity LTS release after a compatibility spike; pin exact editor, URP, Entities, Burst, Collections, Input System, and Addressables versions in the repository. Use IL2CPP and ARM64. Do not chase engine upgrades during production without an explicit migration branch/PR plan and benchmark comparison.

No particular latest engine version, Android target API, distribution policy, pricing, or licensing term is asserted here. Confirm these against official requirements when initializing the project and again before release. Proposed Android minimum is Android 10/API 29, conditional on audience/device research; the Play target API must meet the submission-time requirement and is distinct from the minimum OS.

Use Vulkan as the preferred graphics API only on validated device/driver combinations. Validate OpenGL ES 3 fallback if it is supported by the selected engine/packages and worth its test cost. A feature requiring Vulkan must not be silently used in the fallback path. Maintain a GPU/driver denylist and safe quality defaults.

## 5.2 Layered architecture

```text
Presentation: UGUI/TMP UI, camera, audio, effects, character views
                  ↓ commands          ↑ read-only state/events
Application: session flow, transactions, save orchestration, encounters
                  ↓
Domain: campaign / economy / diplomacy / progression / battle rules
                  ↓
Simulation adapters: ECS systems, jobs, nav queries, physics queries
                  ↓
Infrastructure: storage, assets, platform lifecycle, telemetry, build config
```

Use Unity Input System for actions; a UGUI/TextMeshPro baseline is pragmatic for touch-heavy runtime UI. Use ScriptableObjects for authoring static definitions, then bake validated immutable data for runtime. Keep rules and tests as engine-independent C# where feasible.

**Ownership boundaries:** Campaign state is the source of truth outside battle. Battle simulation owns battle state during an encounter. Presentation observes and submits commands but never directly changes money, health, or troop rosters.

Suggested modules/assembly definitions:
- `Core`: IDs, clocks, math helpers, random streams, command/result contracts.
- `Campaign`: Parties, routing, encounter generation, calendar.
- `Economy`, `Politics`, `Progression`: Independent domain subsystems.
- `Battle.Domain`: Rules and encounter input/output data.
- `Battle.Simulation`: ECS components, systems, navigation, hit resolution.
- `Battle.Presentation`: Visual proxies, animation, camera, effects.
- `UI`: View models/presenters and touch navigation.
- `Persistence`: DTOs, migrations, snapshots, atomic writing.
- `Platform`: Android lifecycle, quality/thermal integration, permissions.
- `Tools` and `Tests`: Importers, validators, headless simulation, fixtures.

Dependencies point inward toward contracts/domain. Avoid global service locators, a monolithic GameManager, and bidirectional ECS/GameObject authority. Use explicit composition roots per scene/session.

## 5.3 ECS battle pipeline

**Core components:** `UnitId`, `FactionId`, `FormationId`, `TransformState`, `Velocity`, `Health`, `Stamina`, `Morale`, `EquipmentRef`, `AttackState`, `TargetRef`, `NavigationState`, and `SimulationLOD`. Visual LOD is separate from gameplay importance.

**Ordered tick:**
1. Consume player/commander commands stamped with the simulation tick.
2. Update formation goals and valid navigation corridors.
3. Update spatial grid and stagger sensing/target selection.
4. Compute steering, integrate movement, resolve local separation.
5. Advance attacks; sweep projectiles/weapons; produce hit events.
6. Resolve damage, deaths, morale, and objective changes in a stable order.
7. Apply queued structural changes at a controlled synchronization point.
8. Publish read-only snapshots/events for interpolated presentation.

Job dependency graphs and reusable native containers avoid unnecessary main-thread completion. Pool spawn/despawn operations and use command buffers for structural changes. Instrument each system with profiler markers before optimization.

Use seeded random streams for repeatable rule tests. Do **not** promise bitwise determinism across ARM devices, floating-point implementations, physics engines, or parallel execution. Persist full authoritative snapshots; recorded commands alone are insufficient for guaranteed cross-device replays.

## 5.4 Encounter and data contracts

```text
EncounterRequest:
  encounterId, campaignRevision, sceneId, rulesVersion, seed
  participatingParties[], committedTroopStacks[], equipmentDefinitionIds[]
  terrainTags[], weather, morale, supplies, deploymentLimits

EncounterResult:
  encounterId, sourceCampaignRevision, outcome, elapsedGameTime
  survivors[], wounded[], dead[], prisoners[], escaped[]
  itemTransfers[], objectiveResults[], experienceAwards[]
```

Validate conservation: Every committed soldier has exactly one resulting disposition; prisoners and inventory cannot duplicate; result matches the expected campaign revision. Persist the committed encounter ID so retrying a transition cannot grant loot twice.

Static definitions require stable machine IDs, schema versions, localization keys, and references validated at import. Balance tables export through a reviewable JSON/CSV pipeline. Runtime builds never call Notion to obtain weapon damage or troop costs.

## 5.5 Persistence, assets, and lifecycle

- Local save envelope includes schema version, build/content version, timestamp, checksum, campaign seed, and payload. A checksum detects corruption; it is not anti-cheat or encryption.
- Write to a temporary file in the same storage location, flush using supported APIs, validate, then replace atomically where supported. Keep a last-known-good backup and test abrupt termination during every step.
- Cloud saves, if added, use revision metadata and explicit conflict choice. Never silently overwrite a longer local campaign with a stale cloud copy.
- Addressables separate boot, shared troops, region scenes, audio, and optional content. Validate dependency duplication and unload handles at scene boundaries.
- Use small bootstrap scenes and loading screens to avoid peak memory from holding two full battles simultaneously. Track shader warm-up and asset upload cost.
- Provisional installed-content budget: ≤1.5 GB for launch. Packaging/download limits and Play Asset Delivery choices must be checked against current store requirements; installed size and AAB download size are different metrics.
- Permissions should be minimal; no contacts/location access. Store credentials, signing keys, and service secrets outside the project and client binary.

## 5.6 Testing and delivery stack

- Unit/EditMode tests: Prices, stock conservation, upgrades, diplomacy thresholds, troop accounting, save migrations.
- PlayMode tests: Control ownership, scene transitions, command application, battle outcomes, pause/resume.
- Simulation tests: Hundreds of seeded campaigns; detect economic collapse, infinite wars, negative resources, stalled succession, and unreachable objectives.
- Device automation/manual QA: Touch controls, GPU/driver behavior, thermals, audio interruption, background process kill, install/update, offline launch, and low storage.
- Telemetry, if consented: Aggregate frame-time distributions, crashes, control/tutorial completion, defeat causes, economy balance. Avoid collecting unnecessary personal information; define retention/deletion rules before launch.
- Toolchain: Blender for models, an agreed texture-authoring tool, Unity Test Framework, Android diagnostics, GitHub Actions or equivalent runners, and a licensed Unity build environment. Audio middleware is optional; use built-in audio unless profiling or production needs justify integration cost.

---

# 6. Project Management & Integrated Workflow

## 6.1 Sources of truth

| System | Authoritative responsibility | Must not become |
|---|---|---|
| Notion | Design intent, lore, approved specifications, meeting decisions, art standards | A duplicate sprint tracker or runtime database |
| Linear | Planned work, ownership, priority, dependencies, bugs, cycle progress | A separate copy of every design document |
| GitHub | Code, import settings, executable data, tests, build recipes, review history | Storage for disposable build artifacts |

This Markdown document is the initial portable baseline. If adopted in Notion, declare Notion the editable design master and keep dated approved exports in GitHub; alternatively retain Markdown as master and make Notion an index. Never let both be silently editable sources of the same specification.

## 6.2 Notion architecture

Create an **Iron Crowns HQ** page with:
- Start Here: Vision, scope ladder, milestone dashboard, links, owners.
- GDD: One database of modular specifications rather than one unmaintainable page.
- Lore & World Wiki: Factions, regions, characters, glossary, timelines.
- Balance Lab: Authoring tables, hypotheses, playtest results, change history.
- Art & Audio Bible: Visual targets, asset budgets, export conventions, licensing.
- Production: Meeting decisions, risks, playtests, release checklists.
- Architecture: ADRs and links to implementation documentation in GitHub.

**Suggested database schemas:**

| Database | Key properties |
|---|---|
| Specifications | Spec ID, title, system, owner, Draft/Review/Approved/Superseded, version, milestone, acceptance summary, related specs, Linear project/issue URL, implementation URL |
| Lore | Lore ID, type, faction/region relations, canonical status, author, spoiler level, localization status |
| Balance tables | Stable definition ID, category, numeric fields with units, design rationale, approved version, export status |
| Assets | Asset ID, category, owner, concept/model/rig/texture/in-engine/approved status, LOD budgets, material count, source path, license, Linear URL |
| Decisions / ADR index | Decision ID, context, alternatives, outcome, owner, date, supersedes, GitHub ADR URL |
| Risks & playtests | Owner, severity, probability, mitigation, evidence, linked milestone, next review |

**Specification template:** Problem → player story → rules/formulas → states and transitions → UX → content requirements → performance budget → edge cases → analytics → acceptance criteria → dependencies → open questions → decision history.

**Art guideline template:** Units in meters; agreed forward/up conversion; applied transforms; naming; pivot; collision proxy; UV rules; rig/bone budget; LODs; texture size/compression; shader/material budget; mobile screenshots; source attribution; validation report. Include animation root-motion policy and mount/rider attachment conventions.

Relations connect troops to equipment and factions, but exported numeric content must pass a schema validator. Restrict canonical lore and approved-balance edits to appropriate owners. Archive superseded designs rather than deleting their decision history.

## 6.3 Linear organization and two-week cycles

For a small team, start with one team and projects for Combat, Campaign & Economy, UI/UX, Content Pipeline, Android Performance, and Release. Avoid separate teams for every discipline until coordination demands it.

**Workflow:** Triage → Backlog → Ready → In Progress → In Review → QA → Done; use Canceled for abandoned work. Model Blocked as a label/relation while preserving the work state. Configure states in the actual team; IDs and defaults must be discovered, not assumed.

- Labels: `feature`, `bug`, `tech-debt`, `spike`, `content`; system labels; `android`, `performance`, `accessibility`, `save-risk`.
- Priority: P0 urgent crash/data loss, P1 milestone blocker, P2 normal committed work, P3 improvement. Keep bug severity separate from scheduling priority.
- Estimate relative complexity (1/2/3/5/8); split an 8-point issue unless it is a bounded spike. Points are not hours.
- Work in progress: Approximately one active implementation item per contributor plus a bounded review responsibility.
- Reserve roughly 20% of cycle capacity for defects, integration, and performance. Replan from actual throughput, not assumed velocity.

**Example early cycles, dependent on team size:**

| Cycle | Outcome | Exit evidence |
|---|---|---|
| 1 | Android toolchain, device harness, movement/camera | Reproducible ARM64 build and baseline capture |
| 2 | Melee/block and 20-agent battle | Touch latency test, hit tests, no recurring combat allocations |
| 3 | Formations and 50-agent stress scene | Minimum-device sustained benchmark, command usability test |
| 4 | Map travel, recruitment, simple trade | Complete offline loop and validated transaction tests |
| 5 | Save/load, recovery, quest chain, UI polish | Suspend/kill recovery, full slice playtest |
| 6 | Slice hardening and 100-agent feasibility | Go/no-go report; content expansion only after review |

These cycles establish a slice, not a promise of a finished game in twelve weeks.

**Definition of Ready:** Approved spec reference; player outcome; measurable acceptance tests; dependencies resolved or identified; design/art inputs available; performance/save risks noted; small enough for one cycle.

**Definition of Done:** Reviewed and merged; automated tests pass; content/import validation passes; QA acceptance on required devices; no unapproved performance regression; migration tested where relevant; documentation updated; accessible controls checked; verified build linked. Merge alone is not Done when device QA remains outstanding.

**Example issue (illustrative identifier, not an existing workspace issue):**

```text
IC-123 — Place infantry in Hold formation from touch command overlay
Spec: GDD-CMD-001 v0.3
Outcome: A player can select infantry and place a facing formation without
         accidentally moving the camera or issuing an attack.
Acceptance:
- Tap, placement, orientation, and confirm work on the minimum test device.
- Cancel causes no order or gameplay action.
- Invalid ground provides a reason and a valid alternative.
- Formation reaches reachable slots; blocked slots visibly degrade/replan.
- p95 command acknowledgement <150 ms excluding intentional pause.
- 50-agent benchmark remains within approved baseline thresholds.
Tests: input ownership, unreachable destination, casualties during movement.
Evidence: QA build, video, profiler capture, linked PR.
```

Bug template: Build SHA/version, device/OS/API, reproduction steps, expected/actual behavior, frequency, save attachment if safe, logs/video, severity, workaround, regression range. Never attach player identifiers or secrets to public issues.

## 6.4 GitHub repository structure and LFS strategy

Proposed structure; these engine directories are not yet created:

```text
iron-crowns/
  README.md
  docs/
    MASTER_GDD_AND_TECHNICAL_PLAN.md
    adr/                     # numbered architecture decisions
    releases/                # approved design exports and release notes
  Game/
    Assets/IronCrowns/
      Runtime/{Core,Campaign,Economy,Politics,Battle,UI,Platform}/
      Editor/
      Content/{Definitions,Prefabs,Scenes,Art,Audio}/
      Tests/{EditMode,PlayMode}/
    Packages/{manifest.json,packages-lock.json}
    ProjectSettings/
  ArtSource/                 # selected canonical source assets via LFS
  Tools/{ContentValidation,Build,Simulation}/
  .github/{workflows,PULL_REQUEST_TEMPLATE.md,CODEOWNERS}
  .gitattributes
  .gitignore
```

**Unity rules:** Force Text serialization, Visible Meta Files, commit every required `.meta` with its asset, pin packages and editor version, and use scene/prefab ownership to reduce conflicts. Use UnityYAMLMerge where applicable, but manually validate semantic merges in the editor.

**LFS candidates:** `.fbx`, `.blend`, `.psd`, `.tga`, `.exr`, large `.png`/`.tif`, `.wav`, `.ogg`, and animation/source binaries. Use LFS locking for non-mergeable files actively edited by multiple artists. Do not put ordinary C#, JSON, CSV, `.meta`, `.unity`, or text-serialized `.prefab` files into LFS indiscriminately.

Example setup for maintainers, to tailor before use:

```bash
git lfs install
git lfs track "*.fbx" "*.blend" "*.psd" "*.tga" "*.exr" "*.wav" "*.ogg"
# Add selected large texture extensions or paths after checking storage policy.
git add .gitattributes
```

Track attributes before adding assets; otherwise a future history migration requires coordinated maintenance. Enforce asset-size limits and LFS-pointer checks in CI. CI and artists need actual LFS content, not pointer files. Monitor storage and bandwidth quotas. Keep raw scans, render caches, build outputs, and archival source libraries in controlled external storage with manifests/checksums in Git.

Ignore Unity `Library`, `Temp`, `Obj`, `Logs`, generated IDE files, local user settings, build directories, crash dumps, signing files, and secrets. Never ignore `.meta` files globally. Use short-lived artifact storage for APK/AAB outputs rather than committing them.

## 6.5 Git Flow and branch governance

**General team policy:** A lightweight Git Flow model can use protected `main` for released state, `develop` for integration, short-lived issue-linked feature branches, release stabilization branches, and narrowly scoped hotfix branches. Require CI, a reviewer, and merge-back of release/hotfix changes to avoid divergence. Avoid long-lived feature branches and parallel scene edits.

For a small team, trunk-based development with short-lived branches and release tags is often cheaper than full Git Flow. Record the team's final choice in an ADR rather than maintaining two competing processes.

**This Arena session is fixed to `arena/94d215f9-iron-crowns`.** All actual work in this session stays on that branch; any future push or PR from this session must use it. The general branch model above is a proposed team policy, not an instruction to switch/create branches here. A PR from this session should target the repository's agreed integration branch (currently the repository baseline is `main`).

PR template: Why; spec link/version; Linear issue; implementation summary; screenshots/video; test evidence; device/performance impact; data migration; risks; rollback; reviewer checklist. Prefer small PRs and feature flags for incomplete systems. Require approval for budget increases and schema changes.

## 6.6 Step-by-step integration setup

### Step 1 — Establish ownership and permissions

Choose a workspace/repository administrator, design owner, technical owner, and release owner. Grant minimum required access. Use dedicated automation identities where appropriate; do not reuse personal tokens in scripts. Agree which system owns each field before enabling automation.

### Step 2 — Create Notion foundations

Create HQ and the databases above in an explicitly chosen parent page. Add templates, stable spec IDs, statuses, and relations. Publish the approved slice scope and acceptance criteria. Share only necessary pages with the integration. This specification does not select or mutate an existing workspace destination.

### Step 3 — Configure Linear

Create or choose the project/team, workflow states, labels, two-week cycles, milestones, and templates. Map approved specs to deliverable issues rather than importing every paragraph. Each issue includes the canonical Notion spec URL and version; the spec includes its related Linear project/issues.

### Step 4 — Connect Linear and GitHub

An administrator installs/authorizes the supported Linear–GitHub integration for this repository. Configure issue references in PR titles/descriptions and status transitions, then test them with a disposable task/PR. Use the actual Linear-generated identifier, not the illustrative `IC-123` above.

Suggested behavior: PR opened → In Review; merged with checks passed → QA; QA acceptance → Done. Verify what the native integration supports in the current workspace. If its auto-close behavior conflicts with QA, disable that transition or handle it with a small explicit automation. A merged PR should not imply a tested release.

### Step 5 — Make cross-links explicit

Issue body links Notion; PR body links Linear and the relevant spec version; Notion links delivered PRs/release notes. GitHub commit messages include the issue identifier when relevant. Keep document links human-readable; a broken or unauthorized link is an integration defect.

### Step 6 — Add optional, bounded automation

Native links are sufficient for the initial team. For additional automation, run a small webhook service or an approved automation platform:

```text
Spec approved → create/update one Linear task proposal
PR opened/merged → native Linear transition where supported
Build completed → attach build metadata/artifact URL to issue
QA approved → close issue; update milestone/release summary
```

- Verify webhook signatures, use allowlisted event types, and validate payloads.
- Deduplicate by event ID; map `(spec ID, version, task role)` to the created issue to prevent duplicate tickets.
- Retry with bounded exponential backoff; honor rate limits; log failed events for manual reconciliation.
- Do not execute webhook text as shell commands or automatically merge code because a document says “Approved.”
- Avoid update loops by recording the originating system and synchronizing only owned fields.
- Secrets reside in the hosting secret store/GitHub environments. Minimize logs and remove credentials/PII.

### Step 7 — Implement CI in layers

| Trigger | Jobs | Output / gate |
|---|---|---|
| Pull request | Content/schema validation, formatting/static checks, EditMode tests, feasible PlayMode smoke tests | Required review checks and test report |
| Trusted integration merge | Full test set, Unity Android IL2CPP build, scene/content validation | Internal APK and build manifest |
| Nightly | Broader campaign simulations, save migration suite, automated device smoke where available | Trend report and regression issues after triage |
| Release candidate | Signed AAB, staged physical-device QA, store checks, license notices | Approved candidate for internal/closed testing |
| Approved release tag | Manual protected-environment approval, publish approved artifact | Staged production rollout and release record |

Unity CI needs a legitimate license/activation strategy for the chosen runner and engine edition. Pin exact editor/container/action versions or immutable action SHAs, Android SDK/NDK/JDK, package lockfiles, and content revision. Cache `Library` only with keys reflecting platform/editor/package changes; caches are disposable and must not mask clean-build failures.

On LFS-enabled repositories, checkout must fetch the required LFS assets. Produce test reports, logs, symbols, checksums, and a build manifest containing commit SHA, engine/toolchain versions, content version, and monotonic Android version code. Documentation-only PRs should not require a full licensed game build once path-based checks are implemented.

**Security:** Untrusted fork PRs receive no signing/store/Unity-service secrets. Avoid privileged workflows that check out and execute untrusted PR code. Signing and store-upload jobs run only after protected-environment approval. Use minimal token permissions; restrict self-hosted runners to trusted workloads and reset them between jobs.

### Step 8 — Distribute, validate, and release

Distribute QA builds through a chosen internal channel or Play internal/closed testing. Send the artifact URL, SHA, device checklist, and linked issues to testers. Store signing material in protected secrets; use Play App Signing where adopted and keep the upload key separately secured.

For production, use staged rollout with crash, ANR, save-integrity, and performance monitoring. Halt on predefined regressions. Store rollback usually means halting rollout and publishing a fixed build with a higher version code—not downgrading users to an old binary. Design save migrations for compatible recovery; preserve backups before irreversible changes.

### Step 9 — Verify the pipeline end to end

Demonstrate one real feature from approved spec → issue → PR → tests → device build → QA → release note. Also test failure cases: expired credentials, duplicate webhook, broken links, failed build, insufficient permissions, and unavailable artifact. Audit links and outstanding QA tasks weekly.

## 6.7 Planning, staffing, and cadence

Planning assumption: A core team of approximately 5–7 people combining a producer/designer, technical lead, gameplay/simulation engineer, UI/tools engineer, technical artist, generalist artist/animator, and shared QA; outsource audio and selected content. People may cover multiple roles, but capacity must be reduced accordingly.

| Phase | Indicative duration | Required exit |
|---|---:|---|
| Discovery and technical spike | 4–6 weeks | Engine decision, touch prototype, min-device 50-agent feasibility |
| Vertical slice | Additional 8–12 weeks | Complete polished loop, safe saves, benchmark gate |
| Production | Additional 5–8 months | Launch systems/content complete within measured budgets |
| Alpha/beta and launch hardening | Additional 2–3 months | Device matrix, migrations, accessibility, store compliance |

Rough planning envelope: 10–15 months before explicit contingency; reserve approximately 20–30% for technical/content uncertainty. Re-estimate after the slice. These are staffing-dependent scenarios, not a fixed bid. A smaller team should reduce factions, castle content, cavalry, and politics rather than simply compress the schedule.

Cadence: Weekly playtest; short daily coordination; cycle planning and demo/retro every two weeks; monthly milestone and burn review; weekly performance review once combat exists. Report playable outcomes, defect aging, cycle throughput, budget trends, and risk changes—not raw issue count as a productivity measure.

---

# 7. Release Gates, Risks & Decisions

## 7.1 Acceptance gates

| Gate | Required evidence |
|---|---|
| Engine approval | Same representative battle on real Android devices; package/render compatibility recorded in ADR |
| Combat prototype | Responsive touch melee, correct hits, readable orders, 50 active combatants meeting minimum-device sustained budgets |
| Vertical slice | Complete offline loop; interruption recovery; validated transactions; playtest learning targets met |
| Scale approval | Representative 100/120-agent tests including equipment, arrows, and cavalry; otherwise retain lower cap |
| Content complete | All launch quests, troop branches, settlement interactions, and siege stages playable; no placeholder dependencies |
| Release candidate | No open critical/blocker defects; save migrations from every supported released schema; device matrix signed off |
| Launch | Signed release artifact, privacy/rating/store compliance, support process, staged rollout and hotfix plan |

Crash-free sessions ≥99.5% and ANR incidence below 0.3% are provisional operational goals once there is sufficient consented/device-distribution data to interpret them. They are not substitutes for resolving known reproducible data loss. Record sample size and affected devices; small internal tests cannot establish production reliability statistically.

## 7.2 Risk register

| Risk | Leading indicator | Mitigation / scope response |
|---|---|---|
| Skinned animation dominates CPU/GPU | Agent count rises but simulation remains cheap while render cost explodes | Profile rig/material path first; reduce rig complexity, nearby full-pose count, and cosmetic variants |
| Thermal throttling invalidates benchmarks | Good first-minute fps, poor 20-minute performance | Sustained device gates; conservative defaults; explicit 30 fps battery mode |
| Command UI overwhelms thumbs | Accidental attacks, canceled orders, high tutorial abandonment | Paused overlay, larger buttons, fewer defaults, repeated novice playtests |
| Siege navigation deadlocks | Queues never drain; unreachable defenders | Explicit portal queues, timeout/recovery rules, authored layouts; defer additional siege content |
| Economy becomes unstable or exploitable | Infinite wealth, permanent starvation, dominant trade exploit | Seeded simulations, bounded prices/production, transaction conservation tests |
| Save corruption on Android interruption | Duplicate outcomes, empty save files, failed restore | Atomic/backup strategy, encounter idempotency, process-kill tests, versioned migrations |
| Scope grows toward PC-scale expectations | More content enters before slice acceptance | Scope ceilings; explicit cuts; require budget and owner for every new system |
| Hybrid ECS complexity erodes iteration | Frequent sync points, mirrored state bugs | Clear authority boundaries, profiler evidence, use ordinary C# where ECS adds no value |
| Licensing or asset provenance gaps | Missing source/license records | Asset registry and license review before ingestion/release |
| Integration automation becomes brittle | Duplicate tickets, stale statuses, privileged tokens everywhere | Native links first, narrow automation, idempotency and weekly reconciliation |

## 7.3 Decisions required before production

1. Confirm launch scope and premium/demo business approach.
2. Select the minimum physical device and representative GPU/driver matrix.
3. Run the Unity-versus-Unreal decision spike if the team's existing engine experience makes the recommendation uncertain.
4. Pin engine/packages and approve the skinning/navigation implementation through measured evidence.
5. Decide whether cavalry and one-stage/multi-stage sieges fit launch budgets.
6. Choose interrupted-battle behavior: full snapshot resume or transparent checkpoint restart.
7. Approve one authoritative documentation model: Notion master with GitHub exports, or GitHub master with Notion index.
8. Choose actual Notion parent, Linear team/project, repository permissions, CI runner/license, and distribution channel before provisioning integrations.
9. Confirm final store requirements, engine licensing, target API, accessibility language scope, and privacy policy before release planning.

## 7.4 First ten working days

- **Days 1–2:** Approve scope, inventory team skills/devices, decide documentation ownership, draft the architecture ADR, and establish the minimum-device benchmark scene specification.
- **Days 3–4:** Initialize the pinned Unity project, Android build recipe, input actions, and character controller; install a reproducible build on the minimum device.
- **Days 5–6:** Implement attack/block states, simplified hit detection, pooled agent spawn, and profiler markers. Validate with placeholder visuals that resemble the intended rig/material cost.
- **Days 7–8:** Add Hold/Charge, spatial partitioning, 20/50/100-agent scenarios, and initial thermal runs. Compare animation/render paths before investing in a custom one.
- **Days 9–10:** Run touch playtests and interruption tests, publish a benchmark/risks report, and approve or reduce slice scope. Exercise one specification-to-issue-to-PR-to-build workflow.

**Final principle:** Preserve the fantasy of leading an army, not the desktop feature count. A coherent, readable, recoverable 50-unit sandbox is a stronger foundation than a 120-unit demo that overheats, loses saves, or cannot be controlled on a phone.
