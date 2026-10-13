## 0.14.0-beta.72 — 2026-10-13

- Merge learned/future spell ranks under native spec groups and order by learned level; enrich old trainer records with exact-rank client metadata, retain explicit unknowns and display learned levels.
- Default to separate compact party cards; Settings > General > Grouped party panel restores the shared background while retaining the existing party mover and position.
- Tighten player/target/target-of-target/party charcoal surfaces and portrait spacing. Keep party pets and native aura widgets outside the card backgrounds; preserve opacity overrides and secure unit behavior.
- Verified local spellbook metadata/grouping, layout/presentation, quest and pinned Forever compatibility checks. In-game appearance and combat acceptance remain pending.

## 0.14.0-beta.71

- Recover future-skill rows from older per-character trainer-price caches, preserving observed prices and explicitly unknown levels. Merge native per-level progression in cancellable 20-level batches and expose a Future skills filter. Suppress learned/older ranks and duplicate native entries; record valid trainer offers even when their prices are unavailable. No Classic spell catalog or guessed Forever levels/costs added.
- Add an owned target-of-target unit frame using the existing RUI unit presentation, direct secret-safe health/resource renderers and secure visibility/target/menu clicks. Give it a persistent targettarget Edit Mode mover and matching Target background opacity. Native pooled/unit updates are not invoked; live portrait refresh follows target identity events instead of health ticks.
- Show 107 known Skyborne racial node locations on the native world map, faction-filtered: Alliance ley lines and Horde elemental convergences. Other races receive none. Passive pins preserve native quest providers; locations do not claim current-phase activity. Coordinate data adapted from MIT-licensed SLLCM v0.3.1, attribution/license in docs/SKYBORNE-MAP-SOURCES.md; no addon installation or communication features imported.
- Quest, layout, performance, Skyborne provider and pinned Forever compatibility checks required. Live spell/trainer metadata completeness, target-of-target event ordering/portrait/layers and Skyborne map pin placement remain acceptance checks.

## 0.14.0-beta.70

- Preserve Blizzard's native map-toggle function instead of wrapping its protected opening path. Permit RUI map tabs, authored guide controls, dungeon atlas browsing, dungeon tracking and local objective selection in combat; defer native layout/waypoint writes. Existing spellbook/bag/settings viewing remains available. Protected edits are not unlocked.
- Replace the rested-XP pip with a flat blue-grey segment ahead of earned XP. Clamp the segment at the current level's edge and show the full numerical rested bonus in the native hover tooltip. Native XP/rested events remain authoritative, including in combat.
- Match charcoal backgrounds to the tracker baseline. Add Settings > Backgrounds with one global slider, sixteen individual overrides and Reset all to global. Update owned backdrops without fading text/icons; include preferences in account settings profiles. Remove stacked action-bar container/portrait and meter background shading.
- Guard every expiring-buff query with the native aura restriction predicate, including outside combat and incremental updates. Restricted updates clear stale custom icons and resume when data is public; this does not expose protected combat auras.
- Local quest, layout, appearance/profile, performance and pinned Forever compatibility checks required. Live combat map opening, rested appearance and background layering need client acceptance. The pasted Details comparison-header error and older native action-cooldown taint remain separate unresolved issues; no third-party code or protected cooldown handlers replaced.

## 0.14.0-beta.69

- Expand twenties coverage with thirteen original faction routes and optional detours. The full catalog contains 36 entries across 20 zones and 673 quest IDs; new routes include recorded prerequisites and retain live eligibility checks.
- Label short visits as optional detours. Prefer a later-starting continuation when unconfigured guides overlap at level 20; retain existing saved routes, chapters and skips. Zone changes remain manual.
- Add a read-only installed Forever metadata audit for quest facts, faction/class restrictions, chapter ranges and 20+ prerequisite order. Quest progression, boundary selection, detour presentation and saved-route regression checks pass locally; travel safety and XP pacing need live acceptance.

## 0.14.0-beta.68

- Add eight original level 20–30 continuation guides for both factions, with ordered hub chapters, chain prerequisites, group/escort notes and the existing saved progression. Library now covers 1–30; zone changes remain manual.
- Make Show quest markers control Blizzard’s questPOI master switch, restoring native pins and blue objective areas when enabled. Keep the native quest log alive behind custom map pages so switching tabs cannot run its focus-clearing OnHide handler.
- Bound Forever profession spell icons to their native buttons, remove parchment/card/rank decoration and retain native rank fill, clicks and confirmation actions. Defer profession styling in combat.
- Quest, layout, performance and pinned Forever checks are required; live marker rendering, profession overlap and route pacing remain separate acceptance checks.

## 0.14.0-beta.67

- Match the shared party surface to the quest tracker opacity, thin border and class accent. Keep portrait boxes/models within their owner's strata/frame level and clip portrait bounds, including player/target portraits.
- Move party auras to the right of each member. Show four small buffs, four small ordinary debuffs and two larger dispellable-type debuffs in distinct rows, using native candidate filters to avoid duplicates. Fit countdown and stack fonts to the icons.
- Preserve actual weapon cooldowns across target/auto-attack changes as Blizzard's swing timer does. Instant/queued spell stop events no longer touch an inactive cast display; native swing events reconcile stale cast flags. Real casts/channels keep priority and resume the remaining swing afterward.
- Local regression and source checks pass; overlap, font readability, dispel display and Heroic Strike event ordering require live acceptance.

## 0.14.0-beta.66

- Migrate party buffs/debuffs into Blizzard's secure-delegated CustomAuraContainer widgets, with RUI square borders, native countdowns, stack counts and tooltips. Each row shows up to four helpful and four harmful auras; harmful borders are red. RUI performs no aura data scans.
- Add compact owned secure pet strips with name, health/resource bars, native target/menu clicks and existence-driven visibility for all five members. Keep opaque health/resource values in the renderer.
- Add ready/waiting/not-ready checks over each portrait; finished results remain briefly, unresponsive members show not-ready, and old timeouts cannot clear a newer check. All three features move and scale with the existing party box.
- Local checks cover native aura API contracts, pet secret-value rendering and ready-check lifecycle; client combat, visuals and taint still require in-game acceptance.

## 0.14.0-beta.65

- Auto-start an unconfigured RUI guide in a supported faction/level/zone. Show ordered pickup, objective and turn-in phases plus upcoming steps independently of quest selection; pickup previews are not treated as accepted quests. Explicit pause/stop remain respected; unsupported zones show route-selection instructions.
- Keep guide navigation and supplemental map selection on the guide step, including pickup steps. Up-next rows follow the same availability priority as the current step.
- Replace RUI styling/layout of native pooled party members with five owned secure unit rows in one persistent party box. Render health/resource values directly without secret arithmetic and leave native pool/setup/aura routines alone. Pet/aura/ready-check presentation is not migrated yet.
- Local quest/layout/performance/Forever checks pass. Party taint, visual layout and route usability require a fresh in-game reload/check; the older cooldown taint report remains unresolved.

## 0.14.0-beta.64

- Record RUI positions in native Edit Mode anchor data and release moved systems from native managed containers before combat, addressing action-bar stack resets. No protected position writes during combat.
- Add free title-area dragging for the combined Backpack, saved with layout profiles and restored on reopen and native container anchoring. Expose Backpack in RUI Edit Mode.
- Add measured red latency bands to main-hand/ranged attack timers and an independent movable/resizable off-hand attack timer. Each uses its own native swing duration; casts retain priority in the player bar.
- Add bounded, read-only action-button taint provenance to SetCooldown error reports. This diagnoses the reported native cooldown failure; its original taint entry point is not yet confirmed or fixed.

