const fs = require('fs');
const path = require('path');
const root = path.resolve(__dirname, '..');
const parser = require(path.join(root, 'node_modules/luaparse'));
const {lua, lauxlib, lualib, to_luastring, to_jsstring} = require(path.join(root, 'node_modules/fengari'));
const source = fs.readFileSync(path.join(root, 'Modules/QuestWorkspace.lua'), 'utf8');
parser.parse(source, {luaVersion:'5.1'});
const L = lauxlib.luaL_newstate();
lualib.luaL_openlibs(L);
if(process.env.PR_WOW_FOREVER_SOURCE){
 const native=fs.readFileSync(path.join(process.env.PR_WOW_FOREVER_SOURCE,'Blizzard_WorldMap/QuestLogOwnerMixin.lua'),'utf8');
 lua.lua_pushstring(L,to_luastring(native));lua.lua_setglobal(L,to_luastring('NATIVE_MAP_OWNER_SOURCE'));
}
lua.lua_pushstring(L,to_luastring(fs.readFileSync(path.join(root,'Core.lua'),'utf8').match(/-- Demand-driven runtime helpers\.[\s\S]*?-- End demand-driven runtime helpers\./)[0]));
lua.lua_setglobal(L,to_luastring('RUNTIME_SOURCE'));
lua.lua_pushstring(L, to_luastring(source));
lua.lua_setglobal(L, to_luastring('QUEST_SOURCE'));
lua.lua_pushstring(L,to_luastring(fs.readFileSync(path.join(root,'Modules/MapQuests.lua'),'utf8')));lua.lua_setglobal(L,to_luastring('MAP_SETTINGS_SOURCE'));
lua.lua_pushstring(L, to_luastring(fs.readFileSync(path.join(root, 'Modules/QuestLocations.lua'), 'utf8')));
lua.lua_setglobal(L, to_luastring('LOCATIONS_SOURCE'));
lua.lua_pushstring(L,to_luastring(fs.readFileSync(path.join(root,'ProjectRuthless_DungeonData/Records.lua'),'utf8')));lua.lua_setglobal(L,to_luastring('BUNDLED_DUNGEON_SOURCE'));
for(const [key,file]of [['AUTHORED_DATA_SOURCE','AuthoredGuideData.lua'],['AUTHORED_SOURCE','AuthoredGuides.lua']]){lua.lua_pushstring(L,to_luastring(fs.readFileSync(path.join(root,'Modules',file),'utf8')));lua.lua_setglobal(L,to_luastring(key))}
const dungeonSource=fs.readFileSync(path.join(root,'Modules/DungeonAtlas.lua'),'utf8');
parser.parse(dungeonSource,{luaVersion:'5.1'});
lua.lua_pushstring(L,to_luastring(dungeonSource));lua.lua_setglobal(L,to_luastring('DUNGEON_SOURCE'));
if (lauxlib.luaL_dostring(L, to_luastring(fs.readFileSync(path.join(__dirname, 'quest-workspace.test.lua'), 'utf8')+'\n'+fs.readFileSync(path.join(__dirname,'map-toggle.test.lua'),'utf8')+'\n'+fs.readFileSync(path.join(__dirname,'quest-progression-integration.test.lua'),'utf8'))) !== lua.LUA_OK) {
  throw new Error(to_jsstring(lua.lua_tostring(L, -1)));
}

require('./run-dungeon-assets.cjs');
