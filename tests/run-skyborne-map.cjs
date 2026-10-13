const fs=require('fs'),path=require('path'),root=path.resolve(__dirname,'..');
const parser=require(path.join(root,'node_modules/luaparse'));
const {lua,lauxlib,lualib,to_luastring,to_jsstring}=require(path.join(root,'node_modules/fengari'));
const L=lauxlib.luaL_newstate();lualib.luaL_openlibs(L);
for(const [key,file] of [['DATA','SkyborneMapData.lua'],['SOURCE','SkyborneMap.lua']]){const s=fs.readFileSync(path.join(root,'Modules',file),'utf8');parser.parse(s,{luaVersion:'5.1'});lua.lua_pushstring(L,to_luastring(s));lua.lua_setglobal(L,to_luastring(key));}
if(lauxlib.luaL_dostring(L,to_luastring(fs.readFileSync(path.join(__dirname,'skyborne-map.test.lua'),'utf8')))!==lua.LUA_OK)throw Error(to_jsstring(lua.lua_tostring(L,-1)));
