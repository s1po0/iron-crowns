# Iron Crowns 0.2 — The Marches, in actual 3D

This rebuild replaces the abstract 2D presentation with a **Godot 4 third-person 3D field prototype**. It is still a small, unfinished game—not the complete RPG.

## What changed
- Visible armored knights with articulated legs/arms, helmets, shields, swords, capes, and procedural walk/attack/block/fall animation.
- A modeled village, crenellated gateway, stone towers, red-roofed buildings, trees, meadow, road, brook, flags, and distant hills.
- Third-person follow camera with touch look controls, movement, melee, blocking, stamina, and dash.
- Allied and enemy soldiers; Follow, Hold, Charge, and Shield Wall; skirmish rewards and reinforcements.
- An actual overhead 3D view of the local region—not the old schematic map.

## Installation
Download **Iron-Crowns-0.2.0-3D.apk**. This build targets Android 8+ on ARM64 phones, with an x86_64 build path used by the emulator. It is debug-signed for evaluation, not a production/store release. Package `com.ironcrowns.marches` installs alongside the old prototype. Saves from the 2D prototype are not imported.

## Scope and verification
Screenshots show the actual engine-rendered scene, not concept art. Engine tests cover character initialization, enemy spawning, melee damage, orders, reward idempotency, and return to camp. The APK passes an Android API 29 emulator launch/control/lifecycle smoke check. Physical-device frame rate, thermals, and touch usability still require testing.

Gold and victory count persist; troop composition and interrupted battles reset when reopening. There is no full campaign economy, dynasty, mounted combat, siege interior, audio, localization, production signing, or full accessibility support in this build.