## 0.14.0-beta.63

- Disable Blizzard decorative art by default on existing and fresh RUI layouts. Add a per-layout Show Blizzard decorative art checkbox in General options; changing it also updates the active saved profile.
- Strip nested Forever gryphon/end-cap textures, bar/menu backgrounds and legacy named button borders. Retain functional icons, cooldowns, notifications and secure controls.
- Cache native trim assets so opting back in restores them. Native texture/atlas updates and normal-button replacements respect the selected setting; profile load restores the choice and legacy profiles default off.

## 0.14.0-beta.62

- Add an independent Default for new characters profile selector in Edit Mode. Save/Load no longer changes that choice; beta61's automatic default is cleared until explicitly chosen.
- Save native chat tab names, message/channel filters, font size, appearance, locking, interaction, docking/order and detached positions with layout profiles. Restore missing tabs without duplicating or deleting unrelated tabs.
- Show native main-hand/ranged swing timing in the player cast-bar position. Casts/channels take priority; cycles stop on cancellation, target change, death or expiration. No combat-log guessing or idle polling.
- Add account-wide leveling history (/pr leveling or General options): per-level played-time milestones and timestamps, custom range comparisons, fastest runs, class averages with sample counts, and 1–max timings. Missing historical levels remain unknown; server /played anchors each login.

## 0.14.0-beta.61

- Share named Edit Mode profiles account-wide and initialize fresh characters from the most recently saved/loaded profile. Existing character layouts remain unchanged; legacy named layouts migrate on login.
- Add a profile dropdown beside the Edit Mode name field, marking the new-character default.

## 0.14.0-beta.60

- Add a saved guide-source choice in Map & quests options (RUI default or Wisp) and an extensible provider reader contract. RestedXP/Questie adapters remain planned, not advertised as available.

- Keep the tracker current objective, native selected/supertracked map quest and supplemental marker selection together. Restore selection when opening the map, defer native writes in combat and exclude pickup-only suggestions.

## 0.14.0-beta.59

- Add passive cog, bag and sword objective spawn markers on the main map and minimap, sharing bag/sword artwork with nameplates. Only public unfinished matching collect, object and kill objectives are shown; native blue areas remain untouched.
- Append native party quest progress to related creature/object tooltips without requiring RUI on other party members.

## 0.14.0-beta.58

- Group party frames into one RUI panel with a native player row plus four party members, sharing one position and scale.

## 0.14.0-beta.57 — Quest tracker position persistence

- Attach the quest tracker to its saved RUI layout when it is created, restoring position and scale on login without opening Edit Mode. Direct tracker dragging now updates the same layout save, preventing stale editor positions from overriding it. Legacy drag positions remain supported.

## 0.14.0-beta.56 — Compact inventory layout and auto-sort

- Replace the native combined-bag bottom-right grid and excess spacing with a content-sized top-left grid of 36px charcoal slots separated by 2px. Keep native item buttons, bag/slot identity, clicks, sorting, search, assignments and currency controls.
- Add 8/10/12-column choices and a per-character Auto-sort when opened checkbox to the existing Bags menu. Auto-sort runs once per opening; combat/grace defers it and closing cancels pending sorting.
- Add a compact free/total-slot footer and remove the native money-border artwork. Currency tracker height is included in the layout.

## 0.14.0-beta.55 — RUI party frames

- Style Forever native pooled party member buttons with compact charcoal panels, class-accent rules, live portraits and flat health/resource bars. Keep native secure clicks, unit updates, aura/ready-check indicators and group layout ownership; retain one party-stack mover.
- Refresh portraits on member/model changes and defer layout work during combat and its grace period.

## 0.14.0-beta.54 — Quest links, inventory controls and trainer spells

- Shift-click current, nearby, context and dungeon tracker quests to insert native quest links into chat or open a draft.
- Expose native bag assignments, cleanup exclusions and bag-mode options through a Bags header control; retain search and native sorting in compact controls.
- Route Forever spellbook keyboard and micro-menu opening paths to RUI regardless of the legacy separation setting. Preserve native talent opening. RUI remains browseable in combat.
- Persist class-trainer offers and display missing future ranks with their observed required level and price, excluding ranks already represented in the spellbook. Revisit a class trainer after reload to populate offers not exposed by the spellbook API; prices are last observed rather than invented.
- Allow the tracker map menu to open the native map during combat; defer layout changes until combat ends.

## 0.14.0-beta.53 — Professions repair

- Theme the native Forever profession overview and crafting pages with restrained RUI charcoal surfaces.
- Restore a persistent visible red unlearn control for both primary professions while retaining Blizzard's original click handler, confirmation dialog and profession-removal ownership.

## 0.14.0-beta.52 — Flat backpack styling

- Remove leather empty-slot backgrounds and large backpack artwork. Use action-bar charcoal slot surfaces, RUI title font and Backpack label, with a plain Sort control. Preserve native item interactions and indicators.

## 0.14.0-beta.51 — Native RUI bags

- Give Blizzard inventory containers charcoal RUI surfaces, flat slots and clean search/close controls. Preserve native bag layout, item clicks, counts, sorting, cooldowns and quest/quality indicators. No Bagnon integration; styling defers during combat and its grace period.

## 0.14.0-beta.50 — Remove spawn dots

- Omit supplemental blue spawn-point dots on both maps. Native objective-area shading, pickup/turn-in symbols and the selected minimap direction remain; recorded locations still support routing.

## 0.14.0-beta.49 — Movable editor panel

- Drag the RUI Edit Mode header to reposition the panel. Its character-specific position survives reopening and reload; screen clamping and combat restrictions remain.

## 0.14.0-beta.48 — Forever editor and charcoal HUD

- Route Escape menu Edit Mode to RUI; expose native bar visibility, lock/cooldown/pickup settings and per-element settings through RUI.
- Decimal coordinates, editable X/Y, cached 8/16/32 grid, edge/centre/equal-gap snapping and live guides; one chat dock anchor and no unused tab movers.
- Clear remaining static button/slot/XP/chat-input art and preserve charcoal surfaces through native texture resets.
- Show timed helpful player buffs under 30 seconds above the player frame; native countdowns, incremental aura cache and deferred full scans. Move crown/guide away from player name.
- Passive left-side nameplate bag/sword/skull hints reuse held-quest objective/dropper caches; no aura-space changes or per-plate database scans.
- Local checks do not establish live appearance/taint or full native edit-mode parity; see docs/FOREVER-EDIT-MODE.md.

## 0.14.0-beta.47 — Forever HUD presentation pass

- Forever-only artwork module adds shared dark surfaces to action bars/buttons, chat/tabs, micro menu/bags, XP/reputation and Details windows. Flat button/XP fills, cropped icons, thin borders, class accent headings and compact action labels. Existing positions, gameplay values, cooldowns, secure click scripts, chat fonts/links and meter calculations retained.
- Reuses created surfaces; coalesces load/chat refresh; blocks styling in combat and waits three seconds on exit. Native XP artwork refresh is guarded. Details integration themes background/frame only; row textures and statistics remain Details-owned.
- Blizzard objective tracker alpha remains suppressed through native alpha/show refreshes while RUI list is enabled; disabling restores initial alpha. Native tracker visibility/event ownership is preserved.
- Quest, layout, performance and Forever checks pass. Live rendering/taint still need review. Native button art may be reapplied by client states; this is a first review pass, not full theme coverage.

