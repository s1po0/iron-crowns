# Castle RTS 0.9 — three-wave defense mission

This is a playable expansion, **not a completed commercial game or a Stronghold-quality replacement**. It retains the 40×40 village map and authored skeletal animation. There is one village-defense mission with three attacks, not a multi-map campaign.

## What changed

- **Housing:** the keep supports 8 living workers/soldiers. Each completed house adds 4 places, up to 48. Unfinished houses add nothing. Recruitment/worker assignment stops when full. Losing housing never deletes existing people; reclaim capacity before recruiting again. Soldiers retain a 24-unit cap.
- **Food and morale:** every 30 simulation seconds the village consumes one bread per six people, rounded up, minimum one. Adequate food restores 8 morale; a shortage loses 16. Morale is clamped to 0–100. Tax income scales from 0 to 8 gold per interval. Below 40 morale, workers take twice as long to finish a production task; walking speed is unchanged. Deliveries remain physical, not instant resource generation.
- **Gates:** select **بەڕێوەبردن** (Manage), tap a gate, then toggle it. Closed gates show a timber door and block A* routes; opening restores passage. A gate cannot close onto a living unit. Placement, demolition and gate changes invalidate routes. Raiders ignore open gates as wall targets and choose a reachable approach to the structure they attack.
- **Building management:** tap any footprint in Manage mode to inspect health, construction and repair costs. Repairs cost one stone per 20 missing health and one wood per 40, rounded up. Finished structures can be repaired when no living raider is within six cells of their center. Demolition needs a second press within five seconds and refunds half the original wood/stone scaled by completion. The keep cannot be demolished. Attached workers are removed and population released when their workplace is removed.
- **Three attacks:** 8, 12, then 16 raiders. The first begins only after the guided economy/wall/barracks objectives, a finished house, six soldiers and four produced bread. After each of the first two attacks, receive 40 gold and 8 bread once, then 90 simulation seconds to prepare. Pause stops the countdown. Victory requires clearing the third attack; keep destruction takes precedence over victory.
- **Interface:** population/capacity, morale, keep health and wave count are visible. Contextual tutorial text warns about full housing and shows time until the next raid. Invalid construction/recruiting buttons are disabled. Build-placement tint is translucent instead of a solid opaque patch. Pause has a visible resume label. Building management is in the fixed action row, not hidden in the building carousel.
- **Installer:** Castle-specific Sorani instructions, font, progress and common error messages. Technical validation/native-picker errors may still include English diagnostics. The older non-Castle installer is unchanged.

## Saves and Android installation — important

0.9 uses **`com.ironcrowns.castles.campaign`**, separately from 0.8 (`com.ironcrowns.castles`) and the earlier third-person game (`com.ironcrowns.marches`). **Do not uninstall those apps to install this version.** Their private files remain intact. This is not an in-place upgrade and it does **not automatically transfer saves between Android packages**.

The earlier builds used ephemeral CI debug-signing keys; their private signing keys are not available for a compatible in-place update. This preview is therefore isolated rather than telling users to uninstall and lose saves. A production release still needs a securely maintained signing key and an explicit cross-package save-export/import migration. Repository secret access was unavailable; no secret or credential was added to the repository.

Within this build, save schema 2 preserves morale, wave countdown and gate state. The loader also accepts schema 1, retains a `.v1-backup` before conversion, and defaults legacy gates to open and morale to 100. The filename remains `castle-rts-v1.json` for loader compatibility; its JSON schema is 2. New Game retains `.previous` and refuses to proceed if that backup cannot be created. Saves are validated and atomically replaced. Old APKs should not be given new schema-2 saves.

Install the 0.9 APK, launch it, choose **هێنانی داتا / IMPORT GAME DATA**, and select the Castle `.icdata` file. No Android/obb copying is required. API-1 Castle model content from 0.8 is compatible; the older Peoples 0.7 pack lacks the RTS model catalog.

## Verification scope

`rts_campaign_test.gd` tests housing limits and loss, recruitment costs, repair costs, demolition restrictions, gate occupancy/path detours, persisted gate/countdown/morale, malformed saves, schema-1 migration, food shortage/recovery, one-time wave rewards, all three wave transitions, victory and defeat precedence. Wave-transition tests deliberately clear enemies to exercise scheduling; they are not a playthrough or a balance benchmark. Existing tests exercise real production/delivery, soldier combat, movement and save round trips.

`rts_test.gd` also injects actual screen-touch events into an Xvfb Godot window to start a game and close a gate through the native UI. It checks paused management cannot modify the simulation. The workflow imports scripts, runs these tests, renders the scene and exports APK plus Data. This is **not a new Android emulator test or a physical-device benchmark**.

## Still unfinished

- Full multi-map campaign, siege machinery, diplomacy, multiplayer and professional final art/animation/audio.
- Authenticated Android Supabase/cloud saves. This build remains offline/local-save; the separate web integration is not Android integration.
- A genuine >1-GB content library and streaming/large-pack API. Real Data remains about 20 MB with API-1's existing 256-MiB limit. No padding or disguised OBB is used.
- Certified performance on 4/6/8-GB devices, extended mobile playtesting and economic/combat balancing.
- Stable production signing and user-facing cross-package save transfer.

## Reviewed build

[Build 39368001061](https://github.com/s1po0/iron-crowns/actions/runs/39368001061), source `5df455deee9c78aa7475da11691fd7339028d85b`, passed import, campaign/production/combat/save tests, injected-touch GUI tests, render and Android export. The actual screenshot was fetched and visually reviewed. No physical-phone performance claim follows from this desktop engine run.

## Published download

[0.9 APK + Data prerelease](https://github.com/s1po0/iron-crowns/releases/tag/v0.9.0-castle-campaign). Install `Iron-Crowns-0.9.0-Castle-Campaign.apk` (174,697,649 bytes), then import `Iron-Crowns-0.9.0-Castle-Data.icdata` (20,083,426 bytes). SHA-256 checksums, manifest and the reviewed screenshot are included. Publication run [39368284066](https://github.com/s1po0/iron-crowns/actions/runs/39368284066) verified checksums before attachment; all five uploaded release assets were confirmed through the public GitHub API after publishing. The reviewed binaries were not rebuilt during publication. Existing 0.8 and earlier releases were not changed.
