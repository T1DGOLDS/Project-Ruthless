const fs=require('fs'),path=require('path'),assert=require('assert');
const root=path.resolve(__dirname,'..');
const parser=require(path.join(root,'node_modules/luaparse'));
const {lua,lauxlib,lualib,to_luastring,to_jsstring}=require(path.join(root,'node_modules/fengari'));
const L=lauxlib.luaL_newstate();lualib.luaL_openlibs(L);
for(const name of ['SettingsRegistry','QuestSupplyData','QuestSupplies','AuctionHouse','AuctionHouseUI','AuctionMarket','ForeverMeters']){
 const source=fs.readFileSync(path.join(root,'Modules',name+'.lua'),'utf8');parser.parse(source,{luaVersion:'5.1'});
 if(name==='AuctionHouse')assert(!/C_AuctionHouse\.(?:PlaceBid|PostItem|PostCommodity|CancelAuction|ConfirmCommoditiesPurchase)\s*\(/.test(source),'RUI must leave transaction execution/confirmation to the native controls');
 lua.lua_pushstring(L,to_luastring(source));lua.lua_setglobal(L,to_luastring(name.toUpperCase()+'_SOURCE'));
}
const native=process.env.PR_WOW_FOREVER_SOURCE;assert(native,'Set PR_WOW_FOREVER_SOURCE');
function read(file){return fs.readFileSync(path.join(native,file),'utf8');}
const frame=read('Blizzard_AuctionHouseUI/Shared/Blizzard_AuctionHouseFrame.lua');
for(const method of ['SelectBrowseResult','SendBrowseQuery','SetDisplayMode','QueryAll'])assert(frame.includes('function AuctionHouseFrameMixin:'+method+'('));

const display=frame.match(/AuctionHouseFrameDisplayMode = \{[\s\S]*?\n\};/)[0];
const displayMethod=frame.match(/function AuctionHouseFrameMixin:SetDisplayMode\(displayMode\)[\s\S]*?(?=function AuctionHouseFrameMixin:GetDisplayMode)/)[0];
lua.lua_pushstring(L,to_luastring(display+'\nAuctionHouseFrameMixin={}\n'+displayMethod));lua.lua_setglobal(L,to_luastring('NATIVE_AUCTION_DISPLAY'));
const sell=read('Blizzard_AuctionHouseUI/Shared/Blizzard_AuctionHouseSellFrame.lua');
for(const method of ['GetMaxQuantity','UpdatePostState','GetQuantity','GetDuration'])assert(sell.includes('function AuctionHouseSellFrameMixin:'+method+'('));
const queryAPI=read('Blizzard_APIDocumentationGenerated/AuctionHouseDocumentation.lua');
for(const api of ['IsThrottledMessageSystemReady','HasFullCommoditySearchResults','HasFullItemSearchResults','MakeItemKey','ReplicateItems','GetNumReplicateItems','GetReplicateItemInfo'])assert(queryAPI.includes('Name = "'+api+'"'));
const cancel=frame.match(/StaticPopupDialogs\["CANCEL_AUCTION"\] = \{[\s\S]*?\n\};/);assert(cancel);
lua.lua_pushstring(L,to_luastring(cancel[0]));lua.lua_setglobal(L,to_luastring('CANCEL_DIALOG'));
for(const [key,file]of [['MENU_SOURCE','ProjectRuthless_Options/Menu.lua'],['PROFILES_SOURCE','Modules/Profiles.lua']]){
 lua.lua_pushstring(L,to_luastring(fs.readFileSync(path.join(root,file),'utf8')+(key==='MENU_SOURCE'?'\n'+fs.readFileSync(path.join(root,'ProjectRuthless_Options/SettingsPages.lua'),'utf8'):'')));lua.lua_setglobal(L,to_luastring(key));
}
assert(read('Blizzard_AuctionHouseUI/Blizzard_AuctionHouseUI.toc').includes('[Game]\\Blizzard_AuctionData.lua [AllowLoadGameType camelot]'));
const ref=JSON.parse(fs.readFileSync(path.join(root,'Assets/QuestSupplies/Reference.json'),'utf8'));
assert.equal(Object.keys(ref.quests).length,ref.clientRecords);assert.equal(ref.clientRecords,6614);
assert.equal(ref.quests[38].items.find(x=>x[0]===731)[1],3);
assert(ref.quests[38].status==='reference'&&ref.quests[92909].status==='unknown');
assert(ref.counts.unknown>3000&&ref.counts.reference>350);
if(lauxlib.luaL_dostring(L,to_luastring(fs.readFileSync(path.join(__dirname,'auction-house.test.lua'),'utf8')))!==lua.LUA_OK)throw Error(to_jsstring(lua.lua_tostring(L,-1)));
