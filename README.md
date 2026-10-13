# Project Ruthless

Project Ruthless is a modular World of Warcraft interface focused on practical tools that preserve Blizzard's familiar workflows.

Active development targets WoW Forever (`Interface 16001`, game type `camelot`). Beta 75 adds first-run choices, familiar native starting anchors, accessibility controls and keyboard settings navigation. It consolidates duplicate settings and fixes the native M-key map toggle. Unified profiles, search, the testing recorder and six release gates remain available; live acceptance is pending.

Install the three bundled folders: ProjectRuthless, ProjectRuthless_Options and ProjectRuthless_DungeonData. Options and dungeon data load on demand. `/pr` opens settings; `/pr record on` enables local test recording; `/pr record off` stops it; `/pr report` opens a copyable bug report. See [testing and release gates](docs/TESTING-AND-RELEASES.md).

RUI no longer edits ElvUI settings or requires a UI overhaul addon. Quest-location coverage still uses an optional external database adapter; complete data independence is planned. Settings and Edit Mode use the same account profiles on Forever. Legacy Retail files are retained without new Retail feature development; the historical feature descriptions below do not establish Forever support.

## Current milestone

Project Ruthless currently provides:

- a standalone addon identity;
- account-wide and per-character saved settings;
- a small module lifecycle;
- `/pr` command namespace;
- native UI foundations without an active ElvUI compatibility module;
- a persistent, copyable Lua error log for addon development.
- a sleek dark `/pr` control centre with automatic character class-colour accents.
- a progressive red border glow that warns when player health falls below 35%.
- an optional experimental Character workspace with equipped gear, compact item-level context, combat stats, and equipment-set selection; Blizzard's Character frame remains the default.
- a standalone Spellbook restoring General, class, Professions, and Macros to the normal book button, with filters, pinned spells, action-bar location feedback, macro templates, autocomplete, validation, and recovery history.
- a functional `/pr` settings centre for presentation, Character, Spellbook, health-warning, compatibility, and diagnostic controls.
- a compact Talents workspace on the normal Talents button/keybind and `/pr talents`, with specialization buttons, a clean loadout list, Save copy/Import/Export/Manage actions, and the native class/hero talent trees.
- a Statistics dashboard inside Blizzard Achievements with account progress, titles, honorable kills, recent milestones, and category completion at a glance.
- a lightweight main-map quest layer that enables Forever's server-provided local stories and low-level quest starts while retaining Blizzard's native quest pins, tooltips, objectives, turn-ins, and tracking.

### Character equipment sets (experimental)

The optional Character workspace delegates its item interactions to Blizzard's native PaperDoll handlers, including drag/drop, right-click use, modified-click socketing, item tooltips, and Alt item flyouts. Its equipment-set manager lets you select a set, then Save current, Equip, Rename, or Delete. Blizzard's normal Character frame is the release default while this workspace completes live testing.

Run `node tests/run-equipment-sets.cjs` for the control-level lifecycle harness and checks against the extracted Blizzard UI source. The final runtime/protected-state check remains in WoW.

### Talents v0.9.1 (awaiting in-game acceptance)

The Ruthless layout keeps `PlayerSpellsFrame.TalentsFrame` attached to its native parent. Blizzard continues to own purchases, Apply/Undo, hero talents, PvP talents, loadout validation, confirmations, and asynchronous load/rollback behavior. Loadout rows use the native load system with an explicit user-input flag. Save copy names a copy of the current build; Manage exposes native rename/delete/action-bar options. This release does not expand the game's saved-loadout cap.

The tree stays at its native internal dimensions and is displayed at 72% scale, alongside a full-size sidebar. The complete workspace fits within 94% of available UI width and 90% of height, respecting the shared scale up to that limit. Native inspection and the optional Blizzard Spellbook restore the original layout. `/pr` > Talents can disable the compact layout; presentation changes requested in combat apply after combat ends.

Run `node tests/run-talents.cjs` to check the adapter using Fengari, Lua 5.1 parsing, a strict UI mock, and Blizzard's native load callback. Set `PR_TEST_DEPS` to a folder containing `fengari` and `luaparse`, and `PR_WOW_SOURCE` to the extracted Blizzard `Interface/AddOns` source directory when running outside Andrew's existing local test environment.

Live acceptance: open the normal Talents window; check tree/tooltips, hero talents and sidebar fit; use Save copy/Manage on a disposable build; verify pending-change cancellation, open Raider.IO Talent Builds, then check inspection and the normal Spellbook. Local tests cannot establish live protected-state/taint behavior or visual acceptance.

The compact workspace intentionally hides both Blizzard's duplicate loadout dropdown and the talent-node search field. Raider.IO Talent Builds is moved out of that hidden dropdown into a full-width sidebar action. Its build browser receives Ruthless surfaces and class-colour accents when opened; Raider.IO retains ownership of its filters, build data, menus, and import/load behavior.

### Achievements v0.10.0 (awaiting in-game acceptance)

