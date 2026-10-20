# Iron Crowns — Unreal Engine migration prototype

**Engine choice: Unreal Engine. Source target: UE 5.6.** This does not claim 5.6 is the latest engine release. The former Godot project and published Android apps remain preserved in the repository.

## What this contains

A native C++ Unreal project, not a renamed Godot executable:

- `.uproject`, Game/Editor targets and a runtime module.
- Custom GameMode, top-down camera pawn, PlayerController and Canvas HUD.
- Runtime-generated instanced 40×40 terrain, three original river/bridge layouts and prototype building geometry.
- Mouse/WASD camera controls; touch selection, drag panning and two-finger zoom handlers.
- Stockpile/woodcutter/farm/mill/bakery construction, resource costs, explicit placement confirmation, suggested plots and eight-second construction timers.
- Initial **inventory-based** wood → grain → flour → bread economy. This is not the old physical-worker simulation.
- Walls and gates with navigation occupancy; open/closed gate geometry and a portable BFS path query.
- Independent validated Unreal save/load with a previous-slot backup. No Godot save is read or overwritten.
- Confirmed map change: press **Next map** twice within five seconds. Save first if needed; changing maps does not automatically save.

The visuals are **engine primitive placeholders**, not finished art or a demonstrated improvement over the Godot release. The initial HUD is English; the Sorani localization/font work is not ported yet. Houses/barracks are constructible placeholders: population/recruitment, visible workers, armies, raids, siege machines, campaign progression, audio and cloud saves are **not ported**. This foundation does not replace the more feature-complete Godot prototype for playtesting.

## Verification — read before installing/building

This workspace has **no Unreal Editor, Unreal Build Tool or Android Unreal toolchain**. Consequently:

- The portable `CastleRules.h` code was compiled with GCC/C++17, warnings treated as errors, AddressSanitizer and UndefinedBehaviorSanitizer; its rule regression suite passed.
- That result **does not compile the Unreal/UHT-specific classes**, test input/rendering, cook content or produce an APK.
- No Unreal screenshot, playable editor session, packaged executable, physical-device result or Android performance claim is available.
- Unreal integration/compiler fixes may still be required when the project is first opened with an actual engine installation.

Do not rename the source ZIP to `.apk` or reuse a Godot `.icdata` as if Unreal could load it. **Unreal does not currently read those Data files or Godot saves.** The old models/textures are not imported as `.uasset` files. Their existing provenance remains under `godot/assets/content/rts/`; any later import must preserve it.

## Open on a development PC

1. Install Unreal Engine **5.6** through Epic's supported distribution (and accept its applicable license). Install the platform's C++ development tools. Never put Epic/GitHub credentials into project files or chat.
2. Open `IronCrowns.uproject`, generate project files if prompted and compile the **IronCrownsEditor** target. The source code targets 5.6; another version may require API/project changes.
3. Open `/Engine/Maps/Entry` and verify Project Settings → Maps & Modes uses `CastleMode` as the default GameMode. Press **Play**. The terrain and buildings are generated at runtime; no binary `.umap` from another engine is included.
4. For a production project, create/save your own `/Game/Maps/...` map and select it in Maps & Modes and Packaging. The Entry map and engine BasicShapes cooking entries are development bootstrap configuration, **not verified packaging configuration**.
5. Before Android distribution: compile in the actual editor, inspect every control on screen, test touch at the target aspect ratios, verify material/shape cooking, set up the engine-compatible SDK/NDK, configure a persistent signing key outside the repository, package and test on a device. None of these is represented as completed here.

Linux editor build helper:

```sh
UE_ROOT=/path/to/UnrealEngine bash scripts/build-unreal-editor.sh
```

Windows: generate Visual Studio project files, select `Development Editor` / `Win64`, build `IronCrownsEditor`, then open the `.uproject`.

## Prototype controls

- **WASD** or drag: pan; mouse wheel or pinch: zoom.
- Select a building → tap empty ground or **Suggest** → **Build**.
- Build **Stockpile**, **Woodcutter**, **Farm**, **Mill**, **Bakery** to exercise the inventory chain.
- Select the cell of a completed gate → **Toggle gate**. Path queries respect the result; there are no moving troops yet.
- **Save / Load** use `IronCrownsUnreal_v1`; previous slot is `IronCrownsUnreal_v1_previous`. This is a local convenience backup, not crash-proof transactional storage or cloud sync.
- **Next map** requires a second press, preserving the on-disk save unless Save is explicitly pressed.

## Tests without Unreal

From the repository root:

```sh
bash scripts/test-unreal-rules.sh
```

Covers map topology and bridge routing, placement/overlap/bounds, exact resource cost, no production without a stockpile, timed grain/flour/bread conversion, gate occupancy, state round trips, invalid/corrupt snapshot rejection and failed-load non-mutation. This is a logic test, not an Unreal build.

## Platform and scope

The intended Android package is `com.ironcrowns.unrealprototype`, independent of previous apps. Android output is not built yet. The mobile-oriented renderer settings disable Lumen methods/virtual shadows/motion blur; they are **configuration intentions, not certified 4/6/8-GB performance**. No 1-GB asset library, OBB, authenticated Android Supabase save or Dropbox save integration is included.

### Recorded verification

Portable-rule CI [39375574500](https://github.com/s1po0/iron-crowns/actions/runs/39375574500) passed for source commit `c175fc6`. Local GCC sanitizer tests also passed with warnings treated as errors. These are **portable C++ checks only**, not Unreal Editor/UHT/Android compilation. No old Android release was replaced.
