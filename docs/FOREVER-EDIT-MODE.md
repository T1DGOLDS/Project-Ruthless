# Forever RUI Edit Mode — beta48

Escape menu's Edit Mode entry opens RUI. No global Escape handler is replaced. The editor uses native secure HUD frames and action buttons, registered game settings for bar visibility/locking/cooldown text/pickup modifier, and Blizzard's per-system settings dialog behind Element settings. These controls retain native setting conversion, dependencies and validation. RUI keeps positions and captured native display settings in its character layouts; this does not migrate or overwrite Blizzard's account layout profiles.

## Controls

- Drag an anchor: labels display decimal X/Y and screen dimensions. Coordinates are UIParent units from screen centre, positive right/up, independent of element scale.
- Snap aligns screen margins, nearest centres/edges, an 8-unit breathing gap, and equal gaps between adjacent aligned elements. It falls back to the selected grid; the snap toggle controls alignment and grid snapping together.
- Grid cycles 8/16/32 units. Grid visibility is independent of snapping. Lines are cached and only displayed while editing; geometry inspection runs during dragging, not normal gameplay.
- Exact X/Y fields apply on Enter. Scale and supported dimensions retain the existing controls. Undo, named Save/Load, Reset selected, Cancel and Done remain.
- Chat has one dock anchor based on its native primary ChatFrame1. Docked tabs stay attached through native docking. Unused tab slots have no movers. Deliberately detached independent chat windows are not moved by the dock anchor.
- Inactive native elements do not produce empty preview boxes; owned cast bars and the chat dock retain deliberate previews.

## HUD appearance and buffs

Static action-slot art, button rims, XP frame trim and chat input borders are cleared and remain clear after native texture/atlas resets. Charcoal surfaces retain icons, cooldowns, hotkeys and native clicks. XP/rested values remain native.

Helpful timed player buffs with public timing appear above the player frame when under 30 seconds remain, with native cooldown countdowns. Permanent buffs and harmful auras are excluded. Incremental aura events update a small cache; full scans defer through combat and the three-second grace period. Threshold and expiry timers replace continuous scans. Restricted timing is omitted rather than compared. Up to 24 urgent buffs display, earliest expiry first.

Leader/guide icons occupy the portrait's top-left corner; raid marks use its top-right corner.

## Live acceptance and scope

Local harnesses check decimal coordinates, nearest edge/equal-gap alignment, cached grid, combat guards, one dock, native-setting save/load, static art reset suppression and buff thresholds/removal. They do not prove live rendering or taint safety.

After reload, check Escape opens RUI, Done/Cancel and target/menu dismissal order; native action-bar rows/orientation/visibility; tab switching and chat input; XP/rested updates; buffs crossing 30 seconds, renewal and dispel in/out of combat; leader/guide/raid marks. Check reconnect/reload and named layout restoration.

This is an editor integration pass, not verified full parity with every native account-layout import/export, system option or input route. Native settings controls are reused in a RUI shell; the entire native dialog control skin has not been rebuilt. Retail loads neither the style nor buff module.

## Nameplate hints

A passive 18-unit icon sits five units left of the native health bar: bag for an unfinished item objective with a known database dropper, sword for an unfinished matching kill objective, skull for an elite/rare-elite/world boss. Loot takes priority over the skull. Existing auras, health values, clicks, raid marks and plate sizing are untouched. The cached held-quest NPC/dropper index is reused; missing/restricted identity or objective data produces no quest icon. Objective cache rebuilds defer through combat/grace; existing hints may therefore wait until after combat to clear. No nameplate polling or database scan per plate.


### Beta64: native anchors and Backpack movement
RUI Apply now releases initialized native systems from managed containers and calls the native UpdateSystemAnchorInfo recorder after applying public coordinates outside combat. SetPoint alone leaves native default-position flags and anchor data stale, allowing native default action-bar layout passes to rearrange bars later. No server-layout save or combat anchor correction is attempted. Native settings and position metadata remain in-memory; RUI saved profiles own reload restoration. In-game combat/vehicle/visibility and taint acceptance are still required.

The combined Backpack is an editor element and also drags freely from its title area (excluding Bags/close controls). Drag end stores the character layout position; Save captures it in account profiles. Native container anchor updates restore that position outside combat/grace; no bag placement is rewritten in combat. Native search, sorting, item clicks and bag assignment remain unchanged.
