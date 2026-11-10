# Forever quest pickup reference — 2026-11-09

Source: https://github.com/Questie/QuestieDB/tree/c1b50fefb19c064edc436429bef73435d9ff4254 (current master when retrieved). Forever data only; raw tables loaded with the upstream Lua 5.1 flavor generator, static corrections and derived passes enabled. Faction-specific Forever quest corrections were evaluated separately for Alliance and Horde. No third-party addon, loader, API or branding is used at runtime.

Reference.json is the preferred editable factual subset: quest identifiers/names, acceptance requirements, real NPC/object giver positions, explicit race-ID masks, faction-specific overrides and a precomputed map index. No quest descriptions, guide prose or dialogue were copied. The installed-client ID cross-check is the existing readable Forever 1.60.1.70862 catalogue; it prevents removed/unconfirmed reference quests from becoming available markers. Current native offers can override older recorded gates and supplement missing metadata.

Counts: 5,233 source quest records; 4,491 have locations; 5,429 positions on 48 maps. Of 6,614 readable client IDs, 4,499 match metadata and 3,957 have locations. 2,115 lack metadata; another 542 have metadata without recorded giver positions. 92 encrypted client records were not readable. Neither source completeness nor server acceptance is guaranteed by these counts. Missing requirements/positions remain explicit and are not invented.

## Permission and corresponding source

Retain UPSTREAM-LICENSE.md, UPSTREAM-gpl-3.0.md and UPSTREAM-PROVENANCE.md with this data. The team's explicit GPLv3 copying/forking permission is used; its historical-contributor caveat remains in full. Do not represent that permission as unanimous consent by all historical contributors. No rights to the upstream name/logo are claimed. RUI implementation remains separately identified in the root licence; these derived records follow the upstream permission and notices.

Reference.json plus build.py are packaged corresponding editable source. Run `python Assets/QuestPickups/build.py` from the repository to regenerate Modules/QuestPickupData.lua, or add `--check` to verify exact output. The upstream revision and retrieval date remain in both reference and runtime summaries. Do not silently regenerate from Classic, another flavor, or an unpinned branch. Import all applicable corrections before extracting locations or gates; never use area centres or old pre-entrance dungeon aliases as giver coordinates.
