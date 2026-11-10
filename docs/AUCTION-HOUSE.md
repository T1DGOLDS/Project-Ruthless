# RUI auction house — beta92

One movable native auction window contains Buy, Sell, Auctions, Tools, Market prices and Settings along a shared bottom tab strip. Tools contains searches, shopping, quest supplies and observed prices. Settings edits auction preferences inline; it does not open another settings window. Drag the title bar to move the entire window. Position is stored in the RUI character layout and travels with saved layouts/profiles. Native panel-manager reanchors are followed by one coalesced position restore outside combat.

Native Buy, Sell and Auctions keep responsibility for listing selection, bidding, purchasing, posting, deposits, cancellation fees and final confirmation. RUI custom pages use the inspected native display-mode lifecycle rather than layering controls over clickable native listings. Native tab click handlers are retained. Selecting a result returns to native listings; filling a valid selling price returns to the selected native Sell view for review. No other auction addon is required and no prices/lists/reports are uploaded.

Open an auctioneer to use the integrated pages. `/pr auction` or Map > Supplies also opens an offline planning catalogue, with trading unavailable until an auctioneer is open. The offline planner has its own saved position. The Start on RUI Tools setting selects Tools on opening; turning it off starts on Buy while all custom tabs remain accessible.

## Full-market price search

Market prices > Scan market makes one explicit `C_AuctionHouse.ReplicateItems` request. There is no automatic background full-market scan and no per-item server-query loop. After the server response, indexing yields after at most 1,000 rows, with a 2ms budget checked every 100 rows when the profiling clock is available. The time check is a cooperative budget, not a guarantee of maximum frame cost. Search filters the cached snapshot locally and reuses unchanged results; no new server query is sent when typing. Click a row to inspect live listings.

The snapshot records item-ID minimum buyout per unit, listed quantity and listing count. Bid-only items have no buyout price. It includes own listings and combines variants of an item ID; it is not an exact-variant competing quote or a sales history. It is never used to fill prices or execute transactions. Timestamps show age. Missing names, invalid rows or capacity limits mark the result partial. Bounds: 250,000 returned listings and 30,000 distinct item IDs per snapshot, with the existing maximum of four realm/faction market scopes. Server snapshot availability is not a guarantee that all auctioneers in a realm/faction share one market.

The prior completed snapshot remains available while indexing. Cancelling, closing the auction house or a 45-second response timeout retains it. Successful scans wait 15 minutes locally before another request; an uncompleted request has a 60-second retry guard. Blizzard may impose its own delay. Unsupported/declined requests and timeouts show an explanation. Do not confuse a stale or partial snapshot with live availability. Opt-in work reports include AuctionMarket.Index; no measured in-game speed claim has been made.

## Searches and shopping

- Searches tab: save/favourite the native search, remember its level/filter settings, choose a default, or browse the last 30 searches. The default restores fields on opening without sending a query. Restoring a saved search clears category selection so an old category cannot silently filter it out. Category selection itself is not saved.
- Shopping tab: type a list name in the filter box and choose New list. Add the current native search, or add a specific quest item using its row's right-click menu. Right-click a shopping row to edit its target, price cap or remove it. Known item IDs subtract native current-character bags/bank counts. Broad text searches without an item ID cannot subtract ownership reliably.
- Search next sends one missing target at a time per click. Busy/throttled or closed auction houses reject the request without advancing the cursor. It does not purchase a shopping list automatically.
- List caps accept copper or values such as `2g 50s`. Caps produce a visible warning when a matching item quote exceeds the cap. They do not replace or bypass native purchase confirmation.
- The list selector includes data-only import/export and recoverable list removal. Imports validate the entire document before writing, preserve existing list names and never execute Lua. Limits: 30 lists, 100 targets per list, 100 saved searches, 30 recent searches per character.

## Selling, prices and owned auctions

Select an item in native Sell. Remember sale saves its quantity/duration for this character. When automatic preference restoration is enabled, selecting that item restores them, with quantity clamped to the native available maximum. New items use the character's default duration, selectable from the Prices tab menu. Stored prices are never automatically restored.

Fill fresh price edits the native unit-price field and updates native validation/deposit/total display. It requires a complete quote for the exact item variant, no older than 60 seconds, and a verified competing price. Match the lowest competing unit price or subtract one copper. Item-stack buyouts are divided by quantity. Own/account listings are excluded from competition; ambiguous account-owned commodity buckets are omitted. Incomplete, absent, stale or mismatched quotes cannot fill a price. Native Post remains a separate user action.

