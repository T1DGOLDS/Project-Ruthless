const fs = require('fs');
const path = require('path');
const root = path.resolve(__dirname, '..');
const parser = require(path.join(root, 'node_modules/luaparse'));
const {lua, lauxlib, lualib, to_luastring, to_jsstring} = require(path.join(root, 'node_modules/fengari'));
const source = fs.readFileSync(path.join(root, 'Modules/ForeverActionBars.lua'), 'utf8');
parser.parse(source, {luaVersion: '5.1'});
for (const file of ['LibStub.lua', 'CallbackHandler-1.0.lua', 'LibActionButton-1.0.lua']) {
    parser.parse(fs.readFileSync(path.join(root, 'Libs/LibActionButton', file), 'utf8'), {luaVersion: '5.1'});
}
// Execute the real registry and callback library with the public registry poisoned.
{
    const L=lauxlib.luaL_newstate();lualib.luaL_openlibs(L);
    const boot=`strmatch=string.match;securecallfunction=function(fn,...)return fn(...)end
        LibStub=setmetatable({},{__call=function()error('external registry consulted')end,__index=function()error('external registry consulted')end})`;
    function run(code){if(lauxlib.luaL_dostring(L,to_luastring(code))!==lua.LUA_OK)throw Error(to_jsstring(lua.lua_tostring(L,-1)));}
    run(boot);
    for(const name of ['LibStub.lua','CallbackHandler-1.0.lua'])run(fs.readFileSync(path.join(root,'Libs/LibActionButton',name),'utf8'));
    run(`local cb=RUIActionBarLibStub('CallbackHandler-1.0');local target={};local event=cb:New(target)
        local receiver={};local result;target.RegisterCallback(receiver,'TEST',function(_,value)result=value end)
        event:Fire('TEST',42);assert(result==42)
        assert(RUIActionBarLibStub('Masque',true)==nil and RUIActionBarLibStub('LibKeyBound-1.0',true)==nil)`);
    console.log('PASS: bundled registry/callbacks run with external libraries unavailable and public registry poisoned');
}
const state = lauxlib.luaL_newstate();
lualib.luaL_openlibs(state);
lua.lua_pushstring(state, to_luastring(source));
lua.lua_setglobal(state, to_luastring('SOURCE'));
const tests = fs.readFileSync(path.join(__dirname, 'forever-actionbars.test.lua'), 'utf8');
if (lauxlib.luaL_dostring(state, to_luastring(tests)) !== lua.LUA_OK) {
    throw Error(to_jsstring(lua.lua_tostring(state, -1)));
}
