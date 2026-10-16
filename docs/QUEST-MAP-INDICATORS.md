# Visual quest indicators — Forever beta46

**Beta 78 update:** RUI positions supplemental markers without an installed map library. The external spawn database is removed by request; source-specific markers are omitted where verified records are absent. Native pins/blue areas remain. [Stage five](STAGE-FIVE.md) supersedes historical coverage/dependency descriptions below. Blue spawn dots remain disabled.

Native blue quest areas remain owned by Blizzard. The addon does not infer boundaries from spawn points. Native map pins take priority when public waypoint metadata exists; blue recorded-location dots supplement remaining quests. Selected locations are larger; gold symbols show pickup and turn-in; uncertain pickups are faded.

All added indicators are visual only: mouse-transparent, no selection, waypoint, tracking, quest-panel or movement actions. Existing native Blizzard markers retain their native behavior. Coordinate coverage uses optional QuestieDB and existing HBD Pins; no new scans or polling are introduced. The selected same-zone minimap edge arrow points to the nearest recorded selected location at refresh time, not a calculated travel route. Other-map/unknown-map direction is omitted. Native player/quest navigation remains intact.

Live review after /reload:
1. Open a logged quest on the main map: check native blue areas, selected emphasis, gold symbols and absence of square/grid shading.
2. Pan and zoom: check marker alignment and size. Click through an RUI dot: it must not change quest selection, tracking, waypoint or open details.
3. Select a quest in the existing quest UI. Move toward its location: the minimap edge arrow should rotate with map orientation and disappear inside the visible map. Repeat with a square and rotating minimap if available.
4. Change selected quests and zones, finish an objective, turn it in and disable the workspace: verify stale indicators disappear.
5. Repeat target/quest interactions in combat and inspect fresh errors. No local test proves live rendering or taint safety.

Automated coverage: passive frames, pool reuse/cleanup, direction-point selection, cross-map fallback, edge rotation/arrival hiding, native marker preference, native area preservation and existing combat-grace scan behavior. Full Retail quest-data coverage and boundary parity are not claimed.

## Beta50 update
Supplemental blue spawn-point dots are now omitted on both maps. Recorded objective locations still support routing and selected minimap edge direction. Native objective-area shading and native quest markers remain unchanged; supplemental pickup and turn-in symbols remain. This supersedes the earlier blue-dot presentation described above.


## beta59 — typed objective spawns
Recorded QuestieDB NPC kills use swords; creature item droppers use bags; direct object objectives and object item sources use an interaction cog. Map and minimap bag/sword icons reuse the same texture provider as Forever nameplate hints. Locations must match a public unfinished client objective by ID and type. Completed, unknown or restricted objectives are omitted. Native blue areas and quest actions remain Blizzard-owned; markers have no mouse interaction. Recorded coordinates are not clipped against native blue-area polygons (no polygon contract is available here), and Forever database coverage can lag the server. No blue spawn dots are restored.

Party hover information uses native tooltip AppendInfo/GetQuestPartyProgress with title/player omission. Creature relationships come from the held-quest cached index; objects use native tooltip quest IDs. No fabricated remote counts, addon messaging or party-member installation requirement. Exact live tooltip data availability/updates and secret-safe native rendering still need in-game validation.

RestedXP route-source decision is pending. No RestedXP is installed in the beta addon folder; reviewed upstream RestedXP/RXPGuides RXPGuides.lua, GuideWindow.lua, GuideLoader.lua and functions.lua on 2026-10-10. Its engine owns parsed guides and active step progression, unlike the current RUI hub route engine. Neither its routes nor engine were copied or installed; current authored routes are not claimed as RestedXP routes. The side tracker redesign remains deferred by request.
