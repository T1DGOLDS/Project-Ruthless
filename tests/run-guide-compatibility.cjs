const fs=require('fs'),path=require('path'),assert=require('assert'),root=path.resolve(__dirname,'..');
const {lua,lauxlib,lualib,to_luastring,to_jsstring}=require('fengari');
const L=lauxlib.luaL_newstate();lualib.luaL_openlibs(L);
for(const [key,file]of [['BRIDGE','Modules/GuideBridge.lua'],['PROFILES','Modules/Profiles.lua']]){
 lua.lua_pushstring(L,to_luastring(fs.readFileSync(path.join(root,file),'utf8')));lua.lua_setglobal(L,to_luastring(key));
}
const source=`local A={modules={}};function A:RegisterModule(k,v)self.modules[k]=v end
assert(load(BRIDGE))('RUI',A);assert(load(PROFILES))('RUI',A)
ProjectRuthlessDB={questWorkspace={useExternalGuide=false}};ProjectRuthlessCharDB={}
local p=A.modules.Profiles
local parsed,why=p:Parse('RUI_SETTINGS_1\\nquestWorkspace.useWisp=false\\nelvui.safeTooltip=true')
assert(parsed,why);assert(parsed.questWorkspace.useExternalGuide==false)
local text=p:Export();assert(text:find('useExternalGuide=false',1,true)and not text:find('useWisp',1,true)and not text:find('elvui',1,true))
assert(A.GuideBridge:Normalize('Wisp')=='External'and A.GuideBridge:Normalize('RUI')=='RUI')
assert(A.GuideBridge:LegacyEnabled({useWisp=false})==false)
assert(A.GuideBridge:Read({entries={}})==nil)
print('PASS: legacy RUI guide/profile imports preserved without re-exporting retired branding keys')`;
if(lauxlib.luaL_dostring(L,to_luastring(source))!==lua.LUA_OK)throw Error(to_jsstring(lua.lua_tostring(L,-1)));
