# Stage five — beta 78

Scope: Forever runtime dependency removal, feature ownership and measured performance. Andrew explicitly selected removal of the installed quest database now, with coverage gaps disclosed, instead of retaining it until redistribution permission could be established. No unlicensed database copy is shipped. Existing independently authored route/seed facts remain.

## Ownership

| Feature | Current owner | Limit |
| --- | --- | --- |
| Quest offers, native pins/blue areas and supplied waypoints | Blizzard | Native offers are not a complete quest/spawn database. Absence from a feed does not prove a quest is unavailable. |
| Route order and authored dungeon prerequisites | RUI | 36 existing 1–30 routes/detours and the existing Deadmines preparation seed. No new zone/chain completeness claim. |
| Supplemental visual marker positioning | RUI MapPins | Uses native public map projections, minimap radius and rotation. Unknown/restricted positions are hidden. Round/square minimaps are supported; custom hybrid shapes use conservative round clipping. |
| Combat statistics, categories, rows and interactions | Native DamageMeter | RUI does not inspect combat-session data, calculate amounts or call native setup/refresh/render methods. Native availability and live taint remain acceptance checks. |
| Meter backgrounds/borders and saved geometry | RUI ForeverMeters | Static chrome only; native row styling is retained. Native categories/sessions/secondary-window preferences stay character-owned. Profiles capture native activation and RUI movers. |
| Leveling-guide engine | RUI by default; explicitly selected provider optional | Existing Wisp adapter retained. Other guide engines require verified integration; they are not silently selected. |

The Camelot manifest no longer lists external quest databases, map libraries or loot addons. Bundled RUI Dungeon Data/reference maps remain load-on-demand and retain their existing attribution. External meters are no longer skinned, hooked or rewritten. The last external action-button glow discovery was removed. The unused Retail talent workspace no longer loads on Forever; the native talent button/keybind remains authoritative. Retained Retail files are not newly developed.

## Quest data changes

QuestData is an internal provider. It lazily combines existing RUI route facts, independently authored prerequisite seed facts and current native quest offers. Native zone names resolve against the current continent's map tree; ambiguous names do not create guessed mappings. Available-quest requests are made once per encountered map by this provider; native quest-line responses trigger a coalesced reread without another request loop.

The default offer path never enumerates the full quest catalog. It reads the current zone and displayed map feeds, omits hidden/in-progress/account-filtered offers, deduplicates and preserves the previous result when unchanged. Known minimum-level/faction/prerequisite gates are checked. Other unadvertised pickups show **check the quest giver**, not confirmed availability. Held/completed native state remains authoritative.

The removed database previously supplied comprehensive creature/object spawn coordinates, item droppers/vendors, pickup gates, source-item supply planning, dungeon associations and boss coordinates. That coverage has **not** been replaced. Supplementary cog/bag/sword map/nameplate hints are omitted when their source records are absent; elite classification remains native. Detailed automatic supply suggestions and many dungeon associations/coordinates are unavailable. Existing saved dungeon selections and routes are preserved rather than deleted. Native tooltip quest IDs can still append native party progress; data without quest IDs cannot be associated by guessing.

The map's progression/library, missing-destination label and bug-report checks disclose these gaps. No location is fabricated, no native blue region is replaced and no existing profile/progress table is reset. The generic static-source/eligibility consumers remain available for future verified RUI records, but no external provider is consulted in the Forever runtime.

## Performance evidence

The independence harness runs actual modules with external addon globals replaced by erroring objects. It checks that the active Forever source does not read them or a shared library registry. Native source contracts use the pinned revision in the live-gates record.

| Simulated operation | Verified result |
| --- | --- |
| Register 100 world markers in one turn | One deferred draw, rather than one complete draw per registration. |
| Redraw unchanged cross-map markers | Static projections are reused; no repeated native conversion queries. |
| Remove all minimap markers / hide minimap | The sole 5-Hz positioning ticker cancels. No per-frame RUI dispatch. |
| Read native quest offers | Zero full-catalog ID enumerations. Unchanged offers retain their snapshot and availability revision. |
| Observe 100 native meter-window constructions | One deferred cosmetics/mover pass; existing surfaces are reused. |
| Load an unrelated addon | Quest workspace does not install/refresh its map/tracker. Native map/tracker and selected guide loads remain relevant. |
| Start with quest workspace disabled | No quest-data materialization through tooltip indexing. |

These are workload/behavior checks, not FPS or real-client CPU benchmarks. Normal minimap positioning still costs work while markers are registered. Native systems retain their own update costs. Source tables and reused UI assets remain resident.

During `/pr record on`, operation measurements retain call count, cumulative/mean/maximum elapsed milliseconds and processed-record counts for queued refreshes, native-offer reads and world/minimap marker drawing. Clocks are read only during recording; unavailable/restricted clocks yield no invented timing. At most 32 aggregate operation labels are retained per session, alongside the existing bounded samples/sessions. An operation includes native calls executed within it; timing is not exclusive Lua CPU or exact allocations. Old recordings without this field remain reportable. Recording never enables itself or uploads information.

## Live acceptance

1. Reload with only the three RUI folders enabled. Verify routes, native starts/turn-ins/blue areas, selection and M open/close. Use a quest with no supplied waypoint: the missing-data explanation should appear without a guessed arrow. Repeat in combat.
2. Verify ordered pickups still follow the chosen RUI route. Unadvertised quests should say check giver. Accept/complete/remove quests and change zones/maps; offers should update after native responses. Inspect unsupported dungeon associations and ensure saved selections survive.
3. Check supplemental/native markers through zoom, continent/zone/floor changes, minimap rotation, round/square minimaps, entry/exit and reload. No duplicate native objective pin or blue-dot cloud should return. Off-map/restricted positions should disappear safely.
4. In Utilities enable the native damage meter when available. Test category/session controls, combat, secondary windows and native dropdown interactions. Check its background opacity, saved movers and profile activation. External meters, if separately enabled for comparison, must be unchanged. Native meter data is not certified taint-free by our static chrome tests.
5. Save/apply/undo/export/import two profiles and reload. Check existing quest progress, chat, bag positions and account defaults. Native meter category/session preferences intentionally remain native character settings.
6. Record matched idle, travel, quest/loot bursts, map interactions and combat sessions. Compare RUI recent CPU, spikes, memory growth and operation aggregates in `/pr report`. Recording adds overhead; whole-game frame gaps cannot prove RUI caused a hitch. Check fresh errors and blocked actions.
7. Test the Utilities controls and coverage notices at 100–150% text, keyboard search/navigation and small-screen layouts. All six live gates remain pending until Andrew supplies current-build evidence.

Run `npm run test:independence` with `PR_WOW_FOREVER_SOURCE` set to the pinned native addon source. Other suites retain generic static-record fixtures; those are not assertions that the removed database coverage ships in this build.
