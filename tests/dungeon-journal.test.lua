local F={};F.__index=F
local function frame(parent)return setmetatable({parent=parent,w=320,h=50,scripts={},shown=true},F)end
function F:SetSize(w,h)self.w=w;self.h=h end
function F:SetWidth(v)self.w=v end;function F:SetHeight(v)self.h=v end
function F:GetWidth()return self.w end;function F:GetHeight()return self.h end
function F:SetText(text)self.text=text;if self.label then self.label.text=text end;if self.scripts.OnTextChanged then self.scripts.OnTextChanged(self)end end
function F:GetText()return self.text or ''end
function F:GetStringHeight()return math.max(12,math.ceil(#(self.text or '')/math.max(8,self.w/6))*12)end
function F:CreateFontString()return frame(self)end;function F:CreateTexture()return frame(self)end
function F:Show()self.shown=true end;function F:Hide()self.shown=false end
function F:IsShown()return self.shown end;function F:IsVisible()return self.shown end
function F:SetScript(k,v)self.scripts[k]=v end;function F:HookScript(k,v)self.scripts[k]=v end
function F:ClearAllPoints()self.point=nil end;function F:SetPoint(...)self.point={...}end
function F:SetJustifyH()end;function F:SetTextColor()end;function F:SetFrameStrata()end;function F:SetFrameLevel()end
function F:GetFrameStrata()return 'MEDIUM'end;function F:GetFrameLevel()return 5 end
function F:SetBackdrop()end;function F:SetAllPoints()end;function F:EnableMouse()end;function F:SetAtlas(v)self.atlas=v end
function F:SetTexture(v)self.texture=v end;function F:SetAutoFocus()end;function F:SetFocus()end;function F:HighlightText()end
function F:RegisterEvent(k)self.event=k end;function F:UnregisterEvent()self.event=nil end;function F:SetParent(p)self.parent=p end
function CreateFrame(_,_,parent)return frame(parent)end
local AUI={modules={},isForever=true}
function AUI:RegisterModule(k,m)self.modules[k]=m end
function AUI:CreateButton(parent)local b=frame(parent);b.label=frame(b);return b end
function AUI:StyleSurface()end;function AUI:Print(s)self.message=s end
local pending={};C_Timer={After=function(_,fn)pending[#pending+1]=fn end}
function issecretvalue(v)return v=='SECRET'end
function UnitClass()return 'Mage','MAGE'end;function UnitFactionGroup()return 'Alliance'end;function UnitLevel()return 20 end
local combat=false;function InCombatLockdown()return combat end
C_QuestLog={IsQuestFlaggedCompleted=function()return false end,GetTitleForQuestID=function(id)return 'Quest '..id end}
C_Item={GetItemInfo=function()end,GetItemCount=function()return 0 end}
UIParent=frame();WorldMapFrame=frame(UIParent);WorldMapFrame.ScrollContainer=frame(WorldMapFrame)
local currentMap=1;local mapWrites=0
function WorldMapFrame:GetMapID()return currentMap end
function WorldMapFrame:SetMapID(id)currentMap=id;mapWrites=mapWrites+1 end
function WorldMapFrame:GetCanvas()return self.ScrollContainer end
C_Map={GetMapInfo=function(id)return {name='Map '..id}end,GetMapArtLayers=function(id)if id==42 or id==43 then return {{layerWidth=1000,layerHeight=700}}end end,
 GetMapGroupID=function()return 2 end,GetMapGroupMembersInfo=function()return {{mapID=42,name='Upper'},{mapID=43,name='Lower'}}end}
AUI.modules.QuestLocations={mapping={[1581]=42},Database=function()return nil end}
local tips={};GameTooltip={SetOwner=function()end,SetText=function()end,SetItemByID=function(_,id)tips.item=id end,SetSpellByID=function(_,id)tips.spell=id end,AddLine=function(_,s)tips.note=s end,Show=function()end,Hide=function()end}
assert(load(FACTS))();assert(load(ATLAS))('RUI',AUI);assert(load(JOURNAL))('RUI',AUI)
local D=AUI.modules.DungeonAtlas;local catalog=D:Load();assert(#catalog==35 and D:Load()==catalog)
for _,entry in ipairs(catalog)do assert(entry.record.LevelRange[3]<=60);assert(not entry.key:find('auchenai'))end
local q={mapPage='Dungeon atlas',mapContent=frame(),mapCopy=frame(),mapHeading=frame(),mapPanel=frame(),entries={}}
function q:RenderMapPage()D:Render(self)end
function q:SetMapBack(label,fn)self.back=fn;self.backText=label end
function q:ShareDungeonQuest()return false,'Not currently shareable'end
D:Render(q);assert(D.journalSearch:IsShown()and D.rows[1].text:find('Levels'))
D.searchText='deadmines';D:Render(q);assert(D.rows[1].text:find('Deadmines'))
D.searchText='nonsense_missing_foo';D:Render(q);assert(D.rows[1].text=='No matching dungeons, bosses or items')
D.searchText='';local selected
for _,e in ipairs(catalog)do if e.key=='the-deadmines'then selected=e end end
D.selected=selected;D.view='Overview';D:Render(q);assert(#D.journalTabs==6 and q.backText=='‹ Dungeons')
D.view='Bosses';D.boss=1;D:Render(q);assert(q.backText=='‹ Bosses')
local foundItem=false
for _,row in ipairs(D.rows)do if row.shown and row.item then row.scripts.OnEnter(row);assert(tips.item and tips.note:find('not published',1,true));foundItem=true;break end end
assert(foundItem);q.back();assert(not D.boss)
D.view='Quests';D:Render(q)
local paladin;for _,quest in ipairs(selected.record.quests)do if quest.id==1654 then paladin=quest end end
assert(paladin and not D:RelevantQuest(paladin),'other-class spell quests must be excluded')
D.quest=selected.record.quests[1];D:Render(q);assert(q.backText=='‹ Quests');q.back();assert(not D.quest)
local marker
AUI.modules.MapPins={AddWorldMapIconMap=function(_,owner,icon,map,x,y)marker={owner=owner,map=map,x=x,y=y}end,RemoveAllWorldMapIcons=function()marker=nil end}
AUI.modules.QuestData={GetDatabase=function()end,mapNames={['Stormwind City']=1453}}
D.quest=selected.record.quests[1];D:ShowPickup(D.quest);assert(marker and marker.map==1453 and marker.owner==D)
D:Render(q);assert(marker and marker.map==1453,'pickup marker must survive an item-data redraw')
D.quest=nil
D.view='Maps';D:Render(q);assert(currentMap==42);D.rows[2].scripts.OnClick();assert(currentMap==43)
D:Render(q);assert(currentMap==43,'item refresh must preserve the selected floor')
local writes=mapWrites;D:Render(q);assert(mapWrites==writes,'repeated render must not reselect the same native floor')
local gap
for _,e in ipairs(catalog)do if e.key=='the-drowned-city'then gap=e end end
D.selected=gap;D.view='Maps';D.nativeFloor=nil;D:Render(q);assert(mapWrites==writes and D.journalSummaries[1].text:find('not available'))
D.view='Overview';D:Render(q);assert(D.journalSummaries[1].shown and D.journalSummaries[2].shown,'summary blocks must not overwrite each other')
D.selected=selected;D.view='Loot';combat=true;D:Render(q);assert(mapWrites==writes);combat=false
D:Hide();assert(not D.journalTabs[1].shown and not D.journalSummaries[1].shown and not D.rows[1].shown)
print('PASS: current Forever catalog, level/search order, six journal views/back, class filtering, honest drop-rate gaps, missing-map handling, floor persistence, isolated pooled surfaces and combat browsing')