## 0.14.0-beta.46 — visual quest-map indicators

- Native blue objective areas and native quest markers remain authoritative. Supplemental world markers use blue location dots, selected emphasis and gold pickup/turn-in symbols; native waypoint metadata suppresses duplicate supplemental world markers.
- Minimap uses matching blue locations and one selected same-zone objective edge-direction arrow. Existing HBD movement/rotation handles placement; no new polling, scans or automatic waypoint/quest writes.
- All RUI location indicators are mouse-transparent frames with no click handlers. Native Blizzard marker behavior remains native. Recorded points do not imply invented area boundaries or routes; missing database/client data remains missing.
- Quest, performance and Forever checks pass. Live review still needed for artwork, rotation, scale and combat taint.

## 0.14.0-beta.45 — native objective areas and bar corrections

- Remove custom objective shading and kill/collect main-map markers; native blue objective-area provider stays intact. Pickup/turn-in and minimap markers retained.
- Guard cast OnSizeChanged height before arithmetic, using the public calculated icon size instead of reading restricted icon geometry.
- Reapply target skin after native creature-classification size changes outside combat. Combat geometry changes remain queued until the existing grace period; immediate in-combat layout correction is not claimed.
- Quest, layout and Forever checks pass. Live review: reload, inspect default objective areas, target minus/normal creatures outside and during combat, and inspect fresh cast errors.

## 0.14.0-beta.44 — live portrait rebinding

- Clear previous portrait models before rebinding player/target, disable blending and refresh across hidden frame transitions. Rejected model bindings leave an empty portrait instead of another unit's face.
- Layout and Forever checks pass, including denied binding and visibility transitions. Live acceptance: reload, alternate friendly players and creatures with Tab/click, repeat in combat and test player form changes. Restricted model availability remains a client boundary.
- Andrew confirmed beta43 Escape behavior working live.

## 0.14.0-beta.43 — Escape blocked-action mitigation

- Remove the map callback registered in Blizzard's shared Escape handler chain, following user evidence of blocked actions starting with that integration.
- Register WorldMapFrame once with standard UISpecialFrames cleanup; native panel/target/menu ordering remains owned by Blizzard. Reload is required to discard the previous callback.
- Quest and Forever checks pass, including no shared Escape registration and duplicate prevention. Live blocked-action elimination remains unverified.
- RestedXP Guides is Andrew's requested quality benchmark for leveling walkthroughs through 1–20 and beyond, not an error attribution.

## 0.14.0-beta.42 — restricted cast geometry

- Guard cast-bar and icon widths before latency geometry arithmetic. Secret geometry keeps a thin red latency marker.
- Layout regressions and Forever syntax/source checks pass. Live reload and fresh cast/target switching checks remain required. Submitted report contains no RestedXP stack references; no RestedXP fault attribution established.

## 0.14.0-beta.41 — Forever cast and aura error mitigation

- Retire duplicate native player/target cast event subscriptions after owned bars are created, including the target spellbar parent-key fallback. Native mixins and unit-frame target selection are unchanged.
- Aura anchor callbacks no longer reconfigure flow layout during a native anchor pass; configuration remains separate.
- Layout and Forever syntax/source checks pass. Live acceptance remains required: reload, target casting enemies with Tab/click, interrupt casts, gain/lose target buffs, and inspect fresh errors.

## 0.14.0-beta.40 — Forever section removal

- Forever no longer loads Character, Achievements or their title tracker. Native panels remain untouched.
- Removed both settings pages and the Character layout selector; stale settings links return to General. Saved preferences are retained for future reskins.
- Verified Forever compatibility, layout and performance checks, including Forever menu navigation. Live acceptance: reload, confirm both sections are absent, and check native Character/Achievements and Escape behavior.

## 0.14.0-beta.35 — map restore and unit-frame polish

## 0.14.0-beta.39 — Cast cancellation and Escape

- Stop, failure (including quiet failure), interrupt and channel-stop events immediately hide and clear owned cast displays instead of re-reading potentially stale cast info. Ignore late updates after stop; reject old stop events when public cast identities distinguish a newer cast.
- Target disappearance and native target-frame hiding clear the independent target cast bar. Native target selection and unit-frame visibility remain Blizzard-owned; RUI never calls ClearTarget or hides the target frame on Escape.
- Register the RUI map at Forever's addon Escape priority, preserving native popup/menu/casting precedence and world target clearing. Native character panels retain normal panel-manager closing. Register the RUI control centre and error viewer as ordinary Escape-close windows.
- Layout, quest, performance and pinned Forever source-contract checks pass. Live cancellation, combat, Escape order and taint still require reload review.

## 0.14.0-beta.38 — Cast-bar latency zones

- Add red measured-network-latency end zones and millisecond labels to independent player/target cast bars. Cast zones anchor right; channel zones anchor left and scale with accessible duration and bar dimensions.
- Sample world latency only on cast updates, using home latency if world latency is unavailable. Target display represents the local connection. Restricted timing retains a thin marker instead of guessing a duration.
- Keep spell icons outside the progress region, reserve label space for latency and recalculate geometry on resize. Regression checks cover proportions, channels, zero latency and secret timing guards. Live presentation remains pending reload review.

## 0.14.0-beta.37 — Independent RUI cast bars

- Add separate addon-owned player and target cast displays with the shared dark/class-accent style. Cast/channel/target events drive updates; native timer rendering handles progress without addon timestamp calculations or interruptibility decisions.
- Give each bar independent saved position, scale, width and height in the layout editor and named layouts. Small resize steps and cast-specific bounds do not alter map dimensions.
- Suppress duplicate native cast graphics without changing native casting event handlers. Restricted duration rendering shows the spell label with empty fill; interruptibility colours and numeric time are not included.
- Local regression checks cover independent casts, channels, target changes, persistent dimensions, uninspected duration objects and denied-timer fallback. Live rendering and secret-value/taint safety remain acceptance checks after reload.

## 0.14.0-beta.36 — Unit-frame skin corrections

- Remove native player/target combat, threat-ring and status artwork even when Blizzard reapplies atlases or textures. Keep generic HUD borders invisible outside editor movers.
- Keep flat health/resource fills after native atlas updates; align health/resource values inside their bars and match native health-loss layers to the custom geometry. Constrain player hit feedback to the portrait with smaller text.
- Reapply skin after native target updates outside combat with a recursion guard. Existing protected-layout combat deferral remains.
- Temporarily exclude native cast bars from RUI movers/restoration as a precaution for the reported secret-interruptibility taint. Blizzard cast bars remain displayed; independent RUI cast-bar positioning is suspended pending a safe integration. This is a mitigation, not a proven root-cause resolution.
- Layout regression and pinned Forever source-contract checks pass. Updated-client rendering, combat target swaps and cast-bar taint still require live acceptance after reload. Older Details-owned role errors remain separate.


