# RUI authored guides — beta 69

**Beta 78 update:** runtime eligibility/location reads now use native/RUI data. External database audits below record historical fact verification, not a runtime dependency or permission to bundle its dataset. Missing spawn/pickup-gate coverage is disclosed; see [stage five](STAGE-FIVE.md). The tracker now shows the current task, with full route browsing in the map.

Open the map, select **Library**, then choose a faction guide. **Chapters** shows the full current route note, chapter selection, pause/resume, stop and skip controls. The tracker keeps a short instruction, current objective and upcoming quests. Selecting a guide clears manual quest focus; returning with Guide restores route navigation.

## Coverage

36 original routes and optional detours cover 20 zones and 673 quest IDs verified against the installed Forever QuestieDB. Shared zones have separate faction routes. Short detours are explicitly labelled in Library and never auto-start as a main leveling route.

| Faction | Zones | Route levels |
| --- | --- | --- |
| Alliance | Elwynn Forest, Dun Morogh, Teldrassil | 1–10 |
| Horde | Durotar, Mulgore, Tirisfal Glades | 1–10 |
| Alliance | Westfall, Loch Modan, Darkshore | 10–20 |
| Horde | The Barrens, Silverpine Forest | 10–20 |
| Alliance | Redridge Mountains | 15–20 |
| Horde | Stonetalon Mountains | 15–20 |
| Both | Ashenvale | 18–20 |

Routes group pickups, objectives and turn-ins into authored hub circuits. Native quest history skips completed quests and advances completed chapters. Progress and explicit skips save per character. Skip leaves the quest in the log. Requirements are evaluated before recommending pickup; unknown requirements show a check-giver status rather than claiming availability. Optional QuestieDB supplies prerequisite and location evidence; without it, availability stays unverified. Held quests use native objective progress.

No guide polling or events are added. Data tables are created on first guide use, and unchanged quest/level/provider/offer state reuses the resolved guide. Existing batched tracker events drive progression. Upcoming current/next chapter IDs feed route supply planning.

## Level 20–30 additions

Select a continuation from **Map > Library**. Existing route/chapter/skips remain saved; completing the earlier route does not automatically change zones.

| Faction | Guide | Levels | Chapters |
| --- | --- | --- | --- |
| Alliance | Duskwood | 20–30 | Darkshire and Raven Hill; The hermit and the cemetery; Sven and the shadowy figure; Southern woods and final reports |
| Alliance | Wetlands | 20–30 | Menethil and the road; Greenwarden and excavation; Raptors and the wrecks; Final hunts and Dun Modr |
| Alliance | Ashenvale | 20–30 | Astranaar continuation; Western and central forest; Raene’s investigation; Eastern forest |
| Horde | Ashenvale | 20–30 | Warsong and Zoram’gar; Thistlefur and the hunt; Satyrs and Warsong supplies; Sharptalon and closing reports |
| Alliance | Stonetalon Mountains | 20–28 | The border and Gaxim; Windshear work; Charred Vale and northern reports |
| Horde | Stonetalon Mountains | 20–29 | Sun Rock continuation; Rebirth and the vale; Windshear and northern targets |
| Horde | Hillsbrad Foothills | 20–30 | Tarren Mill arrival; Hillsbrad farms; The town and mine; Final orders |
| Horde | Thousand Needles | 23–30 | Freewind Post; Sacred fire and Grimtotem; Escorts and northern reports; Shimmering Flats |

The new guides contain 212 unique quest references (206 additional unique quests across the full catalog). Identity, minimum level, faction masks and prerequisite order were checked against the installed Camelot QuestieDB 1.60.1 metadata on 2026-10-11. Original notes group pickups and travel; availability still uses the live provider, with unknown gates clearly reported. Group targets and escorts may be skipped; these are not a measured XP-complete or speedrunning itinerary.

Live acceptance: use an unfinished Alliance Duskwood/Wetlands character and a Horde Hillsbrad/Thousand Needles character. Check pickups against the actual giver, advance a multi-stage chain, reload, and compare chapter/objective progress. Verify each travel loop and pacing before treating route recommendations as optimized.

## Beta69: remaining twenties zones and short visits

Thirteen additional routes fill the remaining outdoor zone/faction coverage supported by the installed Forever metadata. There are now 21 routes or detours starting at level 20 or later, alongside the 15 earlier guides. This adds 101 unique quest IDs to the catalog; the new routes reference 159 distinct quests including earlier prerequisites. Earlier routes and their IDs/chapter order remain unchanged.

