# Iron Crowns 0.5 — The Western Road

A focused visual and combat rebuild, not a claim of AAA/Bannerlord realism.

## Changed
- New/continued journeys enter the third-person field with a prominently visible hero.
  REALM opens the existing strategic travel map; FIELD CAMP returns to the field.
- Closer over-the-shoulder camera with obstacle raycasts, subtle impact motion and reduced HUD obstruction.
- Rebuilt human-proportioned armor, smaller helmet, articulated knees/elbows, textured steel/leather/cloth,
  plain heater shields and no colored foot rings or giant helmet crests.
- Original generated ground, masonry, steel, wood, plaster and roof materials with approximate normal maps;
  continuous terrain/path, atmospheric distance, leaf cutout trees and instanced grass instead of geometric crowns/cones.
- Attacks have windup/recovery, reach, facing and wall-occlusion checks. Shields protect the front only;
  fresh player guards can parry. Impacts stagger, blocking uses stamina, and a stationary dodge steps backward.
- Enemy attacks have readable windups, recovery and defensive reactions.
- Original synthesized footsteps, swing, impact, shield-clash and wind sounds; mute option.
- Saved Mobile/High settings: 600/1,800 grass instances, 2x/4x MSAA and short/long shadow distance.

## Kept
32-settlement strategic map; field battles; wanderer origins, courier jobs, companions and businesses.
Same offline Android package and save v3 compatibility. No campaign reset is needed with a matching signing key.

## Honest limits
This remains procedural prototype art and animation, not scanned assets, motion capture or AAA realism.
One rebuilt shared village/battlefield, not unique explorable interiors for every town. No mounted combat,
full siege system, sophisticated tactical AI, multiplayer or voice acting. Sound effects are synthesized,
not field recordings. Companions remain campaign specialists. Physical-phone performance and extended
combat balance are unverified; start with Mobile graphics.

## Install
Debug-signed ARM64 Android 8+ evaluation APK (x86_64 emulator also included). A changed debug certificate
may require uninstalling the older build, which deletes its local save. Do not uninstall unless you accept
that loss. Automated engine/render/Android checks gate publication; see BUILD.txt and ANDROID-SMOKE.txt.
