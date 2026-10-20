# Castle 0.9.1 — construction usability fix

The player's report was that they could not build a farm and could not find a usable build command. The old confirmation lived among unrelated actions and became disabled on invalid/unselected ground, without a prominent explanation. Prior tests invoked simulation placement directly and tested GUI startup/gates, not the complete touch-only farm construction flow. Those checks were insufficient to establish that construction was usable on Android.

## Changed interaction

1. Tap **کێڵگە** (Farm). All ten building choices are now in two visible rows, not a horizontally clipped carousel.
2. Tap empty ground, or **شوێنی گونجاو** (Suitable plot). The latter selects a legal plot near the camera and centers it, without spending resources.
3. Tap the large green **دروست بکە: کێڵگە** (Build: Farm) button in a dedicated panel above the other controls. A farm costs **35 wood** and takes eight simulation seconds to finish.

The panel displays resource shortages, unsuitable terrain/occupancy, pause state or the next step. Invalid placement no longer makes the command disappear into disabled styling: pressing it explains the problem without charging resources. Pause/game-over still prevent mutation. A map position must explicitly be selected; successful construction clears that selection to prevent accidental duplicate purchases. Cancel spends nothing. Building a farm does not instantly award wheat; a completed stockpile and a worker with available housing are still required for deliveries.

## Verification

The engine test now uses real injected screen-touch events for Farm → map tap → Build, checks the farm exists and exactly 35 wood was charged, and tests invalid confirmation, repeated confirmation, Suitable plot and Cancel. It also asserts the farm choice is fully inside the viewport. No direct simulation placement is used to construct the farms in that GUI test.

A separate Android emulator test installs the actual exported APK, selects `.icdata` through the native Android document picker, taps New Game → Farm → Suitable plot → Build → Save, then inspects the saved farm read-only. It force-stops/restarts the app, resumes and checks that the same farm remains. This passed in [build 39370252398](https://github.com/s1po0/iron-crowns/actions/runs/39370252398), source `cac97d6`, together with the engine regression tests and export. This is not physical-phone testing. The initial emulator test did create the farm and charge 35 wood, but failed a wall-clock completion assumption: software rendering advanced simulation slowly. The test now waits for observed completion without altering game speed or resources.

## Installation caveat

Package `com.ironcrowns.castles.buildfix` is isolated from previous previews because their ephemeral signing keys cannot be recovered. Keep previous apps installed to preserve their private saves; this is **not** an in-place update or automatic cross-package save migration. Existing Castle API-1 Data is compatible. No content-size, graphics overhaul or cloud-save completion is claimed by this focused fix.