| Faction | Additional guide | Suggested levels | Coverage |
| --- | --- | --- | --- |
| Alliance | Redridge Mountains | 20–27 | Lakeshire/lake, northern camps/watchtower, Blackrock strongholds |
| Horde | The Barrens | 20–30 | Crossroads/Ratchet, Taurajo, Bael Modan/coast, final hunts |
| Horde | Silverpine Forest | 20–24 | Sepulcher/roads, Ambermill/Beren’s Peril, Fenris/departure |
| Alliance | Loch Modan | 20–30 | Dam, Farstrider Lodge/group hunts, optional late forge return; use other zones between these visits |
| Alliance | Darkshore | 20–28 | Northern coast, southern escorts, Althalaxx/Ashenvale |
| Alliance | Thousand Needles | 28–30 | Theramore/Highperch and Shimmering Flats; Horde settlements/tasks excluded |
| Alliance | Hillsbrad Foothills | 25–30 | Optional Southshore coastal detour |
| Alliance | Westfall | 20–22 | Optional lighthouse and note detour |
| Alliance | Dun Morogh | 20–23 | Optional Stonegear/Wetlands collection trip |
| Alliance | Dustwallow Marsh | 25–30 | Optional Theramore/Highperch trip |
| Alliance and Horde | Stranglethorn Vale | 28–30 | Separate faction entries for Nesingwary’s introduction only |
| Alliance | The Barrens | 20–24 | Optional Ratchet/Windshear, wanted target and note errands |

The earlier Duskwood, Wetlands, Ashenvale, Stonetalon, Horde Hillsbrad and Horde Thousand Needles continuations remain available. Newcomers receive recorded prerequisite stages in order; completed introductions skip through native history. At overlapping level boundaries, an unconfigured guide now prefers the continuation with the later starting level. Existing active/paused/stopped routes, chapter positions and skips are preserved. Zone transitions remain manual in Library.

“All zones” means outdoor questing zones with recorded non-repeatable content in this range, with a short visit rather than a fabricated full circuit where content is sparse. It does not mean every quest or every zone has ten levels of experience. Installed Forever data puts the first Arathi quests at 31 and Stranglethorn hunting at 31+, so these are not presented as 20–30 hunting circuits. Desolace’s Fish in a Bucket and Feralas’s To the Top are standalone repeatable activities, excluded from this leveling coverage. Dungeon, battleground, class and city-only errands are not separate leveling routes; cities can still be visited by a routed chain. Unrecorded Forever additions remain a data gap.

Read-only metadata audit: `node tools/validate-authored-guides.cjs [path-to-QuestieDB_Camelot.toc]`. It checks every catalog fact against the installed identity/level data, faction/class restrictions and chapter ranges, and checks prerequisite order and duplicate steps for every 20+ route. It records the source version and SHA-256 in its output. On 2026-10-13 this passed against installed QuestieDB 1.0.5 for Forever 1.60.1 (interface 16001). Runtime still checks live eligibility; missing starter/event evidence is not a confirmed pickup.

Live acceptance: reload and select a new route from Library; confirm an actual giver’s pickup, objective and turn-in sequence, then reload mid-chain. Test level-20 Barrens/Redridge selection on an unconfigured character, and confirm a saved earlier guide remains selected. Check optional-detour labels, faction filtering, escort safety and real travel/pacing. Local checks do not establish XP completeness or speedrunning quality.

## Limits

These are first-pass authored circuits, not verified speedrunning routes or a guarantee of reaching level 30 without extra experience. They include selected verified Forever additions, not every custom quest. TBC starting zones and custom starting zones are not included. Class quests and dungeon trips remain separate optional tracking. Runtime coordinates depend on the optional quest database; missing coordinates cannot produce an accurate compass. Cross-continent navigation reports the limitation instead of inventing a bearing.

All prose is original. Quest identity and level facts were checked against locally installed Forever data; no Wisp guide prose or routing was imported.

## Live acceptance: Stormwind → Westfall → Deadmines

Use a level 10–20 Alliance character with unfinished Westfall content. Reload beta 31. Keep the error reporter available and record new errors with timestamps.

1. Open Library and start Westfall. Chapters must replace the quest list cleanly; the full route note must remain readable when the map is wide, tall or small. Switch Quests/Chapters/Settings repeatedly: only one body should show.
2. In Stormwind, open Supplies and check eligible upcoming Westfall purchases. Owned items reduce remaining quantities; completed target quests disappear. Unknown item/source data must not become a false AH instruction. Route prep is evidence-dependent, not a promise that every ingredient is purchasable.
3. Travel to Westfall. The current quest stays visible across zones; a bearing should appear when both positions can be resolved. Nearby quests/pickups must stay within 500 yards. Click a quest to focus it, then Guide to restore the route.
4. Accept, loot for, complete and hand in one routed quest. Pickup changes to objective, then turn-in, then the next task. Compare with the native quest log. Unmet level/profession/prerequisite pickups must not be labelled available; uncertain data must be explicit.
5. Hover a quest item-drop mob and check unfinished progress. Use an actual quest item outside combat: normal click should use it; modified click should link it. Complete an objective in a party: one RUI message, no duplicates on repeat events.
6. In Dungeons, track Deadmines. Check separate held/pickup rows against actual NPC availability, then Share next in a party. Open Dungeon atlas and inspect local maps/boss/loot data with Atlas/AtlasLoot disabled. Local reference maps must not imply a known player position.
7. Pause/resume, select a later chapter, skip a guide quest, then reload. Saved route/chapter/skips must persist and skipped quests must remain in the native log. Stop must release RUI guide ownership.
8. Compare idle/movement/loot/accept/turn-in with /pr perf and visible FPS. Look for individual interaction hitches, not only average CPU. Local simulations cannot prove live FPS, taint, timing or pacing.

Report build, character level, zone, active route/chapter, action, expected/actual result, and a fresh error if present. Do not abandon useful quests just to recreate a test; use available unfinished content.
