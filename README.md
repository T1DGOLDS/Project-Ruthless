# Project Ruthless

Project Ruthless is a modular World of Warcraft interface focused on practical tools that preserve Blizzard's familiar workflows.

The project begins as a hybrid ElvUI companion so Andrew's long-developed layouts remain intact. Modules will gradually move suitable components onto Blizzard's native UI without forcing a visual reset.

## Current milestone

Project Ruthless currently provides:

- a standalone addon identity;
- account-wide and per-character saved settings;
- a small module lifecycle;
- `/pr` command namespace;
- an ElvUI compatibility module that applies the safe-tooltip workaround consistently.
- a persistent, copyable Lua error log for addon development.
- a sleek dark `/pr` control centre with automatic character class-colour accents.
- a progressive red border glow that warns when player health falls below 35%.
- an optional experimental Character workspace with equipped gear, compact item-level context, combat stats, and equipment-set selection; Blizzard's Character frame remains the default.
- a standalone Spellbook restoring General, class, Professions, and Macros to the normal book button, with filters, pinned spells, action-bar location feedback, macro templates, autocomplete, validation, and recovery history.
- a functional `/pr` settings centre for presentation, Character, Spellbook, health-warning, compatibility, and diagnostic controls.
- a compact Talents workspace on the normal Talents button/keybind and `/pr talents`, with specialization buttons, a clean loadout list, Save copy/Import/Export/Manage actions, and the native class/hero talent trees.
- a Statistics dashboard inside Blizzard Achievements with account progress, titles, honorable kills, recent milestones, and category completion at a glance.

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
2. Extract the `ProjectRuthless` folder into `_retail_/Interface/AddOns`.
3. Enable Project Ruthless from WoW's AddOns screen.

ElvUI, Raider.IO, and Epithet integrations are optional. Project Ruthless does not require a separate bootstrap addon.

## License

Project Ruthless is released under the MIT License. See `LICENSE`.

## Commands

- `/pr` — open the Project Ruthless menu
- `/pr status`
- `/pr errors`
- `/pr achievements`
- `/pr statistics`
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
