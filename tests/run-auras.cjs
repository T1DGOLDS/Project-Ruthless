const fs=require('fs'),path=require('path'),parser=require('luaparse');
const {lua,lauxlib,lualib,to_luastring,to_jsstring}=require('fengari');
const root=path.resolve(__dirname,'..'),L=lauxlib.luaL_newstate();lualib.luaL_openlibs(L);
for(const [name,file]of [['MANAGER','Modules/AuraManager.lua'],['AURA_OPTIONS','ProjectRuthless_Options/AuraOptions.lua']]){
 const source=fs.readFileSync(path.join(root,file),'utf8');parser.parse(source,{luaVersion:'5.1'});
 if(name==='MANAGER'&&/GetAuraData|GetSpellCooldown|SetCooldown\(|RefreshLayout\(|secretunwrap|COMBAT_LOG_EVENT_UNFILTERED/.test(source))throw Error('Aura manager must not read or calculate restricted runtime data');
 lua.lua_pushstring(L,to_luastring(source));lua.lua_setglobal(L,to_luastring(name+'_SOURCE'));
}
if(process.env.PR_WOW_FOREVER_SOURCE){
 const native=path.join(process.env.PR_WOW_FOREVER_SOURCE,'Blizzard_AuraContainer');
 const api=fs.readFileSync(path.join(native,'Blizzard_CustomAuraContainer.lua'),'utf8');
 for(const method of ['AddAuraGroup','SetAuraGroupCandidateFilters','SetAuraGroupSortMethod','SetAuraGroupLayout','SetAuraProcessingPolicy'])if(!api.includes(':'+method+'('))throw Error('Missing native aura contract '+method);
 const toc=fs.readFileSync(path.join(process.env.PR_WOW_FOREVER_SOURCE,'Blizzard_CooldownViewer/Blizzard_CooldownViewer.toc'),'utf8');
 if(!toc.includes('standard, camelot'))throw Error('Cooldown viewer not declared for Forever');
}
if(lauxlib.luaL_dostring(L,to_luastring(fs.readFileSync(path.join(__dirname,'aura-manager.test.lua'),'utf8')))!==lua.LUA_OK)throw Error(to_jsstring(lua.lua_tostring(L,-1)));
