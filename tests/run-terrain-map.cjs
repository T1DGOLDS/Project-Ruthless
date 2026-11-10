const fs=require('fs'),path=require('path'),parser=require('luaparse');
const {lua,lauxlib,lualib,to_luastring,to_jsstring}=require('fengari');
const L=lauxlib.luaL_newstate();lualib.luaL_openlibs(L);
for(const [name,file] of [['TERRAIN','TerrainMap.lua'],['DATA','TerrainMapTiles.lua']]){
 const source=fs.readFileSync(path.join(__dirname,'../Modules',file),'utf8');
 parser.parse(source,{luaVersion:'5.1'});lua.lua_pushstring(L,to_luastring(source));lua.lua_setglobal(L,to_luastring(name));
}
const source=fs.readFileSync(path.join(__dirname,'terrain-map.test.lua'),'utf8');
if(lauxlib.luaL_dostring(L,to_luastring(source))!==lua.LUA_OK)throw Error(to_jsstring(lua.lua_tostring(L,-1)));

