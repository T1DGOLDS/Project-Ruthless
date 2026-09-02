# Changelog

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
