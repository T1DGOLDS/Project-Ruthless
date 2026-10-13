# RUI layout editor — beta 34

Open **/pr edit** (or /pr layout), or Control centre → General → Edit RUI layout. Open the RUI panels you want to arrange first. The editor combines labelled mover overlays with a selected-element inspector; it is an original implementation informed by the locally installed ElvUI mover and Blizzard Edit Mode sources. No source/assets from those editors were copied.

Select or drag a highlighted frame. Snapping rounds to an 8-unit grid and aligns within 10 units of screen centre/edges and other visible RUI frame centres. Two centre guides are visible when snapping is on. Toggle Snap for free positioning. Inspector arrows nudge one unit; scale changes by 5%. Map width/height change independently by 40 units within existing responsive bounds. No idle OnUpdate handler is installed.

Forever additionally registers existing minimap, individual unit and cast frames, chat windows, XP/reputation containers, action bars, buffs/debuffs, bags and micro menu. Previous/Next cycles selectors; hidden cast/unit frames have mover previews without showing fabricated native unit data. Secure native buttons and value updates remain native; RUI owns saved layout and presentation. Native achievement child and unavailable panels remain excluded. This module is loaded only by the Camelot manifest.

Player/target now use original 3D portrait panels and flat native health/resource textures informed by Wrath X-Perl. Remaining HUD art is still native, with RUI outlines and layout management; this is not a full replacement of every component. Native layout changes are coalesced and restored outside combat with three seconds of recovery grace. Live rendering/taint and changes made by another UI addon remain acceptance checks.

Changes preview immediately and persist per character. **Undo** retains 20 actions; **Cancel** restores the session's starting layout; **Done** keeps it. Enter a name to **Save** or **Load** one of up to 10 named layouts. Names are typed in this first version; a visual saved-layout picker is not implemented. Reset selected returns the frame to its captured initial placement, not a reset of all addon settings. Hooks restore saved state when supported panels are created/opened later. Combat blocks editing and closes the editor, retaining completed edits.

Shared Core theme supplies editor, map, tracker and menu surfaces; Character now consumes those palette tokens too. Existing frame-specific content and native workflows remain. This is a first editor review build, not a complete replacement for all ElvUI/WoW editor capabilities or a finished whole-addon visual migration.

## Live review

1. Reload beta 34, open map/tracker/menu and /pr edit. Select and drag each; confirm labels and inspector match the selected element.
2. Test snap centre, screen edges and another open frame centre; turn snapping off and place freely. Check overlays do not remain after Done/Cancel.
3. Nudge and scale; resize map width separately from height. Tabs, map canvas and sidebar must remain inside the window. Test at your normal UI scale and a different resolution.
4. Save two named layouts, move frames, load each, undo and cancel. Close/reopen panels and reload to check persistence. Confirm reset selected and unrelated addon settings.
5. Enter combat while editing; editor/anchors must disappear with no protected-state errors. Try /pr edit in combat: no movement should occur. Inspect new ErrorLog entries and report clipping/taint with build and action.

Local tests verify coordinate scaling, snapping, save/load, undo/cancel, lazy construction and combat blocks. They cannot prove native rendering, drag feel, screen bounds or taint.

## Beta 34 live checks

- Resize the map wide, change its scale in /pr edit, close/reopen and /reload. Repeat using the corner grip after saving an editor layout. Latest dimensions must survive; explicitly loading a named layout intentionally restores that saved layout.
- Page through HUD selectors. Move minimap, player/target, individual cast bars, chat and XP; reload. Confirm native clicks, right-click menus, chat scrolling, map icons and casting still work. Hidden mover previews must disappear on Done.
- Check the player portrait while moving/transforming; select different humanoid/creature targets. Confirm health, resources, death, elite/quest/raid marks and buffs remain readable. Fight and leave combat: no taint or frame jump after grace.
- Open class Spellbook and find future entries. Check rank/level against the native trainer. Visit trainer, allow its small batches to finish, then reopen Spellbook and reload: observed prices persist. Discounts may change; unknown cost/rank/level is explicit. Future entries must never cast or drag. Client-provided entries define coverage; complete offline training coverage remains unimplemented.

## Beta 35 regression review

Reload, resize the map wide, close/reopen it with M on Quests, Settings and Dungeons, then /reload and reopen. Dimensions and scale must persist despite native state updates. Toggle override preserves the native combat fallback. Target buffs/debuffs now flow above the frame; inspect tooltips and target changes. Uncustomised target scale follows the player; previously saved target scaling remains intentional. Unit-frame surfaces share the tracker palette, subtle border and accent header. Live visibility/taint remains unverified by mocks.

