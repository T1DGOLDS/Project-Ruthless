# Macro tools and starters

Open Spellbook → Macros → Templates. The panel has Markers, Pings, Tools and Spell starters, a scrollable explanation, and selectable examples for each of Forever's nine classes.

Markers cover all eight target icons and clearing; the native `/tm` parser handles mouseover/target selection, permissions and the `!` keep-marker prefix. Pings use the current native `/ping` parser's six numbered types plus its context ping. A client without `C_Ping.SendMacroPing` shows them as unavailable. Tools include reload, setting/clearing focus, previous target, pet attack and pet recall. Selecting or browsing a row never performs an action or writes a macro. **Create macro** deliberately adds a utility to the currently selected bank, using the existing guarded macro creation path. An existing exact body in that bank is selected instead of duplicating it. It never edits or renames an existing macro, sends a ping, changes a target or reloads the UI.

Spell starters cover mouseover, focus, target of target, cursor placement, self-target, Shift choices, help/harm choices, melee auto-attack, resurrection, manual sequences and aura cancellation. **Open draft** creates an unsaved starter; replace every capitalised placeholder with the exact localized spell name, review macro checks and press Save. Explanations distinguish class examples from learned abilities, reticle spells from feet/self placement, pet resurrection from player resurrection, and one-action-per-press sequences from automatic decisions.

Unsaved editor changes block factory creation/draft replacement until the user closes the panel and saves or reverts them. Combat and full-bank guards preserve the existing behavior. The catalogue is data only and loads before Spellbook on Forever. The non-Forever manifest can retain its existing seven starter fallback.

Native source contract: reviewed Forever UI revision `9dc84f0d3bbae1768ac3405b3716000bd93eda06`, `Blizzard_ChatFrameBase/Shared/SlashCommands.lua` target-marker handler and `Mainline/SlashCommandsOverrides.lua` secure ping handler. Numeric ping types are Attack, Warning, OnMyWay, Assist, AlertNotThreat and AlertThreat; they are not inferred from Retail documentation. Native group restrictions and cooldowns still apply at use time.

Run `node tests/run-macro-factory.cjs` with `PR_WOW_FOREVER_SOURCE` for the native-source contract plus mocked creation/lifecycle checks. Real-client visual fit, learned-spell examples, marker/ping execution and combat/taint remain live acceptance checks.
