# The Open Road — playable wanderer mode

## Start
Select **Create Wanderer** on a clean install, choose an origin, then **Start My Journey**.
Your character is Samir Farroad, an original caravan-raised wanderer. The new path begins
neutral toward all four original realms, with eight soldiers and no land.

| Origin | Starting gold | Food | Mechanical advantage |
|---|---:|---:|---|
| Merchant | 180 | 35 | Grain buy and sell quotes reduced by 1; more seed capital |
| Pathfinder | 120 | 50 | 15% faster travel |
| Freeblade | 120 | 35 | 220 maximum HP instead of 180 |

Origins can only award their starting benefit once. There is no full skill tree,
custom name input, character appearance editor or mounted battlefield combat.

## First playable quest
1. At Hearthglen, open **Journal / Jobs** at the bottom of the map.
2. Choose **Companions** and hire Mara Reed for 60 gold if desired.
3. Choose **Courier Jobs**, then **Accept Delivery**.
4. Choose **Travel to Recipient** to route to Dusk Tower, or close the journal and use map travel.
5. Arrival pauses time. Open the journal and **Hand Over Letters** for 45 gold.
6. Read the Logbook to see completed jobs and places visited.

Only one delivery can be active. It occupies no grain cargo space and requires no deposit.
Each board targets the next settlement in the world registry; rewards are 45–75 gold.
Payment requires physical arrival and can only happen once. Deadline: end of the displayed day
(current day + 4). Origin boards refresh after two days, including after abandonment.
You cannot accept a board remotely. Job state, cooldowns, companions and visited places persist.

## Small-company economy
- Food: 20 provisions for 20 gold. Starting company consumes two per campaign day;
  larger groups consume more. A traveling Steward reduces consumption by one, minimum one.
- Soldiers: recruit up to three for 30 gold, maximum twelve regular soldiers.
- Wages: the existing company wage is at least two gold, normally half the regular soldier count.
- Grain: carry up to 20 units; prices depend on settlement faction, stock, day and origin.
  Local round-trip buying/selling loses money. The logbook counts positive realized margins
  on tracked purchased grain, not revenue or net profit after wages.
- One real second is one campaign hour at 1×. Time pauses in the journal and on arrival.
  Select 1×/2×/4× to run the map while stationary; pay attention to food and wages.

## Four tavern specialists
| Companion | Home town | Hire fee | Effect |
|---|---|---:|---|
| Mara Reed / Scout | Hearthglen | 60 | +10% travel speed while accompanying you |
| Torren Vale / Steward | Stonewatch | 70 | Saves one food/day while accompanying you |
| Nadia Saffron / Trader | Duneshade | 80 | +12 gold per owned-caravan arrival when assigned as leader |
| Edda Grey / Guard | Highcourt | 70 | Reduces the caravan's weekly toll from 30 to 12 gold when leading it |

Each costs two gold/day. These are campaign support specialists, not extra named fighters
or distinct 3D companion models. An assigned caravan leader no longer supplies an escort bonus.
Hire locally; view all home towns and abilities from any location.

## Businesses without land
### Caravan: 400 gold
One owned caravan supported. Hire a companion, visit a town, open Businesses and cycle the
leader selector if necessary. Launch there. Your caravan replaces the first ambient caravan
with an owned, labeled road party. It follows actual connected routes and earns on arrivals:
32 + one third of destination prosperity, plus the Trader's 12-gold bonus when applicable.
Daily cost is six gold including the leader's two-gold salary. Other companions cost two each.

Every seventh campaign day, while at least one of the four raider parties remains undefeated,
the business pays a simplified 30-gold toll (12 with a Guard leader). Defeating all four ends
these tolls. There is no random permanent caravan destruction or full commodity-trading AI.
On reload the owned caravan restarts from its home; finances, ownership and leader persist.

### Grain mills: 500 gold each
Own up to three, one per town. No fief or companion is needed. A mill consumes six stock each
day, returning 10 + one eighth of town prosperity in gold. It suspends income if stock is
insufficient or the owning realm is hostile. Regular market stock replenishment still runs.
There is no workshop interior, production selection or confiscation simulation.
The operating ledger includes companion upkeep and business income/cost, but excludes setup
fees, company wages, food and personal trade. Do not interpret it as your total cash profit.

## Independence and compatibility
New wanderers cannot challenge settlement garrisons. They can trade, recruit, fight raiders,
complete deliveries, accept Roadwarden bounties and own businesses without faction service.
No formal kingdom mercenary contract is implemented. Original four-realm geography and assets
are used, not Calradia or Bannerlord's content.

Save v3 reads prior v1/v2 saves. Existing nonempty campaign states become Veteran captains and
retain their holdings/conquest access; the update does not erase those games to impose a new
origin. There is one save slot and no in-game new-game reset. A fresh install or cleared app
data begins the new neutral path, but **clearing app data deletes the previous save**.
Signing-key changes may require uninstalling to install the APK, also deleting local data.

## Verification
The engine smoke suite covers origin award idempotency, local/remote delivery gates,
expiry/cooldowns, hire locality, companion assignment, business purchase limits and money,
arrival rewards, operating cost, toll removal, neutral assault rejection, malformed saved IDs,
legacy migration and JSON round trips. Existing combat/terrain/road/trade tests remain.
Android touch tests create an origin, recruit soldiers, hire Mara, take and complete a courier
job via real map travel, inspect saved neutrality and milestones, exercise field controls,
and restart the process. Rendered captures are generated from the game, not concept images.
Physical-phone performance and long-duration balance remain unverified.
