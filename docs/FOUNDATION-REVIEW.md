# Foundation review

RUI keeps settings metadata, profiles, layout, diagnostics and feature modules separate. Settings and Edit Mode share account profiles; character observations, prices and quest progress remain with that character. Appearance uses shared palette/background controls with per-surface overrides.

Protected changes defer until combat ends. Native unit, aura, action, map and inventory workflows retain ownership of restricted gameplay behavior. RUI-owned browsing windows can open independently in combat. Missing or restricted data is labelled instead of fabricated.

Events coalesce; hidden views stop display work; optional windows, records and pooled controls are built on demand. Development reports expose configuration problems and bounded measurements. Conflict checks inspect actual native ownership metadata rather than treating installation of another product as proof of a conflict.

Validation uses the source revision in validation/native-source.json and the relevant tests under tests/. Actual Lua5.1 syntax, source contracts, data compilation and release checks are separate from in-game rendering, taint, accessibility and performance acceptance. Six live gates remain pending.