- Match player/target surfaces to the quest tracker: shared translucent dark palette, subtle single border, class accent header and no heavy portrait box outline.
- Restore saved map dimensions/scale after native size, quest-panel and display-state changes. Coalesce restore work and ignore active resizing; retain native opening and combat fallback. M closes the enabled RUI map from quest and custom tabs outside combat.
- Place native target buffs/debuffs above the frame with a full-width upward flow. Match default target scale to player; preserve explicitly saved target scaling. Keep native aura inspection/tooltips and updates.
- Layout, quest, performance and Forever tests pass, including late native map-size reset, toggle on custom tabs, target aura anchoring and scale defaults. Live rendering and taint acceptance remain pending.
## 0.14.0-beta.34 — Forever HUD and persistent map sizing

- Extend the layout editor to native Forever minimap, player/target/focus/pet/party/raid frames, separate cast bars, chat, XP/reputation, action bars, buffs, bags and micro menu when present. Paged selectors and hidden-frame mover previews; readable text nudge controls.
- Add original Wrath X-Perl-inspired player/target presentation: live 3D portraits, dark rectangular panels and flat native health/resource bars. Preserve native unit values, secure clicks and casting; explicitly tint health green and resources by power type; no addon health polling. Other HUD components retain native art with RUI layout control and outlines.
- Synchronise map grip and editor persistence so reopening or reload cannot restore stale map size/scale. Keep independent width/height.
- Display client-provided future spell entries with rank/required level and last-observed trainer cost. Unknown metadata stays explicit; prices require trainer observation and can change. No complete offline Forever training database is bundled. Future entries cannot cast or drag and are excluded from missing-action-bar suggestions.
- Trainer inspection uses cancellable 20-row/100 ms batches. Saved HUD anchors restore outside combat after a three-second grace. Local layout/quest/performance/Forever checks; live portrait composition, protected behaviour, HUD art and spell coverage require review.

## 0.14.0-beta.33 — RUI layout editor

- Add /pr edit and General settings entry: labelled movable RUI anchors, screen/centre alignment, grid snapping, selected-element position/scale controls and independent map dimensions.
- Save up to 10 named character layouts, retain 20 undo actions, cancel a session or reset a selected element. Restore supported lazy-created panels; close and block editing in combat.
- Share the Core theme with editor and Character surfaces; retain class accents. Native/ElvUI combat frames and child achievement panels remain outside editor ownership.
- Layout, quest, performance, equipment and Forever checks cover the review build. Live drag, responsive rendering, scale/persistence and taint acceptance remain pending; see docs/LAYOUT-EDITOR.md.

## 0.14.0-beta.32 — shared availability and paced discovery

- Share cached available/locked/uncertain pickup results across marker, nearby, dungeon and authored-guide surfaces. Separate discovery difficulty filters from actual acceptance requirements.
- Add explicit prerequisite/conflict/level reasons and native reputation, spell/specialization and quest-start item checks; unsupported requirements remain uncertain.
- Suspend discovery during combat and for three seconds afterward. Resume at most 25 quests per 100 ms slice, yielding after a soft 2 ms budget where profiling is available; no combat polling. Keep settled lists until a full scan completes. Ordinary loot without discovered quest-start item dependencies does not rescan.
- Quest/performance/Forever checks pass; live smoothness, availability accuracy and taint require review.

## 0.14.0-beta.31 — authored Classic 1–20 routes

- Add 15 RUI-owned hub routes across 14 Classic zones, with 366 Forever-verified quest identities, original route notes and per-character chapter/skip/pause state.
- Exclude other-class quest categories even when explicit masks are missing; profession categories without verified gates are uncertain, and malformed native profession records cannot imply eligibility.
- Resolve pickups, held objectives and turn-ins from native quest state; expose blocked/uncertain requirements, skip completed chapters and reuse unchanged guide reads.
- Library starts RUI guides; Chapters shows full scrollable notes and controls. Tracker instructions stay compact, guide return clears manual marker focus, and upcoming chapter quests feed supply preparation.
- Quest, performance and Forever checks cover guide progression, requirements, cache reuse and existing navigation/item/dungeon flows. Live pacing, rendering, FPS and taint remain review items; see docs/AUTHORED-GUIDES.md.

## 0.14.0-beta.30 — quest detail background bounds

- Anchor the reskinned quest-detail background to its responsive panel rather than retaining Blizzard's atlas-sized texture height. Prevents the black background extending beneath the map window.
- Quest checks pass; live visual bounds require review.

## 0.14.0-beta.29 — nearby range

- Both nearby quest lists now exclude objectives and pickups beyond 500 yards; native squared distances use a 250,000 threshold. Selected current objective and dungeon manager remain available.
- Quest checks pass.

## 0.14.0-beta.28 — standalone dungeon reference maps and quest polish

- Bundle Classic/TBC map images and demand-loaded dungeon boss/loot records; Dungeon atlas no longer requires Atlas or AtlasLoot. Unsupported native floors use RUI reference maps without invented player coordinates.
- Local reference maps fit the viewport, provide recorded entrance/section selectors and release textures on hide. Package now includes ProjectRuthless_DungeonData alongside primary/options folders.
- Quest details use dark surfaces, compact neutral text and class headers; description/reward/actions remain inside the responsive sidebar with native callbacks preserved.
- Collect minimap markers use bags; object interactions keep cogs.
- Tools offers Review grey quests to abandon, followed by explicit Confirm abandon with the full list visible. Rechecks native grey/abandonable state and combat; leaving Tools cancels review.
- Quest/performance/Forever and bundled-asset checks pass. Live map artwork, details/rewards layout, abandonment and taint acceptance pending.

## 0.14.0-beta.27 — dungeon map error guard

- Validate native map info and nonempty, positive-dimension map art layers before offering or opening dungeon floors. Unsupported floors retain the current map; loot and quest lists remain available.
- Resolve each quest's dungeon relationships once per catalog rebuild, eliminating repeated database reads for every dungeon.
- Suppress native tracker rendering via alpha rather than addon-owned Show/Hide hooks, reducing taint risk while preserving Blizzard layout ownership.
- Supplied Details secret-role error belongs to Details. Live map/timeout/taint retest required; local regressions do not establish live recovery.

## 0.14.0-beta.26 — quest surface polish

- Match map shell, tabs and custom pages to the compact tracker's dark surface; replace tiled letterbox art and native search/count ornament while keeping canvas and icons.
- Keep class accents and difficulty colours; use smaller native quest titles and clear section hierarchy.
- Subtle syntax-style target/action/progress highlights on native objectives and tracker rows. Completed counts turn green; native links and existing colours remain intact.
- Quest, performance and Forever checks pass. In-game visual/taint acceptance remains pending.

## 0.14.0-beta.25 — free map layout and dungeon sharing

- Resize window width and height independently without enlarging fonts; preserve native map projection and icons.
- Responsive sidebar/tab widths and explicit native search/count/scroll anchors prevent overflow; viewport reserves sidebar space on all tabs.
- Save dimensions per character. Resize work stops on release/hide/combat.
- Dungeon manager Share button steps through held shareable quests; individual tracker dungeon rows have Share actions. Each click sends one native share request, allowing party responses before the next.

## 0.14.0-beta.24 — map shell

- Persistent top sidebar tabs switch exclusively between native quests and RUI pages; native refreshes cannot layer the quest log over settings.
- Bottom-right grip scales the map, icons and sidebar together smoothly, preserves map proportions and saves scale per character. No idle resize handler.
- Replace wooden overscroll art with a flat dark surface and flatten breadcrumb decoration without touching canvas/pin layers.
- Map/dungeon quest clicks return to the Quests tab before opening native details.
- Live resize, layering, native map controls and taint checks remain required.

