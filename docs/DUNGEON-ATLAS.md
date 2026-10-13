# Dungeon atlas — beta28

Open the map's Dungeon atlas tab, select a dungeon, then choose a reference map, boss or Dungeon quests. Native maps remain preferred where valid; otherwise RUI displays its bundled square map with entrance/section selectors. Resizing preserves image proportions. Static maps have no player marker, and database coordinates are not projected onto unrelated artwork.

Atlas and AtlasLoot are not runtime requirements. RUI ships 147 unchanged Atlas Classic/Burning Crusade BLP images and 38 dungeon records derived from AtlasLoot Forever 1.60.1. ProjectRuthless_DungeonData loads only on the first atlas request; images load only when selected and textures release on hide. Restart WoW once after adding this folder. The package contains three addon folders, all of which must be installed.

GPL provenance and license accompany the images and records; upstream sources and the export script accompany the records. RUI's own viewer code remains separate. Normal/heroic tables have an explicit switch where available. Only numeric item rows are retained; reference tables are not proof of complete live Forever drops, quest coverage or probabilities.

Boss/loot and held/eligible quest lists remain in the sidebar. Local maps contain upstream printed reference markers; no unverified clickable coordinate overlay is added. Accurate clickable boss pins continue on supported native maps. Quest locations use the existing optional QuestieDB provider, not Atlas libraries. Custom Forever dungeons with no bundled image state that explicitly.

No polling or idle animation. Item cache events subscribe only while the atlas is used. Local checks cover no-Atlas catalog/loot loading, map selection validation, square fitting, asset integrity and packaging. In-game rendering, image accuracy and taint require live review.
