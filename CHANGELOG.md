# Changelog

## Unreleased

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
