# Godot 0.10 — three mission maps and a coherent opening

This is an original castle-building RTS prototype implemented in **Godot 4.4.1/GDScript**, inspired by the general castle-building/defense genre. It does not copy Stronghold maps or assets, and does not claim to reproduce a specific title called “Stronghold 4”. It is not a finished commercial game.

## Three real layouts, not three labels on one map

All three maps use a 40×40 simulation grid at 3 world units per cell. Each has a separately defined river axis/position, bridge corridor, forest/quarry work locations, raider spawn, starting wood/stone, preparation objectives and three wave sizes. The keep stays centrally placed so the established construction controls remain familiar.

| Mission | Terrain and strategy | Preparation | Waves |
| --- | --- | --- | --- |
| Green Valley / دۆڵی سەوز | Eastern north–south river; northern raiders. Learn production and build a defensible village. | 6 soldiers, 4 bread produced | 8 / 12 / 16 |
| Southern Bridge / پردی باشوور | East–west river separates the quarry and southern raiders from the keep. Workers and attacks use the bridge. | 8 soldiers, 8 bread produced | 10 / 14 / 18 |
| Western Gate / دەروازەی ڕۆژئاوا | Western river puts the forest and attacking parties across a shared crossing. Higher preparation requirement. | 10 soldiers, 12 bread produced | 12 / 16 / 20 |

The river rendering, bridge geometry, minimap and A* terrain restrictions use the same mission definition. Workers collect wood/stone from that mission's locations; they are not secretly using the old map's resource points. Colored terrain, clustered forests, resource labels and roads identify the setting. Roads trace the initial walkable keep-to-bridge route; they are decorative, not a speed bonus, and do not redraw when players build over them. Misleading unowned decorative houses were removed from the playable opening.

## Opening and play sequence

1. Choose one of three **visible touch buttons** on the introduction panel. Read the story, resource objective and enemy counts before beginning. All maps are available immediately; there is no claimed campaign-unlock/progression system.
2. Press **دەستپێکردنی میشن** (Start mission), or Resume to load the existing saved map.
3. Build stockpile → woodcutter → farm → mill → bakery. Use the large green Build button and Suitable plot helper preserved from 0.9.1.
4. Build three wall sections, a barracks and enough completed houses for the required workers/soldiers. Produce the stated bread amount and train the required soldiers. The first raid is readiness-gated, not an unexplained countdown before the player learns the game.
5. Use Army command to rally defenders. Closed gates block navigation; keep routes available for deliveries. Defend against three attacks with 90 simulation seconds and one-time recovery supplies between waves.
6. Victory offers **Next mission** and **Choose map**. Defeat offers map selection/retry. Mission endings attempt an immediate local save; failures are reported.

The 160×160 minimap shows the full navigation grid, structures, resource sites, living friendly/enemy units and camera focus. Tap it to move the camera; this does not buy a building or issue an army order. It is explicitly sized before RTL layout so it stays inside the screen. Inspection controls/text were also moved/sized to avoid being clipped or covering the lower action toolbar.

## Save safety

Schema 3 stores `mission_id`; loading restores the matching terrain, navigation and objective settings. Unknown map IDs are rejected. Schemas 1 and 2 load as the historical Valley map, with `.v1-backup`/`.v2-backup` copies retained before conversion. New Game continues to back up the existing save before replacing it. Save versions and map persistence are tested; this is not cross-package Android save transfer.

The APK uses **`com.ironcrowns.castles.maps` / Iron Crowns: Castle Maps** independently of previous previews. Keep earlier apps installed to retain their private saves. Prior ephemeral debug-signing keys are unavailable, so this is not offered as an in-place upgrade; production signing and a proper user-facing save transfer are still unresolved. Compatible Castle API-1 Data remains usable. Definitions/logic changed in the APK; this is not a Data-only engine upgrade.

## Tests and limitations

Engine tests verify each map's terrain mask matches navigation, map masks differ, forest/quarry/spawns connect to the keep, bridges are passable, production actually delivers bread, wave counts/positions are correct, map saves round-trip, invalid IDs fail and legacy schema-2 backups remain. GUI tests use injected touch events to construct farms and pan the minimap, requiring touch targets to fit within the real viewport.

Android smoke testing selects the Southern Bridge map through its visible button, builds a farm via touch, checks the saved map ID and resource cost, restarts the APK and verifies map/farm restoration. It uses an emulator, not physical-phone performance evidence. Engine renders are captured for all three maps. Wave scheduling tests are not a complete balanced human playthrough of each mission.

Still unfinished: professional final art/animation/audio, siege machinery, a long campaign/world map, diplomacy, multiplayer, native authenticated cloud saves, a genuine >1-GB used-content library/streaming API, stable production signing and certified 4/6/8-GB phone performance. This update does not claim those features.

## Verified build

[39372968104](https://github.com/s1po0/iron-crowns/actions/runs/39372968104), source `6e1044687955a54be4ee8d5a7019efdd71878a5a`, passed Godot import, all three map tests, existing campaign/economy/combat/save tests, touch construction/minimap/viewport checks, rendering all three maps, APK export and native Android emulator mission-selection/build/save/restart verification. An earlier keyboard-driven dropdown test stayed on Valley; replacing it with visible mission buttons produced a verified Southern Bridge save. No emulator result is represented as a physical-phone benchmark.

## Published download and review

[Public 0.10 release](https://github.com/s1po0/iron-crowns/releases/tag/v0.10.0-castle-maps): APK **174,714,466 bytes**, Data **20,083,426 bytes**, manifest, checksums, three desktop map renders, actual Android menu and Southern Bridge gameplay screenshots. The images were fetched and visually reviewed before publishing. Upload run [39373633890](https://github.com/s1po0/iron-crowns/actions/runs/39373633890) attached the exact reviewed build without rebuilding and verified payload checksums. Public GitHub API inspection confirmed nine uploaded assets and non-draft prerelease status. Prior releases and their binaries were not changed.
