# Stage 4: auras and cooldowns — beta 77

Open `/pr` → Auras & cooldowns. This is the first supported template-based manager, not a general WeakAuras scripting engine. Additional groups start off to preserve existing layouts. The native cooldown feature retains its existing enable preference.

## Supported controls

- **Combat auras / Buff focus / Minimal:** choose a simple custom-aura preset, then adjust individual switches.
- **Player buffs, Player debuffs, Your target debuffs:** native secure containers with bounded icon counts, size/spacing and optional expiration-first ordering. Your target debuffs uses the native PLAYER filter. Each group has an Edit Mode mover.
- **Focus buff:** enter one exact player helpful-aura spell ID, including the intended rank. Zero clears it. This is not a name matcher, automatically ranked spell family or arbitrary expression. Blizzard's spell-ID matching restrictions apply: helpful friendly auras and harmful hostile auras are the permitted contexts. Unsupported/secret matches are rejected natively.
- **Native cooldowns:** Essential, Utility, tracked buff icons and tracked buff bars continue to use Blizzard's runtime and alerts. Choose tracked spells & alerts opens their original configuration with the RUI surface. Native charge, cooldown and aura calculations remain untouched. RUI provides reversible thin borders/reduced decorative icon trim and position/scale movers. Other native icon/bar artwork is not comprehensively replaced in this build.
- **Party switches:** buffs, native-classified debuffs and larger dispel indicators. Classification uses the native processing policy rather than declaring every Magic/Curse/Poison/Disease/Bleed aura dispellable by every class. The game's current classification still needs live class/rank verification.
- **Expiring self buffs:** switch and 5–60-second threshold for the existing public-timing display. Restricted timing cannot be read or filtered by remaining time and is not guessed. Native cooldown buff displays are a separate supported option.
- **Preview samples:** static icons, labels and a bar with literal sample values. No live aura/cooldown queries, triggers or alerts are involved. Close the sample frame when finished.

Global and individual Auras background colour/opacity live under Backgrounds. Empty custom-group anchors have no large backdrop. Settings text and sample titles use the accessibility font preference; native countdown fonts retain native sizing. Exact spell selection and alert configuration stay in the supported native UI rather than a duplicate private-state editor.

## Profiles and diagnostics

The existing profile selector includes aura preferences, mover positions, native cooldown activation and, when available, a bounded opaque cooldown-data snapshot. Data is obtained/restored through documented `C_CooldownViewer.GetLayoutData` / `SetLayoutData` only. It is never executed as Lua. Snapshots are limited to 64 KiB and retain their class identity; applying another class's snapshot preserves this character's native spell layout and reports the mismatch. General RUI aura preferences still apply.

If native cooldown storage changes, **reload is required** to refresh Blizzard's cached configuration. The result and configuration checks say so. RUI does not enter native refresh methods to force an immediate update. Existing recovery snapshots include supported native data. Older profiles without cooldown data retain the character's native layout; old complete settings profiles reset new RUI aura overrides. Fresh characters without an account default start without extra custom groups.

Check configuration on the page and `/pr report` explain disabled native/custom displays, unsupported native capability, a focus group without a spell ID, large dispel indicators switched off, combat-deferred presentation changes, restricted public-timing displays, oversized native snapshots and pending reload. These explain known configuration/capability conditions; they cannot diagnose the hidden contents of a restricted aura list. A loaded competing addon remains only a possible conflict.

## Runtime boundary

Compatibility input: pinned Forever native revision recorded in `validation/live-gates.json`; the native cooldown addon explicitly declares Camelot support. Custom aura filters, sorting and rendering use the native inbound APIs. RUI never scans live aura data for the new groups, calculates secret cooldown values, invokes native live RefreshLayout/SetCooldown paths, or reads a secured aura-instance map. Native movers skip native system-setting mutation and expose geometry only.

Presentation changes defer during combat. Settings and static previews remain browsable; native spell/alert editing and activation changes require leaving combat. This is a protected-edit boundary, not a certification that all native event chains are taint-free. No combat-log subscription or custom-code engine is introduced. Native viewers/containers own any runtime callbacks they require; RUI has no new per-frame polling.

Group configuration signatures avoid redundant inbound rebuilds. Related addon/spec/spell/CVar events coalesce. Party and expiring-buff settings refresh only their own features. Native pool cosmetic styling reuses one border per item and never enters its live data/update methods.

## Live acceptance

1. Reload, open the new page and confirm existing layout/cooldown activation is preserved. Test search for focus, aura spacing, party dispel and cooldown alerts; verify long labels, 125–150% text and small-screen sidebar fit.
2. Enable each custom group separately. Apply/remove buffs and debuffs, switch friendly/hostile targets, test your own target auras versus another player's, and verify native counts/tooltips/timers. Configure an exact known helpful spell rank, then zero/unknown ID and another rank. No match must not produce guessed information.
3. Enable native cooldowns where supported. Use native spell selection/order, icon/bar categories and alerts. Test casts, charges, proc auras and spec changes in combat. Look for blocked actions, secret errors or a hidden display returning unexpectedly. Move each viewer outside combat and verify native reanchors/reload preserve geometry.
4. Test party aura switches with classes that can and cannot dispel each type, learned ranks/spec changes and actual dispellable debuffs. Ordinary debuffs must remain visible in their normal group; large icons must reflect native classification, not a hardcoded all-class promise.
5. Test expiring-buff thresholds outside combat and restrictions during/after combat. Turn the feature off and verify its timer cancels and icons clear. Check static preview values remain clearly labelled as samples.
6. Edit during combat: preferences should defer without native layout/data mutation; pending explanations should appear and edits apply after combat. Verify the native spell/alert editor reports its edit restriction while RUI remains browsable.
7. Save two complete profiles with different aura settings/native cooldown arrangements. Apply, reload when instructed, undo, export/import, overwrite/recover and use a new-character default. Test a different class; native cooldown data must be preserved with an explicit mismatch message. Quest progress and recording logs remain unchanged.
8. Record idle, combat, repeated settings/group changes and native spell/event bursts. Verify disabled groups stop native processing, repeated settings reuse frames, cosmetic refreshes preserve gameplay state and no RUI idle OnUpdate appears. Compare profiler evidence, not synthetic timings alone.

`test:auras` checks the manager/options against sealed runtime boundaries and the pinned inbound API contracts. Settings tests cover profile sharing/reset and managed party classification. These are simulated/static checks: installation, profiles, combat, information, accessibility and performance live gates remain pending.
