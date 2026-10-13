const fs=require('fs'),path=require('path');const root=path.resolve(__dirname,'..');const parser=require(path.join(root,'node_modules/luaparse'));const {lua,lauxlib,lualib,to_luastring,to_jsstring}=require(path.join(root,'node_modules/fengari'));
const source=fs.readFileSync(path.join(root,'Modules/LevelHistory.lua'),'utf8');parser.parse(source,{luaVersion:'5.1'});
const L=lauxlib.luaL_newstate();lualib.luaL_openlibs(L);lua.lua_pushstring(L,to_luastring(source));lua.lua_setglobal(L,to_luastring('SOURCE'));
if(lauxlib.luaL_dostring(L,to_luastring(fs.readFileSync(path.join(__dirname,'level-history.test.lua'),'utf8')))!==lua.LUA_OK)throw Error(to_jsstring(lua.lua_tostring(L,-1)));