The Statistics tab now opens on a dark Ruthless dashboard built from Blizzard's live achievement records. It shows achievement points, completed achievements, earned titles, honorable kills when that statistic exists, recent milestones, and category progress. `Browse details` restores Blizzard's full statistics list, and selecting any native category also leaves the overview. Achievement comparisons continue to use Blizzard's original presentation.

Open it from the normal Achievements window, `/pr achievements`, `/pr statistics`, or `/pr` > Achievements. The settings toggle restores the original Statistics tab without a reload.

## Development loop

The live WoW AddOns directory uses a junction to this repository. Edit the source, save it, then use `/reload` in WoW to load the current revision.

## Installation

1. Download the latest `ProjectRuthless.zip` release.
2. Extract the `ProjectRuthless` folder into `_retail_/Interface/AddOns` for Retail or `_classic_beta_/Interface/AddOns` for the WoW Forever beta.
3. Enable Project Ruthless from WoW's AddOns screen.

### WoW Forever beta

The Forever build keeps the Ruthless Spellbook, macro workspace, settings, diagnostics, and low-health warning. Forever already has a dedicated Spellbook micro button, so Project Ruthless routes that button and its keybind directly to the Ruthless workspace and leaves the Professions button untouched.

Forever's Character and Talents frames contain Camelot-specific behavior. Project Ruthless currently leaves those native frames intact instead of applying the Retail replacements. The Statistics dashboard is also disabled because Blizzard's current Achievement UI is not exposed as a Camelot addon. These boundaries are deliberate until each frame passes live beta testing.

The Map & quests module uses Forever's live quest-line and quest-offer feeds, including optional local stories and trivial quests. It deliberately avoids a bundled third-party quest database, so it cannot reveal quest locations that the server does not advertise to the client.

ElvUI, Raider.IO, and Epithet integrations are optional. Project Ruthless does not require a separate bootstrap addon.

Macro spell ranks update automatically when a new rank is learned. Explicit references such as `/cast Fireball(Rank 1)` become the newly learned rank, including references in sequences and tooltip directives. Previous versions are retained in Macro History. Disable **Automatically update macro spell ranks** in Spellbook settings if you deliberately use lower ranks. Updates wait until combat ends and defer macros with unsaved editor drafts; macros exceeding the 255-byte limit are left intact.

Quest workspace preview: enable **Compact quest workspace (preview)** under `/pr quests`. The class-coloured overlay shows the current quest, objective summary, destination, same-zone navigation and three nearby quests. Click a nearby quest to follow it; scroll to browse. Dragging saves the panel position. Open the world map and click **Ruthless** for quest information, tracking/skip/recovery tools, arrow/opacity/position settings and supplies. Dry Times has an inventory checklist and merchant reminders for actually offered missing items, based on ATT Forever quest 116 and the current quest description. Proximity alerts, wider item-source coverage, authored 1–20 routes and prerequisite help remain planned. Chapters/library/professions currently explain their unavailable state. Disable the preview to restore Blizzard's tracker; Wisp/TomTom visibility remains controlled by those addons.

## License

Project Ruthless is released under the MIT License. See `LICENSE`.

## Commands

- `/pr` — open the Project Ruthless menu
- `/pr status`
- `/pr errors`
- `/pr achievements`
- `/pr statistics`
- `/pr quests`
- `/pr errors clear`
- `/pr errors test`
- `/pr errors on`
- `/pr errors off`
- `/pr healthglow test`
- `/pr healthglow on`
- `/pr healthglow off`
- `/pr tooltip on`
- `/pr tooltip off`

## Principles

- Preserve Andrew's established layout and muscle memory.
- Make one visible change at a time.
- Prefer Blizzard-native systems when they are stable and capable.
- Retain ElvUI compatibility until a replacement module earns its place.
- Keep modules independently disableable and reversible.

### Forever guide and objective locations (0.14.0-beta.4 preview)

Keep **QuestieDB** enabled; **Questie** itself can stay disabled. Keep **ForeverWisp** enabled with an active guide for the current action, up-next preview and route navigation. ForeverWisp or TomTom supplies HereBeDragons-Pins for objective markers. Ruthless does not bundle either addon's database or guides.

With the Ruthless quest workspace enabled, the panel follows Wisp's displayed guide. The map Ruthless → Tools controls open guide step options and the guide browser; Settings can switch back to active quests. The original Wisp panel remains available during this integration preview.

Recorded active-quest NPC/object and item-source locations appear on both maps. Current quest locations receive larger class-coloured markers. Hover for the quest/source; click outside combat to set that point as a native waypoint. These records describe known spawn locations, not a guarantee that an NPC or object is currently present. Missing database coverage is not filled with invented coordinates.

Live acceptance: `/reload`, leave Questie disabled and QuestieDB enabled, check that Ruthless matches Wisp's current pickup/turn-in and two upcoming actions, turn your character to check the small arrow, then select a quest with mob/object objectives and inspect both maps. Preview the next guide step through Tools and confirm both panels change together. Disable the Ruthless workspace and confirm its pins disappear.

