# Ruthless UI

Ruthless UI is a standalone interface overhaul for **WoW Forever**. It brings familiar game controls into a consistent charcoal interface, with searchable settings, shared profiles and practical tools for everyday play.

## Features

- Compact player, target, pet and party frames; configurable auras, nameplates, cast bars and attack timers.
- Persistent action-bar layouts, a grid-based layout editor, alignment guides and account profiles.
- A Spellbook for class and pet abilities, future skills, macros, autocomplete, explained templates and recovery history.
- A separate Professions window for recipes, leveling, vendors, crafting estimates and shopping plans.
- A map workspace for quests, available pickups, routes, progression, supplies and a dungeon journal.
- Auction tools with saved character searches, shopping lists, price observations, market snapshots and selling preferences.
- A combat meter, combined backpack, square minimap, flight timers, repair reminders and leveling history.
- Accessibility choices, feature explanations, configuration checks and local bug/performance reports.

## Install

Download a [versioned release](https://github.com/T1DGOLDS/Project-Ruthless/releases) and install all three folders in your Forever client's `Interface/AddOns` folder:

- `ProjectRuthless`
- `ProjectRuthless_Options`
- `ProjectRuthless_DungeonData`

Run `/reload` after an update. Existing profiles and character progress are retained. Settings and Edit Mode share account profiles, with a separate default selection for new characters.

## Open the tools

- `/pr`: searchable settings, profiles, accessibility and help.
- `/pr edit`: movement, scaling, grid snapping and alignment.
- Spellbook shortcut: spells, pet abilities and macros.
- Professions shortcut (normally K): the separate profession workspace.
- M: map, quests, routes, supplies and dungeon information.
- `/pr auction`: auction planning; `/pr meter`: combat meter.
- `/pr checks`: guided live checks; `/pr report`: copyable bug report.
- `/pr record on` and `/pr record off`: optional local performance recording.

## Current scope

Current source and documentation live on [forever-beta](https://github.com/T1DGOLDS/Project-Ruthless/tree/forever-beta). Builds are experimental. The six manual acceptance checks remain pending; automated checks do not certify client combat safety, visual quality or performance gains. Protected edits defer until combat ends. Missing quest, recipe, vendor, map and price data remain labelled; crafting margins and reference travel times are estimates.

Read the [feature guide](https://github.com/T1DGOLDS/Project-Ruthless/blob/forever-beta/docs/FEATURE-GUIDE.md), [profession guide](https://github.com/T1DGOLDS/Project-Ruthless/blob/forever-beta/docs/PROFESSIONS.md), [quest coverage](https://github.com/T1DGOLDS/Project-Ruthless/blob/forever-beta/docs/QUEST-AVAILABILITY.md) and [testing workflow](https://github.com/T1DGOLDS/Project-Ruthless/blob/forever-beta/docs/TESTING-AND-RELEASES.md).

## Licence and credits

RUI's licence is in [LICENSE](LICENSE). Bundled libraries, reference data and map assets retain their required source, copyright and licence notices alongside those files. These notices describe included material.