Prices are observations from the listings returned by your searches, not a full-market valuation or a historical sales database. At most 500 rows are inspected per result set. Over-limit sets remain partial and cannot be used to fill a selling price. Bounds: 200 live quote variants per visit, 500 historical variants per realm/faction scope, 14 observed days per variant, four realm/faction scopes. Closing the auction house drops live quotes. Observations can combine auctioneers visited in that realm/faction scope; they do not establish that every auctioneer shares the same market. Cached history is never used to execute a transaction or fill a sale.

Prices tab > My auctions shows current native owned listings and marks lower verified competing prices. Click to check an item's listings. Right-click to open Blizzard's cancellation-fee confirmation. Ownership/status is checked again immediately before opening it, and sold entries are excluded. Bid-only entries retain native management but have no fixed-price undercut comparison. No automatic cancellation occurs.

## Quest supplies and the data boundary

Quest supplies groups candidates by zone/category and displays item, quantity, owned/missing count, quest, quest level, reference minimum level and source. Complete native turn-in observations override the reference requirement list for an ID. Native item name/binding takes priority. Bound/conjured references and unknown binding are not promoted to purchase candidates.

The catalogue contains 6,614 readable QuestV2 IDs from installed Forever build 1.60.1.70862. Its header also declares 92 encrypted records this extractor did not read. In the readable set, 363 quest IDs have Classic purchase references across 65 zone/category groups, with 323 distinct candidate items. Another 3,172 reference quests have no tradable requirements in Classic, and 3,079 IDs lack reference requirements. None of these Classic requirements or eligibility rules are assumed verified for Forever. Client records can include inactive/deprecated quests and are not an active-quest count.

Show audit rows exposes missing/reference-only records. Missing records cannot start purchases. Make list uses the largest requirement per item in the currently filtered zone results rather than summing repeatable/mutually exclusive quests. This is a planning target, not a promise it completes every quest simultaneously. Completed non-repeatable quests are omitted when native completion data is available. Class, faction, prerequisite and changed quest requirements must be checked before buying reference supplies.

`QUEST_PROGRESS` records complete native required-item lists. Hidden, partial or restricted results do not overwrite existing observations. Native completion/item APIs and source provenance remain distinct. Observations stay account-local, outside settings profiles. No automatic full-catalogue server query runs at login. [Data source, licences, ledger and regeneration](../Assets/QuestSupplies/README.md).

## Settings, performance and acceptance

RUI Settings > Auction house controls opening on RUI Tools, recent-search recording, automatic saved sale preferences and price observations. Appearance/behaviour preferences join RUI profiles. Lists/searches/sale targets remain character-specific, price observations remain scoped account data, and quest facts remain account-local facts. Backgrounds > Auction house uses the shared RUI opacity/colour inheritance.

Native frame loading/show timing is observed rather than assumed. Result bursts coalesce. Hidden tools do not render on bag changes. The catalogue allocates lazily, filters cache until query/zone/inventory/data changes, and distinct item ownership lookups share a per-filter cache. Larger text uses fewer, taller visible rows. Opt-in recordings include `QuestSupplies.Filter`; this does not claim a measured in-game CPU reduction.

Automated checks cover real control handlers, default restore without querying, cross-character separation, throttle/closed-house guards, lists/caps/import validation, quote completeness/freshness/variants, owner exclusion, native cancellation confirmation acceptance/cancellation, sold/bid-only states, callback coalescing, bounded history and idle widget reuse. They use mocks and inspected native source. They do not certify a live auction transaction.

Live check: reload and confirm beta92, visit an auctioneer, inspect native Buy/Sell/My auctions and the integrated RUI pages, search a cheap familiar item, save it and a default, close/reopen, create/import a disposable shopping list, select a sale item and fill a price without posting, then inspect and dismiss a native cancellation confirmation if you have an existing auction. Check quest reference labels in two zones and a new/native turn-in. Test readable layout with larger text. Review `/pr errors` and `/pr report`. Spend/post/cancel only when deliberately testing your own transaction. All six repository live gates remain pending.

Live follow-up: drag the title bar, close/reopen and reload; check the position, all six bottom tabs and inline Settings. Start a scan, type a familiar item name, inspect its age/unit price, then click through to native listings. Stop a second in-progress scan if available and verify the earlier snapshot survives. Check native Buy/Sell/Auctions and their confirmations before trading.
