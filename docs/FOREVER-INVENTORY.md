# Forever inventory

RUI owns the combined inventory geometry and presentation. Blizzard continues to own the item-button instances, their bag/slot IDs, actions, tooltips, search/filtering, sorting, bag assignment menus, money and watched currencies. There is no Bagnon dependency.

Local source review: installed Bagnon src/frame.lua (Layout, PlaceItemGroup, PlaceSearchBar, PlaceFooter), BagBrother core/classes/itemGroup.lua (Layout, stable per-bag slot buttons and event-driven updates), and core/classes/containerItem.lua (native item operations and cooldown handling). These were used to understand design and lifecycle; RUI does not copy their implementation.

The earlier skin retained Blizzard's bottom-right anchored grid and portrait-header padding. RUI now measures a top-left grid using existing EnumerateValidItems buttons, with 36px slots, 2px gaps, 8px side padding, a 58px header/search area and a 26px footer plus watched-currency height. Column choices are 8, 10 or 12. Native geometry refreshes are post-hooked with a layout reentrancy guard. No item data scan or per-frame polling is added.

Menu.ModifyMenu extends MENU_CONTAINER_FRAME_COMBINED with RUI settings, keeping original assignment/cleanup options. ruiBags in character saved variables stores columns and autoSort. OnShow requests one SortBags call when enabled; combat and its grace period defer that request; hiding cancels it. Item updates do not sort. Auto-sort defaults off.

Local harness checks geometry, click preservation, settings and deferred sorting. Live appearance, item pickup/split/use, currencies, bag assignment, full-bag sort and combat taint still require in-game acceptance. Offline bank/alt inventory caching and full Bagnon feature parity are not implemented.


## Combined reagent bag — beta92
The held reagent bag joins the combined backpack, including its native item-button pool and total/free slot counts. A narrow adapter extends combined routing/identity and adds only missing reagent bag/slot pairs after the original pool rebuild. Native Initialize, click scripts, bag/slot IDs, search, cooldowns and sorting remain responsible for item behavior. Bank routing and individual-bag mode remain separate. Duplicate held reagent windows close only when combined mode is active. Native bag-container updates rebuild slots on equipment changes; repeated updates do not duplicate them. Protected combat work defers.

Live check: reload outside combat, open/close the backpack, search an item in the reagent bag, inspect its tooltip, move/split an inexpensive stack, sort, then close/reopen and reload. If testing bag swaps/removal, empty the bag first through normal game controls. Check item locks/cooldowns and confirm that bank bags and individual-bag mode still behave normally. Automated checks execute inspected native initialization/routing but do not certify live bag interactions or absence of taint.


## Initialization repair — beta93
Beta92 used the old Initialize(bag, slot) contract against a client that requires Initialize(containerFrame, bag, slot). The missing slot argument caused SetID errors; prematurely increased capacity then caused nil item-button errors during layout and close. This was an RUI regression, not an item-data problem.

The adapter now observes the initialized native regular buttons for containerFrame ownership and calls the matching contract. It updates capacity after successful construction, and rolls appended controls back on an incompatible initializer while restoring separate reagent routing. Tests reject invalid/nil slot IDs, execute the current native UpdateItemSlots/Initialize, assert every advertised slot has a button, and cover partial initialization failure. The real broken beta92 module fails this strengthened current-source harness.

Current development reference: Gethe/wow-ui-source forever 9dc84f0d3bbae1768ac3405b3716000bd93eda06, checked 2026-11-09. validation/native-source.json records provenance; tools/check-native-source.cjs checks the test checkout and CI/live-gate pins, and --check-remote verifies branch freshness. Historical fixtures are regression-only references. The source mirror is not a substitute for live-client protected/taint testing.
