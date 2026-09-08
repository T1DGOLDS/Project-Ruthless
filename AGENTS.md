# Repository guidance

Project Ruthless targets modern retail World of Warcraft and Lua 5.1 syntax.

- Preserve Blizzard-owned workflows and protected behavior wherever possible.
- Keep ElvUI, Raider.IO, and Epithet integrations optional.
- Run the relevant harness in `tests/` before submitting changes.
- Treat in-game rendering, combat restrictions, protected state, and taint as separate acceptance checks that local mocks cannot prove.
- Do not commit generated release archives.
