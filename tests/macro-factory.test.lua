unpack=table.unpack
local AUI={isForever=true,modules={}}
function AUI:RegisterModule(id,module)self.modules[id]=module end
function AUI:Print(message)self.lastMessage=message end
function AUI:StyleSurface()end
ProjectRuthlessDB={spellbook={state={selectedMacros={},selectedMacroKeys={}},macroBackups={}}}
Constants={MacroConsts={MAX_ACCOUNT_MACROS=120,MAX_CHARACTER_MACROS=30}}
RAID_CLASS_COLORS={MAGE={r=.2,g=.8,b=1}}
function UnitClass()return 'Mage','MAGE'end
function strtrim(v)return(v or ''):match('^%s*(.-)%s*$')end
local combat=false;function InCombatLockdown()return combat end
assert(load(CATALOGUE))('ProjectRuthless',AUI);assert(load(SPELLBOOK))('ProjectRuthless',AUI)
local book=AUI.modules.Spellbook;local catalogue=AUI.MacroTemplates:Catalogue();local byID={}
local markers,pings,starters=0,0,0
for _,entry in ipairs(catalogue)do
 assert(not byID[entry.id]);byID[entry.id]=entry;assert(#entry.body<=255 and #entry.macroName<=16 and #entry.explanation>25)
 if entry.category=='Markers'then markers=markers+1 end
 if entry.category=='Pings'then pings=pings+1 end
 if entry.examples then starters=starters+1;for _,class in ipairs(AUI.MacroTemplates.classes)do assert(type(entry.examples[class])=='string'and #entry.examples[class]>30)end end
end
assert(markers==9 and pings==7 and starters==11 and #catalogue==33)
assert(byID.marker8.body:find('!8',1,true)and byID.marker0.body:find(' 0',1,true))
assert(byID.targettarget.body:find('@targettarget,harm,nodead',1,true))
assert(byID.cursor.examples.PALADIN:find('not with a reticle',1,true))
print('PASS: nine markers, seven pings, six tools, eleven explained starters and all nine class examples; no invalid-size macros or reticle claims')

local Frame={};Frame.__index=Frame
function Frame:SetScript(k,fn)self.scripts[k]=fn end
function Frame:HookScript(k,fn)local before=self.scripts[k];self.scripts[k]=function(...)if before then before(...)end;fn(...)end end
function Frame:Show()self.shown=true;if self.scripts.OnShow then self.scripts.OnShow(self)end end
function Frame:Hide()self.shown=false end
function Frame:IsShown()return self.shown end
function Frame:SetShown(v)self.shown=v end
function Frame:SetText(v)self.text=v end;function Frame:GetText()return self.text or ''end
function Frame:SetSize(w,h)self.w=w;self.h=h end
function Frame:SetWidth(w)self.w=w end;function Frame:SetHeight(h)self.h=h end
function Frame:GetWidth()return self.w or self.parent and self.parent:GetWidth()or 640 end
function Frame:GetHeight()return self.h or 500 end
function Frame:GetFrameLevel()return 1 end
function Frame:SetAllPoints(parent)parent=parent or self.parent;self.w=parent:GetWidth();self.h=parent:GetHeight()end
function Frame:SetPoint(point,...)self.points[point]={...}end
function Frame:ClearAllPoints()self.points={}end
function Frame:CreateFontString()return setmetatable({parent=self,scripts={},points={},font=true},Frame)end
local textScale=1
function Frame:GetStringHeight()
 local lines=0;for line in ((self.text or '')..'\n'):gmatch('(.-)\n')do lines=lines+math.max(1,math.ceil(#line/math.max(1,math.floor(self:GetWidth()/(6*textScale)))))end
 return lines*12*textScale
end
for _,method in ipairs({'SetBackdrop','SetBackdropBorderColor','SetBackdropColor','SetTextColor','SetJustifyH','SetEnabled','SetAlpha','SetFrameLevel','SetCursorPosition','SetFocus','HighlightText','SetTexture'})do Frame[method]=function(self,value)self[method]=self[method]or value end end
function CreateFrame(_,_,parent)return setmetatable({parent=parent,scripts={},points={},shown=false},Frame)end
function AUI:CreateButton(parent)return CreateFrame('Button',nil,parent)end
function AUI:CreateSmoothScrollFrame(parent)
 local f=CreateFrame('ScrollFrame',nil,parent);f.w=420
 function f:SetScrollChild(child)self.content=child end
 function f:SetVerticalScroll(value)self.offset=value end
 return f
end
function AUI:CreateListScroll(parent)
 local f=self:CreateSmoothScrollFrame(parent);f.content=CreateFrame('Frame',nil,f)
 function f:SetItemCount(n)self.count=n end;function f:GetItemOffset()return self.offset or 0 end
 function f:ScrollTo()self.offset=0 end;function f:PlaceItem(row,index)row.index=index end
 return f
end
local bank={[1]={'Existing',134400,'/say existing'},[121]={'Character',134400,'/say keep'}}
local writes,edits,pingCalls,reloads=0,0,0,0
local full=false
function GetNumMacros()local a,c=0,0;for id in pairs(bank)do if id>120 then c=c+1 else a=a+1 end end;return a,full and 30 or c end
function GetMacroInfo(id)local row=bank[id];if row then return unpack(row)end end
function CreateMacro(name,icon,body,character)
 assert(not combat);writes=writes+1;local a,c=GetNumMacros();local id=character and 120+c+1 or a+1;bank[id]={name,icon,body};return id
end
function EditMacro()edits=edits+1 end
function ReloadUI()reloads=reloads+1 end
book.macroScope='character';book.selectedMacro=121
book.SelectMacro=function(self,id)self.selectedMacro=id;self.macroDirty=false end
book.macroView=CreateFrame('Frame');book.macroView:SetSize(672,516)
book:ShowMacroTemplates();assert(writes==0 and not book.newMacroDraft,'browsing the factory must not create an empty draft')
assert(book.templateScroll.count==33 and book.templateSelected.id=='marker8')
for _,scale in ipairs({1,1.25,1.5})do textScale=scale;book:RefreshMacroTemplateFactory();local cat=book.templateCategoryButtons[1].points.TOPLEFT
 assert(-cat[2]>=36+book.templateHint:GetStringHeight()+9)
 assert(book.templateDetail:GetHeight()>=book.templateExplanation:GetStringHeight()+19)
end
local id=book:CreateUtilityMacro(byID.marker8);assert(id==122 and writes==1 and edits==0 and bank[121][3]=='/say keep')
assert(book:CreateUtilityMacro(byID.marker8)==id and writes==1)
book.macroDirty=true;assert(not book:CreateUtilityMacro(byID.reload)and writes==1);book.macroDirty=false
combat=true;assert(not book:CreateUtilityMacro(byID.reload)and writes==1);combat=false
full=true;assert(not book:CreateUtilityMacro(byID.reload)and writes==1);full=false
assert(not book:CreateUtilityMacro(byID.ping1)and writes==1)
C_Ping={SendMacroPing=function()pingCalls=pingCalls+1 end}
assert(book:CreateUtilityMacro(byID.ping1)and writes==2 and pingCalls==0)
assert(book:CreateUtilityMacro(byID.reload)and writes==3 and reloads==0)
book.macroScope='account';assert(book:CreateUtilityMacro(byID.marker8)==2 and writes==4,'banks remain independent')
assert(book.templateRows[1].entry and not book.templatePanel.scripts.OnUpdate)
print('PASS: lazy/read-only browsing, scroll/detail reflow at 100/125/150%, explicit utility creation, exact deduplication, separate banks, dirty/combat/full guards and no ping/reload execution')

book.macroScope='character';book.macroDirty=false
book.macroName=CreateFrame('EditBox');book.macroEditor=CreateFrame('EditBox');book.macroIcon=CreateFrame('Texture')
book.macroEmpty=CreateFrame('Frame');book.macroDetails=CreateFrame('Frame');book.saveMacroButton=CreateFrame('Button')
book.AnalyseMacro=function()end;book.RefreshMacroList=function()end
local before=writes;book:ApplyMacroTemplate(byID.targettarget)
assert(book.newMacroDraft and book.selectedMacro==nil and book.macroDirty and writes==before and book.macroEditor:GetText()==byID.targettarget.body)
local body=book.macroEditor:GetText();book:ApplyMacroTemplate(byID.cursor);assert(book.macroEditor:GetText()==body,'unsaved starter must be preserved')
book.macroDirty=false;full=true;book.newMacroDraft=false;book:ApplyMacroTemplate(byID.cursor);assert(not book.newMacroDraft and book.macroEditor:GetText()==body);full=false
print('PASS: spell starters create fresh unsaved drafts; placeholder editing requires Save and never overwrites selected macros or dirty drafts')
