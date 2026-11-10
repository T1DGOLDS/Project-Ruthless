# Quest/map navigation and guide presentation

## Navigation

The map sidebar keeps six content destinations: Quest log, Available, Guides, Progression, Supplies and Dungeon atlas. Custom pages now have a shared **Back** button in their header. Page history is bounded to twenty entries; returning does not add another history entry. Guide chapters return to the guide library and selected progression groups return to the group list. Specialized atlas nesting can use `QuestWorkspace:SetMapBack(label, callback)` to name its own parent. The heading leaves room for Back and does not wrap over the content.

Guide routes are filtered by faction, race and nearby level range by default. The player's current zone comes first, then level and name; **All routes** remains an explicit choice. Existing 20–30 routes have not been deleted. Progression lists put the live quest log first, then dungeon preparation, native groups and original routes in level order. Race-specific original routes no longer appear for other races.

## Current-step guide

The default view is deliberately focused: the current quest, a pickup/objective/turn-in instruction, its native objective progress and at most one passive upcoming-step label. Unverified pickups cannot take priority over objectives or turn-ins already present in the player's log. Known giver names are read from existing recorded facts; missing names/availability are not invented. Other held quests remain in the normal quest log.

Open the active guide's Chapters page to change:

- **Guide detail**: current step or expanded chapter notes and route groups.
- **Upcoming step**: show/hide the single preview.
- **Other active quests**: show/hide unrelated held quests in the side tracker.

These preferences use `questWorkspace.guideDetail`, `guideUpcoming` and `guideOtherQuests`. Chapter controls also retain Pause/Resume, Stop, chapter selection, Skip and progression browsing. Skipping a guide entry does not abandon its quest.

## Reference and data limits


The existing original RUI route file contains 36 routes/detours, 673 quest metadata records and suggested ranges from 1 to 30. It contains no level-60–70 routes. Thus that higher-expansion material came from a different catalog, not this file. The atlas has its own source and filtering work.

**This presentation cleanup does not establish that every route, travel instruction or prerequisite is accurate on live Forever.** Current-step instructions and recorded metadata improve the display, but the original hub/loop routing still requires quest-by-quest live validation against current public Forever records. Unknown requirements remain explicit. Full 1–20 route accuracy and pacing still require live validation.

## Validation

The quest-workspace and progression suites exercise Back/history and scroll reset, opt-in chapter notes, level/faction/race route filtering/current-zone ordering, focused-tracker opt-in for unrelated quests, and existing combat/native map behavior. The beta100 instance-transition completion-announcement regression remains covered. These simulations do not prove real-client layout, route quality or combat safety.
