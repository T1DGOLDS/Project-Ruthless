# Settings consolidation — beta97

## Four review passes

1. Inventory and ownership: enumerate rendered controls and entry points, preserve stored values, and identify duplicate definitions and misplaced links. Seventeen primary sections become thirteen. Contextual auction settings remain integrated in that window and use the main menu's shared definitions.
2. Consolidation: Interface / Activities / Setup & Support. Backgrounds is a child of Appearance, quick setup a child of Profiles, error log / compatibility / About children of Help. Old IDs retain valid destinations. Map/tracker configuration lives in Map & quests; the map retains content and actions.
3. Presentation: shared scrolling layout, headings, explanatory descriptions, explicit choice menus, separate profile workflows, search synonyms and exact nested destinations. Aura/cooldown and configuration readouts use the same layout. Native professions remain accessible from the spellbook; the unused map placeholder is removed.
4. Regression review: construct all thirteen primary pages, test non-overlapping rows and scroll extent at 100/125/150% simulated text metrics, exercise choices/profile-table replacement, verify native contracts, and retain manual live gates. Mocks do not prove real-client visual quality.

## Settings navigation

| Group | Primary pages |
| --- | --- |
| Interface | Appearance; Unit frames; Action bars; Auras & cooldowns; Spellbook & macros; Chat; Bags & inventory |
| Activities | Map & quests; Auction house; Combat & utilities |
| Setup & Support | Profiles; Accessibility; Help & diagnostics |

Appearance contains global and individual background controls. Profiles separates save/load, new-character defaults, import/export and recovery/setup. Chat retains native per-tab filters and complete profile saving. The auction house keeps contextual settings with shared metadata. Native game accessibility/settings retain their own ownership and combat restrictions.

The map now has Quest log, Available, Guides, Progression, Supplies, and Dungeon atlas; Quest actions and Map settings are separate utilities. Chapters are a Guides subview. Zone preparation lives with Supplies. Outgoing rows are cleared before specialised rendering, smooth-scroll targets reset across pages, and navigation sizes to text height.

## Implementation and boundaries

SettingsPages.lua supplies Forever presentation through shared widgets and measured reflow. SettingsRegistry.lua owns navigation, search records, aliases and shared auction metadata. Menu.lua retains shared shell/widget behavior; AuraOptions.lua uses the same layout. No preference-key migration or profile wipe. Setup choices remain drafts until Finish succeeds.

LiveSettings resolves the current account/character section on every read/write, preventing cached widgets from editing a previously loaded profile. Nested fields retain content coordinates for exact search scrolling. Wizard drafts stay out of ordinary search. The first nonempty search still indexes pages once; later searches reuse them. This update does not claim an unmeasured CPU/FPS improvement or bypass protected combat actions.

## Live checks still required

Reload beta97. Review normal/large text, search then sidebar navigation, profile load while settings stays open, backgrounds, bag columns and aura focus ID. Switch Guides/Progression/Available repeatedly, inspect scrollbars/headers, and confirm M and passive combat browsing. All six manual release gates remain pending until Andrew records evidence.
