# Performance audit — local beta 11

Date: 2026-10-08. Scope: shared core and all 13 modules, for Forever and supported Retail features. Previous beta 10 package preserved outside the repository for comparison. This is a local, uncommitted build; no public release was changed.

## Reference inspected

Public EllesmereUI revision `52e68688b68bfaeba4af4cbf2cb702aa35a541a8`:

- [Core flyout lifecycle](https://github.com/EllesmereGaming/EllesmereUI/blob/52e68688b68bfaeba4af4cbf2cb702aa35a541a8/EllesmereUI.lua): register events on show, unregister on hide; resolve static button attributes separately from changing cooldown state.
- [Shared UI core](https://github.com/EllesmereGaming/EllesmereUI/blob/52e68688b68bfaeba4af4cbf2cb702aa35a541a8/EllesmereUI_UICore.lua): stop temporary animation handlers; create optional controller plumbing only when a consumer needs it.
- [Options manifest](https://github.com/EllesmereGaming/EllesmereUI/blob/52e68688b68bfaeba4af4cbf2cb702aa35a541a8/EllesmereUIOptions/EllesmereUIOptions.toc): separate load-on-demand options addon.
- [Quest visibility](https://github.com/EllesmereGaming/EllesmereUI/blob/52e68688b68bfaeba4af4cbf2cb702aa35a541a8/EllesmereUIQuestTracker/EllesmereUIQuestTracker_Visibility.lua) and QoL: cache state at events and queue one pass per burst instead of continuously rebuilding UI.

Ruthless implements its own helpers and changes. No EllesmereUI code, media or modules are bundled. Architecture inspection is not a performance benchmark of EllesmereUI.

## Module coverage

| Area | Finding and implemented treatment |
| --- | --- |
| Core | Smooth scroll repeatedly measured and repositioned its thumb every frame even at rest. Its handler now exists only during movement/dragging and stops on settle/hide. Shared queue coalesces refresh bursts and rechecks actual visibility, including hidden parents. Startup events unregister after use. `/pr perf` queries metrics on demand. |
| Character / equipment | Display/stat/cast events were permanently registered; each burst queued separate full refreshes. Bind them only while visible, filter unit events to player, coalesce refreshes, sample movement twice per second only in Stats mode. Model drag handler is attached only during interaction; stat changes no longer reload the model. Existing protected equipment-set workflows and pooled rows remain. |
| Spellbook / macros | Rebuilt spell groups and queried action-bar membership repeatedly. Cache raw groups by mode/off-spec setting and invalidate on spell/skill/spec changes. Cache true and false bar membership until bar/spell/combat-end events or reopening. Display events only while visible. Macro editor is constructed on first Macros selection; caret blinking uses native animation while focused. The 96-button icon picker, templates and history are built only when their own buttons are used. Icon choices cache until spell/skill/spec/equipment changes. |
| MacroRanks | Already event-driven with a single pending batch, combat deferral, draft protection and bounded backup history. Retained; no recurring scan added. Event dispatch for an enabled background rank feature is necessary even with the editor closed. Existing rank regression suite passes. |
| Talents / Raider.IO skin | Hidden frame could receive broad events and rebuild chrome. Layout/refresh now require a shown frame; display events follow visibility and cast events are player-filtered. Event-driven refresh bursts coalesce. Integration hooks remain attached once and act on UI edges; no polling added. Forever continues using the native unsupported panel. |
| Achievements | Criteria bursts could repeat complete dashboard queries. Subscribe only while the dashboard is visible, queue one refresh, and drop queued work after hiding. Construct dashboard only on first request. Forever support gate remains. |
| Titles / Epithet | Each text search rescanned title ownership and formatted every name. Cache known names and cleaned search text; invalidate on title/name events. Hidden title panels do not rebuild. Achievement provenance scans yield and stop when their request card is closed. Initial ownership snapshot remains necessary for earned-history bookkeeping. |
| QuestWorkspace | Previously created disabled tracker/map assets at login and rebuilt context on each periodic update. Create tracker/map on enable, unregister workspace events on disable, coalesce native events. Compare guide content before redrawing; refresh nearby context after meaningful movement. External Wisp display bridge still checks every two seconds while used; compass remains a lightweight four-Hz visible update. Source widget discovery caches by frame identity while direction/distance remain live. |
| QuestLocations | Database contract/dungeon results now cache against their dependencies. No world-map OnUpdate polling; redraw on show/map/size edges. Offer discovery is incremental (25 IDs per slice, 50 ms between slices), retains level candidates, re-evaluates changing eligibility and cancels obsolete work. No scans when disabled; completion queues a tracker refresh so stationary players see pickups. |
| MapQuests | Quest-line response handling could request quest lines again and repeat full provider refreshes. Responses now coalesce refreshes and do not issue another request. Settings application still uses native CVar/filter APIs and checks combat. |
| Menu | Opening the settings shell previously built every page and formatted captured errors on unrelated pages. Build each page on first selection; format diagnostics only for Diagnostics/About. Reuse built pages. |
| LowHealthGlow | Disabled glow previously created texture/curve and subscribed to health events. Create assets only on enable/preview; remove all events when disabled. Reuse curve until threshold/alpha changes; preserve secret-safe native curve evaluation. |
| ErrorLog | Bounded storage and batched notices already exist. Removed the redundant scheduled login installation. It still captures actual errors regardless of its viewer being closed; no recurring formatting/polling added. Error-storm overhead is not zero. |
| ElvUICompat | Already a small settings/login edge operation, with no recurring timer, polling or frame allocation. Retained. Tooltip compatibility remains optional. |

## Verified work-count reductions

Fengari simulation runs actual update handlers extracted from the saved beta 10 and current source. Native UI costs are mocked; no CPU/FPS percentage is inferred.

| Stationary 60-second scenario | Beta 10 | Beta 11 |
| --- | ---: | ---: |
| Guide-display reads | 60 | 30 |
| Context/layout passes | 60 | 1 |
| Compass updates | 600 | 240 |
| Settled visible scrollbar callbacks at 20 FPS | 1,200 | 0 |
| Full display refreshes for a 100-event burst | Up to 100 in affected handlers | 1 |

The initial context pass remains intentional. Moving, changing quests, interacting or receiving relevant native events legitimately causes more work. Bridge allocation and native compass/map queries still have a cost while those features are active.

## Validation

All seven suites pass: performance, quests, equipment, talents, achievements, macro ranks and Forever compatibility. Behavior checks cover hidden-parent visibility, event unsubscription/reopening, queued refresh suppression, scroll settling/restoration, model dragging, cache hits including false values, pin/settings/spell invalidation, disabled asset creation, bounded scan slices, scan cancellation after disable/re-enable, settings page reuse and unavailable profiler handling.

Run `npm run test:performance` for idle/cache checks. For the saved baseline comparison, run `node tests/run-performance.cjs --baseline <extracted beta 10 ProjectRuthless folder>`. The baseline archive is not committed or shipped.

## Live acceptance and limits

Reload beta 11. Open/close each supported panel; change spells, equipment, filters and pins; enable/disable quest workspace and glow; select another map zone; check quest-item use and dungeon tracking. Use `/pr perf` after standing still, moving, combat and opening panels. It reports native recent average over the last 60 profiler ticks and session peak in milliseconds per tick, without starting a timer or changing profiling settings. Peaks include earlier activity and are not reset by this command.

A comparison with EllesmereUI must use comparable enabled features, client, location, movement/combat and addon set. Ruthless is not yet proven faster than EllesmereUI, and live FPS/CPU/taint and visual acceptance remain pending.

“Zero idle cost” applies to removed handlers/scans/subscriptions and assets not yet constructed. Lua files still load through the TOC; tables, lightweight bootstrap listeners and once-installed hooks remain resident. Previously used frames/textures stay pooled because WoW frames are not disposed like ordinary Lua objects. A separate load-on-demand options package could reduce resident source memory further, but this pass does not introduce that packaging migration.

## Beta 12: loot and quest dialogue spikes

Static quest sources now cache by database identity, quest ID and phase. Unchanged offers and quest snapshots retain their identity. Redundant forced marker rebuilds were removed. Quest/bag bursts wait 350 ms; unchanged loot snapshots refresh item buttons without context/layout redraws. Regression checks pass; live hitch recovery is pending. Genuine changed marker sets still register synchronously.