## 0.14.0-beta.23 — foundation review build

- Fix keyed guide-quest cache invalidation; reuse unchanged world/minimap pins across selection changes.
- Replace tracker frame-rate timer checks with hide-cancelled native interval timers; add keyed combat render deferral.
- Share menu/map/tracker surface palette and class accents; save menu placement and refresh only visible option controls.
- Add versioned, validated settings profiles with named save/load, export/import, pre-import undo and manual reload.
- Add optional-provider status to About; run all seven suites in CI against pinned native UI source.
- Demand-load the separate RUI Options addon; add searchable settings navigation and optional-provider status.
- Keep authored guides, full dungeon coverage, complete overhaul breadth and live FPS/taint proof as outstanding work.

# Changelog

## Unreleased

### 0.14.0-beta.22 - 2026-10-08 (dungeon atlas)

- Map Dungeon atlas tab integrates the installed AtlasLoot Forever dungeon library with native dungeon floor maps.
- Boss list, clickable recorded map locations and per-boss loot rows with item tooltips/modified-click linking.
- Dungeon quest view shares pickup/objective/hand-in locations, native quest details and per-dungeon tracking.
- Dungeon data loads on demand; rows/pins pool, boss locations cache and item-cache events unsubscribe when unused.
- Missing client floors, boss coordinates or loot records remain explicit gaps; live client rendering/coverage acceptance pending. No third-party source/assets bundled.

### 0.14.0-beta.21 - 2026-10-08 (multi-zone preparation)

- Database-driven supplies for held quests, active guide quests and relevant future quests in selected zones; prepare for the displayed zone through map Settings.
- Future prerequisites may remain unmet while planning supplies; actual pickup eligibility is unchanged.
- AH advice requires non-soulbound native binding metadata; recorded vendor supplies remain separate. Missing item metadata waits for item-cache responses.
- Reminders show in Classic capital maps or when opening an AH; compact section caps at five items, with the full list in Supplies. Coverage depends on quest objective counts and sources in QuestieDB.

### 0.14.0-beta.20 - 2026-10-08 (route preparation and auto hand-in)

- Stormwind shows missing upcoming Westfall AH supplies for detected Westfall quests/guide steps or the explicit Prepare for Westfall setting, levels 9–22. Supplies includes the same shopping list.
- Auto hand-in option defaults off; completes native quest progress and claims rewards only when there are zero/one choices, outside combat. Multiple reward choices remain manual.

### 0.14.0-beta.19 - 2026-10-08 (map panel overlap)

- Settings tab opens an opaque RUI panel fitted to the native right quest-log space; native log hides while that panel is open and returns on close.
- Higher panel frame level prevents native headers/controls drawing over settings.
- Remaining native map border textures are suppressed.

### 0.14.0-beta.18 - 2026-10-08 (cleaner map quest list)

- Replaced ornate zone-header textures with subtle class-coloured separator rules and text.
- Native quest scrollbar, tracking checks and window controls receive subdued class accents; quest background is softer.
- Native click, collapse, track and scrollbar behavior retained; no new timers. In-game visual acceptance pending.

### 0.14.0-beta.17 - 2026-10-08 (map/sidebar visual consistency)

- Native map chrome uses dark strips and class-coloured borders/title, with ornate border artwork suppressed. The map canvas remains unobscured.
- Native quest panel backgrounds and headers match the tracker; pooled quest rows reuse difficulty/elite/completion title styling.
- Ruthless map tabs highlight the selected page with class accents; map quest copy uses tracker title styling.
- Styling runs on map opening/native list refresh outside combat, without a polling loop. Live visual acceptance remains pending.

### 0.14.0-beta.16 - 2026-10-08 (party quest completion readout)

- Party chat reports newly completed held-quest objectives; full quest completion reports ready to turn in.
- Reuses batched tracker events, combines simultaneous objective completions per quest and suppresses duplicate updates, reload announcements, solo and raid output.

### 0.14.0-beta.15 - 2026-10-08 (selected objective visibility)

- Selected quest areas use a stronger blue fill at 38% opacity, replacing the faint gold 16% fill that blended into parchment.

### 0.14.0-beta.14 - 2026-10-08 (quest status accents)

- Muted red/orange/yellow/green/grey quest title difficulty accents relative to player level.
- Native elite quest tags add an Elite badge; completed held quests show a green ready-check tick.
- Class-coloured headings and silver uncertainty markers remain; quest rows retain level/completion metadata.

### 0.14.0-beta.13 - 2026-10-08 (pickup eligibility and quest-drop tooltips)

- Guide pickup markers now use eligibility checks; known level/profession restrictions block offers. Profession, spell and reputation changes rescan offers.
- Unverified requirements use silver markers and explicit uncertainty text rather than claiming availability or guessing a level requirement.
- Wide Forever race masks avoid 32-bit truncation.
- Held-quest NPC drop sources are indexed for mob tooltips, with live unfinished objective progress and no database scan on hover.
- Database omissions may still cause incorrect offers; live availability and tooltip acceptance remain pending.

### 0.14.0-beta.12 - 2026-10-08 (loot and quest event spikes)

- Batch quest/bag event bursts for 350 ms; unchanged quest snapshots only refresh supplied quest items.
- Cache static quest spawn sources per database/quest phase; retain dungeon classification snapshots when quest information is unchanged.
- Remove forced marker rebuilds before offer discovery and preserve unchanged offer results.
- Live loot/dialogue latency remains to be verified after reload.

### 0.14.0-beta.11 - 2026-10-08 (addon-wide performance audit)

- Audited the shared core and every module against demand-driven patterns in the public EllesmereUI source. Added visible-only event binding and one-refresh-per-burst scheduling.
- Settled scrollbars and stationary character models no longer run update handlers; macro carets use focus-bound native animation. Character, spellbook, talents and achievements drop display events while hidden.
- Cache spell groups, action-bar membership (including false results), title names and health-glow curves with explicit invalidation. Avoid reloading the character model for unrelated stat updates.
- Build settings pages, the macro editor, achievement dashboard and disabled quest/glow assets only when needed. Existing assets remain pooled after first use.
- Remove world-map polling; redraw on map/size/show changes. Rebuild quest context when guide content or position changes; compass updates every 0.25 seconds and the installed-guide bridge checks every 2 seconds.
- Quest offer scans yield every 25 IDs, cache level candidates, stop when disabled and reject obsolete scan continuations. Completed scans refresh dungeon/pickup information even while stationary.
- Add on-demand /pr perf using native recent-average and peak CPU metrics; no background profiler loop.
- All seven suites pass. A stationary 60-second simulation against beta 10 reduces context/layout passes from 60 to 1 and settled scrollbar callbacks from 1,200 to zero. These measure work counts, not client CPU/FPS or a comparison with EllesmereUI. See docs/PERFORMANCE-AUDIT.md.

### 0.14.0-beta.10 - 2026-10-08 (tracker performance hotfix)

- Cache dungeon classification until the quest/offer snapshot changes, reuse it for recommendations and tracked rows, and avoid rebuilding unchanged map search areas. Content updates once per second; compass bearings update independently ten times per second.
- Added a permanent Menu button on the tracker opening the main map directly to dungeon track/untrack controls.
- Guard secret spell cooldown values before checking duration, including outside combat. The separately reported Questie aura-taint stack is not attributed to Ruthless’s error recorder.
- Regression tests verify cached database reads, offer invalidation, update cadence and map-menu behavior. Live frame-rate recovery remains to be confirmed.

