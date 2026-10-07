# Iron Crowns 0.1.0 — Playable Android prototype

An original offline **2D action-strategy prototype**, not the full 3D Unity/Unreal game in the roadmap.

## Download
Install **Iron-Crowns-0.1.0-prototype.apk** on Android 8.0 or newer. Allow installation from your browser/file manager when Android requests it. No network permissions, accounts, purchases, or ads.

## Play
- Travel between four settlements; recruit, train, buy provisions, and trade grain.
- Take a bounty contract and lead your company into real-time field battles.
- Use the left stick, STRIKE, BLOCK, and HOLD / CHARGE / WALL / FOLLOW.
- Capture three keeps to unite the Marches; fiefs generate daily income.
- Campaign autosaves. A killed battle restores the pre-battle checkpoint.

## Verification
Built with JDK 17, Gradle 8.9, Android SDK 35. Campaign transaction tests and 100,000 randomized rule checks pass, as does Android lint. The attached build metadata identifies the exact source commit; checksums identify the APK. See SMOKE-TEST.txt for emulator verification. Physical-device thermal/performance and full touch-usability testing remain outstanding.

## Important limitations
**Debug-signed prerelease for evaluation only**, not a production/store release. Independently rebuilt APKs may require uninstalling the earlier build because debug keys differ; uninstall deletes saves.

This version is 2D Java/Canvas. It does not implement third-person 3D, Unity/Unreal, mounted combat, siege interiors, diplomacy/dynasties, audio, multiplayer, or all accessibility features. Keep assaults use field battles. See docs/PROTOTYPE.md for complete controls and limitations.
