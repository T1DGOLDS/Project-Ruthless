# Quest availability — beta96

Map pickup discovery no longer depends on Blizzard returning every quest through GetAvailableQuestLines/GetQuestLineInfo. That beta94 approach failed live and its per-ID native scan has been removed. RUI now bundles a corrected Forever pickup index and independently evaluates known acceptance requirements for the current character. Native offers remain authoritative supplements and retain priority over recorded gates. Blizzard pins and blue objective areas remain untouched.

## Main map

With quest markers enabled, browse any covered zone or continent: eligible, unaccepted, uncompleted quests appear at recorded quest givers, independently of the chosen guide or selected quest. Multiple givers are preserved. Hover a pickup marker to see quests at the same spot. The map's Available tab searches the viewed map and its child zones by quest name, giver or quest ID. Results sort by quest level/name, show giver coordinates, and can be clicked to follow that pickup; Shift-click inserts a native chat link where available. The native Quests tab still shows the active quest log. Search focus is retained while typing; rows reuse frames and follow sidebar width.

## Requirements and performance

Checks cover minimum/maximum level, explicit race/class masks and class sorts, prerequisite groups/alternatives, exclusions, active-parent/unlock gates, professions, reputation, source items and known spells/specializations. Forever Skyborne IDs 95/96 use explicit bits 32/33 without 32-bit truncation. Repeatable/exploration flags alone are not missing acceptance requirements. Unsupported/missing requirements stay uncertain and are not shown as confirmed available. Completed and held quests are excluded. Existing trivial/account-completed filters apply.

Generated tables do not allocate on file load. The catalogue is requested on map browsing or an explicit metadata/status lookup; discovery uses precomputed per-map lists and caches requirement results against character/quest lifecycle invalidation. It does not repeatedly ask the client to confirm thousands of IDs. Before the first map/status request, the native-only minimap feed stays lightweight. After data is loaded, current-zone pickups remain available on the minimap. Combat keeps cached results; uncached eligibility waits for combat end. Map/quest work still uses the existing coalesced events and combat-exit grace period. Full-world first-open cost needs live measurement; no FPS guarantee is claimed from mocks.

## Source and coverage

[Current source and notices](../Assets/QuestPickups/README.md): QuestieDB Forever revision c1b50fefb19c064edc436429bef73435d9ff4254, retrieved 2026-11-09, including static/derived and faction-specific Forever corrections. This is bundled factual reference data, with no installed-addon dependency. Full upstream GPLv3 permission, historical-contributor caveat and provenance are preserved; editable JSON and its deterministic builder ship with the data.

5,233 source records, 4,491 located, 48 maps. Cross-checking readable installed-client IDs leaves 4,499 with metadata and 3,957 with locations. 2,115 readable IDs lack metadata, another 542 lack recorded locations, and 92 client records were encrypted. Some IDs represent non-pickup/internal content: these counts are data gaps, not a count of missing playable quests. Native offers supplement coverage. Current game data and this source still do not prove a complete list of every server-eligible quest. Diagnostics show these counts; searching an exact quest ID with no result explains known locks or missing metadata. No fabricated pickup coordinates or eligibility.

## Verification

Actual Lua 5.1 compilation; complete generated-source/index validation; real Westfall records render into pickup points while native offers return nothing, with no accepted quests/guide and unrelated selection; completion/acceptance, level/race/class/prerequisite/exclusion/reputation/repeatable/restricted/combat rules; faction-specific giver isolation; continent/zone and name/giver/ID search; cached reads; native-only supplements; actual Available page focus/pooling/resize/follow/cleanup. Existing quest, independence, performance and Forever source contracts remain checked. Live client rendering/eligibility remains a pending release gate: reload beta96, browse Westfall, hover markers and use Available, accept/turn in quests, change maps, and repeat in combat.
