local _,AUI=...
local F={};AUI:RegisterModule("FlightTimer",F)
local function read(fn,...)
 if type(fn)~="function"then return end
 local ok,a,b,c,d=pcall(fn,...)
 if ok and not(issecretvalue and (issecretvalue(a)or issecretvalue(b)or issecretvalue(c)or issecretvalue(d)))then return a,b,c,d end
end
local function finite(v)return not(issecretvalue and issecretvalue(v))and type(v)=="number"and v==v and math.abs(v)<1e8 end
local function clock(n)n=math.max(0,math.floor(n or 0));return ("%d:%02d"):format(math.floor(n/60),n%60)end
local function enabled()return not(ProjectRuthlessDB.mapQuests and ProjectRuthlessDB.mapQuests.flightTimer==false)end
function F:Speed()
 local legacy=Constants and Constants.LegacyConsts
 if legacy and C_Traits then
  local id=read(C_Traits.GetConfigIDByTreeID,legacy.LEGACY_TREE_ADVENTURE_ID)
  local node=id and read(C_Traits.GetNodeInfo,id,110300)
  local rank=node and read(function()return node.activeRank end)
  if finite(rank)then return rank>0 and 1/1.2 or 1,rank>0 and "fast"or "normal"end
 end
 return 1,"unknown-perk"
end
function F:Snapshot()
 self.slots={};self.origin=nil
 local map=read(GetTaxiMapID);self.taxiMap=map
 local list=map and read(C_TaxiMap and C_TaxiMap.GetAllTaxiNodes,map)
 local bySlot={}
 if type(list)=="table"then for _,node in ipairs(list)do
  local slot=read(function()return node.slotIndex end)
  if finite(slot)then bySlot[slot]=node end
 end end
 local count=read(NumTaxiNodes)
 if not finite(count)or count>200 then return end
 for slot=1,count do
  local node=bySlot[slot];local name=read(TaxiNodeName,slot);local state=read(TaxiNodeGetType,slot)
  local id=node and read(function()return node.nodeID end)
  local position=node and read(function()return node.position end)
  local x,y
  if position then x,y=read(position.GetXY,position)end
  if type(name)=="string"then
   local row={name=name,id=finite(id)and id or nil,x=x,y=y,map=map}
   self.slots[slot]=row;if state=="CURRENT"then self.origin=row end
  end
 end
end
function F:Key(origin,destination,path,perk)
 if not origin or not destination then return end
 local version,build=read(GetBuildInfo)
 return table.concat({tostring(read(UnitFactionGroup,"player")or "?"),tostring(version),tostring(build),tostring(perk),path},"|")
