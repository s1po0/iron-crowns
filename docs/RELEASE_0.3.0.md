# Iron Crowns 0.3 — A larger, original campaign map

## Map expansion
- A separate **900 × 680 world-unit continent**, approximately 19× the ground area of the previous 180 × 180 diorama.
- **32 settlements:** 8 towns, 8 castles, 16 villages across four original factions.
- Continuous sculpted terrain, mountain ranges, northern snow, southern drylands, forests, a coast, river, bridges, roads, farms, modeled settlements and faction banners.
- Drag/pinch/scroll camera navigation, zoom controls, atlas, settlement browsing and company locator.

## Playable campaign systems
- A mounted company marker travels along a connected road graph with a visible route; arrival pauses time.
- 8 merchant caravans, 4 faction patrols and 4 raider parties move while campaign time advances.
- Provisions, daily wages, grain prices/stock, local-only recruitment/trading, bandit contracts and simple faction hostility/truce transactions.
- Raider encounters and castle garrison challenges connect to the existing 3D battle scene. Captured castles pay daily income.
- Company size, map position, food, cargo, fiefs, relations, market stocks and gold persist. Travel reloads paused; interrupted battles restore the pre-battle company count.

## Important scope limits
This is inspired by the **grounded medieval campaign-map presentation** of Mount & Blade II, but uses original geography, factions, names and procedural assets. It is not a copy of Calradia or a complete Bannerlord equivalent.

The **combat arena has not become a seamless continent**. Encounters reuse one small field scene; castle challenges are field battles, not implemented siege interiors. Full diplomacy AI, noble houses/dynasties, multiplayer, cavalry combat, comprehensive equipment/crafting, audio and a production content library remain absent. Caravans/patrols use simple road movement, not a fully simulated kingdom economy.

## Install and verification
Download `Iron-Crowns-0.3.0-Campaign.apk`. Intended for Android 8+ ARM64 devices. Debug-signed evaluation prerelease, not a store release. Package remains `com.ironcrowns.marches`; debug signing may differ between CI builds, so Android may require uninstalling 0.2 first (which deletes its local save). The save loader accepts v1/v2 data when installed with a compatible signing key.

Engine smoke tests cover map connectivity, trade constraints, route traversal, save round trips, fief income/conquest and combat. Android emulator checks exercise real touch recruitment, settlement selection, road travel, saved arrival, pan/zoom, combat and restart. Real-phone performance, thermal endurance and extended campaign balancing still need testing. Build SHA, checksums and screenshots accompany this release.
