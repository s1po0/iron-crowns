# Castle RTS — independent Android preview

## Direction approved by the player

A top-down castle-building RTS, not the third-person wanderer game. Low targets 4 GB RAM devices, Medium 6–8 GB, High 8 GB+. RAM alone is **not** a graphics benchmark; GPU capability, resolution and thermal limits still require physical-device validation.

The Android export preset `CastleRTS` uses package `com.ironcrowns.castles`, so installing it does not uninstall or overwrite the previous `com.ironcrowns.marches` game. The previous APK/release and web game are not replaced. Its save is `castle-rts-v1.json`, independent of earlier campaign saves.

## Implemented first mission

- A Sorani introduction and ten-step objective panel, showing how to build rather than starting on an unexplained map.
- Stockpile → woodcutter → wheat farm → mill → bakery. Workers physically follow obstacle-aware A* routes; their carried goods are only credited upon delivery.
- Timber/stone costs, eight-second construction, protected building footprints, blocked water and a bridge crossing. Walls obstruct routes; gate cells remain traversable. The gate currently behaves as an open passage, not a controllable siege gate.
- Stone quarry, houses, barracks, walls and gates. Housing is currently decorative: a population/housing simulation is not claimed.
- Recruit soldiers, issue a rally order, complete the food chain and repel eight raiders. Soldiers and raiders have health, attack cooldowns, damage and death. Raiders can damage walls and the keep; keep destruction loses the mission.
- Skeletal workers/soldiers using the existing anatomical body assets, with authored keyframe walk/carry/work/attack cycles and transition blending. These are not motion-capture animations.
- CC0 Quaternius MegaKit textured houses and yard props, original keep/wall construction geometry, terrain, river shader, bridge, textured foliage and quarry rocks. Asset provenance is recorded beside the converted models; no Stronghold proprietary assets are used.
- Low/Medium/High presentation presets (30/30/45 FPS caps, 70/85/100% 3D resolution, reduced foliage, shadows off on Low), without changing economy or enemy counts by quality.
- Separate validated local saves, atomic replacement, prior-save backup before New Game, 30-second autosave, explicit pause and ambient sound toggle.

## Build

Godot 4.4.1. Run the project through `res://rts.tscn`, or use the ordinary bootstrap with `-- --rts`. For Android, use the `CastleRTS` export after installing the native data-import plugin with `scripts/godot-android-template.sh`. Build genuine Data with `scripts/build-content-bundle.py`; never rename an arbitrary ZIP to `.obb`.

The `Castle RTS preview` Actions workflow imports the project, runs `rts_test.gd`, renders a real game screenshot and exports the independent APK plus `.icdata`. Build logs, checksums and binaries are uploaded as artifacts. A render from a seeded showcase fixture is not evidence of physical-phone frame rate or a completed campaign.

## Explicit limits / remaining work

This is the **first playable mission**, not a finished Stronghold-scale game. The requested **greater-than-1-GB content pack has not been produced**. Current real assets total about 20 MB; making duplicate or empty files would not improve quality. The existing safe Data API has a 256 MiB total / 16 MiB per-file budget. A genuine larger pack requires a versioned, chunked/streamed asset pipeline and licensed media actually used by missions; that is not silently represented as already complete here.

No new OBB is supplied. `.icdata` is the existing native Android file-picker/import format, not an OBB with a different extension. Future content expansion must retain corruption checks, safe paths, bounded memory, atomic activation and enough free disk space for rollback.

The connected Supabase project is healthy, and the separate web game's auth/RLS remain intact. **This new Android preview still saves locally; authenticated Android cloud-save integration is not implemented.** Unrelated Gmail/Notion/other connectors are not accessed simply to increase a connection count. Asset size, use of connectors and feature count are not substitutes for visual review and gameplay testing.

Not yet included: full siege machinery, controllable gate state, housing simulation, seasons, multiple missions, multiplayer, adaptive GPU benchmarking, or certified 4/6/8-GB phone performance. The installer is inherited from the previous English bootstrap; the new RTS mission UI itself is Sorani.
