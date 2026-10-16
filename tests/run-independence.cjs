const fs=require('fs'),path=require('path'),assert=require('assert');
const root=path.resolve(__dirname,'..'),parser=require(path.join(root,'node_modules/luaparse'));
const {lua,lauxlib,lualib,to_luastring,to_jsstring}=require(path.join(root,'node_modules/fengari'));
const L=lauxlib.luaL_newstate();lualib.luaL_openlibs(L);
const toc=fs.readFileSync(path.join(root,'ProjectRuthless_Camelot.toc'),'utf8');
assert(!/^## OptionalDeps:.*(?:Questie|TomTom|AtlasLoot|Details|ElvUI)/m.test(toc));
for(const file of toc.split(/\r?\n/).filter(x=>x.endsWith('.lua'))){
 const source=fs.readFileSync(path.join(root,file.replaceAll('\\','/')),'utf8');
 assert(!/\bLibQuestieDB\b|\bLibStub\s*\(|\bDetails\s+or\s+_detalhes|ElvUI_Bar|_G\.RaiderIO|_G\.Epithet/.test(source),'External runtime coupling in '+file);
}
for(const [key,file]of Object.entries({DATA:'Modules/QuestData.lua',PINS:'Modules/MapPins.lua',METERS:'Modules/ForeverMeters.lua',DIAGNOSTICS:'Modules/Diagnostics.lua',LOCATIONS:'Modules/QuestLocations.lua'})){
 const source=fs.readFileSync(path.join(root,file),'utf8');parser.parse(source,{luaVersion:'5.1'});
 lua.lua_pushstring(L,to_luastring(source));lua.lua_setglobal(L,to_luastring(key+'_SOURCE'));
}
assert(!/\b(?:SetCooldown|GetCombatSession|GetCombatSessionSource|COMBAT_LOG_EVENT_UNFILTERED|RefreshLayout)\s*\(/.test(fs.readFileSync(path.join(root,'Modules/ForeverMeters.lua'),'utf8')));
const native=process.env.PR_WOW_FOREVER_SOURCE;
assert(native,'Set PR_WOW_FOREVER_SOURCE for native contracts');
function check(file,terms){const source=fs.readFileSync(path.join(native,file),'utf8');for(const term of terms)assert(source.includes(term),'Native contract missing '+term);}
check('Blizzard_DamageMeter/Blizzard_DamageMeter.toc',['camelot']);
check('Blizzard_DamageMeter/DamageMeter.lua',['DamageMeterSessionWindow','SetupSessionWindow']);
check('Blizzard_APIDocumentationGenerated/MapDocumentation.lua',['GetWorldPosFromMapPos','GetMapPosFromWorldPos','GetMapWorldSize']);
check('Blizzard_APIDocumentationGenerated/MinimapDocumentation.lua',['GetViewRadius']);
check('Blizzard_APIDocumentationGenerated/QuestLineInfoDocumentation.lua',['GetAvailableQuestLines','startMapID','questName','inProgress']);
check('Blizzard_SettingsDefinitions_Frame/AdvancedOptions.lua',['damageMeterEnabled']);
if(lauxlib.luaL_dostring(L,to_luastring(fs.readFileSync(path.join(__dirname,'independence.test.lua'),'utf8')))!==lua.LUA_OK)throw Error(to_jsstring(lua.lua_tostring(L,-1)));
