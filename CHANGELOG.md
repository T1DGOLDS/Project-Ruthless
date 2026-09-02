# Changelog

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
