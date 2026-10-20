# Crown Campaign — 0.13 development, not an Android release yet

This is an additive Godot campaign, not a completed Warband clone. The published
0.12 APK and complete Data remain unchanged. The new campaign reuses that Data;
its new executable systems require a new APK, not a Data-only update.

## Implemented source

- Four empires, twelve settlements, sixteen adult royal-house members and named
  inhabitants. A local ordinary-person start: 80 gold, six food, no army or house.
- Work, provisions, courier/escort/relief contracts, recruitment and training,
  wages, hunger, morale, property income, allegiance and earned governorship.
- Map travel, periodic border wars/raids, castle capture and garrison reinforcement.
  Battles are explicitly **strategic autoresolution**, not player-controlled combat.
- A walkable 3D settlement representation with reused licensed village models,
  animated inhabitants, faction-colored guards and up to six party representatives.
  Rendered buildings/people are capped for mobile; population is simulated, not
  thousands of simultaneously rendered NPCs.
- Separate atomic local campaign save, validation, corrupt-save write lock and
  confirmed new-game backup. Existing castle RTS remains separately accessible.
- Eight curated Sorani story chapters from a public, read-only Supabase table;
  packaged offline story and validated monotonic cache. No player names, saves or
  private account information are uploaded. Only a publishable client key ships.

## Verification and remaining gates

`Crown campaign validation` compiles with Godot 4.4.1 and tests organic progression,
contracts, saves, invalid data, battles, the live public HTTPS story, actual UI
input and avatar movement. It captures an offline scene for visual review. Passing
syntax parsing alone is not a gameplay verification.

Before Android release: pass engine/UI tests; inspect the actual render; extend
native Android smoke tests to exercise this campaign and return to the old RTS;
export and verify the new APK against the unchanged full 0.12 Data. No 0.13 APK
has been declared tested or published yet.

Not implemented: player-driven melee/riding, fully interactive royal NPC dialogue,
marriage/inheritance, unrestricted diplomacy, or physical-device performance
certification. The underlying original RTS, older modes and public releases are
preserved.
