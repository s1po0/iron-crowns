# Iron Crowns — The Ashen Marches

A **stylized third-person 3D Android field prototype**: an armored captain, a visible company of soldiers, and a modeled medieval village. Built with **Godot 4.4.1**, replacing the original abstract 2D presentation.

![Actual engine-rendered scene](docs/screenshots/iron-field.png)

## Play the 3D preview

Download **Iron-Crowns-0.2.0-3D.apk** from the [0.2 prerelease](https://github.com/s1po0/iron-crowns/releases/tag/v0.2.0-3d-preview). It is an evaluation/debug-signed APK, not a production or store release. Android 8+ ARM64 phones are the intended target; real-device performance still requires testing.

- Animated, articulated low-poly knights: armor, helmets, swords, shields, capes.
- Third-person movement, touch camera, melee, block, stamina, dash.
- Follow, Hold, Charge, and Shield Wall orders.
- Skirmish rewards, reinforcements, and saved gold/victories.
- A village gateway, towers, houses, market props, trees, road, brook, and mountains.
- An overhead **3D local-region overview**—not a full kingdom campaign yet.

[Controls, build instructions, architecture, and limitations](docs/3D_PREVIEW.md) · [Title screen](docs/screenshots/iron-title.png) · [Region overview](docs/screenshots/iron-map.png)

## Build and test

Open `godot/project.godot` in Godot **4.4.1**. Use the Compatibility renderer. Android export requires JDK 17, Android SDK tools, the official Godot Android export template, and a debug keystore configured in the editor.

```bash
godot --headless --path godot --editor --import --quit
godot --headless --path godot -- --smoke
godot --headless --path godot --export-debug Android /absolute/output/Iron-Crowns-0.2.0-3D.apk
```

The [3D workflow](.github/workflows/godot-3d.yml) tests gameplay rules, renders real screenshots, exports an APK, and checks Android interaction/rendering/lifecycle behavior. It does not replace physical-device performance or playtesting.

## Scope, honestly

This is one playable 3D region and a repeatable skirmish, **not** a finished Bannerlord-scale RPG. There are no cavalry, siege interiors, dynasty simulation, full campaign economy, sound, localization, or production signing. Troop composition and interrupted battles reset between app sessions; only gold and victory count persist. See the preview guide before testing.

`app/` and `tests/` preserve the earlier **legacy 2D Java prototype**; they are not the current 3D game. Its APK uses a different package name and its saves do not migrate to this build.

[Master GDD and long-term architecture plan](docs/MASTER_GDD_AND_TECHNICAL_PLAN.md) describes proposed future systems, not the current feature list. Engine/font license notices are included in `godot/assets/`.