### 0.14.0-beta.9 - 2026-10-08 (usable quest items and dungeon tracking)

- Quest-item clicks now call Blizzard’s native quest-item use function; shift-click retains chat linking. The current log index and item link are checked at click time.
- Added saved per-dungeon tracking, held quests and eligible pickups under a separate Dungeons section, and a map Dungeons tab to change choices. Prompts react to quest, zone and level updates using installed QuestieDB dungeon relationships and known eligibility.
- Refined the tracker with a class-coloured accent, stronger contrast, aligned objective counts and an Along the way group. Removed the redundant dungeon View button from the visible layout.
- Simulated interaction and Forever compatibility checks pass; item targeting, combat use and visual acceptance still require the running game. Database coverage and conservative eligibility filters remain limitations.

### 0.14.0-beta.3 - 2026-10-07 (compact quest companion and map hub)

- Replaced repeated quest-card buttons with a 292×300 class-coloured current-objective summary, integrated destination/arrow/distance and three nearby entries. Quest actions moved into map Tools.
- Added a Ruthless pane inside the world map with active quests, tools, appearance controls and supplies. Chapters/library/professions identify unimplemented guide content rather than claiming installed routes.
- Added a first supply record for Dry Times: inventory checklist and merchant reminders only for actually offered missing items. Reminders stop after quest completion; broader quest and proximity coverage remains outstanding.
- Saved dragged panel position per character; added position locking, arrow toggle and opacity controls.

### 0.14.0-beta.2 - 2026-10-07 (quest card controls)

- Simplified the panel heading to Quests and unified labels and action text around a gold quest accent.
- Added Track/Untrack, Waypoint, Map and Skip controls to each quest card. Waypoint selects the native supertracked quest and places its available destination on the map.
- Moved navigation into the selected quest card, with extra height to separate the arrow/distance from controls. Native tracking/waypoint writes are blocked during combat.

### 0.14.0-beta.1 - 2026-10-07 (quest workspace preview)

- Added an opt-in compact, translucent quest panel under Map & quests: active objectives and turn-ins, nearby sorting, selected destination in the header, same-zone navigation arrow and distance, scrolling, and persistent skip/restore without abandoning quests.
- Replaces Blizzard's tracker while enabled and restores it on disable. Combat defers native tracker visibility and navigation reads.
- Available-quest database coverage, original 1–20 authored guides, prerequisite explanations and advanced map controls remain planned. Wisp and TomTom panels are not automatically changed.

### 0.13.0-beta.2 - 2026-10-07 (automatic macro ranks)

- Newly learned spell ranks automatically upgrade explicit older rank references in both macro banks. Spell commands, conditions, sequences, names, and icons are preserved.
- Each automatic edit saves the previous macro in History. Combat, unloaded spell text, and unsaved editor drafts defer updates; rankless references and unrelated text remain intact.
- Added a Spellbook setting to disable automatic rank updates when intentionally maintaining downrank macros. Updates trigger on learning, not login.

### 0.13.0-beta.1 - 2026-10-06 (lightweight quest map)

- Added a lightweight Map & quests module using Forever's native quest-line, quest-offer, active objective, turn-in, task, and quest-hub data.
- Enables optional local-story and low-level quest markers on the main map, with account-completed quest starts available as an opt-in filter.
- Added `/pr quests` and a Map & quests settings page. Map updates remain Blizzard-owned; Project Ruthless changes visibility filters and requests a native provider refresh.

### 0.12.0-beta.7 - 2026-10-06 (visible macro caret)

- Added an explicit class-coloured blinking text caret to both the macro name and macro body fields.
- The caret follows WoW's live cursor coordinates and remains visible above the custom editor surfaces while typing.

### 0.12.0-beta.6 - 2026-10-06 (macro editing clarity)

- Added persistent Macro Name and Macro Body labels, a stronger body-editor border, and white editor text.
- Added live `TYPING IN NAME` / `TYPING IN BODY` focus feedback so the active keyboard destination is always visible.

### 0.12.0-beta.5 - 2026-10-06 (combat Spellbook browsing)

- Restored opening and browsing the Ruthless Spellbook during Forever combat with a protected-state-safe read-only presentation.
- Suspends cooldown reads, live action-bar scans, spell casting, and spell dragging during combat while keeping tabs, search, filters with cached bar state, and macro browsing available.

### 0.12.0-beta.4 - 2026-10-06 (WoW Forever combat safety)

- Prevented the Ruthless Spellbook from refreshing or opening during Forever combat, where spell cooldown fields become secret values.
- Automatically closes the Ruthless Spellbook when Forever combat begins and removes its action-bar grid and pulse mutations on that client.
- Added source-contract checks for secret cooldown handling, combat closure, and protected action-bar isolation.

### 0.12.0-beta.3 - 2026-10-06 (WoW Forever diagnostics fix)

- Replaced the Retail-only `SimpleEditBox:GetStringHeight()` call with a hidden `FontString` measurement shared by diagnostics and macro editing.
- Added a source-contract check against Forever's generated widget API documentation so scrolling edit boxes cannot regress to the unsupported method.

### 0.12.0-beta.2 - 2026-10-06 (WoW Forever taint fix)

- Removed addon-driven Character and Talents launch buttons on Forever. Opening Camelot's Character frame through addon Lua tainted secret health values and caused Blizzard's `TextStatusBar.lua` to fail when showing or hiding the panel.
- Added a regression check that rejects native Character and Talents launch calls from unsupported Forever paths.

### 0.12.0-beta.1 - 2026-10-06 (WoW Forever compatibility preview)

- Added a Camelot manifest for WoW Forever 1.60.1 (`Interface 16001`) while preserving the Retail manifest and package.
- Routed Forever's dedicated Spellbook button and keybind into the Ruthless Spellbook and macro workspace without replacing its Professions button.
- Left Forever's native Character and Talents windows intact while their Camelot-specific layouts undergo live beta testing.
- Disabled the Ruthless Statistics dashboard on Forever because Blizzard's current Achievement UI is not exposed to the Camelot game type.
- Added a Forever compatibility gate that checks manifests, client detection, native-frame safeguards, and the beta Spellbook redirect contract.

### 0.11.0 - 2026-09-09 (release candidate)

- Restored Blizzard's native PaperDoll item-slot handlers in the optional Character workspace. Drag/drop, right-click use, modified-click socketing, tooltips, and Alt item flyouts now stay under Blizzard's implementation without replacing Blizzard's internal slot registry.
- Returned every existing installation to Blizzard's Character frame once after updating. The experimental Ruthless Character workspace remains available as an explicit opt-in under `/pr` > Character.
- Detached Blizzard's equipment-set icon selector from the Ruthless frame so it keeps its native size, anchoring, and modal layout.
- Removed the required early error-capture bootstrap from the main addon's metadata to eliminate its taint surface and simplify public packaging.
- Added native-source contract checks for the PaperDoll click, drag/drop, modified-click, tooltip, and flyout scripts.

### 0.10.3 - 2026-09-09 (awaiting live acceptance)

