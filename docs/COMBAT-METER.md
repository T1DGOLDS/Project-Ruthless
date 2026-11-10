# RUI combat meter — beta90

RUI uses Forever's native damage engine and native session/source windows. Native code retains live combat updates, ordering, totals, class colours, source/spell records and interactions. RUI does not read or sort protected combat records, parse combat-log events, replace native click handlers or refresh native data providers from addon execution.

## Controls

- `/pr meter` enables the native meter and opens the RUI controls explanation. Existing profile activation preferences are retained at login. An unprofiled character receives one initial activation attempt; subsequent choices are respected.
- Use the meter's type selector for damage/DPS, healing/HPS, damage taken, interrupts, dispels, deaths and the categories offered by the installed client.
- Use the fight selector for current fight, overall or previous fights. Native history remains native; RUI does not create a separate combat-history database.
- Click a player row to inspect spell contributions. Shift-click pins the native breakdown open.
- The native meter settings button retains reset, additional windows, lock and supported display options. RUI Edit Mode stores window positions.
- RUI Settings > Utilities controls activation, flat fills and row text size, with a background-colour/opacity shortcut. Meter preferences and geometry travel with RUI profiles. Native metric/session selections remain character-owned native preferences.

## Presentation and safety

RUI supplies charcoal surfaces, thin borders, flat class-coloured row fills, configurable text and matching source-window backgrounds. Turning flat fill off restores captured native texture/atlas styling. Font setters do not inspect rendered names or values. Global colour/opacity and accessibility backgrounds use the Meters group.

Initialized native rows are observed with the supported ScrollUtil callback. Cosmetics queue outside native data initialization and wait until combat ends; a row first appearing during combat can temporarily retain native styling. The native meter continues updating during that wait. Callbacks register once per scroll box, pooled rows are reused, and repeated combat callbacks coalesce into one after-combat styling request. No RUI meter polling, native Setup/Refresh call, data snapshot or numeric combat-value arithmetic is added.

This provides the native-supported live meter workflow in RUI presentation. It does not claim the whole Details plugin ecosystem, custom combat scripts, a separate report/export parser, unlimited native history or unrestricted access to hidden combat data. Unavailable native categories are not invented.

## Evidence and live acceptance

Tests poison native combat-data/setup calls and verify RUI never enters them. They cover native click-handler preservation, flat/native texture restoration, text changes, one callback registration, combat deferral, retained profile activation and reuse of existing surfaces. Existing native-meter independence, profile, settings, layout and performance suites also run.

Live acceptance still requires an ordinary fight with changing live rows/values, click/Shift-click spell breakdowns, current/overall/previous fight selection, healing and other relevant categories, secondary windows, reset confirmation, reload/profile geometry and a crowded fight under `/pr record`. Confirm RUI presentation returns after combat for newly pooled rows. Inspect `/pr errors` afterward. Static/mocked tests cannot certify combat safety, accuracy, visual fit or CPU cost in WoW.
