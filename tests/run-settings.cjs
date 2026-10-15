const fs=require('fs'),path=require('path'),parser=require('luaparse');
const {lua,lauxlib,lualib,to_luastring,to_jsstring}=require('fengari');
const root=path.resolve(__dirname,'..');
function run(test,extra='') {
 const L=lauxlib.luaL_newstate();lualib.luaL_openlibs(L);
 const sources={Core:'Core.lua',Profiles:'Modules/Profiles.lua',UnifiedProfiles:'Modules/UnifiedProfiles.lua',SettingsRegistry:'Modules/SettingsRegistry.lua',Menu:'ProjectRuthless_Options/Menu.lua',MenuLoader:'Modules/MenuLoader.lua',Spellbook:'Modules/Spellbook.lua',CharacterV2:'Modules/CharacterV2.lua',QuestWorkspace:'Modules/QuestWorkspace.lua',QuestLocations:'Modules/QuestLocations.lua',LowHealthGlow:'Modules/LowHealthGlow.lua',Titles:'Modules/Titles.lua'};
 Object.assign(sources,{LayoutEditor:'Modules/LayoutEditor.lua',HUD:'Modules/ForeverHUD.lua',Style:'Modules/ForeverStyle.lua',Buff:'Modules/ForeverExpiringBuffs.lua',Hint:'Modules/ForeverNameplateHints.lua',Error:'Modules/ErrorLog.lua',Accessibility:'Modules/Accessibility.lua',FirstRun:'Modules/FirstRun.lua'});
 for(const [name,file] of Object.entries(sources)) {
  const source=fs.readFileSync(path.join(root,file),'utf8');parser.parse(source,{luaVersion:'5.1'});
  lua.lua_pushstring(L,to_luastring(source));lua.lua_setglobal(L,to_luastring(name.toUpperCase()+'_SOURCE'));
  if(name==='LayoutEditor'){lua.lua_pushstring(L,to_luastring(source));lua.lua_setglobal(L,to_luastring('SOURCE'));}
 }
 const source=fs.readFileSync(path.join(__dirname,test),'utf8')+extra;
 if(lauxlib.luaL_dostring(L,to_luastring(source))!==lua.LUA_OK)throw Error(to_jsstring(lua.lua_tostring(L,-1)));
}
run('unified-profiles.test.lua');
run('performance.test.lua','\n'+fs.readFileSync(path.join(__dirname,'settings-ui.test.lua'),'utf8')+'\n'+fs.readFileSync(path.join(__dirname,'accessibility-setup.test.lua'),'utf8'));
run('layout-editor.test.lua','\n'+fs.readFileSync(path.join(__dirname,'unified-layout.test.lua'),'utf8')+'\n'+fs.readFileSync(path.join(__dirname,'accessible-portraits.test.lua'),'utf8')+'\n'+fs.readFileSync(path.join(__dirname,'party-aura-manager.test.lua'),'utf8'));