- Fixed the Alt-hover equipment flyout error by calling Blizzard's `ItemLocation:CreateFromEquipmentSlot` API with its required method form and shielding hover refresh from tooltip-location failures.
- Switched New set and Rename to Blizzard's icon-capable Gear Manager popup when it is available, with the earlier text-only dialogs retained as a fallback.
- Added coverage for native gear-popup routing, selected-set handoff, default ignored shirt/tabard slots, and the corrected item-location call style.

### 0.10.2 - 2026-09-09 (awaiting live acceptance)

- Fixed equipment-set Create and Rename dialogs on the live StaticPopup implementation, where the edit box is exposed as `EditBox` instead of `editBox`.
- Added coverage for the live popup shape and Enter-key accept path so the new-set dialog cannot silently pass with the wrong field name again.

### 0.10.1 - 2026-09-09 (awaiting live acceptance)

- Completed the Character equipment-set manager with explicit selection, Save current, Equip, Rename, and Delete actions.
- Added overwrite and delete confirmations; saves and renames preserve the selected set icon and saved ignored slots.
- Replaced the eight-row ceiling with a scrolling set list and added refresh coverage for equipment-set and swap events.
- Blocked combat, casting, unavailable-manager, locked-item, duplicate-name, and capacity failures with clear feedback.
- Added a control-level test for create, save, equip, rename, delete, cancellation, ignored slots, blocked states, and scrolling.

### 0.10.0 - 2026-09-07 (awaiting live acceptance)

- Added a first-class Statistics dashboard inside Blizzard Achievements.
- Surfaced achievement points, completion, earned titles, honorable kills, recent milestones, and category progress from live Blizzard records.
- Kept the complete native statistics browser one click away and left player comparisons on Blizzard's original view.
- Added `/pr achievements`, `/pr statistics`, and an Achievements settings section with a native-view fallback.

### 0.9.1 - 2026-09-07 (awaiting live acceptance)

- Removed the unnecessary Talents loadout search and Blizzard's duplicate talent search/loadout controls from the compact workspace.
- Fixed the lower-left label overlap and moved Raider.IO Talent Builds into a dedicated full-width sidebar action.
- Restyled and repositioned the Raider.IO talent-build window with Ruthless surfaces, class-colour accents, cleaner rows, and more useful proportions.

### 0.9.0 - 2026-09-07 (awaiting live acceptance)

- Added the compact Talents workspace around the native talent editor, retaining class artwork, hero talents, PvP controls, and Apply/Undo behavior.
- Replaced the standalone specialization page with class-appropriate specialization buttons above the trees.
- Added a searchable loadout sidebar, explicit pending-change status, Save copy, Import, Export, and Manage actions.
- Retained native loadout confirmation, cancellation, failure recovery, and existing saved-loadout limits.
- Added `/pr talents` and a Talents settings section with a native-layout fallback.
- Restored original layout for inspection and native Spellbook; deferred layout changes during combat and fitted the window to available screen space.
- Added isolated adapter tests using the real native dropdown implementation and talent-load callback. Live rendering and protected-state behavior still require in-game acceptance.

### Earlier foundation changes

- Restored native Enter/newline editing in macros; Up/Down select suggestions, while Tab or click inserts them.
- Restored native mouse caret placement inside the macro editor.
- Fixed new equipment-set dialogs that could appear without a Create button and made Enter activate Create safely.
- Changed the shared window-scale control from five-percent to one-percent increments.
- Standardised action buttons on the dark, class-accented Project Ruthless treatment, removing red Blizzard button skins from addon-owned controls.
- Unified editor, macro list, suggestion list, icon picker, history, diagnostics, and title scrolling with Character stats' 30-pixel wheel step and smooth easing.
- Corrected scrollbar dragging at non-default window scales and made scrolling settle exactly at its target.
- Deferred scale-slider application until drag release to prevent the control moving beneath the pointer; rounded percentage readouts consistently.

- Added the first functional Character workspace with a live player model, equipped-item slots and tooltips, compact item-level context, combat stats, and directly selectable equipment sets.
- Restricted window movement to the header and added natural left-drag character rotation.
- Reworked item-level overlays into compact dark badges and added item-quality slot borders.
- Expanded the character readout into distinct primary, secondary, and defence/utility stat groups.
- Matched Blizzard's familiar equipment geography, with gloves at top-right and weapons centred beneath the model.
- Added left-drag rotation, mouse-wheel zoom, right-drag panning, and a model-view reset control.
- Replaced the compact stat cards with a scrollable extended inspector covering core stats, weapon damage, secondary ratings, defence, tertiary attributes, and live movement speeds.
- Split the right column into dedicated All Stats and Equipment Sets views to prevent content collisions.
- Corrected model panning so right-drag moves laterally and vertically without changing camera depth.
- Added Project Ruthless's reusable smooth scrollbar with restrained wheel speed and a class-colour thumb.
- Coloured section headings by class and the equipped item level by the dominant quality of equipped combat gear.
- Added an optional Progress view with live Mythic+ rating, best key, current raid progress, and Raider.IO profile details.
- Added a clear empty state to the Equipment Sets view.
- Moved current Mythic+, raid, and rated-PvP progress into a compact identity strip beside the character name.
- Changed the Character heading to the class-coloured character name with level and specialization beneath it.
- Replaced the model-control footer and text Reset button with a subdued circular reset icon.
- Made the character model display its weapon unsheathed by default.
- Reapplied the unsheathed state after the asynchronous player-model load so equipped weapons remain visible.
- Added a Draw/Sheathe model control and explicitly kept weapons visible while changing sheath state.
- Restyled the model reset control with Project Ruthless surfaces and class-colour accents.
- Removed the decorative frame around the compact progress strip.
- Read rated PvP progress using the same bracket-index ordering as Blizzard's Conquest panel, including Solo Shuffle and Blitz.
- Merged secondary ratings into Offence for a cleaner stat hierarchy.
- Added hover explanations for character stats, including the active specialization's own Mastery description and rating.
- Displayed the equipped title with the character name in the class-coloured heading.
- Moved Character out of the `/pr` control centre into a standalone replacement opened by WoW's normal Character button and keybind.
- Rebuilt `/pr` as a functional settings centre for general presentation, Character, Spellbook, health warnings, compatibility, diagnostics, and addon information.
- Added live window scale and opacity controls plus switches for Character details, Spellbook integration, off-spec visibility, missing-bar highlights, macro suggestions, and ElvUI tooltip compatibility.
- Expanded the macro editor with account and character banks, safe explicit saves, editable blank names, icon selection, drag-to-action-bar support, and autocomplete for commands, directives, conditionals, and learned spells.
- Added persistent macro recovery history before edits, deletions, and moves; restoring always creates a new copy.
- Added keyboard-driven categorised autocomplete, live spell/icon previews, non-blocking syntax checks, searchable macro names and bodies, and common macro templates.
- Added safe macro duplication and account/character moves that create the destination copy before removing the source.
- Added Spellbook filters for current abilities, passives, assigned spells, and missing-bar spells.
- Added right-click spell pins with a starred section and clickable action-bar markers that pulse visible assigned buttons.
- Remembered the last Spellbook tab, filter, searches, scroll positions, macro bank, and selected macro.

## 0.6.0 - 2026-09-03

