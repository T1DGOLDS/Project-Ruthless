const fs=require('fs');const root='F:/Github/Project-Ruthless/';const {lua,lauxlib,lualib,to_luastring,to_jsstring}=require(root+'node_modules/fengari');
const L=lauxlib.luaL_newstate();lualib.luaL_openlibs(L);
function run(s){if(lauxlib.luaL_dostring(L,to_luastring(s)))throw Error(to_jsstring(lua.lua_tostring(L,-1)))}
const src='C:/World of Warcraft/_classic_beta_/Interface/AddOns/AtlasLootClassic_DungeonsAndRaids/';
let area={};for(const m of fs.readFileSync('work/atlas-reference/Data/AreaIDs_ClassicTBC.lua','utf8').matchAll(/\["([^"]+)"\]\s*=\s*(\d+)/g))area[m[2]]=m[1];
run(`getfenv=function()return _G end
FACTION_ALLIANCE='Alliance';FACTION_HORDE='Horde';ATLASLOOT_IT_ALLIANCE=91;ATLASLOOT_IT_HORDE=92
UnitFactionGroup=function()return 'Alliance'end
C_Map={GetAreaInfo=function(id)return AREA_NAMES[tostring(id)] or ('Zone '..id)end}
AREA_NAMES={}
local records={};local diffs={};local count=0
function addDifficulty(self,name)if not diffs[name]then count=count+1;diffs[name]=count end;return diffs[name]end
records.AddDifficulty=addDifficulty;records.AddContentType=function()return 1 end;records.AddItemTableType=function()return 1 end;records.AddExtraItemTableType=function()return 1 end
local locales=setmetatable({},{__index=function(_,key)return key end})
AtlasLoot={CLASSIC_VERSION_NUM=1,BC_VERSION_NUM=2,WRATH_VERSION_NUM=3,Locales=locales,IngameLocales=locales,ItemDB={Add=function()return records end},ReturnForGameVersion=function(classic)return classic end,Data={ContentPhase={GetActivePhase=function()return 7 end}},GameVersion_EQ=function(_,version)return version==1 end,GameVersion_GE=function(_,version)return version<=1 end,GameVersion_LT=function(_,version)return 1<version end}
CreateFrame=function()return {SetScript=function()end}end
RECORDS=records;DIFFS=diffs
`);
for(const [id,name]of Object.entries(area))run(`AREA_NAMES[${JSON.stringify(id)}]=${JSON.stringify(name)}`);
let constants=new Set();for(const file of ['data.lua','data-tbc.lua'])for(const m of fs.readFileSync(src+file,'utf8').matchAll(/ATLASLOOT_[A-Z0-9_]+/g))constants.add(m[0]);let ci=100;for(const name of constants)run(name+'='+ci++);
for(const file of ['data.lua','data-tbc.lua']){if(file==='data-tbc.lua')run('AtlasLoot.GameVersion_LT=function()return false end;AtlasLoot.GameVersion_GE=function(_,v)return v<=2 end');let s=fs.readFileSync(src+file,'utf8');s=s.split('local pulseEngine =')[0];run(s)}
run(`
local output={}
local function encode(v)
 local kind=type(v);if kind=='string'then return string.format('%q',v)elseif kind=='number'or kind=='boolean'then return tostring(v)elseif kind~='table'then return 'nil'end
 local fields={};for k,val in pairs(v)do if type(val)~='function'then fields[#fields+1]='['..encode(k)..']='..encode(val)end end;table.sort(fields);return '{'..table.concat(fields,',')..'}'
end
for key,record in pairs(RECORDS)do
 if type(record)=='table'and record.InstanceID and record.items and record.LevelRange then
  local r={name=record.name,InstanceID=record.InstanceID,MapID=record.MapID,LevelRange=record.LevelRange,AtlasMapFile=record.AtlasMapFile,AtlasMapFile_AL=record.AtlasMapFile_AL,LoadDifficulty=1,items={}}
  for _,boss in ipairs(record.items)do if type(boss)==\'table\'then
   local b={name=boss.name,npcID=boss.npcID,AtlasMapFile=boss.AtlasMapFile,loot={}}
   for _,name in ipairs({'NORMAL','HEROIC','20RAID','40RAID','10RAID','25RAID'})do
    local diff=DIFFS[name];local entries=diff and boss[diff]
    if type(entries)=='number'then entries=boss[entries]end
    if type(entries)=='table'and entries.GetItemsFromDiff then entries=boss[entries.GetItemsFromDiff]end
    local list={};for _,entry in ipairs(type(entries)=='table'and entries or {})do if type(entry)=='table'and type(entry[2])=='number'and entry[2]>0 then list[#list+1]={entry[1],entry[2]}end end
    if #list>0 then b.loot[name]=list end
   end
   r.items[#r.items+1]=b end
  end
  output[key]=r
 end
end
EXPORT='RUI_DungeonData='..encode(output)
`);
lua.lua_getglobal(L,to_luastring('EXPORT'));const out=to_jsstring(lua.lua_tostring(L,-1));
const folder=root+'ProjectRuthless_DungeonData/';fs.mkdirSync(folder,{recursive:true});fs.writeFileSync(folder+'Records.lua','-- Derived loot/map records; see SOURCE.md for provenance and GPL terms.\n'+out+'\n');
fs.copyFileSync('C:/World of Warcraft/_classic_beta_/Interface/AddOns/AtlasLootClassic/LICENSE',folder+'LICENSE-GPL-2.0.txt');
fs.writeFileSync(folder+'SOURCE.md',`# Bundled dungeon records\n\nDerived from installed AtlasLoot Forever 1.60.1 data.lua and data-tbc.lua (GPL v2), originally https://github.com/Hoizame/AtlasLootClassic. Records retain GPL terms; see included license. Normal/heroic/raid numeric loot entries are preserved separately. UI scripts, libraries and animations are not copied. Tables are reference data, not a guarantee of live Forever loot completeness. Original data source and export script are retained under Source/ for reproducibility.\n`);
fs.mkdirSync(folder+'Source',{recursive:true});for(const file of ['data.lua','data-tbc.lua'])fs.copyFileSync(src+file,folder+'Source/'+file);fs.copyFileSync(__filename,folder+'Source/export.cjs');
fs.writeFileSync(folder+'ProjectRuthless_DungeonData.toc','## Interface: 16001, 120001\n## Title: RUI Dungeon Data\n## Version: 0.14.0-beta.28\n## LoadOnDemand: 1\nRecords.lua\n');
console.log('Exported '+out.length+' bytes');
