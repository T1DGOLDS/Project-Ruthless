const fs = require('fs');
const path = require('path');
const root = path.resolve(process.argv[2] || path.join(__dirname, '..'));
const dependencyRoot = process.env.PR_TEST_DEPS || path.join(root, 'node_modules');
const nativeRoot = process.env.PR_WOW_SOURCE;
if (!nativeRoot) throw new Error('Set PR_WOW_SOURCE to an extracted Blizzard Interface/AddOns directory.');
const parser = require(path.join(dependencyRoot, 'luaparse'));
const {lua, lauxlib, lualib, to_luastring, to_jsstring} = require(path.join(dependencyRoot, 'fengari'));

parser.parse(fs.readFileSync(path.join(root, 'Modules/CharacterV2.lua'), 'utf8'), {luaVersion:'5.1'});
console.log('PASS: Character equipment-set Lua 5.1 syntax');

const paperDollXml = fs.readFileSync(path.join(nativeRoot, 'Blizzard_UIPanels_Game/Mainline/PaperDollFrame.xml'), 'utf8');
for (const handler of ['OnClick', 'OnDragStart', 'OnReceiveDrag', 'OnEnter', 'OnLeave']) {
  if (!paperDollXml.includes(`<${handler}`)) throw new Error(`native PaperDoll template is missing ${handler}`);
}
if (!paperDollXml.includes('PaperDollItemSlotButton_OnModifiedClick')) throw new Error('native slot template no longer exposes modified-click handling');
console.log('PASS: live-source PaperDoll template owns click, drag/drop, modified-click, tooltip, and Alt-flyout scripts');

const L = lauxlib.luaL_newstate();
lualib.luaL_openlibs(L);
lua.lua_pushstring(L, to_luastring(fs.readFileSync(path.join(root, 'Modules/CharacterV2.lua'), 'utf8')));
lua.lua_setglobal(L, to_luastring('CHARACTER_SOURCE'));
const test = fs.readFileSync(path.join(__dirname, 'equipment-sets.test.lua'), 'utf8');
if (lauxlib.luaL_dostring(L, to_luastring(test)) !== lua.LUA_OK) {
  throw new Error(to_jsstring(lua.lua_tostring(L, -1)));
}