end
function F:Selected(slot)
 if not enabled()or not finite(slot)then return end
 -- The map can be rebuilt for another continent; take the actual click's map.
 local map=read(GetTaxiMapID)
 if map and map~=self.taxiMap then self:Snapshot()end
 local origin,destination=self.origin,self.slots and self.slots[slot]
 if not origin or not destination or origin==destination then return end
 local path={tostring(origin.id or origin.name)};local hops=read(GetNumRoutes,slot)
 if not finite(hops)or hops<1 or hops>=40 then path=nil end
 if finite(hops)and hops>1 and hops<40 then
  for hop=2,hops do
   local middle=self.slots[read(TaxiGetNodeSlot,slot,hop,true)]
   if not middle then path=nil;break end
   path[#path+1]=tostring(middle.id or middle.name)
  end
 end
 if path then path[#path+1]=tostring(destination.id or destination.name)end
 local factor,perk=self:Speed()
 self.pending={origin=origin,destination=destination,selected=GetTime(),factor=factor,perk=perk,
  key=path and self:Key(origin,destination,table.concat(path,">"),perk)}
 self:Create();self.driver:Show()
end
function F:Expected(flight)
 local saved=ProjectRuthlessDB.flightTimes or {};local learned=flight.key and saved[flight.key]
 if type(learned)=="table"and finite(learned.seconds)and learned.seconds>=5 and learned.seconds<=3600 then return learned.seconds,"Measured"end
 local data=AUI.TravelData and AUI.TravelData.referenceFlights
 local nodes=data and data[read(UnitFactionGroup,"player")]
 local value=nodes and nodes[flight.origin.id]and nodes[flight.origin.id][flight.destination.id]
 if finite(value)then return value*flight.factor,"Estimate"end
end
function F:AtDestination(destination)
 if not destination or not finite(destination.map)or not finite(destination.x)or not finite(destination.y)then return false end
 local pos=read(C_Map and C_Map.GetPlayerMapPosition,destination.map,"player")
 if not pos then return false end
 local x,y=read(pos.GetXY,pos);local w,h=read(C_Map.GetMapWorldSize,destination.map)
 if not finite(x)or not finite(y)or not finite(w)or not finite(h)or w<=0 or h<=0 then return false end
 return ((x-destination.x)*w)^2+((y-destination.y)*h)^2<=300^2
end
function F:Finish()
 local flight=self.flight
 if enabled()and flight and flight.key and not flight.partial then
  local seconds=GetTime()-flight.start;local _,perk=self:Speed()
  if seconds>=5 and seconds<=3600 and perk==flight.perk and self:AtDestination(flight.destination)then
   local store=ProjectRuthlessDB.flightTimes or {};ProjectRuthlessDB.flightTimes=store
   store[flight.key]={seconds=math.floor(seconds+.5),at=read(GetServerTime)or 0}
   local count,oldest,oldTime=0,nil,math.huge
   for key,value in pairs(store)do count=count+1;local at=type(value)=="table"and value.at or 0;if not finite(at)then at=0 end;if at<oldTime then oldest,oldTime=key,at end end
   if count>512 and oldest then store[oldest]=nil end
  end
 end
 self.flight=nil;self.pending=nil;self.frame:Hide();self.driver:Hide()
end
function F:Tick()
 if not enabled()then self:Finish();return end
 local taxi=read(UnitOnTaxi,"player")
 if taxi==nil then
  if self.pending and GetTime()-self.pending.selected>10 then self:Finish()end
  return -- an unavailable/secret state is not a landing
 end
 local now=GetTime()
 if not self.flight then
  if taxi then
   self.flight=self.pending or {partial=true};self.pending=nil;self.flight.start=now
   if self.flight.origin then self.flight.total,self.flight.source=self:Expected(self.flight)end
  elseif not self.pending or now-self.pending.selected>10 then self:Finish();return else return end
 elseif not taxi then self:Finish();return end
 local f=self.flight;local elapsed=now-f.start
 local total=f.total;local second=math.floor(total and math.max(0,total-elapsed)or elapsed)
 if f.shown~=second then
  f.shown=second
  self.label:SetText(f.destination and f.destination.name or "Flight")
  self.time:SetText(total and ((f.source=="Estimate"and "~"or "")..clock(second).." remaining")or (clock(second).." elapsed"))
  self.detail:SetText(f.partial and "Since reload · full duration unknown"or (f.source or "Learning this route"))
 end
 self.progress:SetMinMaxValues(0,total or math.max(1,elapsed));self.progress:SetValue(total and math.min(total,elapsed)or elapsed)
 self.frame:Show()
end
function F:Create()
 if self.frame then return end
 local frame=CreateFrame("Frame","RUIFlightTimer",UIParent,"BackdropTemplate");self.frame=frame
 frame:SetSize(250,58);frame:SetPoint("TOPRIGHT",UIParent,"TOPRIGHT",-30,-280);frame:SetFrameStrata("MEDIUM")
 frame:SetBackdrop({bgFile="Interface\\Buttons\\WHITE8X8",edgeFile="Interface\\Buttons\\WHITE8X8",edgeSize=1})
 AUI:StyleSurface(frame,"window",nil,"Cast")
 self.label=frame:CreateFontString(nil,"OVERLAY","GameFontNormalSmall");self.label:SetPoint("TOPLEFT",7,-6);self.label:SetPoint("TOPRIGHT",-7,-6);self.label:SetJustifyH("LEFT")
 self.time=frame:CreateFontString(nil,"OVERLAY","GameFontHighlightSmall");self.time:SetPoint("TOPLEFT",7,-21)
 self.detail=frame:CreateFontString(nil,"OVERLAY","GameFontDisableSmall");self.detail:SetPoint("BOTTOMRIGHT",-7,7)
 self.detail:SetPoint("BOTTOMLEFT",7,7);self.detail:SetJustifyH("LEFT")
 local accessibility=AUI.modules.Accessibility
 for _,font in ipairs({self.label,self.time,self.detail})do font:SetWordWrap(false);if accessibility then accessibility:RegisterText(font)end end
 self.progress=CreateFrame("StatusBar",nil,frame);self.progress:SetPoint("BOTTOMLEFT",1,1);self.progress:SetPoint("BOTTOMRIGHT",-1,1);self.progress:SetHeight(2)
 self.progress:SetStatusBarTexture("Interface\\Buttons\\WHITE8X8");local r,g,b=AUI:AccentColor();self.progress:SetStatusBarColor(r,g,b)
 local editor=AUI.modules.LayoutEditor;editor:Attach("flightTimer","Flight timer",frame)
 frame:SetMovable(true);frame:SetClampedToScreen(true);frame:EnableMouse(true);frame:RegisterForDrag("LeftButton")
 frame:SetScript("OnDragStart",function()frame:StartMoving()end)
 frame:SetScript("OnDragStop",function()frame:StopMovingOrSizing();local value=editor:Capture(frame);if value then editor:Store().elements.flightTimer=value end end)
 self.driver=CreateFrame("Frame");self.driver:Hide();local elapsed=0
 self.driver:SetScript("OnUpdate",function(_,dt)elapsed=elapsed+dt;if elapsed>=.2 then elapsed=0;F:Tick()end end)
 frame:Hide()
end
function F:ApplySettings()
 if not enabled()and self.frame then self:Finish()end
end
function F:OnPlayerLogin()
 if not AUI.isForever then return end
 self:Create();self.events=CreateFrame("Frame")
 for _,event in ipairs({"TAXIMAP_OPENED","PLAYER_CONTROL_LOST","PLAYER_CONTROL_GAINED","PLAYER_ENTERING_WORLD"})do self.events:RegisterEvent(event)end
 self.events:SetScript("OnEvent",function(_,event)
  if event=="TAXIMAP_OPENED"then self:Snapshot()
  elseif enabled()and read(UnitOnTaxi,"player")then self.driver:Show();self:Tick()
  elseif self.flight then self:Tick()end
 end)
 if type(TakeTaxiNode)=="function"then hooksecurefunc("TakeTaxiNode",function(slot)F:Selected(slot)end)end
 if enabled()and read(UnitOnTaxi,"player")then self.driver:Show();self:Tick()end
end
