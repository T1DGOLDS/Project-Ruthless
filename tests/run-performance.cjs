const fs=require('fs'),path=require('path');const root=path.resolve(__dirname,'..');
const {lua,lauxlib,lualib,to_luastring,to_jsstring}=require(path.join(root,'node_modules/fengari'));
const parser=require(path.join(root,'node_modules/luaparse'));
const L=lauxlib.luaL_newstate();lualib.luaL_openlibs(L);
const files=['Core.lua','Modules/MenuLoader.lua','Modules/Profiles.lua','Modules/Spellbook.lua','Modules/CharacterV2.lua','Modules/QuestWorkspace.lua','Modules/QuestLocations.lua','Modules/LowHealthGlow.lua','ProjectRuthless_Options/Menu.lua','Modules/Titles.lua'];
for(const file of files){const source=fs.readFileSync(path.join(root,file),'utf8');parser.parse(source,{luaVersion:'5.1'});lua.lua_pushstring(L,to_luastring(source));lua.lua_setglobal(L,to_luastring(path.basename(file,'.lua').toUpperCase()+'_SOURCE'));}
const baselineIndex=process.argv.indexOf('--baseline');
if(baselineIndex>=0){
 const baseline=process.argv[baselineIndex+1];
 const extract=source=>source.match(/    local elapsed(?:=0|,contentElapsed=0,0)[\s\S]*?    f:SetScript\("OnUpdate",function[\s\S]*?    end\)/)[0];
 for(const [name,source]of [['BASELINE_UPDATE_SOURCE',extract(fs.readFileSync(path.join(baseline,'Modules/QuestWorkspace.lua'),'utf8'))],['CURRENT_UPDATE_SOURCE',fs.readFileSync(path.join(root,'Modules/QuestWorkspace.lua'),'utf8').match(/    local lastMap,lastX,lastY[\s\S]*?        lastMap,lastX,lastY=map,x,y\n    end\)/)[0]],['BASELINE_CORE_SOURCE',fs.readFileSync(path.join(baseline,'Core.lua'),'utf8')]]){lua.lua_pushstring(L,to_luastring(source));lua.lua_setglobal(L,to_luastring(name));}
}
if(lauxlib.luaL_dostring(L,to_luastring(fs.readFileSync(path.join(__dirname,'performance.test.lua'),'utf8')))!==lua.LUA_OK)throw Error(to_jsstring(lua.lua_tostring(L,-1)));
