# Iron Crowns 0.6 — Riders of the Marches

**Evaluation preview. Requires BOTH the APK and matching Data download.**

## Install

1. Download `Iron-Crowns-0.6.0-Riders.apk` and `Iron-Crowns-0.6.0-Data.pck` from this same release. Do not unzip or rename the PCK.
2. Install the APK. At first launch, tap **IMPORT GAME DATA**, open **Downloads**, and select the PCK.
3. Keep the app open while it copies and verifies the pack. The game opens only after its size and SHA-256 match the manifest embedded in the APK.
4. Once installed, play offline. The downloaded PCK can be deleted: a verified copy is stored in private app storage. Allow space for both copies during installation.

This is a genuine Godot resource pack, not a renamed ZIP, filler file or Google Play OBB. It contains the materials, sound and equipment/world catalog excluded from the core APK. No manual access to Android/obb, storage permission or Play licensing key is required. Wrong or corrupt packs are rejected. Restart verifies the installed copy again. Uninstalling or clearing app data deletes both installed Data and campaign saves; a future version requires its own matching Data.

Debug-signed for evaluation. If Android rejects an update because the previous build has a different debug certificate, uninstalling may be necessary and **will erase saves**. This is not production signing or a Play Store release.

## Riding and sword combat

- Approach the horse beside the starting road, then **MOUNT** / **E**.
- Left stick or W/S accelerates/brakes; A/D or stick left/right steers. This is horse-relative steering, not strafing.
- **GAIT** / Shift cycles walk, trot and canter. Cantering drains horse stamina; low stamina limits speed.
- **CUT: LEFT/RIGHT** / R selects the side for your next Strike / Space. Mounted strikes retain a windup and only hit an enemy on the selected side, within reach and without a solid obstruction. Speed adds a capped damage bonus, not instant kills.
- Block remains available. Raiders can wound rider or horse. A disabled horse forces foot combat; resting after a battle restores it.
- Release movement to slow down. **DISMOUNT** checks speed, ground slope and room beside the horse before placing the hero on foot.
- REALM still opens the strategic campaign; the horse is a field mount, not an additional persistent army or trade resource. Starting a skirmish places you on foot beside a rested mount.

## Presentation changes

The map uses textured terrain, revised coastlines and quieter sea/region colors. Characters draw from the separate equipment catalog, with different armor materials, coats and closed/open helmet silhouettes. The horse has a saddle, bridle/reins, stirrups and animated legs; the hero uses a seated pose and wider mounted camera.

All designs, world geometry and assets are original. Bannerlord, Warband and Steel and Flesh are gameplay/presentation references, not sources of copied assets or code.

## Limits

This remains a small procedural 3D prototype, **not Bannerlord-level realism or a complete replacement for those games**. Only the player rides; there are no cavalry armies, horse trading, lance combat, cavalry charges or persistent horse ownership. Mounted contact uses timed reach/side/raycast checks, not blade physics. Equipment variation is cosmetic, not an inventory system. Battles still use one shared field. Horse anatomy, animation and combat balance need further art/gameplay work. Real-phone performance, touch comfort and thermal behaviour remain unverified.

The release's `BUILD.txt`, `ANDROID-SMOKE.txt`, `DATA-MANIFEST.json` and `SHA256SUMS.txt` describe the exact tested artifact pair. Do not mix files from separate builds even if their visible version names match.

## Verified build

- Game/APK source: `81101bf944f70b9c7dd3faecf0c93af52878db82`.
- [Actions 37637940551](https://github.com/s1po0/iron-crowns/actions/runs/37637940551): passed in 8m39s.
- Engine regressions: existing combat/campaign/wanderer systems plus mounting, gait, dismount speed guard, side-selected hits and bounded speed damage.
- PCK directory audit: real imported textures, audio and catalog, no game scripts/scenes. APK audit: bulk Data assets absent and embedded manifest exactly matches the exported pack.
- Android API 29 x86_64 emulator: actual system-picker import from Downloads, same-size corrupt pack rejected, correct pack installed, public downloads deleted, offline restart, touch mounting/gait/side/riding/strike/dismount, settings, recruiting, courier/companion progression, campaign travel and save restoration.
- Screenshots are actual engine/Android captures. Neither these tests nor the screenshots establish real-phone frame rates or production-quality animation.

The native importer reads Android's selected document URI directly. This avoids Godot 4.4's built-in Downloads-provider path conversion limitation without requesting all-files storage access.
