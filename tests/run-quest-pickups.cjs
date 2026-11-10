const fs=require('fs'),path=require('path'),assert=require('assert');
const root=path.resolve(__dirname,'..');
const {lua,lauxlib,lualib,to_luastring,to_jsstring}=require(path.join(root,'node_modules/fengari'));
const parser=require(path.join(root,'node_modules/luaparse'));
const source=JSON.parse(fs.readFileSync(path.join(root,'Assets/QuestPickups/Reference.json'),'utf8'));
assert.equal(source.flavor,'Forever');assert.equal(source.revision,'c1b50fefb19c064edc436429bef73435d9ff4254');
assert(Object.keys(source.quests).length>5000);assert(source.byMap[1436].includes(22));
assert.equal(source.raceMasks[95],4294967296);assert.equal(source.raceMasks[96],8589934592);
for(const [id,q]of Object.entries(source.quests))for(const site of q.sites){
 assert(site[0]>0&&site[1]>0&&site[1]<=1&&site[2]>0&&site[2]<=1);
 assert(source.byMap[site[0]].includes(+id));
}
const L=lauxlib.luaL_newstate();lualib.luaL_openlibs(L);
for(const [key,file]of Object.entries({PICKUP_DATA:'Modules/QuestPickupData.lua',AVAILABILITY:'Modules/QuestAvailability.lua',DATA:'Modules/QuestData.lua',LOCATIONS:'Modules/QuestLocations.lua'})){
 const text=fs.readFileSync(path.join(root,file),'utf8');parser.parse(text,{luaVersion:'5.1'});
 lua.lua_pushstring(L,to_luastring(text));lua.lua_setglobal(L,to_luastring(key+'_SOURCE'));
}
if(lauxlib.luaL_dostring(L,to_luastring(fs.readFileSync(path.join(__dirname,'quest-pickups.test.lua'),'utf8')))!==lua.LUA_OK)throw Error(to_jsstring(lua.lua_tostring(L,-1)));
console.log('PASS: all packaged pickup locations indexed, normalized, source pinned and high-bit Skyborne race masks preserved');
