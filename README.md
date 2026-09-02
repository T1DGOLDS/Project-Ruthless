# Project Ruthless

Project Ruthless is Andrew's personal, modular World of Warcraft interface.

The project begins as a hybrid ElvUI companion so Andrew's long-developed layouts remain intact. Modules will gradually move suitable components onto Blizzard's native UI without forcing a visual reset.

## Current milestone

Project Ruthless currently provides:

- a standalone addon identity;
- account-wide and per-character saved settings;
- a small module lifecycle;
- `/pr` command namespace;
- an ElvUI compatibility module that applies the safe-tooltip workaround consistently.
- a persistent, copyable Lua error log for addon development.
- a central `/pr` menu with Status and Errors tabs.

## Development loop

The live WoW AddOns directory uses a junction to this repository. Edit the source, save it, then use `/reload` in WoW to load the current revision.

## Commands

- `/pr` — open the Project Ruthless menu
- `/pr status`
- `/pr errors`
- `/pr errors clear`
- `/pr errors test`
- `/pr errors on`
- `/pr errors off`
- `/pr tooltip on`
- `/pr tooltip off`

## Principles

- Preserve Andrew's established layout and muscle memory.
- Make one visible change at a time.
- Prefer Blizzard-native systems when they are stable and capable.
- Retain ElvUI compatibility until a replacement module earns its place.
- Keep modules independently disableable and reversible.
