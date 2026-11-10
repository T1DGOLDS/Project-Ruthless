# Forever action bar ownership - beta87

## Implementation

ForeverActionBars creates eight SecureHandlerStateTemplate containers with 12 LibActionButton buttons each, before ForeverHUD attaches movers. RUI owns their geometry and does not expose them to the native Edit Mode system registry. Secure page/visibility drivers run in combat. Event-driven bindings reuse native commands and action slots. This is an architectural replacement for earlier native anchor recovery attempts.

Main bar supports pages 1-18 and bonus/stance/stealth/override transitions. Fixed pages for bar2-8 are 6, 5, 3, 4, 13, 14, 15. Native pet, stance, extra-action, override and gamepad controls remain. Main presentation hides for native vehicle/override/possession UI. These special states need live testing.

## Migration and settings

Existing layoutEditor.elements bar1-bar8 are read before replacements are built. Coordinates, scale normalization, native numeric grid settings, visibility and bar-enable choices carry across. Original elements are copied once to ProjectRuthlessCharDB.actionBarMigrationBackup. Action slots are never rewritten. A failed construction leaves the original bars active and restores saved element data.

One RUI profile still owns the interface. Edit Mode Element settings edits icon size, spacing, rows/columns, button count, orientation and empty slots. Existing action-bar enable controls use RUI visibility. Native numeric setting IDs remain the serialization keys so existing layouts load without another selection. All geometry/configuration writes require out-of-combat execution. No level-up restore timer or layout polling is added.

## Library boundary

LibActionButton 168 provides secure action drag/click handling, state updates, hotkeys, range feedback and native duration-object cooldown rendering for Forever. It is bundled with LibStub 2 and CallbackHandler 8. A private RUIActionBarLibStub registry prevents installed addon libraries from replacing the bundled engine or supplying optional dependencies. Refer to ../Libs/LibActionButton/README.md for sources, licences and local modifications.

Replaced buttons are removed individually from Blizzard event/update/range/usable registries. Extra actions and other native buttons remain. Stock presentation is hidden only after every replacement exists. This does not claim to resolve the separate native objective-tracker secret-aura taint report.

## Evidence and acceptance

Automated checks execute the real private registry/callback bootstrap with the public registry poisoned, then simulate migration, all fixed slot pages, main state mappings, dual bindings, native reanchors during combat, deferred binding changes and partial-creation failure. Layout tests exercise owned-grid profile capture/apply without native setting writes. Package tests verify bundled files/licences survive archiving. Lua 5.1 syntax and Forever contracts run separately.

These checks do not execute WoW's protected runtime. Live acceptance must verify level-up during combat with unchanged bar bounds, spell drag/drop, cooldowns, keybinds, profile save/load/reload, stances/forms/stealth and vehicle/override/possession controls. Check /pr errors afterward. All release live gates remain pending.
