# Shared quest availability — beta 32

RUI pickup markers, nearby rows and dungeon pickups consume the offer list built with PlayerStatus. Synthetic guide markers and authored guides use the same result through PlayerEligibility. Held quests keep native objective/completion state. Confirmed locked pickups are excluded; uncertain pickups retain silver styling and an explicit reason. Authored guides can show a locked task with its reason so the player can skip it or meet its requirements.

Results cache by quest and preparation mode against a cached character snapshot. Quest lifecycle, level, skill, reputation, spell and relevant quest-start item changes invalidate them. Preparation can bypass prerequisite completion for future shopping; it is never used to label actual pickups available. Discovery's level/difficulty window is a relevance filter, not an acceptance restriction.

Checks cover native held/completed state, minimum/maximum level, class and race masks, class sort category, prerequisite groups/alternatives, conflicts, parent/unlock chains, profession skill, reputation point thresholds, known spells/specializations and required starting items. Missing native evidence and unsupported rank/event rules remain uncertain. Profession sort category alone does not prove its skill threshold or whether it is a learning introduction.

## Scheduling and stable presentation

Offer scans stop before starting or continuing a batch in combat. Combat exit schedules a three-second grace period; re-entering combat cancels that resumption. No repeated combat polling occurs. Outside combat, a slice processes at most 25 quests, stops after a soft 2 ms budget if the native profiler is available, then waits 100 ms. An individual database call can exceed that soft budget; this is not a hard FPS guarantee.

Completed offer lists replace the prior list atomically. Cached results remain settled during combat/grace; they may briefly reflect prior eligibility until refreshed. Uncached requests during that period stay uncertain. Ordinary bag changes do not rescan unless a required quest-start item dependency has been discovered. Active quest counters/navigation still use their existing lightweight updates; this is availability discovery scheduling, not a whole-addon combat freeze.

## Data policy

Accepted product direction: comprehensive bundled databases are welcome when useful. Disk/archive size, resident memory and ongoing CPU are separate budgets. Existing dungeon data/options load on demand; authored guide tables are lazy. This build does not bundle a full replacement quest database or establish a measured size/CPU comparison with the normal addon stack. Future data packs should use demand loading, reusable indices and paced work, with ownership/licensing and live measurements recorded beside the implementation.

## Live review

Reload beta 32. Check known wrong-class/profession pickups disappear or are explicitly uncertain. Confirm locked authored tasks explain their requirement. Change a skill or quest prerequisite and wait for discovery to settle. Loot repeatedly, fight, then leave combat: no list flicker or scan burst should occur; availability may take a few seconds to catch up. Compare /pr perf with actual FPS and individual interaction hitches. Record quest ID/name and the real NPC acceptance result for any mismatch. Missing source requirements cannot be proven from local tests.
