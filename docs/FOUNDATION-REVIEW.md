## Beta.25 free resize and dungeon sharing

Reload. Drag the bottom-right + handle horizontally: width changes while height and text scale stay fixed. Drag vertically: only height changes. Reopen the map to check saved dimensions. Check wide and minimum-size Quests/Settings/Dungeons views: native search/count and scrollbars must remain within the sidebar, tabs/content should reflow and the map viewport must remain separate. Map projection and icons remain native; a wider viewport does not stretch geographic pixels.

In a party, use Dungeons > Share dungeon quests. Each click shares one held, natively shareable quest; wait for party responses, then Share next. Tracker dungeon rows also offer Share. Pickups, unshareable quests, solo mode and combat cannot issue shares. A sent request does not mean a recipient accepted it; native level/prerequisite restrictions still apply.
## Beta.24 map review

Reload, open the map, and drag the small bottom-right triangle diagonally. Map, markers and menu scale proportionally; scale is saved per character. The top tabs remain present on Quests. Switch Quests/Settings/Dungeons/Atlas repeatedly, accept a quest with Settings selected, then reopen the map. Only the selected right-side view should appear. Wooden filler and ornate breadcrumb textures are removed; native map canvas, icons, zoom/pan, navigation and quest actions remain. Resize/switching are blocked during combat. New regression tests pass in mocks; native rendering and taint require live review.

# Foundation review — beta.23

Review entry: reload the live linked addon, open /pr, then Profiles and About. Profiles stores presentation/behaviour settings only; progress, macro content, error history and character locations remain local. Paste exports into the editor to import; validation completes before any write. Undo keeps one previous settings snapshot. Reload is explicit so no old views silently retain changed settings.

Performance changes: tracker has no OnUpdate dispatch; separate native timers run navigation at 250 ms and guide/context checks at 2 seconds, stop on hide and guard hidden parents. Existing unchanged-loot batching remains. Map/minimap pin identities survive selection/style-only changes; removed locations unregister individually and pooled frames are reused. Genuine new pin sets still register synchronously: incremental updates reduce churn but do not yet enforce a time budget.

CI executes all seven suites with Gethe/wow-ui-source revision a84e2b1b41d3d4137127c07e4da448aa3251d6f1 as reproducible compatibility input. Native sources are excluded from addon syntax traversal. New regressions cover keyed guide IDs, unchanged-marker registration counts, timer lifecycle, combat queue replacement, profile validation/roundtrip/undo and options construction.

Options now ship as a separate load-on-demand addon with a lightweight main-addon loader. Install both folders.

Remaining competition gaps: full widget/font/pixel/theme migration, unified layout editor and deeper per-control search (navigation search is implemented), comprehensive eligibility predicates, stable guide adapter/own authored content, verified dungeon coverage and broad combat/everyday UI ownership. Shared surface tokens and settings profiles are foundations, not completion of those larger systems.

Live acceptance: check arrow while moving and crossing zones; loot/accept/turn-in hitches; map selection/pins before and after completing quests; enable/disable in combat then leave combat; menu/profile scroll and saved placement; reload with optional providers absent; fresh taint errors. Source/mocks cannot certify native rendering or comparative CPU/FPS.


### Beta26 visual review
- Reload, open the map and compare shell/tabs/quest background with the tracker. Check city and outdoor maps, narrow and wide window sizes, all sidebar pages and native quest details.
- Confirm class accents remain; incomplete counts are warm yellow, completed counts muted green, colon-delimited objective targets light cyan. Difficulty colours must still be visible.
- Scroll/collapse/reopen the quest list: no duplicate colour markup or broken item links; map artwork and quest icons remain usable. This build uses existing game fonts rather than bundling Inter/Cascadia.

### Beta27 error retest
Reload first to clear the invalid map state and prior taint. Open Dungeon atlas and select several dungeons/floors, then close with Escape and reopen with M. Missing native maps should say unrecorded rather than changing the map. Confirm bosses/loot/quests remain accessible. Toggle the RUI tracker off/on outside combat; native tracker alpha should restore. Monitor fresh errors and stalls while accepting/looting quests. Details' secret-role error remains outside this patch.

### Beta28 live review
Restart WoW once to discover ProjectRuthless_DungeonData. Test Dungeon atlas with Atlas and AtlasLoot disabled: Deadmines interior/entrance, BFD sections and a TBC dungeon. Resize wide/tall, switch tabs, close/reopen the map and confirm reference art returns. No player marker is expected on static maps. Boss lists and loot must remain available; custom/unrecorded maps must say so.

Click a held quest: description, rewards, Back and bottom action buttons must fit the right pane with dark styling. Check long descriptions and multiple item rewards at minimum and wide map sizes. Check Selling Fish drop locations now show bags on the minimap; interactable objects still show cogs.

Tools → Review grey quests to abandon should show only native grey, abandonable quests and change the button to Confirm abandon. Changing tabs cancels. Only confirm when willing to lose the listed progress/items; green quests must remain untouched. Recheck combat blocking and new errors.

## Beta 31 authored guide review

Use [Authored guides](AUTHORED-GUIDES.md) for coverage and the Stormwind → Westfall → Deadmines live journey. Include other-class and missing-profession pickups in the availability review; uncertain category-only requirements must remain silver and explicit.
