const fs=require('fs'),path=require('path'),assert=require('assert'),root=path.resolve(__dirname,'..');
const parser=require('luaparse'),{lua,lauxlib,lualib,to_luastring,to_jsstring}=require('fengari');
const L=lauxlib.luaL_newstate();lualib.luaL_openlibs(L);
for(const [key,file]of [['CORE_SOURCE','Core.lua'],['DIAGNOSTICS_SOURCE','Modules/Diagnostics.lua']]){const source=fs.readFileSync(path.join(root,file),'utf8');parser.parse(source,{luaVersion:'5.1'});lua.lua_pushstring(L,to_luastring(source));lua.lua_setglobal(L,to_luastring(key));}
for(const name of ['ProjectRuthless.toc','ProjectRuthless_Camelot.toc'])assert(!fs.readFileSync(path.join(root,name),'utf8').includes('ElvUI'));
assert(!fs.existsSync(path.join(root,'Modules/ElvUICompat.lua')));
if(lauxlib.luaL_dostring(L,to_luastring(fs.readFileSync(path.join(__dirname,'foundation.test.lua'),'utf8')))!==lua.LUA_OK)throw Error(to_jsstring(lua.lua_tostring(L,-1)));
