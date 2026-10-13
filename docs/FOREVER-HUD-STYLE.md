# Forever HUD visual review — beta47

Forever only. Shared dark surfaces/class accents cover native action buttons and bars, chat and tabs, XP/reputation containers, micro menu, bags and Details background/frame. Native positions, sizes, button clicks, chat font size/links, XP/rested values and meter statistics remain intact. Details row textures/colors are still owned by Details.

After /reload:
- Check empty/filled action slots, readable hotkeys/counts, macros, pressed/toggled states, cooldown sweep and proc alerts. Test keyboard casts and drag/drop outside combat.
- Check chat readability on bright/dark ground, tab switching, scrolling, item/player links and text entry. Saved chat size/position should persist.
- Gain XP and inspect rested fill and native tooltip. Check reputation display and level-up changes.
- Open every micro-menu button and each bag. Check item counts, full bags and highlights.
- Enter combat and check Details rows/toolbars, ability clicks and performance. Exit combat: styling resumes only after the grace period. Inspect fresh /pr errors and blocked-action popups.
- Enable RUI's quest workspace, then accept/complete quests: native tracker should remain invisible. Disable RUI's workspace and verify the previous native tracker opacity returns.

Local checks cover surface reuse, retained click scripts/placement, absent optional addons, combat/grace deferral, native tracker reset suppression and Forever-only loading. They do not establish live visual quality or taint safety. Review unexpected native artwork resets with screenshots.

## Decorative art preference — beta63

General options includes **Show Blizzard decorative art**, unchecked by default. This is stored in the character's layout editor preferences and saved in layout snapshots as __art.blizzardArt. The active named account layout is updated when the checkbox changes. Legacy snapshots without the field default off, and the current active legacy layout receives the default at login. New-character inheritance includes the saved preference. Undo/cancel follows layout snapshot restoration.

Known decorative texture subtrees are cleared, including Forever's frame-based EndCaps.LeftEndCap.Texture / RightEndCap.Texture, bar/menu BackgroundArt, action-button slot/border art, chat/input trim and the existing RUI inventory/profession trim coverage. The old texture-only pass could not remove the nested gryphons. Cached native texture/atlas assets allow the option to restore stock trim; callbacks enforce the choice through native refresh and button normal-texture replacement. No whole action bar, interactive window or gameplay icon subtree is hidden. RUI layout, flat fills and functional item/spell/notification/cooldown art remain. Native Character/Achievements windows still follow the prior decision to await their separate Forever reskins; this switch does not build those skins.

Combat blocks preference changes; queued application respects the existing three-second combat grace. Local layout tests cover nested end caps, native resets, opt-in restoration, icon preservation, profile save/load, legacy defaults and combat. Live review: reload the shown character; gryphons, ornamental action/menu/bag trim should be absent. Toggle in General, load old/new profiles, reload and verify the saved choice. Live appearance/taint remain separate acceptance checks.


### Beta64 attack latency and cooldown diagnosis
Main-hand/ranged player attack timing now uses the same red measured network-latency band as spell casts. The off-hand has a separate owned bar with an independent native PLAYER_SWING duration, position and size. Countdown text includes seconds and latency milliseconds; zero latency hides the band. No predicted repeating swings or idle polling. Spell casts take priority in the player bar. Live dual-wield event ordering/appearance remains to be checked.

The reported native ActionButton SetCooldown secret-value error is not reproduced locally and is unresolved. ErrorLog adds a maximum of 32 taint provenance lines for native action-button fields, shared event registry and cooldown globals only on a new matching error. It reads no cooldown values and never replaces native cooldown handlers. The pasted stack identifies the failing native sink, not the original taint writer. Check a fresh reload and, if recurring, inspect the updated /pr errors report; a client taint log may still be needed.

## Beta65: owned party rows

The new October 10 20:35-20:36 errors identify native pooled party UpdateMember/UpdateArt and aura calls executing with RUI taint. RUI no longer registers/styles/repositions those members, hooks their updates, calls their Setup/Layout/UpdatePartyFrames, or writes native member data. Only native PartyFrame alpha is suppressed; Blizzard retains its events and pool. The saved party mover now targets RUIPartyFrame with owned secure player plus party1-4 rows and native visibility drivers. Secure left target/right menu behavior remains.

Health and power pass directly to status bars/font widgets; percentages use native percent APIs with ScaleTo100, without inspecting secret numeric values. Portraits refresh on roster/name/model events rather than every health update. One fixed five-row box retains the party layout profile key. Native pet/aura/ready-check indicators are not yet migrated into the owned rows.

Tests trip on any attempted native pool/setup/update call, check independent secure rows/visibility and pass opaque values through health/resource renderers in combat. These prove the local isolation contract, not that every client taint origin is removed. Fresh reload, roster changes, secure targeting/menu, rendering and combat acceptance remain required. The pasted earlier 18:56 cooldown/objective-tracker errors predate beta64; the original cooldown taint origin remains unresolved.

## Beta66: party aura, pet and ready-check migration

Supersedes beta65's missing-feature limit. Each of five rows now includes four helpful and four harmful 16px square aura icons below resource bars. The Camelot manifest loads Blizzard_AuraContainer as an optional dependency. CustomAuraContainerTemplate inbound secure delegates own aura access, sorting, visibility and layout; initialized CustomAuraButton widgets bind RUI icon textures, native cooldowns and stack font strings, retaining native secure tooltip behavior. Harmful borders are red. No GetAuraSlots/GetAuraDataByIndex/GetUnitAuras calls or manual cooldown arithmetic are added to RUI's party code. This requires the current Forever aura container API; unsupported clients omit the aura containers.

