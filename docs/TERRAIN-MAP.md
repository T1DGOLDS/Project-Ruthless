# Forever terrain layer

The bottom-left Terrain button on the world map switches the existing canvas between parchment and minimap terrain. It remembers the choice per character. This layer provides terrain artwork, not live minimap tracking dots. Native pins, quests and map controls keep their own layers. Unsupported maps and gaps retain the native art. Only in-view tiles are assigned textures; closing the map releases their texture references.

TerrainMapTiles.lua contains only numeric outdoor tile positions and client FileDataIDs for maps 0, 1 and 2991. These are Blizzard WDT facts for wowf 1.60.1.70790, cross-referenced from the generated Data/Tiles.lua index in MagicMap commit 3016c98588296a1dfad9559fdd21b108f4084b25 (https://github.com/benmills/MagicMap). RUI does not include MagicMap code, depend on the addon, or ship Blizzard textures. The renderer uses the current client's map corner coordinates for placement. Game art belongs to Blizzard Entertainment.

Live check: toggle on Zephras Isle, zoom/pan, compare coastline and player alignment, switch to a continent or unsupported map, check quest pin hover, toggle back to parchment, then reload and verify the preference.
