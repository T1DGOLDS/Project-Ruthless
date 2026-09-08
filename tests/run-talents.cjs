const fs = require('fs');
const path = require('path');
const root = path.resolve(process.argv[2] || path.join(__dirname, '..'));
const dependencyRoot = process.env.PR_TEST_DEPS || path.join(root, 'node_modules');
const nativeRoot = process.env.PR_WOW_SOURCE;
if (!nativeRoot) throw new Error('Set PR_WOW_SOURCE to an extracted Blizzard Interface/AddOns directory.');
const parser = require(path.join(dependencyRoot,'luaparse'));
const {lua,lauxlib,lualib,to_luastring,to_jsstring} = require(path.join(dependencyRoot,'fengari'));
for (const file of fs.readdirSync(root,{recursive:true}).filter(f=>f.endsWith('.lua') && !f.startsWith('tests'))) {
  parser.parse(fs.readFileSync(path.join(root,file),'utf8'),{luaVersion:'5.1'});
}
console.log('PASS: Lua 5.1 syntax');
const L=lauxlib.luaL_newstate(); lualib.luaL_openlibs(L);
function inject(name,text) {lua.lua_pushstring(L,to_luastring(text));lua.lua_setglobal(L,to_luastring(name));}
inject('CORE_SOURCE',fs.readFileSync(path.join(root,'Core.lua'),'utf8'));
inject('TALENTS_SOURCE',fs.readFileSync(path.join(root,'Modules/Talents.lua'),'utf8'));
inject('LOAD_SYSTEM_SOURCE',fs.readFileSync(path.join(nativeRoot,'Blizzard_SharedXML/Shared/LoadSystem/LoadSystemTemplates.lua'),'utf8'));
const native=fs.readFileSync(path.join(nativeRoot,'Blizzard_PlayerSpells/ClassTalents/Blizzard_ClassTalentsFrame.lua'),'utf8');
const callback=native.match(/local function LoadConfiguration\(configID, isUserInput\)[\s\S]*?self\.LoadSystem:SetLoadCallback\(LoadConfiguration\);/);
if(!callback) throw new Error('Native load callback changed; inspect adapter');
inject('NATIVE_LOAD_CALLBACK',callback[0]);
if(lauxlib.luaL_dostring(L,to_luastring(fs.readFileSync(path.join(__dirname,'talents.test.lua'),'utf8')))!==lua.LUA_OK) {
  throw new Error(to_jsstring(lua.lua_tostring(L,-1)));
}
