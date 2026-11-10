local _,AUI=...
local H={};AUI:RegisterModule("SpiritHealers",H)
local TEMPLATE="RUISpiritHealerPinTemplate"
local function public(v)return not(issecretvalue and issecretvalue(v))end
local function read(fn,...)
 if type(fn)~="function"then return end
 local ok,a,b=pcall(fn,...);if ok and public(a)and public(b)then return a,b end
end
local function number(v)return public(v)and type(v)=="number"and v==v and math.abs(v)<1e8 end
local function xy(pos)
 if not pos or not public(pos)then return end
 local x,y=read(pos.GetXY,pos);if number(x)and number(y)and x>=0 and x<=1 and y>=0 and y<=1 then return x,y end
end
local function settings()return ProjectRuthlessDB and ProjectRuthlessDB.mapQuests or {}end
function H:Locations(mapID)
 if settings().showSpiritHealers==false then return {}end
 local points,native={},{}
 local function add(x,y,name,source,release,owned)
  if not number(x)or not number(y)then return end
  for _,p in ipairs(points)do if math.abs(p.x-x)<.003 and math.abs(p.y-y)<.003 then
   if release then p.release=true end
   return
  end end
  points[#points+1]={x=x,y=y,name=name or "Spirit healer",source=source,release=release,native=owned}
 end
 local list=read(C_DeathInfo and C_DeathInfo.GetGraveyardsForMap,mapID)
 if type(list)=="table"then for _,row in ipairs(list)do if public(row)then
  local x,y=xy(row.position)
  local name=public(row.name)and type(row.name)=="string"and row.name or nil
  if x then add(x,y,name,"Supplied by the game",false,true);native[#native+1]={x=x,y=y}end
 end end end
 for _,p in ipairs(AUI.TravelData and AUI.TravelData.healers or {})do
  if p.map==mapID then add(p.x,p.y,"Spirit healer","Recorded Forever location; phase may vary")end
 end
 local dead=read(UnitIsDeadOrGhost,"player")
 local release=dead and read(C_DeathInfo and C_DeathInfo.GetDeathReleasePosition,mapID)
 local x,y=xy(release)
 if x then add(x,y,"Release destination","Current destination supplied by the game",true)end
 return points
end
-- A nearest-location estimate, not the server's death-release rule. Distances
-- use world-map dimensions, so wide maps do not distort the partitions.
function H:Region(points,index,width,height)
 local own=points[index];if not own then return {}end
 local poly={{0,0},{1,0},{1,1},{0,1}};width=width or 1;height=height or 1
 for j,p in ipairs(points)do if j~=index then
  local a=2*(p.x-own.x)*width*width;local b=2*(p.y-own.y)*height*height
  local c=(p.x*p.x-own.x*own.x)*width*width+(p.y*p.y-own.y*own.y)*height*height
  local clipped={}
  for i,v in ipairs(poly)do
   local prev=poly[i==1 and #poly or i-1];local d=a*v[1]+b*v[2]-c;local before=a*prev[1]+b*prev[2]-c
   if (d<=0)~=(before<=0)then local t=before/(before-d);clipped[#clipped+1]={prev[1]+(v[1]-prev[1])*t,prev[2]+(v[2]-prev[2])*t}end
   if d<=0 then clipped[#clipped+1]=v end
  end
  poly=clipped;if #poly==0 then break end
 end end
 return poly
end
function H:ClearCoverage()
 for _,line in ipairs(self.lines or {})do line:Hide()end
 if self.caption then self.caption:Hide()end
end
function H:DrawCoverage(index)
 self:ClearCoverage()
 if not self.provider or settings().showSpiritCoverage~=true or settings().showSpiritHealers==false then return end
 local map=self.provider:GetMap();local points=self.points or {};if #points<2 then return end
 local canvas=map:GetCanvas();local w,h=canvas:GetWidth(),canvas:GetHeight()
 if not number(w)or not number(h)or w<=0 or h<=0 then return end
 local ww,wh=read(C_Map and C_Map.GetMapWorldSize,map:GetMapID())
 if not number(ww)or not number(wh)or ww<=0 or wh<=0 then return end
 if not self.overlay then
  self.overlay=CreateFrame("Frame",nil,canvas);self.overlay:SetAllPoints(canvas);self.overlay:EnableMouse(false)
  self.overlay:SetFrameLevel(canvas:GetFrameLevel()+1);self.lines={}
  self.caption=self.overlay:CreateFontString(nil,"OVERLAY","GameFontNormalSmall")
  self.caption:SetPoint("BOTTOM",canvas,"BOTTOM",0,28);self.caption:SetText("Spirit-healer areas: estimates · hover a healer to isolate")
 end
 self.caption:Show();local used=0
 for i=1,#points do if not index or i==index then
  local poly=self:Region(points,i,ww,wh)
  for k,v in ipairs(poly)do
   local nextPoint=poly[k==#poly and 1 or k+1];used=used+1
   local line=self.lines[used]
   if not line then line=self.overlay:CreateLine(nil,"ARTWORK");self.lines[used]=line;line:SetThickness(1.5)end
   line:SetStartPoint("TOPLEFT",canvas,v[1]*w,-v[2]*h);line:SetEndPoint("TOPLEFT",canvas,nextPoint[1]*w,-nextPoint[2]*h)
   line:SetColorTexture(.35+.45*(i%3)/2,.65,.95,index and .85 or .35);line:Show()
  end
 end end
end
function H:Install()
 if self.provider or not WorldMapFrame or not MapCanvasDataProviderMixin or not MapCanvasPinMixin then return end
 for k,v in pairs(MapCanvasPinMixin)do if RUISpiritHealerPinMixin[k]==nil then RUISpiritHealerPinMixin[k]=v end end
 local p=CreateFromMixins(MapCanvasDataProviderMixin);self.provider=p
 function p:RemoveAllData()self:GetMap():RemoveAllPinsByTemplate(TEMPLATE);H:ClearCoverage()end
 function p:RefreshAllData()
  self:RemoveAllData();H.points=H:Locations(self:GetMap():GetMapID())
  for i,point in ipairs(H.points)do
   -- Native graveyard pins retain selection and click handling. Overlay only
   -- an actual-release marker when needed, and recorded outdoor healers.
   if not point.native or point.release then self:GetMap():AcquirePin(TEMPLATE,point,i)end
  end
  H:DrawCoverage()
 end
 function p:OnCanvasSizeChanged()H:DrawCoverage()end
 function p:OnHide()H:ClearCoverage()end
 WorldMapFrame:AddDataProvider(p)
end
function H:ApplySettings()
 self:Install();if self.provider and WorldMapFrame:IsShown()then self.provider:RefreshAllData()end
end
function H:OnPlayerLogin()
 if not AUI.isForever then return end
 self:Install();self.events=CreateFrame("Frame")
 for _,event in ipairs({"ADDON_LOADED","PLAYER_DEAD","PLAYER_ALIVE","PLAYER_UNGHOST","CEMETERY_PREFERENCE_UPDATED","REQUEST_CEMETERY_LIST_RESPONSE"})do self.events:RegisterEvent(event)end
 self.events:SetScript("OnEvent",function(_,event,addon)if event~="ADDON_LOADED"or addon=="Blizzard_WorldMap"then H:ApplySettings()end end)
end
RUISpiritHealerPinMixin={}
function RUISpiritHealerPinMixin:OnLoad()
 self:UseFrameLevelType("PIN_FRAME_LEVEL_AREA_POI");self:SetScalingLimits(1,1,1.2)
 self.Icon:SetAtlas("poi-graveyard-neutral")
end
function RUISpiritHealerPinMixin:OnAcquired(point,index)
 self.point=point;self.index=index;self:SetPosition(point.x,point.y)
 self.Icon:SetVertexColor(point.release and .4 or 1,1,1)
end
function RUISpiritHealerPinMixin:OnMouseEnter()
 local p=self.point;GameTooltip:SetOwner(self,"ANCHOR_RIGHT");GameTooltip:SetText(p.release and "Current release destination"or p.name)
 GameTooltip:AddLine(p.source,.8,.85,.9,true)
 GameTooltip:AddLine(("%.1f, %.1f"):format(p.x*100,p.y*100),.7,.75,.8)
 if settings().showSpiritCoverage then GameTooltip:AddLine("Outlined areas estimate the nearest recorded healer, not guaranteed respawn coverage. Server rules, terrain, phase and neighbouring zones can differ.",1,.8,.4,true)end
 GameTooltip:Show();H:DrawCoverage(self.index)
end
function RUISpiritHealerPinMixin:OnMouseLeave()GameTooltip:Hide();H:DrawCoverage()end
