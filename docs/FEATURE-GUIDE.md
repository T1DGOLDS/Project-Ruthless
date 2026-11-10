# Introduction and feature guide

The centered RUI introduction appears after login/reload until the user chooses **Don't show again**. The choice is account-wide in `ProjectRuthlessDB.introduction.dontShowAgain`, independent of exported profiles and first-character setup. Dismissing with Close, Escape or Finish does not silently opt the account out. The popup is deferred during combat; a manual replay works even after opting out.

Four short pages introduce settings/search, unified profiles and precise layout, spell/macro/inventory/combat tools, and map-owned journey information. **Browse all RUI features** opens a permanent settings guide. **Quick setup** retains the existing setup workflow; the older automatic full-settings setup prompt defers to this introduction so two first-run surfaces do not open together. No character layout or preference migration occurs.

`FeatureGuide:BuildSettings(menu,parent)` builds the `features` child page using the shared scrolling/reflow framework. It describes twenty-two existing tool groups, explains non-obvious interactions and limits, and provides unique searchable contextual settings links. Help remains descriptive: it never starts a performance recording, changes a profile, buys an item, creates a macro or casts a spell merely by being read.

Keyboard support: Tab/Shift-Tab moves through footer controls, Enter/Space activates, Left/Right moves through tour pages, and Escape closes. Text follows RUI accessibility scaling and the popup fits the current screen. Popup assets and the Escape registration are reused; no per-frame work is installed. Real-client visual/accessibility/combat acceptance remains separate from simulated checks.

Integration: Forever manifest loads `Modules/FeatureGuide.lua`; settings defines a `features` page calling `BuildSettings`, routes it as a child of Help & diagnostics, includes it in search pages and adds a feature-guide action. The existing menu loader accepts `Show("features")` once the page builder is registered.
