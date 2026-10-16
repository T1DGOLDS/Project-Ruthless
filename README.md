# Project Ruthless

Ruthless UI is a standalone interface overhaul for WoW Forever (`Interface 16001`, game type `camelot`). It presents native game functions through a consistent charcoal interface, searchable settings and shared profiles.

## Beta 79

The release-readiness follow-up adds `/pr checks`: six guided live checks, evidence notes and version/client-specific manual results included in the bug report. Nothing passes automatically. [Workflow and limits](docs/LIVE-CHECKS.md).

## Stage-five foundation

Stage five removes the installed quest-database and map-library connections, external meter styling and the unused Retail talent workspace from Forever's load list. RUI now owns its supplemental map markers and reads native quest offers/waypoints. Blizzard's native damage meter supplies combat information; RUI supplies its background, borders and saved movers.

**Quest coverage has changed:** the complete spawn database is no longer used. Native quest markers and blue areas remain Blizzard-owned. RUI's original 1–30 routes, current offers, held objectives and supplied waypoints remain available. Unrecorded spawn locations, item-drop sources, pickup requirements and dungeon associations stay unknown. Supplementary cog/bag/sword markers require verified source records and are omitted where none exist. Read the [coverage and stage-five checks](docs/STAGE-FIVE.md).

## Installation

Install the three bundled folders together:

- ProjectRuthless
- ProjectRuthless_Options
- ProjectRuthless_DungeonData

Options and dungeon data load on demand. No other installed addon is required. An explicitly selected supported leveling-guide provider is optional; Wisp is currently supported. RestedXP and other providers are not claimed as implemented.

Existing profiles and character progress are retained. Settings and Edit Mode use the same account profiles, with a separate default selection for new characters. Fresh characters without a selected default begin with the familiar native arrangement in RUI presentation.

## Controls

- `/pr`: searchable settings, backgrounds, profiles, accessibility and diagnostics.
- `/pr edit`: positions, grid snapping and shared profiles.
- `/pr spellbook`: spells and macros.
- `M`: native map with RUI quest progression, routes and dungeon information.
- `/pr record on` / `/pr record off`: opt-in local performance recording.
- `/pr report`: copyable bug report with configuration checks and measured work.
- `/pr checks`: guided live testing and self-reported outcomes.

Auras & cooldowns offers simple native-rendered groups, presets, static previews and exact-ID buff focus. Native spell/alert configuration remains native. Utilities contains health feedback, native damage-meter activation and leveling history. Visual preferences live in settings; journey information lives primarily in the map.

## Validation and limits

Seventeen automated suites cover the current build. All six live acceptance gates remain pending: installation, profiles, combat, information, accessibility and performance. Automated mocks and in-game manual status buttons do not certify native combat safety, visuals, accessibility parity or FPS improvements.

Native protected edits defer during combat. RUI does not calculate secret aura/cooldown/combat values. Restoring changed native cooldown configuration requires reload. Native meter categories, session selections and secondary-window preferences remain character-owned by Blizzard; profiles include activation and RUI mover positions. No other addon's settings are migrated or changed.

- [Stage five: independence, coverage and measured work](docs/STAGE-FIVE.md)
- [Auras and cooldowns](docs/AURAS-AND-COOLDOWNS.md)
- [Quest progression coverage](docs/QUEST-PROGRESSION.md)
- [Testing, reporting and release gates](docs/TESTING-AND-RELEASES.md)
- [Changelog](CHANGELOG.md)

Legacy Retail source remains preserved without new Retail feature development. Bundled dungeon reference assets/data retain their included attribution and licence notices; they are distinct from requiring another installed addon.
