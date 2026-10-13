# Guide sources

Accepted direction (2026-10-10): RUI presents walkthrough information; the user chooses the route engine. Default RUI routes, Wisp, RestedXP, Questie if a walkthrough API is available, and future providers should fit the same presentation. Do not copy guide data or silently substitute engines.

Current beta60: Map & quests options has a saved Guide source cycle button for RUI default and Wisp; map Settings also offers source cycling. RUI uses the existing authored route selection. Wisp reads its existing active route. Missing Wisp reports not running and falls back to the ordinary quest list, without substituting another guide. New default settings choose RUI. Old callers without guideSource retain historical auto behavior.

QuestWorkspace:RegisterGuideProvider(id,label,reader) registers another source. reader(workspace) returns a presentation record with quest, target, phase, count, instruction, objectives, next, optional id/questIDs/futureQuestIDs. All rendered strings must be public, and IDs must be verified. Reader must be cheap/cache-backed: visible tracker samples it on the existing cadence. RUI stamps source=id. Provider owns route progression; external action/navigation adapters are not implemented by this reader contract. Invalid or unavailable provider output produces no guide. Native quest-list selection/highlight synchronization remains separate.

RestedXP and Questie integration remain planned: verify actual walkthrough API and Forever support before registering either. RestedXP is not installed locally; source inspected but no guide data/engine copied. Questie database/quest markers alone do not establish a walkthrough engine. No claim of external guide compatibility or 1–20 completeness. Tracker redesign remains deferred.

## Beta65: active route presentation

An explicit RUI source auto-starts only when no route was configured or explicitly stopped, and the current map (or parent) matches a bundled faction/level route. Existing held route quests select their chapter; otherwise the highest chapter start level reached is used. Zone mapping uses the installed database, with zone-name fallback. Existing active routes remain selected across travel.

The tracker keeps RUI guide presentation when nearby quests are clicked. Available pickups come first, followed by held objectives, turn-ins, uncertain availability and blocked requirements, preserving authored order within each group. Up-next uses that same order; previewing a pickup never counts as acceptance. Guide navigation and supplemental selected markers follow the guide step; only held quests can be selected in Blizzard's log. An unrelated pickup preview cannot redirect the guide arrow.

Paused/stopped guides show an explicit state. Without a matching route, the tracker says CHOOSE A GUIDE and directs the user to Map > Library; resume an existing paused route from Chapters. No fallback to the currently selected quest masquerades as a walkthrough. Route transitions between zones are still manual via Library; these 15 original hub routes remain limited coverage, not a complete optimized external walkthrough. Provider choices and unavailable-provider behavior are unchanged.

## Beta68: level 20–30 extensions

RUI now includes eight additional original continuation routes in Duskwood, Wetlands, both factions’ Ashenvale and Stonetalon, Horde Hillsbrad and Thousand Needles. The Library lists 1–30 guides. Selection/progression/provider behavior is unchanged; zone transitions remain manual. See AUTHORED-GUIDES.md for coverage and live acceptance limits.

## Beta69: remaining twenties coverage

The catalog now has 36 routes/detours, 20 zones and 673 verified quest IDs. Thirteen additions cover remaining twenties zone/faction visits; sparse content is labelled Optional detour in Library and does not auto-start. Unconfigured auto-selection prefers a later-starting continuation at shared level boundaries. Configured routes and external provider choices stay selected; no automatic zone transitions or new provider adapter. See AUTHORED-GUIDES.md for exact ranges, prerequisites, excluded repeatable-only zones and live limits.
