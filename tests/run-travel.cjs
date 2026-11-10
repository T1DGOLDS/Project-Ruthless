const fs=require('fs'),path=require('path'),assert=require('assert'),root=path.resolve(__dirname,'..');
const parser=require('luaparse'),{lua,lauxlib,lualib,to_luastring,to_jsstring}=require('fengari');
const L=lauxlib.luaL_newstate();lualib.luaL_openlibs(L);
for(const [key,file]of [['DATA','TravelData.lua'],['HEALERS','SpiritHealers.lua'],['FLIGHTS','FlightTimer.lua'],['MINIMAP','ForeverMinimap.lua'],['REPAIR','RepairReminder.lua']]){
 const source=fs.readFileSync(path.join(root,'Modules',file),'utf8');parser.parse(source,{luaVersion:'5.1'});lua.lua_pushstring(L,to_luastring(source));lua.lua_setglobal(L,to_luastring(key));
}
const facts=JSON.parse(fs.readFileSync(path.join(root,'Assets/Travel/travel-facts.json'),'utf8'));
assert.equal(facts.healers.length,85);assert.equal(Object.values(facts.referenceFlights).flatMap(Object.values).flatMap(Object.values).length,881);
assert(facts.healers.every(p=>p.x>=0&&p.x<=1&&p.y>=0&&p.y<=1));
if(process.env.PR_WOW_FOREVER_SOURCE){
 const native=p=>fs.readFileSync(path.join(process.env.PR_WOW_FOREVER_SOURCE,p),'utf8');
 const death=native('Blizzard_APIDocumentationGenerated/DeathInfoDocumentation.lua');
 for(const name of ['GetGraveyardsForMap','GetDeathReleasePosition'])assert(death.includes('Name = "'+name+'"'));
 const taxi=native('Blizzard_UIPanels_Game/Shared/TaxiFrame.lua')+native('Blizzard_UIPanels_Game/Shared/TaxiFrame.xml');
 for(const name of ['TakeTaxiNode','TaxiNodeGetType','TaxiNodeName','GetNumRoutes','TaxiGetNodeSlot'])assert(taxi.includes(name+'('));
 const minimap=native('Blizzard_Minimap/Camelot/Minimap.lua');
 assert(minimap.includes('function MinimapClusterMixin:UpdateMinimapConfig()')&&minimap.includes('ui-hud-minimap-frame-generic-mask'));
 assert(native('Blizzard_APIDocumentationGenerated/MinimapFrameAPIDocumentation.lua').includes('Name = "SetMaskTexture"'));
 console.log('PASS: current Forever death, taxi and minimap API contracts');
}
if(lauxlib.luaL_dostring(L,to_luastring(fs.readFileSync(path.join(__dirname,'travel.test.lua'),'utf8')))!==lua.LUA_OK)throw Error(to_jsstring(lua.lua_tostring(L,-1)));
