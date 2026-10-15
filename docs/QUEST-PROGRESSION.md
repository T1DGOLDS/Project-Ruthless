# Quest progression — beta 76

RUI owns this engine, interface and original progression presentation. It has no Attune bridge and does not redistribute Attune code, assets, layout or database. It uses native Forever APIs, independently authored RUI requirement facts and existing original RUI routes.

## Interaction

Open Map → Progression. Choose a dungeon, native quest group, existing faction route or Your quest log. Select a quest node to inspect status, ID, known pickup area/giver, minimum level, prerequisites and source limitations. Follow explicitly makes that quest the current side-tracker task. Merely browsing a node leaves the active guide unchanged. Return to leveling guide releases that focus.

The chart uses wheel scrolling, Shift+wheel horizontal scrolling and empty-space dragging. Zoom and Reset view buttons remain at the bottom. Left/right arrows select quest nodes while the graph has no text editor focus, scrolling the selection into view. Status text and selection marks accompany colour. The sidebar scrolls separately. No graph OnUpdate runs except during an active pan gesture; hiding stops it.

Sharing is an explicit button for the selected quest and delegates to the existing native sharing path. The game still decides whether a quest can be shared; party membership, held/shareable state and combat restrictions are rechecked. No background survey, guild synchronization or automatic sharing is introduced.

## Coverage and certainty

- **Original dungeon prerequisites:** The Deadmines Alliance preparation path has eleven quest nodes, including the Defias report/escort chain, its branch into Red Silk Bandanas, and independent dungeon pickups. IDs, minimum levels, starter identities and prerequisite relationships were checked against installed Forever metadata on 2026-10-16. Notes and layout are original RUI work. Live review is pending; database evidence is not server acceptance evidence. This is dungeon quest preparation, not a claim the dungeon requires an entry attunement.
- **Existing original routes:** the faction-appropriate RUI hub routes appear as quest groups using existing title/minimum-level facts and hub areas. A hub's quest order is guidance, not a proved prerequisite relationship. Individual giver coordinates are not inferred from hub names.
- **Native quest groups:** discover native quest lines from the current log and available map feed. Membership is retained per character, bounded at 32 groups and 160 quests per group. Blizzard's membership/order does not establish prerequisites, so these groups have no fabricated dependency edges. Full/unavailable groups remain browsable through the native quest log; the new UI does not claim exhaustive game coverage.
- **Live quest log:** all public non-header log records appear independently, with native held/completed/turn-in states. No external quest database is necessary for this view.
- **Unknowns:** unmet known prerequisites are Blocked; unavailable state is Unknown; otherwise an unheld quest says Check giver, never falsely Available. Missing coordinates remain missing. Location actions use only real native supplied coordinates; known text areas remain useful without a waypoint.

All other dungeon prerequisite chains require independently sourced/verified content. Existing optional QuestieDB/location adapters still support older guide eligibility, spawn information and tooltips elsewhere in the addon. Beta76 does not claim those remaining dependencies are removed. Optional user-selected leveling guide providers remain a deliberate supported exception. The accepted permanent direction is native/RUI-owned quest progression throughout the map.

## Ownership and performance

Content and native observations are separate from current status. Native completion/held state remains authoritative, including a held repeatable quest whose historical flag is completed. Pickup suggestions do not become completed quests. Following a chain can advance to its next unresolved quest, but unknown acceptance requirements remain visible.

Focus and retained native groups live in per-character `questProgression`; profile changes do not overwrite them. This is not a new account character-history database. Native data queries occur on demand, states cache until related quest/level/zone changes, event bursts coalesce, and the graph reuses controls. Bounds and graph validation prevent unbounded drawing, duplicate IDs, missing prerequisite references and cycles. No combat-log access, aura/health inspection or hidden-value arithmetic is required.

The compact tracker now shows the current step, that quest's objectives and special item only. Nearby/dungeon lists and preparation prose remain available through map tools rather than being repeated on the tracker. The previous nearby-database context scan is bypassed on this surface.

## Live acceptance

1. With Attune, Questie and QuestieDB disabled, open Map → Progression. Check Your quest log and available native groups. Verify native map pins and M open/close still work.
2. On Alliance, open The Deadmines. Inspect the Defias chain and branch into Red Silk Bandanas; click each node and verify giver/area, minimum level and state against the server. Check independent dungeon pickups. Record any Forever mismatch as data corrections, not a passed gate.
3. Open a dungeon from the atlas without a usable native floor: the supported Deadmines chain should occupy the map canvas. Native mapped floors, bosses, loot and reference maps remain reachable through Dungeon atlas.
4. Browse a node while following a leveling guide; the tracker must stay unchanged. Press Follow and confirm the tracker now shows only that step/objectives/item. Complete/turn in a quest, verify actual completion and next unresolved focus; abandon/reaccept, reload and switch profiles. No previous quest or stale pickup should remain as the active task.
5. Pan, zoom, scroll both axes, use keyboard node selection, resize/reopen the map and switch tabs. Graph must disappear on every other tab and on disabling the workspace. Check 100–150% text, long names and small screens for clipping.
6. Browse during combat without blocked actions or secret errors. Try sharing a held shareable quest outside combat, then solo, unshareable and during combat. Expect native restrictions and useful messages, not bypasses.
7. Record quest/bag bursts, graph opening, prolonged idle and repeated open/close. Compare recordings; no idle graph callbacks, control growth or repeated hitches should appear. Automated tests do not certify live CPU cost.

`npm run test:progression` covers standalone engine/graph behaviour; `test:quests` also checks the actual workspace's focus-only rendering. Six live release gates remain pending until Andrew supplies evidence.
