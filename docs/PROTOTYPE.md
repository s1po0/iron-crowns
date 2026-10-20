# Iron Crowns 0.1.0 — Android prototype

This is an **original, native Android 2D playable prototype**, not the full Unity/Unreal 3D game in the master GDD. It uses Java and Android Canvas, has no third-party runtime libraries, and needs no network or sensitive permissions.

## Implemented
- Landscape overworld with four trading settlements and three capturable keeps.
- Automatic travel, food consumption, daily wages, and fief income.
- Recruitment (30-soldier cap), veteran training, grain trading, and one bounty contract.
- Real-time top-down battles: player movement, melee strikes, blocking, allied/enemy melee units and automatic archers.
- Hold, Charge, Shield Wall (`WALL`), and Follow orders; up to 61 combatants including the player, depending on the encounter.
- Defeat/recovery, battle rewards, keep ownership, and a three-fief campaign goal.
- Local autosave with a backup checkpoint, pause, help, and reset confirmation.

## Controls
Tap a settlement to travel; arrive to recruit, trade, train, or rest. Hunt bandits from the bottom bar. Accept the Roadwarden contract before your first victory for extra gold. Hostile keeps have stronger garrisons.

In battle, drag the bottom-left joystick, hold **STRIKE** near an enemy, and hold **BLOCK** to reduce incoming damage. You cannot strike while blocking. Order your troops with the bottom row. Hold and Wall anchor near the commander's position when issued. Archers fire automatically. If the commander falls, the army continues fighting.

Capture all three keeps to become sovereign. Each keep pays 18 gold per campaign day; a day passes after twelve seconds of actual travel or when resting. Battles also advance one day. Time does not advance while the app is closed.

## Install
Download `Iron-Crowns-0.1.0-prototype.apk` from the GitHub prerelease onto an Android 8.0+ phone. Allow “Install unknown apps” for the browser/file manager you use, install, then revoke that permission if desired. The application ID is `com.ironcrowns.game.prototype`.

This is a **debug-signed prerelease APK**, not a Play Store production release. Debug signing is suitable only for evaluation. Independently rebuilt debug APKs may use different signing certificates and require uninstalling the previous build, which deletes local saves. A stable protected release signing key must be established before distributing production updates.

## Save behavior and limits
Campaign transactions save immediately. Backgrounding saves the campaign and pauses any live battle. If the process is killed during a battle, reopening restores the **pre-battle campaign**, not exact battle positions. This permits replaying an interrupted battle. No offline time progression or cloud saves. Do not uninstall if you need to retain the campaign.

SharedPreferences provides a small local checkpoint store, with a previous JSON checkpoint as fallback. This is a prototype persistence implementation, not the versioned, transactional production save service specified in the master plan.

## Build from source
Requirements: JDK 17, Gradle 8.9, Android SDK platform 35 and compatible build tools. Configure `ANDROID_HOME` or `local.properties` and accept SDK licenses.

```bash
bash scripts/test.sh
gradle --no-daemon :app:assembleDebug :app:lintDebug
# Output: app/build/outputs/apk/debug/app-debug.apk
adb install -r app/build/outputs/apk/debug/app-debug.apk
```

The checked-in GitHub Actions workflow installs these dependencies and uploads the APK, checksum, build SHA, and lint report. No Gradle wrapper binary is included; use the pinned Gradle version or CI.

## Known gaps
- 2D Canvas graphics, not third-person 3D, Unity, Unreal, ECS, or Vulkan rendering.
- Keep capture uses field combat; no siege interiors, cavalry, diplomacy, dynasty, dynamic commodity simulation, equipment inventory, or multiplayer.
- AI uses simple pairwise target selection/separation; it is not the production spatial-grid architecture.
- Archer traces are visualized instantaneous attacks, not physical ballistic projectiles.
- Fixed virtual viewport and custom Canvas controls; full screen-reader semantics, localization, remappable controls, audio, and haptics are not yet implemented.
- No production signing, store submission, telemetry, or promise of performance on untested physical devices.
- Automated tests cover campaign rules, not complete combat or touch usability. Physical Android acceptance testing is still required.

## Manual acceptance checklist
- Fresh install opens, help works, and landscape safe areas remain usable.
- Travel to a town; recruit, buy food, train, buy/sell grain; money and capacity cannot go negative.
- Use simultaneous movement/strike/block; release or interrupt touch and confirm no stuck inputs.
- Issue each formation order; win, retreat, and lose a battle.
- Capture all keeps; verify daily income and sovereign banner.
- Background/resume in battle, kill the process, and verify pre-battle recovery.
- Confirm reset requires a separate confirmation and canceled reset preserves the save.
- Run a 20-minute battle/travel soak on representative physical devices and inspect thermals/memory.