## Beta 37 independent cast bars

RUI owns separate Player cast bar and Target cast bar displays. In /pr edit, drag either labelled mover and independently adjust Width, Height and Scale. Width steps are 10 units, height steps 2, with bounds 100–700 wide and 14–80 high. Positions and dimensions persist per character and in named layouts, without changing map size. Editing remains blocked in combat.

Displays refresh on cast/channel/target events and use the native status-bar duration renderer; RUI does not compare interruptibility, calculate secret timestamps, poll on every frame, or call native casting event methods. Native cast-bar graphics are suppressed with alpha; native casting events remain owned by Blizzard. Restricted duration rendering falls back to the spell label with an empty fill. Interruptibility colouring and numeric time readout are not implemented.

Live review: reload beta37, move/resize both bars independently, Done, cast Shadow Bolt and channel Drain Life, select a casting enemy, switch targets during casts, interrupt/stop a cast, then reload and confirm both layouts. Check /pr errors for secret-interruptibility errors; local mocks cannot prove live taint safety.

## Beta 38 latency display

Both cast bars show measured world network latency in red milliseconds. Red end-zone width represents latency divided by accessible cast/channel duration, clamped to the bar width. Casts use the right end; remaining-time channels use the left. Resize recalculates width from cached timing without network polling. The target indicator also represents your connection, not the enemy player's latency. When timing is secret/unavailable, a thin red marker and measured milliseconds remain; no guessed duration or secret arithmetic. Zero latency hides the zone. Inspect a normal cast, channel and independently resized bar after reload; live appearance remains a review check.

## Beta 39 cancellation and Escape review

Reload, begin a cast and press Escape, move, or interrupt it; the bar must disappear immediately. Repeat for a channel and for a target's interrupted cast. Quickly start another cast and verify late stop events do not hide the newer cast when public IDs are available. No secret GUID comparisons are used.

With a target selected and no active cast, open the map or character pane and press Escape: the panel should close while the target remains selected. Next Escape clears the target and native target frame; its independent RUI cast bar also disappears. With no remaining interaction, Escape opens the game menu. Active casts, popup dialogs and context menus retain their native higher priorities. Repeat in combat and with the RUI menu/spellbook/editor open. Native character visibility and target clearing are not overridden.

## Account layouts — beta61 (superseded by beta62)
Named Edit Mode layouts are stored in ProjectRuthlessDB.layoutProfiles.layouts. Save or Load selects layoutProfiles.default for fresh characters. ADDON_LOADED initializes a character without layoutEditor from a deep copy of that default before any module restores frames. Existing character layouts are not overwritten. Settings already live account-wide; this feature transfers layout snapshots, including captured native element settings, rather than character quest progress.
Legacy character layouts migrate once on that character's login, retaining the originals. Existing account names win conflicts; an existing active legacy name seeds the default only when none exists. Other characters' unvisited saved-variable files are not scanned. The dropdown beside the name field lists account layouts alphabetically and marks the default. Unsaved edits do not change the default snapshot: save the main layout after changes. Live cross-character login, native bars and dropdown rendering still require acceptance.

## Explicit defaults and chat setup — beta62
The separate **Default for new characters** dropdown chooses a saved account layout or None. Saving/loading a layout never changes this selection. The beta61 automatic default is cleared until a deliberate selection is made. Existing initialized characters are preserved; use Load for those. Save again after changing your main character's layout or chat setup to update its snapshot.

Layout snapshots include native chat window names, message-group/channel subscriptions, font size, background color/alpha, lock/interaction settings, dock order, selected tab, and detached window geometry. Restore creates missing named tabs, excludes temporary whispers, and retains unrelated existing tabs/history. Channel subscriptions do not join new/private channels. This is not a chat-history or global chat-color/CVar backup. New-character chat restoration waits until chat is initialized; combat work remains deferred.

Review: reload on your main, save a profile, explicitly choose it as default, create a fresh character and inspect bars and chat tabs/filters. Load repeatedly to confirm no duplicate extra tabs. None disables inheritance for future fresh characters.

## Auto-attack display — beta62
Main-hand melee and ranged PLAYER_SWING events use the player cast-bar anchor, dimensions and scale. A separate status fill avoids competing with a native secret cast timer. Casts/channels have priority and resume an unfinished swing countdown on ending. Off-hand swings do not reset the primary timer. There is no simulated repeating cycle: expiry, stop-auto-attack, target change and death clear it; the next actual swing re-arms it. Swing seconds replace the cast latency label; red network latency remains a cast/channel feature. Live event ordering, visual layering, melee/ranged cancellation and combat taint need acceptance.
