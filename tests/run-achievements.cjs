const fs = require('fs');
const path = require('path');
const root = path.resolve(process.argv[2] || path.join(__dirname, '..'));
const dependencyRoot = process.env.PR_TEST_DEPS || path.join(root, 'node_modules');
const parser = require(path.join(dependencyRoot, 'luaparse'));
const {lua, lauxlib, lualib, to_luastring, to_jsstring} = require(path.join(dependencyRoot, 'fengari'));

for (const file of fs.readdirSync(root, {recursive:true}).filter(file => file.endsWith('.lua') && !file.startsWith('tests'))) {
  parser.parse(fs.readFileSync(path.join(root, file), 'utf8'), {luaVersion:'5.1'});
}
console.log('PASS: Lua 5.1 syntax');

const L = lauxlib.luaL_newstate();
lualib.luaL_openlibs(L);
lua.lua_pushstring(L, to_luastring(fs.readFileSync(path.join(root, 'Modules/Achievements.lua'), 'utf8')));
lua.lua_setglobal(L, to_luastring('ACHIEVEMENTS_SOURCE'));

const test = fs.readFileSync(path.join(__dirname, 'achievements.test.lua'), 'utf8');
if (lauxlib.luaL_dostring(L, to_luastring(test)) !== lua.LUA_OK) {
  throw new Error(to_jsstring(lua.lua_tostring(L, -1)));
}
