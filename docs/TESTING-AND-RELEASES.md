# Testing and releases — beta 74

## In-game testing

`/pr record on` starts local development recording. It samples native RUI CPU measurements every two seconds, observes whole-game frame intervals without allocating per frame, and refreshes native package-memory measurements at most every thirty seconds outside combat. `/pr record off` stops the timer, frame observer and events. Recording remains off until explicitly enabled, resumes after reload when left enabled, and retains at most five sessions with 240 recent samples per session. Aggregate frame and sampled-CPU summaries cover the full recording.

`/pr report` opens the copyable bug reporter. Add steps, expected behaviour and actual behaviour, refresh, select and copy. Settings > Diagnostics also provides these actions. Reports include version/build, configuration checks, potential overlapping UI owners, bounded recording samples and captured errors. Reports stay on the machine; RUI does not send messages or upload data. SavedVariables persist on normal logout/reload; a crash can lose unflushed records. Review reports before sharing because captured errors can contain other addons' text.

Native recent CPU averages are milliseconds per profiling tick, not percentages or total time. Main, options and dungeon-data values are shown separately. Native peak/counter values span the application session; counter differences describe the recording window when those counters remain valid. Mean sampled recent averages are labelled as such. Whole-game frame gaps do not prove RUI caused a hitch. Memory is sampled per-addon KiB, not an exact allocation counter or proof of a leak. Unavailable/restricted measurements stay unavailable. Profiling and the frame observer add overhead: compare recording-on and recording-off runs.

## Six live gates

`validation/live-gates.json` records installation, profiles, combat, information, accessibility and performance/coexistence acceptance for a particular version. Each gate has concrete checks and starts **pending**. Automated checks do not mark live gates passed. Andrew supplies in-game outcomes; retain a dated report or other evidence for every passing gate. Failed checks retain their failure description until retested.

For a production release, record reviewer, date, the exact tested-source digest printed by `node tools/check-release-gates.cjs`, and evidence for all six passing gates. Runtime/source changes invalidate that digest. Do not turn pending into pass merely to publish. The native source revision is the pinned compatibility input, not a claim the live client has the same build.

Experimental prereleases can ship with pending/failed gates disclosed in their release notes and LIVE-ACCEPTANCE.txt. Stable tags are blocked without matching source and complete live evidence. Every tagged release first runs all automated suites using the pinned native input. Packages include a checksum. GitHub assets are not overwritten; local packaging refuses to overwrite an existing ZIP and cleans only its own uniquely named staging directory. Previous release archives remain intact.

## Repeatable scenarios

Compare native UI and RUI on the same hardware/settings with similar scenes. Record idle, travel, crowded nameplates, five-player combat, bag opening/sorting, map/spellbook browsing and repeated UI open/close cycles. Include stance/form changes, queued melee abilities, offhand/ranged attacks, pets, target changes and party aura transitions. Test with optional addons absent, then with likely overlapping UI addons. A loaded addon is a possible conflict, not proof of causation; RUI's diagnostics never change its settings.

Fresh-install/default-layout, full accessibility, aura/cooldown editor and third-party-data independence work remain subsequent milestones. Unified profiles are implemented in beta 74 and require the live checks below. Existing native cooldown-taint reports still require live diagnosis.

## Stage 2 acceptance

After `/reload`, open Profiles. Legacy saves appear as `Settings: name` or `Layout: name`; these deliberately apply only the component that was actually saved. Original stores are retained. For a complete setup, load the intended legacy components, then save a profile under your preferred name. Settings and Edit Mode now use that same selector. The separate default chooses the saved setup for new characters; it does not reset existing characters. Each character keeps a working settings copy on logout/reload rather than inheriting another character's latest edits.

Create two disposable profiles with visibly different positions, colours, party grouping, chat tabs/filters, bag preferences and native bar visibility. Switch between them from both settings and Edit Mode. Verify Undo apply and Edit Mode Cancel restore the previous complete setup. Overwrite one disposable save and use Recover overwritten save. Set one as the new-character default, log into a new character, then return to an existing character and verify its working setup was preserved. Export/import the full profile, then try malformed text and applying during combat; neither should change the setup. Check `/pr report` after these steps.

Profiles include preferences and presentation, not quest/guide progress, leveling history, trainer observations, macro backups or error/recording logs. They do not copy action-button assignments, keybindings, another addon's configuration, or arbitrary native accessibility CVars. Native bar preferences use the game's registered settings callbacks; unavailable preferences are reported and require a live check. Permanent chat tabs outside the saved setup close after successful restoration; temporary whispers and General/Combat Log stay available. Chat message history is not copied.

Search for `auto sort`, `player opacity`, `transparency`, `cooldown` and `gryphon`. Open results and check the correct page/control is visible, including entries farther down Backgrounds and subsequent result pages. Change global background colour, give Player a separate colour, change the global colour again, cancel a colour-picker edit, and reset Player to Follow global. Text and icons should remain readable. Existing pages register their actual controls into the search metadata; the initial declarative definitions cover new feature controls, with further consolidation possible without a second search index.
