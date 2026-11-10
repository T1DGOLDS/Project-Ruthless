# Travel facts — retrieved 2026-11-10

This is data only. No other addon needs to be installed or loaded.

* 85 Spirit Healer positions: NPCs 6491 and 278875 from the corrected **Forever** export of [QuestieDB](https://github.com/Questie/QuestieDB), revision `c1b50fefb19c064edc436429bef73435d9ff4254`. Direct area-to-UI-map mappings only. Retain the bundled QuestieDB licence notices and their historical-contributor qualification. No test NPCs or faction-controlled battleground spirit guides.
* 881 directed **Classic reference** durations: `global_classic` in [InFlight Defaults.lua](https://github.com/LudiusMaximus/InFlight/blob/2efdd7ba6d0e094edf84a04eeb40c038f004ea52/Defaults.lua), revision `2efdd7ba6d0e094edf84a04eeb40c038f004ea52`, MIT (full notice alongside). This is the same fallback table upstream selects for Forever; its Forever-specific overrides are empty at retrieval. These durations are estimates, never described as measured Forever flights. RUI records its own completed flights separately, including the chosen hops and current speed-perk state.

The editable source is `travel-facts.json`; regenerate Lua with `python tools/build-travel-data.py`. Do not merge Retail/Cataclysm flight times or assume the reverse direction takes the same time.

## Coverage limitation

No authoritative death-release polygons were found. Blizzard's inspected DeathInfo API exposes locations and the current release destination, not boundary polygons. Online UnstuckSkips partitions describe unstuck teleports and are not imported as death coverage. Optional RUI outlines are nearest-recorded-healer estimates, in physical map units, clipped to the displayed map. They cannot account for server rules, phase, inaccessible terrain, or every neighbouring-zone healer. Hover tooltips explain this. The game's supplied release position is shown separately and takes precedence as the actual destination.
