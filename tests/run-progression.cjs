const fs=require('fs'),path=require('path'),parser=require('luaparse');
const {lua,lauxlib,lualib,to_luastring,to_jsstring}=require('fengari');
const root=path.resolve(__dirname,'..'),L=lauxlib.luaL_newstate();lualib.luaL_openlibs(L);
for(const [name,file]of [['DATA','QuestProgressionData.lua'],['PROGRESSION','QuestProgression.lua']]){
 const source=fs.readFileSync(path.join(root,'Modules',file),'utf8');parser.parse(source,{luaVersion:'5.1'});
 if(/Attune_DB|LibQuestieDB|Attune_Data|loadstring|COMBAT_LOG_EVENT_UNFILTERED/.test(source))throw Error('External/unsafe progression dependency');
 lua.lua_pushstring(L,to_luastring(source));lua.lua_setglobal(L,to_luastring(name+'_SOURCE'));
}
const native=process.env.PR_WOW_FOREVER_SOURCE;
if(native){const source=fs.readFileSync(path.join(native,'Blizzard_APIDocumentationGenerated/QuestLineInfoDocumentation.lua'),'utf8');for(const name of ['GetQuestLineInfo','GetQuestLineQuests','GetAvailableQuestLines'])if(!source.includes('Name = "'+name+'"'))throw Error('Missing pinned native API '+name);}
if(lauxlib.luaL_dostring(L,to_luastring(fs.readFileSync(path.join(__dirname,'quest-progression.test.lua'),'utf8')))!==lua.LUA_OK)throw Error(to_jsstring(lua.lua_tostring(L,-1)));
