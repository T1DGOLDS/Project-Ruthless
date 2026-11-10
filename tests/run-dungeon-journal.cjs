const fs=require('fs'),path=require('path'),assert=require('assert'),root=path.resolve(__dirname,'..');
const {lua,lauxlib,lualib,to_luastring,to_jsstring}=require('fengari'),parser=require('luaparse');
const L=lauxlib.luaL_newstate();lualib.luaL_openlibs(L);
for(const [key,file]of [['FACTS','ProjectRuthless_DungeonData/WowheadRecords.lua'],['ATLAS','Modules/DungeonAtlas.lua'],['JOURNAL','Modules/DungeonJournal.lua']]){
 const source=fs.readFileSync(path.join(root,file),'utf8');parser.parse(source,{luaVersion:'5.1'});lua.lua_pushstring(L,to_luastring(source));lua.lua_setglobal(L,to_luastring(key));
}
const facts=JSON.parse(fs.readFileSync(path.join(root,'Assets/DungeonJournal/facts.json'),'utf8'));
assert.equal(Object.keys(facts.records).length,35);assert.equal(facts.summary.published,30);assert.equal(facts.summary.bosses,217);assert.equal(facts.summary.quests,249);
for(const d of Object.values(facts.records)){
 assert(d.LevelRange[1]>=1&&d.LevelRange[2]<=60);assert(d.source.startsWith('https://www.wowhead.com/forever/'));
 for(const q of d.quests){if(q.coordinates)assert(q.coordinates.every(x=>x>=0&&x<=100));assert(!/Only/.test(q.pickupZone||''));}
}
for(const quest of facts.records['blackfathom-deeps'].quests.filter(q=>[1200,6561].includes(q.id)))assert.equal(quest.giver.id,4787);
assert(facts.records.zulfarrak.preparation.some(p=>p.id===9240));
assert(fs.readFileSync(path.join(root,'ProjectRuthless_DungeonData/ProjectRuthless_DungeonData.toc'),'utf8').includes('WowheadRecords.lua'));
if(lauxlib.luaL_dostring(L,to_luastring(fs.readFileSync(path.join(__dirname,'dungeon-journal.test.lua'),'utf8')))!==lua.LUA_OK)throw Error(to_jsstring(lua.lua_tostring(L,-1)));