- Added the first functional Titles workspace to the Project Ruthless menu.
- Added live title search, alphabetical/recent sorting, favourites, left-click equip, and right-click provenance.
- Added conservative achievement matching with completion-date provenance and direct achievement navigation.
- Added forward-looking acquisition tracking without fabricating dates for legacy titles.
- Replaced unsupported star characters with native favourite icons and highlighted favourited rows.
- Corrected equipped-title highlighting and removed confidence text from the provenance card.
- Removed the premature title-state read that left equipped highlighting one selection behind.
- Replaced the blocking full achievement scan with instant Epithet metadata integration and chunked on-demand Blizzard fallback searches.
- Replaced the removed `NEW_TITLE_EARNED` event with change detection driven by `KNOWN_TITLES_UPDATE`.
- Installed the error handler before module initialization so startup failures are retained.
- Normalized Blizzard's two-digit achievement years to four-digit display years.
- Added the `!ProjectRuthless` early bootstrap to retain Lua errors raised before the main addon initializes.
- Replaced Blizzard's blocking Lua error popup with grouped chat notices while retaining full details in `/pr errors`.
- Collapsed error bursts by addon and rate-limited repeated notices to reduce combat chat spam.

## 0.5.0 - 2026-09-03

- Added a smoothly scaling red low-health border glow.
- The effect begins below 35% health, stays subtle through the upper range, then steepens below 10% to reach 40% opacity at 1% health.
- Uses Midnight's secret-value-safe health curve and hides while dead or ghosted.
- Added preview and enable/disable commands for rapid iteration.

## 0.4.0 - 2026-09-03

- Rebuilt the menu shell with modern dark surfaces and sidebar navigation.
- Added automatic class-colour accents throughout the Project Ruthless menu.
- Refined typography and spacing while preserving Andrew's established dark UI direction.

## 0.3.0 - 2026-09-02

- Added the main Project Ruthless menu, opened with `/pr`.
- Added Status and Errors tabs.
- Embedded the persistent, copyable Lua error viewer in the menu.

## 0.2.0 - 2026-09-02

- Added a persistent Lua error recorder retaining the latest 50 errors across UI reloads.
- Added a copyable in-game error viewer through `/pr errors`.
- Added commands to clear, enable, and disable Project Ruthless error logging.
- Added `/pr errors test` for verifying the recorder on demand.

## 0.1.1 - 2026-09-02

- Renamed AndrewUI to Project Ruthless.
- Replaced the `/aui` command with `/pr`.
- Renamed saved-variable namespaces to match the permanent addon identity.

## 0.1.0 - 2026-09-02

- Created the standalone AndrewUI addon foundation.
- Added account-wide and per-character saved settings.
- Added `/aui` status and safe-tooltip commands.
- Added an ElvUI compatibility module for the Midnight tooltip-taint workaround.

## 0.14.0-beta.4 — Installed guides and quest database

- Read the installed ForeverWisp current action, instructions, unresolved up-next rows and travel navigation into the class-coloured compact panel. Wisp retains guide content and progression. Explicit preview and step controls are available through the map Tools tab.
- Optional QuestieDB contract 3 integration reads active quest creature/object spawns, item drop/container/vendor sources, guide pickup and completed quest turn-in locations. Uses the installed Forever zone mapping and overrides without re-projecting coordinates.
- Optional HereBeDragons-Pins (provided by installed ForeverWisp or TomTom) draws those locations on both maps. Current quest markers are larger and class coloured; other active quests are dimmed. Marker tooltips identify recorded sources; clicks set the chosen waypoint outside combat.
- Native quest navigation now supports adjacent maps on the same continent.
- Local simulation and syntax validation only; live map rendering and Wisp integration await acceptance. This is not full Questie feature parity: available-quest eligibility, per-objective completion filtering, special extra objectives and all future supplies are not implemented. Wisp browser pages remain in Wisp's own browser, opened from the map controls.

## 0.14.0-beta.5 — Quieter world map

- Removed Ruthless's individual spawn icons from the world map. Only the selected quest receives class-coloured approximate search-area shading on its zone map.
- Native quest-detail selection and Ruthless quest selection focus the zone with the most recorded objective points; native waypoints provide a fallback if database points are absent.
- Minimap locations remain individually clickable, reduced to 12px for the current quest and 9px for others.
- Simulated checks cover area deduplication, selected-quest and zone isolation, zone switching, icon size and cleanup. Live visual acceptance remains pending.

## 0.14.0-beta.6 — Classic gold quest markers

- Replaced search-area shading with consolidated gold world-map icons: native question marks for completed quest turn-ins, exclamation marks for pickups, backpack symbols for collection objectives and swords for kills. One recorded point represents each quest/type/zone rather than each spawn.
- Active-quest marker clicks open Blizzard's quest details in the side log. Unaccepted quests open Ruthless pickup/source details, since they have no native quest-log entry yet.
- Detailed minimap locations remain. Completed turn-ins get larger native gold question marks; smaller objective markers are square, correcting an unintended stretched height in beta 5.
- Added batched QuestieDB available-quest scanning with level, race/class, active/completed, prerequisite, exclusion and parent checks. Unverified profession/reputation/special requirements are excluded rather than guessed. Native map offer handling remains intact; this is not complete Questie eligibility parity.
- Wisp arrow identification now supports numeric texture file IDs used by the live client. Route content/progression remains owned by installed Wisp.
- Local simulated marker classification, quest-details/pickup clicks, eligibility, numeric arrow texture and existing Forever compatibility checks pass. Live rendering and taint acceptance remain pending.

## 0.14.0-beta.7 — Selected areas and quest context

- Reduced world-map and minimap marker sizes by 25%. Gold classified world-map markers remain, with translucent gold search cells for the currently selected quest's recorded objective/drop locations. Pickup and turn-in points are not shaded as search areas.
- Added a separate scrollable nearby section alongside guide up-next steps. Includes active quests and known available pickups within 1,000 yards on the current map.
- While in an instance, show matching dungeon quests using QuestieDB's named dungeon area IDs/aliases or recorded locations on an actual dungeon map. Outdoor map coordinates are not treated as dungeon matches.
- Clicking a context row focuses that quest or pickup in the Ruthless tracker and navigation; Guide returns to Wisp. Accepting a manually selected pickup replaces the temporary pickup entry with the real quest log entry.
- Simulated checks cover area isolation, marker sizes, nearby pickups, dungeon aliases/outdoor exclusion, combat blocking and context rerouting/Guide return. Live visual/combat acceptance remains pending. Dungeon coverage depends on installed database records; this does not add quests to the player's game log or modify Wisp's route.

## 0.14.0-beta.8 — Tracker information and navigation

- Guide objectives now include live counters and along-the-way tasks from the installed Wisp display. Objectives have a scrollable section; title/instruction/objective/up-next/context sections use measured content heights instead of fixed gaps.
- Ruthless independently recommends dungeon trips when matching quests are in the log. View lists the dungeon's quest context without modifying Wisp; clicking a quest focuses it and Guide restores the route.
- Read-only navigation continues during combat and across adjacent zones. A valid Wisp bearing is not discarded because its arrow texture is temporarily hidden; native/database destinations provide fallback. Fully hidden/stopped Wisp routes are not treated as current bearings. Cross-continent travel still requires a valid intermediate route destination.
- Added actual quest-item links/icons, hover tooltips and modified-click chat links for current guide/native quests. Forever's GetQuestLogSpecialItemInfo returns the link and icon together; the older separate link function is only a fallback. These are item links, not secure casting controls.
- Local interaction simulations and Forever syntax/compatibility checks pass. Live layout, compass and item-link acceptance remain pending.
