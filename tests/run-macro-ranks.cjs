const fs = require('fs');
const path = require('path');
const root = path.resolve(__dirname, '..');
const parser = require(path.join(root, 'node_modules/luaparse'));
const {lua, lauxlib, lualib, to_luastring, to_jsstring} = require(path.join(root, 'node_modules/fengari'));
const source = fs.readFileSync(path.join(root, 'Modules/MacroRanks.lua'), 'utf8');
parser.parse(source, {luaVersion:'5.1'});
const L = lauxlib.luaL_newstate();
lualib.luaL_openlibs(L);
lua.lua_pushstring(L, to_luastring(source));
lua.lua_setglobal(L, to_luastring('MACRO_RANKS_SOURCE'));
if (lauxlib.luaL_dostring(L, to_luastring(fs.readFileSync(path.join(__dirname, 'macro-ranks.test.lua'), 'utf8'))) !== lua.LUA_OK) {
  throw new Error(to_jsstring(lua.lua_tostring(L, -1)));
}
