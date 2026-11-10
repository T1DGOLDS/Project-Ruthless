const fs=require('fs'),path=require('path'),root=path.resolve(__dirname,'..');
const parser=require('luaparse'),{lua,lauxlib,lualib,to_luastring,to_jsstring}=require('fengari');
const L=lauxlib.luaL_newstate();lualib.luaL_openlibs(L);
for(const [name,file]of [['SOURCE','Modules/FeatureGuide.lua'],['FIRST_RUN','Modules/FirstRun.lua']]){
 const source=fs.readFileSync(path.join(root,file),'utf8');parser.parse(source,{luaVersion:'5.1'});lua.lua_pushstring(L,to_luastring(source));lua.lua_setglobal(L,to_luastring(name));
}
if(lauxlib.luaL_dostring(L,to_luastring(fs.readFileSync(path.join(__dirname,'feature-guide.test.lua'),'utf8')))!==lua.LUA_OK)throw Error(to_jsstring(lua.lua_tostring(L,-1)));
