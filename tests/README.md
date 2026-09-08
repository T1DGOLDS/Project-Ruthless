# Talents adapter checks

Run `node tests/run-talents.cjs [addon-root]`.

Run `npm install` once for `luaparse` and `fengari`. The Talents and equipment checks also require `PR_WOW_SOURCE` to point to an extracted Blizzard `Interface/AddOns` source directory. `PR_TEST_DEPS` may point to an alternate dependency directory.

The harness executes the native dropdown implementation and extracts the exact `LoadConfiguration` callback from `Blizzard_ClassTalentsFrame.lua`. The remainder of the game API is mocked; unknown frame methods fail rather than silently succeeding. Checks cover read-only browsing, specialization count, filtering, native load confirmation and cancellation, combat/casting/commit restrictions, action callbacks, restoration, and scale fitting.

Passing these checks is not evidence of successful server changes, live rendering, or absence of taint in the running client. In-game acceptance remains separate.
