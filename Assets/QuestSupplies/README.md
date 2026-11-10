# Quest-supply reference data

Readable client-record universe: 6,614 QuestV2 records from Andrew's installed Forever build 1.60.1.70862, read-only CASC extraction on 2026-11-08. The table declares 6,706 records, including 92 encrypted records this extractor did not read. Their IDs and requirements are not fabricated. Area names come from the same client's AreaTable (1,375 readable records; 46 encrypted records were not read). Records can include inactive/deprecated IDs. This is not a claim that 6,614 quests are currently available to a player.

The local QuestObjective export contained zero rows. Client quest IDs alone do not disclose item requirements, counts, eligibility or auction restrictions. No quest/spawn addon database was copied or reconnected.

## Classic reference baseline

Factual subset of CMaNGOS Classic-DB: quest ID, title, levels, zone/category, race/class masks, repeatability, predecessor ID, required item IDs/counts, item names, binding and flags. These are Classic 1.12 references, not verified Forever requirements. Positive references require binding None/Bind-on-equip/Bind-on-use and exclude conjured items. The actual Forever client can still reject an item for auction. No expressive quest dialogue/descriptions or spawn database are included.

Source: https://github.com/cmangos/classic-db
Pinned revision: c33f90b8eeb3f8bacb53d5cbfee45075c80b416c
Input: Full_DB/ClassicDB_1_12_1_z2815.sql.gz
Input archive SHA-256: 4f92db520868ab4e566726f68b5b2e380ae781209beaf22237b4f7f04600d0c0

The generated subset and editable Reference.json are GPL-3.0 reference data. Upstream LICENSE-REFERENCE.txt and COPYRIGHT-REFERENCE.md are retained. RUI's independently authored implementation/serializer retains its own MIT licence. These notices do not transfer Blizzard's underlying intellectual-property rights.

## Coverage ledger

- 363 client quest IDs have candidate purchasable item requirements in the Classic reference, across 65 zone/category groups, using 323 distinct candidate items.
- 3,172 matching client IDs have no tradable requirements in the Classic reference. They are not confirmed empty in Forever.
- 3,079 client IDs have no reference requirements. They are explicitly unknown.
- All reference quest requirements and eligibility need Forever confirmation. None were promoted to confirmed merely because an ID matches.

RUI records complete native required-item lists from QUEST_PROGRESS, after checking hidden/partial responses. Current native item binding/name information supersedes the reference. Native turn-in observations supersede the reference requirements for that ID. This does not establish faction/class/prerequisite eligibility or universal auctionability. Unknown binding is omitted from positive purchasing rows. Actual auction results establish that an item was listed in that market. Account observations are separate from profiles, and are not silently published or uploaded.

## Rebuilding

Reference.json is the editable source of the bundled subset. From the repository run:

    python tools/build-quest-supplies.py --check

The serializer is also supplied here. From this directory in an extracted addon:

    python build_catalogue.py --source Reference.json --output ../../Modules/QuestSupplyData.lua

The runtime Lua module lazily allocates its data on the first catalogue/turn-in request. Its small summary supports diagnostics without materializing the catalogue. It makes no network requests or catalogue scans at login.
