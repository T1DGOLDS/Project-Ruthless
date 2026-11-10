# Performance checks

RUI measures its own work and preserves native ownership of protected behavior. Options and dungeon data load on demand. Most windows and recipe tables are constructed when first used; pooled widgets are reused on later visits.

Quest, inventory and spell changes coalesce into bounded refreshes. Unchanged snapshots retain their identity. Native offer discovery and crafting observations yield between batches, pause when restricted and avoid rebuilding hidden views. Minimap positioning runs only while its content is visible and relevant. Optional route display reads are isolated in the provider bridge.

/pr record on and /pr record off collect bounded local sessions. Reports distinguish sampled CPU, native counters, frame gaps, memory growth and instrumented operation counts. Exact allocations and per-feature causation of a global frame gap are unavailable. No data is uploaded automatically.

Compare matched idle, travel, combat, crowded, map and bag scenarios on the same client with comparable enabled features. Automated workload checks verify lifecycle and bounded work; they do not establish live FPS gains. See TESTING-AND-RELEASES.md for the manual checks.
