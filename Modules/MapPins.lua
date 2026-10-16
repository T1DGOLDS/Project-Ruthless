local _,AUI=...
-- RUI-owned positioning for visual-only markers. Native pins remain untouched.
local P={world={},mini={}}
AUI:RegisterModule("MapPins",P)
local function public(v)return not(issecretvalue and issecretvalue(v))end
local function read(fn,...)
 if type(fn)~="function"then return end
 local ok,a,b=pcall(fn,...);if ok and public(a)and public(b)then return a,b end
end
local function xy(pos)
 if not pos then return end
 local x,y=read(pos.GetXY,pos)
 if type(x)=="number"and type(y)=="number"then return x,y end
end
function P:Project(record,map)
 if record.map==map then return record.x,record.y end
 if not C_Map or not CreateVector2D then return end
 -- Retain static transforms on each registered marker, not across player data.
 local cached=record.projection
 if cached and cached.map==map then return cached.x,cached.y end
 local target=self.projectionTarget
 if not target or target.map~=map or not target.continent then
  target={map=map,continent=read(C_Map.GetWorldPosFromMapPos,map,CreateVector2D(.5,.5))};self.projectionTarget=target
 end
 local continent,pos=read(C_Map.GetWorldPosFromMapPos,record.map,CreateVector2D(record.x,record.y))
 local result,projected
 if continent and continent==target.continent and pos then result,projected=read(C_Map.GetMapPosFromWorldPos,continent,pos,map)end
 local x,y;if result==map then x,y=xy(projected)end
 if x and y then record.projection={map=map,x=x,y=y}end;return x,y
end
function P:DrawWorld()
 if not WorldMapFrame or not WorldMapFrame:IsShown()then return end
 local diagnostics=AUI.modules.Diagnostics;local started=diagnostics and diagnostics:BeginWork();local count=0
 local map=read(WorldMapFrame.GetMapID,WorldMapFrame)
 local canvas=read(WorldMapFrame.GetCanvas,WorldMapFrame)
 local width,height=canvas and read(canvas.GetWidth,canvas),canvas and read(canvas.GetHeight,canvas)
 for icon,record in pairs(self.world)do
  count=count+1
  local x,y=self:Project(record,map)
  if canvas and width and height and x and y and x>=0 and x<=1 and y>=0 and y<=1 then
   icon:SetParent(canvas);icon:ClearAllPoints();icon:SetPoint("CENTER",canvas,"TOPLEFT",x*width,-y*height);icon:Show()
  else icon:Hide()end
 end
 if started then diagnostics:EndWork("World map markers",started,count)end
end
function P:DrawMini()
 if not Minimap or not Minimap:IsVisible()then return end
 local diagnostics=AUI.modules.Diagnostics;local started=diagnostics and diagnostics:BeginWork();local count=0
 local map=read(C_Map and C_Map.GetBestMapForUnit,"player")
 local pos=map and read(C_Map.GetPlayerMapPosition,map,"player")
 local px,py=xy(pos)
 local width,height;if map then width,height=read(C_Map.GetMapWorldSize,map)end
 local radius=read(C_Minimap and C_Minimap.GetViewRadius)
 local mw,mh=read(Minimap.GetWidth,Minimap),read(Minimap.GetHeight,Minimap)
 local rotating=read(C_CVar and C_CVar.GetCVarBool,"rotateMinimap")
 local facing=rotating and read(GetPlayerFacing)or 0
 local square=read(GetMinimapShape)=="SQUARE"
 for icon,record in pairs(self.mini)do
  count=count+1
  local x,y=self:Project(record,map)
  if px and py and width and height and radius and radius>0 and mw and mh and facing and x and y then
   local dx,dy=(x-px)*width/radius,(py-y)*height/radius
   if rotating then local c,s=math.cos(facing),math.sin(facing);dx,dy=dx*c+dy*s,-dx*s+dy*c end
   local distance=square and math.max(math.abs(dx),math.abs(dy))or math.sqrt(dx*dx+dy*dy)
   if distance<=.9 or record.edge then
    if distance>.9 then dx,dy=dx*.9/distance,dy*.9/distance end
    icon:ClearAllPoints();icon:SetPoint("CENTER",Minimap,"CENTER",dx*mw/2,dy*mh/2);icon:Show()
   else icon:Hide()end
  else icon:Hide()end
 end
 if started then diagnostics:EndWork("Minimap markers",started,count)end
end
function P:SyncTicker()
 if next(self.mini)and Minimap and Minimap:IsVisible()then
  if not self.timer then self.timer=C_Timer.NewTicker(.2,function()self:DrawMini()end)end
 elseif self.timer then self.timer:Cancel();self.timer=nil end
end
function P:Install()
 if self.installed then return end;self.installed=true
 if WorldMapFrame then
  WorldMapFrame:HookScript("OnShow",function()self:DrawWorld()end)
  WorldMapFrame:HookScript("OnSizeChanged",function()self:DrawWorld()end)
  if hooksecurefunc and WorldMapFrame.SetMapID then hooksecurefunc(WorldMapFrame,"SetMapID",function()self:DrawWorld()end)end
  local canvas=read(WorldMapFrame.GetCanvas,WorldMapFrame)
  if canvas then canvas:HookScript("OnSizeChanged",function()self:DrawWorld()end)end
 end
 if Minimap then
  Minimap:HookScript("OnShow",function()self:SyncTicker();self:DrawMini()end)
  Minimap:HookScript("OnHide",function()self:SyncTicker()end)
 end
end
function P:AddWorldMapIconMap(owner,icon,map,x,y)
 self:Install();self.world[icon]={owner=owner,map=map,x=x,y=y}
 if not self.worldQueued then self.worldQueued=true;C_Timer.After(0,function()self.worldQueued=nil;self:DrawWorld()end)end
end
function P:AddMinimapIconMap(owner,icon,map,x,y,_,edge)
 self:Install();self.mini[icon]={owner=owner,map=map,x=x,y=y,edge=edge};self:SyncTicker()
end
function P:RemoveWorldMapIcon(_,icon)self.world[icon]=nil;icon:Hide()end
function P:RemoveMinimapIcon(_,icon)self.mini[icon]=nil;icon:Hide();self:SyncTicker()end
function P:RemoveAllWorldMapIcons(owner)for icon,r in pairs(self.world)do if r.owner==owner then self:RemoveWorldMapIcon(owner,icon)end end end
function P:RemoveAllMinimapIcons(owner)for icon,r in pairs(self.mini)do if r.owner==owner then self.mini[icon]=nil;icon:Hide()end end;self:SyncTicker()end