Validation: `npm run test:quests` covers the guide display bridge, explicit callbacks, secret-value handling, source expansion, serialized Forever zone overrides, both-map pin registration, marker clicks, selection/disable cleanup and cross-zone navigation. Tests use simulated UI/APIs; they do not prove live rendering or combat taint behavior.

### World-map presentation update (0.14.0-beta.5)

The world map now shades approximate search areas for the selected quest instead of displaying every spawn icon. Click a quest in the native map quest list to focus its objective zone. Minimap spawn icons remain available at smaller sizes. Area shading follows recorded database locations; it is not live spawn occupancy or exact authored quest boundaries.

Acceptance: `/reload`, click two quests in different zones from the map quest list, and confirm the map changes zones and shades only the selected quest. Check that minimap icons remain clickable and smaller. Close/reopen and zoom the map, then disable the workspace and confirm its shading disappears.

### Classic gold map markers (0.14.0-beta.6)

The main map uses consolidated quest markers instead of shading: question mark = ready to hand in, exclamation mark = pickup, bag = collection source, sword = kill objective. Detailed spawn icons stay on the minimap, with larger question marks for turn-ins. Click an active-quest map marker to view its native side-log details; pickup markers show Ruthless's source/location details.

Database offer scanning runs in small batches after login and quest/level changes. It checks basic known eligibility; quests requiring unverified skill, reputation or special restrictions are omitted. This does not promise every Questie offer. A representative marker is a recorded source point near the centre of that quest/type's zone locations, not a marker for every spawn.

Acceptance: `/reload`, allow the pickup scan to finish, inspect gold exclamation/question marks and bag/sword markers, click an active quest marker and then a pickup marker, and check that the class-coloured arrow appears in the tracker while turning. Existing Wisp markers may remain visible because Wisp still owns its UI.

### Quest context and selected areas (beta 7)

Gold markers are 25% smaller. The selected quest also shades recorded objective search cells. Nearby quests and eligible pickups within 1,000 yards appear below guide up-next; scroll over those rows to browse all matches. In a dungeon the section instead lists matching dungeon quests from your log and known eligible pickups. Click a row to focus it; Guide returns to Wisp. Database coverage remains the limit, and selecting a pickup does not accept it automatically.

Acceptance: reload, click two world-map quests and compare their gold search areas; select a nearby active quest and a pickup, then return to Guide. Enter a dungeon with a logged dungeon quest and verify that its row appears and can be selected; scroll to additional rows. Test again outside the dungeon to ensure ordinary nearby context returns.

### Tracker information (beta 8)

The tracker displays current guide objective counts and along-the-way tasks, with content-sized spacing and scrolling for longer objective lists. Ruthless's own dungeon recommendation View opens matching logged quests without changing Wisp's route. Current quest special items appear as icons and item links: hover for details or Shift-click to link in chat. They do not cast/use the item.

Compass reading is allowed during combat and keeps valid cross-zone Wisp bearings even while the source arrow is momentarily hidden. Native/database points provide fallback. A missing position or destination on a different continent still needs actual route data; no fabricated bearing is shown.

Acceptance: reload, compare objective counts and spacing with Wisp; open the Deadmines recommendation in Ruthless and focus a quest; return to Guide; turn/move across zones and enter combat to check the compass; inspect and Shift-click a supplied quest-item link.


Local beta 9: quest-item buttons use the native quest-log item action (shift-click links to chat). Dungeon tracking is saved per character and managed from the world-map Dungeons tab; it lists held quests and eligible pickups from installed QuestieDB. Objective counts are aligned separately from names. Live item use and visual acceptance remain pending.

Local beta 10 adds the tracker Menu button opening world-map dungeon controls and caches dungeon classification/map area drawing. Compass updates are separate from once-per-second content refresh. Live FPS recovery is pending; simulated cache, invalidation, cadence and menu interaction checks pass.


Local beta 11 audits every module and reduces idle work through visible-only subscriptions, cached data, demand-created settings/macro/dashboard UI, event-driven map drawing and stopped idle animations. `/pr perf` reads native CPU metrics only when requested. See [performance audit](docs/PERFORMANCE-AUDIT.md) for module coverage, measured simulation results and the live acceptance procedure.

### Beta28 dungeon atlas
The dungeon atlas now ships its own maps and demand-loaded boss/loot records. Install all three packaged addon folders and restart WoW once; Atlas/AtlasLoot are not required. See docs/DUNGEON-ATLAS.md for source licensing, optional quest-coordinate provider and coverage limits.

## Authored Classic guides

Beta 31 adds RUI-owned 1–20 hub routes. Open Map → Library to start, then Chapters for full instructions and saved chapter controls. Coverage and the live review procedure are in [Authored guides](docs/AUTHORED-GUIDES.md). Routes require live pacing review; custom/TBC starter zones are not yet covered.

## Edit layout

Use `/pr edit` or General → Edit RUI layout to arrange open RUI panels. [Layout editor](docs/LAYOUT-EDITOR.md) describes supported panels, controls and live review checks.
