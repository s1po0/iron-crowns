# Campaign expansion 0.3

The map is now a separate 900×680-unit strategic world, not an overhead camera pointed at the old village. The original 180×180 ground plane remains the shared combat/training arena. The strategic layer has about 19 times its area, but this is a world-coordinate comparison—not a claim of real geographical kilometers.

## Implemented versus requested
| Bannerlord-like category | This build | Not implemented |
|---|---|---|
| World map | Original 3D continent; mountains, forest, drylands, snow, coast, river, roads, bridges | Calradia or copied assets; seamless continent combat |
| Settlements | 8 towns, 8 castles, 16 farming villages | 32 unique visitable interiors |
| Armies and travelers | Player company; caravans, patrols, raiders on roads | Full faction warfare AI and logistics |
| Trading | Grain stock affects quotes; supply consumption, wages and local transactions | Workshops, multi-good production chains, autonomous profit-maximizing trade |
| Recruitment | Recruit locally; persistent company count, 12-soldier combat cap | Full faction troop trees, mounted player combat |
| Politics | Four named original factions, hostility after conquest, paid truce | Noble personalities, councils, marriage, inheritance, dynasty |
| Fiefs | Field challenge to capture a castle, daily income, owner banner | Actual wall assault, siege engines, town sieges, building projects |
| Quests | Roadwarden bounty for defeating a raider party | Story campaigns and diverse procedural quest library |

## Controls
Begin Campaign opens the map at Hearthglen. Drag empty terrain to pan, pinch or scroll to zoom; +/− are alternatives. Tap a settlement to inspect it, or use Previous/Next on its panel. Choose Travel to route along roads. The gold line previews the route. Arrival pauses time. At the destination, buy supplies, recruit, trade grain or accept a contract. Castle garrisons can be challenged in the existing field arena. Hostile patrols and raiders can interrupt travel; fight or pay to pass.

One real second at 1× advances one campaign hour. Player road travel is about 15 map units/second before shortages; 2×/4× accelerate the simulation. Food and wages apply every 24 hours, including time manually advanced while stationary. Captured castles pay 18 gold/day. A food shortage slows movement and can cause desertion; a minimal recovery company is preserved. Transactions are validated on proximity/resources, not just UI availability.

FIELD CAMP returns to the shared 3D arena; REALM returns to the map unless a battle is active. The town shown in the arena does not change to match every campaign settlement. No unique interiors are implied.

## Technical approach
`realm.gd` owns campaign data, terrain construction, AStar3D road topology, moving parties, transactions and encounters. `realm_overlay.gd` draws the campaign HUD with zoom-dependent labels. `game.gd` remains the authority for gold, roster actors and encounter outcomes. Realm and battle visibility/cameras are switched explicitly; campaign time never runs during an active battle.

Terrain uses a deterministic height mesh and vertex colors; vegetation uses MultiMesh batches; static settlement geometry is grouped by a shared material palette. Road route rendering and party movement use the same sampled graph positions. Pan/zoom is constrained to the map bounds. Rendering is not evidence of physical-phone performance; profile before raising army/tree density.

## Persistence
Save envelope v2 retains gold/victories and adds the realm payload. v1 saves migrate with a new map/starting supplies. Company size (not individual health/experience), position, food, cargo, day/hour, fiefs, relationships, stocks and defeated party IDs persist. Moving routes reload stopped and are replanned from the nearest road node when the player chooses a new destination. NPC routes/positions restart from deterministic origins; they are not fully persisted. Battle interruptions restore the pre-battle company count; completed outcomes commit once before leaving the result screen. Saves remain temporary-file replacements without cloud sync.

## Original art direction
Muted earth/forest colors, continuous relief rather than oversized cone props, snow lines, smaller settlement models, faction-colored standards, and parchment/gold typography reference the readability of a grounded medieval strategy map. No Bannerlord code, textures, map topology, faction names, characters or UI assets are copied.
