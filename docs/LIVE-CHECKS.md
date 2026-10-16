# In-game live checks — beta 79

The original five build stages are implemented, with their live acceptance still pending. This follow-up makes that acceptance work usable inside the addon; it does not declare the product release-ready or introduce an automatic certification system.

Open `/pr checks`, or Help & diagnostics → Live checks. The six checks match the repository's live-gate IDs: installation, profiles, combat, information, accessibility and performance. Select a check, press **Start check**, perform the listed steps, enter evidence describing what happened, then choose **Pass**, **Fail** or **Pending**. Pass/Fail require a started check and nonblank notes. Starting a retest returns that check to pending. Evidence is limited to 1,500 bytes; drafts remain local to the current window/build until a result is recorded.

Related settings opens the relevant settings section. Bug report opens the existing copyable reporter; its output now includes the current build's manual results and labelled historical results. No information is uploaded or sent automatically. The live-check window builds only when requested, is movable, fits the screen, uses accessibility-scaled labels and supports native EditBox input/Escape. The report's header reflows and the window fits the screen. Live text fit and keyboard/combat behavior still need testing.

## Results and observations

Results are per character, outside settings profiles, and grouped by RUI version plus native client build/interface. A changed version or client build starts pending rather than inheriting passes. Up to three runs are retained. In-progress historical checks without an ending observation do not acquire observations from the current build. Changing profiles preserves the local evidence; exporting a profile does not export it. SavedVariables flush on normal logout/reload; crashes can lose unsaved runtime results. This identifier cannot detect arbitrary local source edits made without changing the addon version.

Start/result actions snapshot whether error capture and the performance recorder are enabled, the current profile, combat state and a cumulative captured-error count when available. Counts cover the shared account error log and all addons, not proven RUI errors. They survive repeated-error grouping, retention trimming and Clear log. This is a count, not an additional archive of messages. Disabled capture does not invent observations. Before/after enable flags are snapshots, not proof that capture stayed enabled throughout the test. No combat/quest/action APIs are called to run tests automatically, and no new timer, per-frame handler or background test event subscription is added.

The performance recorder remains explicitly controlled by `/pr record on` and `/pr record off`; starting a check does not turn it on. The performance checklist asks for comparable recorded and unrecorded scenarios. Whole-game frame gaps, empty error logs and automated test results do not establish a passing live check.

The in-game results are **self-reported**. RUI never rewrites `validation/live-gates.json`, marks a repository gate passed or authorizes a stable release. Stable publication still requires review, dated evidence and the exact tested source digest. Reports include this distinction. All six repository gates remain pending in beta79.

## Acceptance for this workflow

1. Open the window from the command and both settings shortcuts. Confirm it stays unallocated before use and opens/reopens without duplicate windows or Escape registrations.
2. Try Pass/Fail without starting and without notes. Nothing should be recorded as passed. Start, record a failure, retest and record a real outcome. Select other checks and verify drafts are retained; close/reopen and save/reload a recorded result.
3. Use a disposable error to verify new captured-error observations. Clear the visible log and verify the cumulative count remains; turn capture off and check the displayed flag. Captured errors may be from other addons and do not automatically fail or pass a check.
4. Change profiles and verify evidence stays local. Export/import a profile and confirm it contains no testing evidence. On the next addon/client build, prior passes must appear only as history.
5. Test 100–150% text, long evidence, keyboard input, scrolling, small-screen fitting and dragging. Browse during combat; no gameplay test or protected mutation should execute automatically. Related settings retain their existing protected-edit restrictions.
6. Copy `/pr report` and confirm it contains notes, version/build, manual status and error/recording observations. Confirm it does not claim stable acceptance, continuous error coverage or source-digest verification.

`npm run test:live-checks` exercises the actual model, window, reporter and cumulative error counter with sealed UI methods and explicit state changes. It checks canonical gate IDs, validation, version/build isolation, bounded history, draft handling, profile isolation, missing/secret build data, local reporting and absence of background gameplay automation. These are static/simulated checks, not live acceptance.
