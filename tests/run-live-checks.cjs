const fs=require('fs'),path=require('path'),assert=require('assert'),root=path.resolve(__dirname,'..');
const parser=require('luaparse'),{lua,lauxlib,lualib,to_luastring,to_jsstring}=require('fengari');
const L=lauxlib.luaL_newstate();lualib.luaL_openlibs(L);
for(const [name,file]of Object.entries({LIVE:'Modules/LiveChecks.lua',ERROR:'Modules/ErrorLog.lua',DIAGNOSTICS:'Modules/Diagnostics.lua'})){
 const source=fs.readFileSync(path.join(root,file),'utf8');parser.parse(source,{luaVersion:'5.1'});
 lua.lua_pushstring(L,to_luastring(source));lua.lua_setglobal(L,to_luastring(name+'_SOURCE'));
}
const source=fs.readFileSync(path.join(root,'Modules/LiveChecks.lua'),'utf8');
assert(!/NewTicker|OnUpdate|SetCVar|SetAttribute|SendAddonMessage|OnPlayerLogin|LoadAddOn/.test(source),'Live checks must remain demand-driven, local and read-only toward gameplay');
const gates=JSON.parse(fs.readFileSync(path.join(root,'validation/live-gates.json'),'utf8'));
lua.lua_pushstring(L,to_luastring(gates.gates.map(g=>g.id).join(',')));lua.lua_setglobal(L,to_luastring('REQUIRED_IDS'));
assert(fs.readFileSync(path.join(root,'ProjectRuthless_Camelot.toc'),'utf8').includes('Modules\\LiveChecks.lua'));
assert(!fs.readFileSync(path.join(root,'ProjectRuthless.toc'),'utf8').includes('Modules\\LiveChecks.lua'));
if(lauxlib.luaL_dostring(L,to_luastring(fs.readFileSync(path.join(__dirname,'live-checks.test.lua'),'utf8')))!==lua.LUA_OK)throw Error(to_jsstring(lua.lua_tostring(L,-1)));
