# Stylized 3D rebuild — 0.2

## Direction
The original 2D APK did not meet the intended visual brief. This is a replacement **3D vertical slice**, built with Godot 4.4.1's GL Compatibility renderer. Unity was not available in the build environment. It is a separate prototype track, not an implementation of the entire Unity architecture in the master GDD.

All scenery and character geometry is original procedural low-poly modeling in the engine. Armor, articulated limbs, helmet details, shield geometry, swords, and capes replace the old abstract unit circles. Movement and attack animations are procedural, not mocap or a full imported skeletal animation library.

## Play
- Left stick / WASD: movement.
- Drag the open right screen / hold right mouse: camera.
- STRIKE / Space / left click: melee; BLOCK / Q: defend; DASH / Shift: evasive burst.
- Follow, Hold, Charge, Wall / 1–4: company orders.
- REALM / M: overhead 3D region overview.
- Begin Skirmish: defend the road, earn 80 gold on victory.
- Recruit: three soldiers for 30 gold, to a maximum of twelve.
- Menu / Escape / Android Back: pause.

The current village is a single local scene with basic solid-building collision. The AI uses direct steering and local separation, not a complete navigation mesh; leading soldiers deep into building clusters may expose pathing limits. No interiors or interactions with market props yet.

## Persistence
Gold and victory count are saved after battle rewards/recruitment and on backgrounding. Temporary-file replacement protects small progress writes. A new session starts with eight soldiers; exact company state and live battles are **not** persisted. This is a field prototype, not a durable campaign save implementation. Defeat has a recovery path with a minimum four-soldier company on returning to camp.

## Build
Open `godot/project.godot` with Godot **4.4.1**. Run `main.tscn`. The project uses no external add-ons. Android export uses the official debug template, JDK 17, an Android SDK, and a local debug keystore configured in Godot Editor Settings.

```bash
godot --headless --path godot --editor --import --quit
godot --headless --path godot -- --smoke
godot --headless --path godot --export-debug Android /absolute/path/Iron-Crowns-0.2.0-3D.apk
```

The GitHub workflow installs the pinned editor/export template, tests gameplay, renders screenshots in a software OpenGL desktop session, exports the APK, and launches it on an Android emulator. `--capture` renders three deterministic visual review images; it does not award/save progress. It pauses the encounter AI for a legible character/world screenshot, so it is not performance evidence.

## Architecture
- `art.gd`: primitive mesh generation, materials, waving cloth shader, static scenery batching.
- `world.gd`: deterministic village/environment construction and basic collisions.
- `knight.gd`: articulated character model, animations, health/damage.
- `game.gd`: camera, controls, battle rules, orders, spawning, rewards, progress.
- `hud.gd`: scalable touch HUD, scene menus, region labels, pointer ownership.

Environment meshes are combined by material to reduce draw calls. Characters still use multiple mesh parts per joint; there is no claim that the GDD's 50–120-unit targets are achieved. Maximum field scale is deliberately small (player + up to twelve allies + up to sixteen enemies). Profile physical phones before increasing that cap.

## Outstanding work
Visual review with players; physical-device performance, frame pacing, safe-area and multitouch tests; stronger navmesh navigation; imported skeletal animation if justified; sound; accessibility semantics and scalable UI; full company persistence; proper campaign map progression; production signing.

## Third-party notices
Godot is MIT-licensed; official export-template engine notices are included by the engine. Cinzel and Manrope are used under the SIL Open Font License; their license files are included under `godot/assets/fonts/`. No Bannerlord assets, code, or characters are used.
