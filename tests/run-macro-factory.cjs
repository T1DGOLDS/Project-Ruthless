const fs=require('fs'),path=require('path'),assert=require('assert'),root=path.resolve(__dirname,'..');
const parser=require('luaparse'),{lua,lauxlib,lualib,to_luastring,to_jsstring}=require('fengari');
const L=lauxlib.luaL_newstate();lualib.luaL_openlibs(L);
for(const [name,file]of [['CATALOGUE','Modules/MacroTemplates.lua'],['SPELLBOOK','Modules/Spellbook.lua']]){
 const source=fs.readFileSync(path.join(root,file),'utf8');parser.parse(source,{luaVersion:'5.1'});lua.lua_pushstring(L,to_luastring(source));lua.lua_setglobal(L,to_luastring(name));
}
if(process.env.PR_WOW_FOREVER_SOURCE){
 const base=process.env.PR_WOW_FOREVER_SOURCE;
 const markers=fs.readFileSync(path.join(base,'Blizzard_ChatFrameBase/Shared/SlashCommands.lua'),'utf8');
 const pings=fs.readFileSync(path.join(base,'Blizzard_ChatFrameBase/Mainline/SlashCommandsOverrides.lua'),'utf8');
 assert(markers.includes('SLASH_COMMAND.TARGET_MARKER')&&markers.includes('SetRaidTarget(target, tonumber(marker))'));
 for(const [id,type]of [[1,'Attack'],[2,'Warning'],[3,'OnMyWay'],[4,'Assist'],[5,'AlertNotThreat'],[6,'AlertThreat']])assert(pings.includes('["'+id+'"] = Enum.PingSubjectType.'+type));
 assert(pings.includes('C_Ping.SendMacroPing(pingMacroInfo)'));
 console.log('PASS: current Forever marker parser and six native ping types');
}
if(lauxlib.luaL_dostring(L,to_luastring(fs.readFileSync(path.join(__dirname,'macro-factory.test.lua'),'utf8')))!==lua.LUA_OK)throw Error(to_jsstring(lua.lua_tostring(L,-1)));