Each member also owns a secure pet button in the portrait column: player pet or partypet1–4, name plus health/resource strips, native target/menu attributes and existence visibility driver. Opaque values go directly to renderer widgets; pet changes and unit events refresh the strip without geometry writes in combat. Ready-check status sits over the portrait, using native ready/waiting/not-ready atlases. Finish retains results for ten seconds, converts waiting to not-ready, and a revision prevents an older timeout from hiding a subsequent check. Roster changes clear stale results. No idle addon polling is introduced.

Rows are 230x84 with 86px spacing in a 242x442 single party box; existing saved party coordinates/scale continue to apply. Tests cover native inbound binding and pinned API availability, zero addon aura reads, all pet tokens/secure attributes, opaque pet health/resource combat updates and ready-check transitions/timeouts. Live aura rendering/tooltips, pet summon/dismissal, ready checks, roster changes and combat/taint still need in-game acceptance. The separate cooldown taint investigation remains unresolved.

## Beta67: right-side party auras and contained portraits

Party surface now uses the same window colour, max(.72, questWorkspace.opacity), border alpha .22 and class accent as QuestWorkspace. One 320x442 party box contains the existing member/pet controls and a right-hand aura column. Per member: four 16px buffs at y=-4, four 16px ordinary harmful effects at y=-26, and two 28px dispellable-type harmful effects at y=-48. Native include/excludeDispelTypes candidate filters partition Magic/Curse/Disease/Poison/Bleed using Blizzard's AuraUtil.DispellableDebuffTypes definition. This means dispellable types, not only effects the current class can remove. The secure delegate still owns classification/data/updates; no addon aura scan. Timer fonts are 8px on small icons and 10px on large, stacks 8px.

The party root is LOW strata, and owned rows/pets/aura containers inherit their parents. Portrait boxes/models on player, target and party inherit their owner strata, share the owner's frame level, respect parent alpha and clip to portrait bounds. Models draw in ARTWORK, allowing ordinary higher windows to cover the full unit display. No combat styling/geometry writes were added. Native widget clipping, overlapping windows and timer readability remain live visual checks. This supersedes beta66's aura placement and width.

Swing review compared Blizzard_SwingTimer.lua: native showSwingTimer CVar plus Edit Mode Always/InCombat/Hidden control Blizzard's own display; RUI's cast-sharing countdown remains independent and does not rewrite those settings. Blizzard does not clear a weapon cooldown on target change or auto-repeat/attack stop; RUI now retains the real countdown to expiry on those events. Death/world reset still clear it. Instant/queued spell STOP/FAILED events only stop an active cast, and each native main/ranged swing reconciles a stale active-cast flag against current casting info. Cast/channel priority and remaining-swing resume remain, with fresh display callbacks after resume. No speculative repeating cycles or guessed Heroic Strike timings are introduced. Local tests cover queued-ability start without cast info, unrelated stop, stale flag reconciliation and target/auto-stop retention; live Heroic Strike acceptance is pending.
# Beta68 profession correction — 2026-10-11

Forever profession actions use `IconTexture` rather than the action-bar `Icon` field. RUI now bounds and crops that field inside its native button, strips decorative icon overlay/flash, parchment and rank border/background/flare, and supplies the charcoal surface. Native rank fill/mask/text, spell clicks, highlights and unlearn confirmations remain. Profession styling defers in combat. Local geometry/action-retention and pinned source checks pass; the reported visual overlap requires an in-game recheck.


## Target of target — beta71

An owned SecureUnitButtonTemplate row now renders targettarget with the same compact portrait, name, health and resource treatment as RUI party rows. It defaults beneath the target frame, inherits the Target background-opacity override, and has its own saved targettarget Edit Mode position/scale. Native target-of-target presentation alone is alpha-suppressed; RUI never calls native UnitFrame setup/update functions. Secure existence visibility and target/menu clicks work independently of Lua health rendering. Secret health/power values go directly to renderer widgets without comparisons or arithmetic. Identity/model events refresh the portrait; health/power ticks do not rebuild it. No aura/pet/ready-check UI is added to this row. Local checks cover secure attributes, visibility driver, persistent mover, target-victim changes and opaque-value combat rendering; live frame stacking, combat event ordering and portrait binding still need acceptance.


## Beta72 — compact unit surfaces and party cards

Player and target content now fits 252x64 UI units with a 52px portrait, four-pixel horizontal inset and one-pixel border. Owned party/target-of-target cards use a 224x56 charcoal surface with a 44px portrait and four-pixel inset. Party pets and right-side native aura widgets remain outside the tight surface; the full member layout reserves 76px for them. Portrait containment/layer inheritance and opaque health/resource rendering remain unchanged.

Separate party cards are the default, inside the existing single saved party mover. Settings > General > Grouped party panel restores a single compact shared background. Both choices keep one aligned five-member stack and the current position/scale; this is a visual grouping preference, not independently draggable members. The group background is 230x398 and does not shade the external aura column. Global and Party opacity overrides continue to apply; the transparent wrapper stays transparent in separate mode. The preference is included in account settings profile export/import. Geometry changes defer in combat; presentation opacity can refresh without moving secure rows. Live visual/combat acceptance remains required.
