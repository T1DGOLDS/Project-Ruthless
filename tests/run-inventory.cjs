const fs=require('fs'),path=require('path'),assert=require('assert');
const root=path.resolve(__dirname,'..'),parser=require(path.join(root,'node_modules/luaparse'));
const {lua,lauxlib,lualib,to_luastring,to_jsstring}=require(path.join(root,'node_modules/fengari'));
const source=fs.readFileSync(path.join(root,'Modules/ForeverInventory.lua'),'utf8');parser.parse(source,{luaVersion:'5.1'});
const native=process.env.PR_WOW_FOREVER_SOURCE;assert(native,'Set PR_WOW_FOREVER_SOURCE');
const container=fs.readFileSync(path.join(native,'Blizzard_UIPanels_Game/Mainline/ContainerFrame.lua'),'utf8');
const names=['UpdateItemSlots','MatchesBagID','IsBagOpen','IsUsingCombinedBags','Initialize','SetBagSize'];
for(const name of names)assert(container.includes(':'+name+'('));
const init=container.match(/function ContainerFrameItemButtonMixin:Initialize\([^)]*\)[\s\S]*?(?=function ContainerFrameItemButtonMixin:UpdateQuestItem)/)[0];
const routing=container.match(/function ContainerFrameSettingsManager:IsUsingCombinedBags\(optionalID\)[\s\S]*?(?=function ContainerFrameSettingsManager:SetUsingCombinedBags)/)[0];
const update=container.match(/function ContainerFrameMixin:UpdateItemSlots\(\)[\s\S]*?(?=function ContainerFrameMixin:UpdateItemLayout)/)[0];
for(const [label,initializer,actualUpdate]of [['current native',init,update],['historical regression',fs.readFileSync(path.join(root,'tests/fixtures/container-initialize-legacy.lua'),'utf8'),'']]){
 const L=lauxlib.luaL_newstate();lualib.luaL_openlibs(L);
 const withContainer=/Initialize\(containerFrame, bag, slot\)/.test(initializer);
 for(const [name,value]of [['INVENTORY_SOURCE',source],['NATIVE_ITEM_INITIALIZE',initializer],['NATIVE_BAG_ROUTING',routing],['NATIVE_ITEM_SLOTS',actualUpdate],['CONTRACT_LABEL',label]]){lua.lua_pushstring(L,to_luastring(value));lua.lua_setglobal(L,to_luastring(name));}
 lua.lua_pushboolean(L,withContainer);lua.lua_setglobal(L,to_luastring('CONTAINER_ARGUMENT'));
 if(lauxlib.luaL_dostring(L,to_luastring(fs.readFileSync(path.join(__dirname,'inventory.test.lua'),'utf8')))!==lua.LUA_OK)throw Error(label+': '+to_jsstring(lua.lua_tostring(L,-1)));
}
