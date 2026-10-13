# Forever inventory

RUI owns the combined inventory geometry and presentation. Blizzard continues to own the item-button instances, their bag/slot IDs, actions, tooltips, search/filtering, sorting, bag assignment menus, money and watched currencies. There is no Bagnon dependency.

Local source review: installed Bagnon src/frame.lua (Layout, PlaceItemGroup, PlaceSearchBar, PlaceFooter), BagBrother core/classes/itemGroup.lua (Layout, stable per-bag slot buttons and event-driven updates), and core/classes/containerItem.lua (native item operations and cooldown handling). These were used to understand design and lifecycle; RUI does not copy their implementation.

The earlier skin retained Blizzard's bottom-right anchored grid and portrait-header padding. RUI now measures a top-left grid using existing EnumerateValidItems buttons, with 36px slots, 2px gaps, 8px side padding, a 58px header/search area and a 26px footer plus watched-currency height. Column choices are 8, 10 or 12. Native geometry refreshes are post-hooked with a layout reentrancy guard. No item data scan or per-frame polling is added.

Menu.ModifyMenu extends MENU_CONTAINER_FRAME_COMBINED with RUI settings, keeping original assignment/cleanup options. ruiBags in character saved variables stores columns and autoSort. OnShow requests one SortBags call when enabled; combat and its grace period defer that request; hiding cancels it. Item updates do not sort. Auto-sort defaults off.

Local harness checks geometry, click preservation, settings and deferred sorting. Live appearance, item pickup/split/use, currencies, bag assignment, full-bag sort and combat taint still require in-game acceptance. Offline bank/alt inventory caching and full Bagnon feature parity are not implemented.
