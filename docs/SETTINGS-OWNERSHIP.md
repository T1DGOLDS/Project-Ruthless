# Settings ownership audit — beta 75

| Preference | Canonical control | Contextual access |
| --- | --- | --- |
| Auto-sort when bags open; bag columns | Bags & Inventory | Bag menu opens RUI bag settings |
| Guide provider | Map & Quests | Map Settings opens Guide provider settings |
| Quest charcoal opacity | Backgrounds: Quest | Map Settings opens Quest background settings |
| Complete profiles and new-character default | Shared UnifiedProfiles service | Settings and Edit Mode share the same selection/store |
| Accessibility preferences | Accessibility | Quick setup stages choices until Finish |

Window opacity intentionally fades the full window, including text/icons; background opacity changes only its charcoal surface. These are separate controls with explicit descriptions. Global appearance and individual overrides are intentional. Each background reset has a distinct search identity.

The declarative registry test rejects duplicate section/key pairs. The bag-menu test rejects reintroduced RUI sorting checkboxes. Manual review covers dynamically registered controls and context shortcuts; this is not a claim that every similarly named native option is redundant.

## Stage 3 live acceptance

1. Reload, then press M twice with the native quest-log panel preference both on and off. Repeat on RUI Quests and Settings pages, in and out of combat. The second press should close the map without losing quest selection. Check the error report.
2. On an existing character, confirm positions/default selection remain unchanged. Create a disposable new character with no account default, then another with a default. Only the first should offer setup; the second should load the saved profile. Setup deferred by combat should appear after combat ends.
3. On the fresh character, compare bars, chat, player/target, party, tracker and cast anchors with Blizzard's starting arrangement. RUI replacement geometry differs; hidden/unavailable native anchors need live inspection. Confirm captured positions survive reload. Finish setup and verify its recovery snapshot and unchanged layout.
4. Test static and animated player/target/party portraits, target identity changes, reduced motion and instant scrolling. Native camera/accessibility choices must remain untouched. Check that missing portrait models do not leave stale identities.
5. Test text at 100%, 125% and 150%, long/localized labels and a small screen. Check every settings page, search results, spellbook and tracker for clipped or overlapping content. HUD/native fonts retain their existing sizing. High contrast raises charcoal opacity; whole-window fading can still reduce final contrast.
6. With no edit box focused, use Tab/Shift-Tab, Enter/Space, slider arrows and PageUp/PageDown. Confirm the selected row remains visible, search Enter opens its first result, normal typing remains intact and gameplay keys propagate when unused. Repeat in combat and check for blocked actions. Native screen-reader coverage is not certified by these additions.
7. Open each native accessibility category from RUI. Test the game's colourblind, audio-assist, subtitle, text/contrast and motion options against RUI surfaces. Retain any unsupported behaviour as a failing accessibility gate, not a passed parity claim.
8. Save/switch/export/import two profiles with different accessibility choices. Load an old complete profile and verify stage-3 preferences reset rather than leaking from the previous setup. Confirm existing character working settings persist.

Use `/pr record on` for representative runs and `/pr report` for evidence. Automated mocks do not establish live combat, native accessibility, layout or performance acceptance.
