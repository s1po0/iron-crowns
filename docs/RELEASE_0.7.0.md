# Iron Crowns 0.7 — Peoples of the Marches

This is the **one-time foundation APK change** required to replace 0.6's exact-Data hash lock. Future compatible **API 1 content** can be installed without rebuilding or reinstalling this APK. Engine features and incompatible APIs may still require a new APK.

## Downloads and installation

For the first installation, download **both** `Iron-Crowns-0.7.0-Peoples.apk` and `Iron-Crowns-0.7.0-Data.icdata`. Install the APK, open it, tap **IMPORT GAME DATA**, and choose the `.icdata` from Downloads. Do not rename it to `.obb`, unzip it, or copy it into Android/obb.

The old 0.6 APK cannot read this format. Its PCK is also not a valid 0.7 Data file. The app explains incompatible/corrupt content rather than loading it.

### Later Data-only updates

1. Download compatible API 1 `.icdata` content from a source you trust.
2. On the title screen, tap **MANAGE DATA**. The game saves and closes; reopen it to enter the installer without an active battlefield in memory.
3. Select the new Data file. After successful installation, close and reopen as prompted to clear old model/material caches.
4. Your campaign save is separate. A failed import does not replace the previous active content.

No broad storage permission or Google Play licensing key is used. The native importer reads only the document selected in Android's system picker. The installed copy works offline; the public Downloads copy can be deleted.

## What changed

- A **20-bone anatomical human body** derived from the CC0 MakeHuman base replaces primitive player/soldier bodies. Skin weights drive limbs, riding and combat poses; supported geometry comes from Data. The catalog supplies skin, hair, eyes and clothing colors.
- **2,700 × 2,040** campaign world, nine times the previous rectangular area, with **64 settlements** rather than 32.
- **Six original factions**: Ashen Crown, Northguard, Verdant League, Sunward Dominion, Khurai Horse Clans and Storm Coast Pact.
- Factions screen with clan names, leaders, descriptions, settlement allegiances and standings. New journeys remain independent.
- World dimensions, settlement definitions, roads, region anchors, ridges, factions, head/scalp OBJ geometry, materials, audio and supported appearance settings now come from Data.
- Existing mounted and foot combat, campaigns, recruitment, companions, courier work and saves remain part of the game.

Open **REALM**, then **ATLAS**, to see the expanded world. Use its faction control to inspect the six peoples.

## Mod/content boundaries

`.icdata` is an original sequential raw-asset container, not a Godot PCK or a renamed OBB. API 1 accepts supported JSON definitions, OBJ geometry, images, WAV audio and notices. It rejects scripts, Godot scenes/resources, unsafe paths, incompatible APIs, malformed supported definitions and hash/size mismatches before activation. It does not load Bannerlord/Warband mods.

Checksums detect corruption; **they are not publisher signatures or proof that a download is trustworthy**. Only install packs from trusted sources. Content should retain stable settlement IDs and the `ashen-marches` world ID for save compatibility. API 1 has bounded world, file, faction and settlement counts.

## Important limitations

This is a prototype improvement, **not the character quality shown in the reference screenshots**. Characters now use a full anatomical skin, but clothing is still material-defined rather than detailed layered garments. Hair, skin shading, armor detail, weapon grips and animation still need substantial art work. This does not match the reference screenshots. The runtime body is a restricted numeric derivative of the licensed GLB, not an arbitrary executable model format.

The Khurai clans are original, not Bannerlord's Khergit family tree. Clan leaders are background profiles: family-tree simulation, marriage, heirs, dynasties and AI cavalry armies are not implemented. Campaign travel and the shared battlefield remain separate. Physical-phone performance, thermals and extended combat feel are not yet verified.

Debug-signed for evaluation. Android may reject installation over a differently signed older build; uninstalling deletes saves and installed Data. Back up important progress before uninstalling. Do not interpret an emulator pass as production signing or device certification.

## Build verification

- Exact tested APK/initial Data source: `ecce218a81d87b541fb8b9246e5aa193d8699b0c`.
- [Actions 37852970751](https://github.com/s1po0/iron-crowns/actions/runs/37852970751) passed the complete pipeline in 10m16s.
- Engine: anatomical skin/clothing regression, Data schema/corruption checks, foot and mounted combat, world road connectivity, trade, wanderer progression and save tests.
- Android API 29 x86_64: native document import; same-size corrupt Data rejected; initial Data plus a changed-catalog revision 2 installed without replacing the APK; offline cold restart; riding/gait/side/dismount controls; recruitment; companion hiring; courier acceptance/travel/payout; settings; campaign/save restoration.
- Device automation waits for the rendered journal menu and committed transactions rather than assuming each screen finishes in one second. Assertions and single transactional taps are retained.
- Actual engine and Android captures were reviewed. No claim is made about physical-phone frame rates, thermals, finished animation or reference-level graphics.

The release is staged from this successful run without rebuilding the reviewed binaries.
