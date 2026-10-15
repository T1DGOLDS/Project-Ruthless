local _,AUI=...
local P={rows={},buttons={},edges={},revision=0}
AUI:RegisterModule("QuestProgression",P)
local function public(v)return not(issecretvalue and issecretvalue(v))end
local function read(fn,...)
 if type(fn)~="function"then return end
 local ok,v=pcall(fn,...);if ok and public(v)then return v end
end
local function number(v)return public(v)and type(v)=="number"and v==v and v>0 and v<100000000 end
local function stringValue(v)return public(v)and type(v)=="string"and v or nil end
local function field(t,k)return type(t)=="table"and public(t)and public(t[k])and t[k]or nil end
function P:Store()
 ProjectRuthlessCharDB.questProgression=ProjectRuthlessCharDB.questProgression or {known={}}
 local s=ProjectRuthlessCharDB.questProgression;s.known=s.known or {};return s
end
function P:Invalidate()
 self.revision=self.revision+1;self.states={};self.catalog=nil
end
function P:QuestTitle(id,fallback)
 return stringValue(read(C_QuestLog.GetTitleForQuestID,id))or fallback or "Quest #"..id
end
function P:RememberLine(info,map)
 local line=field(info,"questLineID");if not number(line)then return end
 local key="native:"..line;local s=self:Store()
 local ids=C_QuestLine and read(C_QuestLine.GetQuestLineQuests,line)
 if type(ids)~="table"then return end
 local nodes,seen={},{}
 for _,id in ipairs(ids)do
  if number(id)and id%1==0 and not seen[id]then
   if #nodes>=160 then return end -- Do not silently truncate a dependency view.
   seen[id]=true;nodes[#nodes+1]={id=id,title=self:QuestTitle(id),requires={}}
  end
 end
 if #nodes==0 then return end
 local first=field(info,"questID");local x,y=field(info,"x"),field(info,"y")
 local start=field(info,"startMapID");if not number(start)then start=map end
 if number(start)and type(x)=="number"and type(y)=="number"and x>=0 and x<=1 and y>=0 and y<=1 then
  for _,node in ipairs(nodes)do if node.id==first then node.point={map=start,x=x,y=y}end end
 end
 local count=0;for _ in pairs(s.known)do count=count+1 end
 if not s.known[key]and count>=32 then self.discoveryNotice="32 quest groups retained. New quests remain visible in Your quest log.";return end
 s.known[key]={key=key,name=stringValue(field(info,"questLineName"))or "Quest line #"..line,nodes=nodes,kind="native",source="Blizzard quest group · prerequisites not supplied"}
end
function P:Catalog()
 if self.catalog then return self.catalog end
 local map=C_Map and read(C_Map.GetBestMapForUnit,"player")
 local entries={};local count=read(C_QuestLog.GetNumQuestLogEntries)or 0
 if not number(count)then count=0 end
 for i=1,math.min(count,100)do
  local info=read(C_QuestLog.GetInfo,i);local id=field(info,"questID")
  if number(id)and not field(info,"isHeader")then
   entries[#entries+1]={id=id,title=stringValue(field(info,"title"))or self:QuestTitle(id),requires={}}
   if C_QuestLine then self:RememberLine(read(C_QuestLine.GetQuestLineInfo,id,number(map)and map or nil,false),map)end
  end
 end
 if C_QuestLine and number(map)then
  local lines=read(C_QuestLine.GetAvailableQuestLines,map)
  if type(lines)=="table"then for i=1,math.min(#lines,100)do self:RememberLine(lines[i],map)end end
 end
 local list,byKey={},{};local faction=read(UnitFactionGroup,"player")
 self.owned=self.owned or AUI.CreateQuestProgression()
 for _,chain in ipairs(self.owned)do if not chain.faction or chain.faction==faction then list[#list+1]=chain;byKey[chain.key]=chain end end
 local authored=AUI.modules.AuthoredGuides
 if authored then
  if not self.routeChains then
   self.routeChains={}
   for _,route in ipairs(authored:Catalog())do
    local nodes,seen={},{}
    for _,hub in ipairs(route.hubs)do for _,id in ipairs(hub.quests)do if not seen[id]then
     local fact=authored.facts[tostring(id)]or {};seen[id]=true
     nodes[#nodes+1]={id=id,title=fact.title,minLevel=fact.min,area=route.name.." · "..hub.name,requires={}}
    end end end
    self.routeChains[#self.routeChains+1]={key="route:"..route.id,name=route.name.." · route",faction=route.faction,kind="route",nodes=nodes,source="RUI authored route · route order does not prove prerequisites"}
   end
  end
  for _,chain in ipairs(self.routeChains)do if chain.faction==faction then list[#list+1]=chain;byKey[chain.key]=chain end end
 end
 for key,chain in pairs(self:Store().known)do list[#list+1]=chain;byKey[key]=chain end
 local held={key="log",name="Your quest log",kind="log",nodes=entries,source="Live Blizzard quest log · independent quests"}
 list[#list+1]=held;byKey.log=held
 table.sort(list,function(a,b)if a.kind=="dungeon"and b.kind~="dungeon"then return true elseif b.kind=="dungeon"and a.kind~="dungeon"then return false end;return a.name<b.name end)
 self.catalog=list;self.byKey=byKey;return list
end
function P:Chain(key)self:Catalog();return self.byKey[key]end
function P:Layout(chain)
 local byID,depth,visiting={}, {},{};local failure
 if #chain.nodes>160 then return nil,"This chain exceeds the 160-quest view limit."end
 for _,node in ipairs(chain.nodes)do if byID[node.id]then return nil,"Duplicate quest identity in this chain."end;byID[node.id]=node end
 local function visit(id)
  if depth[id]then return depth[id]end
  if visiting[id]then failure="A prerequisite cycle needs correction.";return 0 end
  local node=byID[id];if not node then failure="A prerequisite quest is missing from this chain.";return 0 end
  visiting[id]=true;local d=0
  for _,parent in ipairs(node.requires or {})do d=math.max(d,visit(parent)+1)end
  visiting[id]=nil;depth[id]=d;return d
 end
 local columns,positions={},{}
 for i,node in ipairs(chain.nodes)do
  local d=visit(node.id)
  if chain.kind~="dungeon"then d=math.floor((i-1)/5)end
  columns[d]=(columns[d]or 0)+1;positions[node.id]={x=24+d*250,y=24+(columns[d]-1)*110}
 end
 if failure then return nil,failure end
 return positions
end
function P:Status(chain,node)
 self.states=self.states or {};local key=chain.key..":"..node.id
 if self.states[key]then return unpack(self.states[key])end
 local result,reason
 local on=read(C_QuestLog.IsOnQuest,node.id);local done=read(C_QuestLog.IsQuestFlaggedCompleted,node.id)
 if on==true then result=read(C_QuestLog.IsComplete,node.id)==true and "Turn in"or "In progress"
 elseif done==true then result="Completed"
 elseif done==nil or on==nil then result="Unknown";reason="Quest state is unavailable in this client."
 else
  local level=read(UnitLevel,"player");local missing,unknown={},false
  for _,id in ipairs(node.requires or {})do
   local finished=read(C_QuestLog.IsQuestFlaggedCompleted,id)
   if finished~=true then missing[#missing+1]=self:QuestTitle(id);if finished==nil then unknown=true end end
  end
  if #missing>0 then result=unknown and "Unknown"or "Blocked";reason=(node.any and "Complete one prerequisite: "or "Complete prerequisites: ")..table.concat(missing,", ")
   if node.any then for _,id in ipairs(node.requires)do if read(C_QuestLog.IsQuestFlaggedCompleted,id)==true then result=nil;reason=nil;break end end end
  end
  if not result and node.minLevel and (not number(level)or level<node.minLevel)then result=number(level)and "Blocked"or "Unknown";reason="Requires level "..node.minLevel end
  if not result then result="Check giver";reason=chain.kind=="dungeon"and "Known prerequisites met. Confirm current availability with the quest giver."or "Blizzard has not supplied complete acceptance requirements."end
 end
 self.states[key]={result,reason};return result,reason
end
function P:FindNode(chain,id)for _,node in ipairs(chain.nodes)do if node.id==id then return node end end end
function P:Follow(chain,node)
 local state=self:Store();state.active=chain.key;state.quest=node.id
 self.selected=chain.key;self.selectedQuest=node.id
 local q=AUI.modules.QuestWorkspace;q.manualFocus=true;q.selected=node.id
 q.manualPickup={id=node.id,title=self:QuestTitle(node.id,node.title),detail="Check quest giver",point=node.point}
 q:Refresh()
end
function P:Guide()
 local state=self:Store();local chain=state.active and self:Chain(state.active);if not chain then return end
 local node=self:FindNode(chain,state.quest)
 if not node then
  state.active=nil;state.quest=nil;local q=AUI.modules.QuestWorkspace;q.manualFocus=nil;q.manualPickup=nil;return
 end
 if self:Status(chain,node)=="Completed"then
  local nextNode,blocked
  for _,n in ipairs(chain.nodes)do local status=self:Status(chain,n);if status=="In progress"or status=="Turn in"or status=="Check giver"then nextNode=n;break elseif status~="Completed"then blocked=blocked or n end end
  nextNode=nextNode or blocked
  if nextNode then node=nextNode;state.quest=node.id end
 end
 local status,reason=self:Status(chain,node);local objectives={}
 local q=AUI.modules.QuestWorkspace;q.selected=node.id
 if status=="Check giver"then
  if not q.manualPickup or q.manualPickup.id~=node.id then q.manualPickup={id=node.id,title=self:QuestTitle(node.id,node.title),detail=reason,point=node.point}end
 else q.manualPickup=nil end
 if status=="In progress"then
  for _,v in ipairs(read(C_QuestLog.GetQuestObjectives,node.id)or {})do local text=stringValue(field(v,"text"));if text then objectives[#objectives+1]=text end end
 end
 local instruction=reason or (status=="Completed"and "Chain finished. Open the map to choose your next step."or status=="Turn in"and "Return to the quest's turn-in marker."or "Follow the current quest objectives.")
 if status=="Check giver"and node.area then instruction="Check "..(node.giver or "the quest giver").." in "..node.area..". "..instruction end
 return {source="RUI progression",id=node.id,quest=self:QuestTitle(node.id,node.title),target=node.giver or chain.name,phase=status:upper(),count="",instruction=instruction,objectives=objectives,next={},questIDs={[node.id]=true}}
end
function P:Action(action)
 if action=="stop"then self:Store().active=nil;self:Store().quest=nil;local q=AUI.modules.QuestWorkspace;q.manualFocus=nil;q.manualPickup=nil;q:Refresh()
 else self.selectedQuest=self:Store().quest;self:Open(self:Store().active)end
end
function P:ShowLocation(node)
 if not node.point then AUI:Print("No verified giver coordinates are available. The quest details show the known pickup area.");return end
 if WorldMapFrame and type(WorldMapFrame.SetMapID)=="function"then WorldMapFrame:SetMapID(node.point.map)end
 self:Hide();AUI.modules.QuestWorkspace:SelectMapPage("Quests")
 if InCombatLockdown()then AUI:Print("Location map opened. Place a waypoint after combat.");return end
 if UiMapPoint and C_Map and C_Map.SetUserWaypoint then C_Map.SetUserWaypoint(UiMapPoint.CreateFromCoordinates(node.point.map,node.point.x,node.point.y))end
end
function P:Hide()
 if self.frame then self.frame:Hide()end
 for _,row in ipairs(self.rows)do row:Hide()end
end
function P:Open(key)
 self.selected=key;local q=AUI.modules.QuestWorkspace;q:SelectMapPage("Dungeons")
end
function P:CreateGraph()
 if self.frame then return end
 local parent=WorldMapFrame;local f=CreateFrame("Frame",nil,parent,"BackdropTemplate");self.frame=f
 f:SetPoint("TOPLEFT",parent.ScrollContainer,"TOPLEFT");f:SetPoint("BOTTOMRIGHT",parent.ScrollContainer,"BOTTOMRIGHT")
 f:SetFrameStrata(parent:GetFrameStrata());f:SetFrameLevel(parent:GetFrameLevel()+220);f:EnableMouse(true)
 f:SetBackdrop({bgFile="Interface\\Buttons\\WHITE8X8",edgeFile="Interface\\Buttons\\WHITE8X8",edgeSize=1});AUI:StyleSurface(f,"window",1,"Map")
 local label=f:CreateFontString(nil,"OVERLAY","GameFontNormalSmall");label:SetPoint("TOPLEFT",12,-12);label:SetText("Quest progression · wheel to scroll · Shift + wheel sideways · drag empty space to pan")
 if AUI.modules.Accessibility then AUI.modules.Accessibility:RegisterText(label)end
 local scroll=CreateFrame("ScrollFrame",nil,f);self.scroll=scroll;scroll:SetPoint("TOPLEFT",8,-36);scroll:SetPoint("BOTTOMRIGHT",-8,42);scroll:EnableMouseWheel(true)
 local canvas=CreateFrame("Frame",nil,scroll);self.canvas=canvas;canvas:SetSize(800,600);scroll:SetScrollChild(canvas);canvas:EnableMouse(true)
 local function move(dx,dy)
  scroll:SetHorizontalScroll(math.max(0,math.min(scroll:GetHorizontalScroll()+dx,scroll:GetHorizontalScrollRange())))
  scroll:SetVerticalScroll(math.max(0,math.min(scroll:GetVerticalScroll()+dy,scroll:GetVerticalScrollRange())))
 end
 scroll:SetScript("OnMouseWheel",function(_,delta)if IsShiftKeyDown()then move(-delta*70,0)else move(0,-delta*70)end end)
 canvas:SetScript("OnMouseDown",function(_,button)
  if button~="LeftButton"then return end
  local x,y=GetCursorPosition();canvas:SetScript("OnUpdate",function()
   local nx,ny=GetCursorPosition();local scale=canvas:GetEffectiveScale();move((x-nx)/scale,(ny-y)/scale);x,y=nx,ny
  end)
 end)
 local function stop()canvas:SetScript("OnUpdate",nil)end
 canvas:SetScript("OnMouseUp",stop);f:SetScript("OnHide",stop)
 local function action(text,x,fn)
  local b=AUI:CreateButton(f);b:SetPoint("BOTTOMLEFT",x,9);b:SetSize(104,24);b:SetText(text);b:SetScript("OnClick",fn)
 end
 action("Zoom −",12,function()self.zoom=math.max(.65,(self.zoom or 1)-.1);self:Render(AUI.modules.QuestWorkspace)end)
 action("Zoom +",124,function()self.zoom=math.min(1.3,(self.zoom or 1)+.1);self:Render(AUI.modules.QuestWorkspace)end)
 action("Reset view",236,function()self.zoom=1;scroll:SetHorizontalScroll(0);scroll:SetVerticalScroll(0);self:Render(AUI.modules.QuestWorkspace)end)
 f:EnableKeyboard(true);f:SetPropagateKeyboardInput(true)
 f:SetScript("OnKeyDown",function(_,key)
  f:SetPropagateKeyboardInput(true)
  if GetCurrentKeyBoardFocus and GetCurrentKeyBoardFocus()then return end
  local chain=self:Chain(self.selected);if not chain then return end
  local i=1;for index,node in ipairs(chain.nodes)do if node.id==self.selectedQuest then i=index;break end end
  if key=="LEFT"or key=="RIGHT"then
   i=math.max(1,math.min(#chain.nodes,i+(key=="RIGHT"and 1 or -1)));self.selectedQuest=chain.nodes[i].id
   self:Render(AUI.modules.QuestWorkspace,true);f:SetPropagateKeyboardInput(false)
  end
 end)
end
function P:Render(q,focus)
 self.renderedRevision=self.revision
 for _,row in ipairs(self.rows)do row:Hide()end
 for _,control in ipairs(q.mapControls or {})do control:Hide()end
 for _,button in ipairs(q.dungeonMapButtons or {})do button:Hide();if button.share and type(button.share)~="function"then button.share:Hide()end end
 q.mapScroll:ClearAllPoints();q.mapScroll:SetPoint("TOPLEFT",12,-42);q.mapScroll:SetPoint("BOTTOMRIGHT",-30,12)
 local chain=self.selected and self:Chain(self.selected);local rowIndex=0;local offset=0
 local function row(text,fn)
  rowIndex=rowIndex+1;local b=self.rows[rowIndex]
  if not b then b=AUI:CreateButton(q.mapContent);self.rows[rowIndex]=b end
  b:ClearAllPoints();b:SetPoint("TOPLEFT",0,-offset);b:SetSize(q.mapContent:GetWidth(),42);b:SetText(text);b:SetScript("OnClick",fn);b:Show();offset=offset+48;return b
 end
 if not chain then
  self:Hide();q.mapHeading:SetText("Quest progression");q.mapCopy:SetText(self.discoveryNotice or "");if self.discoveryNotice then offset=80 end
  row("Browse dungeon maps, bosses & loot",function()q:SelectMapPage("Dungeon atlas")end)
  for _,entry in ipairs(self:Catalog())do local c=entry;row(c.name.."\n"..#c.nodes.." quests · "..(c.kind=="dungeon"and "Dungeon preparation"or "Quest group"),function()self.selectedQuest=nil;self:Open(c.key)end)end
  q.mapContent:SetHeight(math.max(400,offset));return
 end
 local positions,err=self:Layout(chain)
 if not positions then
  self:Hide();q.mapHeading:SetText("Chain unavailable");q.mapCopy:SetText(err);offset=100
  row("‹ All quest groups",function()self.selected=nil;self:Render(q)end);return
 end
 self:CreateGraph();self.frame:Show();q.mapHeading:SetText(chain.name)
 local node=self:FindNode(chain,self.selectedQuest)or chain.nodes[1]
 if not node then
  self:Hide();q.mapCopy:SetText("No quests are currently supplied for this group.")
  row("‹ All quest groups",function()self.selected=nil;self:Render(q)end);return
 end
 self.selectedQuest=node.id;local status,reason=self:Status(chain,node)
 local title=self:QuestTitle(node.id,node.title)
 local location=node.area or (node.point and stringValue(field(read(C_Map.GetMapInfo,node.point.map),"name")))or "Pickup area not supplied by Blizzard"
 local text=title.."\nQuest #"..node.id.." · "..status..(node.minLevel and "\nMinimum level: "..node.minLevel or "").."\n\n"..(node.dungeon and "Dungeon objective\n"or "").."Pick up: "..(node.giver and node.giver.."\n"or "")..location.."\n\n"..(reason or "").."\n\n"..chain.source
 q.mapCopy:SetText(text);offset=math.max(200,(q.mapCopy:GetStringHeight()or 180)+16)
 row("‹ All quest groups",function()self.selected=nil;self:Render(q)end)
 row("Follow this step",function()self:Follow(chain,node);self:Render(q)end)
 row("Show pickup location",function()self:ShowLocation(node)end)
 row("Share this quest",function()local _,message=q:ShareDungeonQuest(node.id);AUI:Print(message)end)
 if self:Store().active then row("Return to leveling guide",function()self:Action("stop");self:Render(q)end)end
 q.mapContent:SetHeight(math.max(600,offset))
 for _,b in ipairs(self.buttons)do b:Hide()end;for _,e in ipairs(self.edges)do e:Hide()end
 local zoom=self.zoom or 1;local width,height=0,0;local edgeIndex=0
 local function segment(x,y,w,h)
  edgeIndex=edgeIndex+1;local t=self.edges[edgeIndex]
  if not t then t=self.canvas:CreateTexture(nil,"BACKGROUND");t:SetColorTexture(.45,.48,.55,.65);self.edges[edgeIndex]=t end
  t:ClearAllPoints();t:SetPoint("TOPLEFT",x*zoom,-y*zoom);t:SetSize(math.max(1,w*zoom),math.max(1,h*zoom));t:Show()
 end
 for i,n in ipairs(chain.nodes)do
  local pos=positions[n.id];local b=self.buttons[i]
  if not b then b=AUI:CreateButton(self.canvas);self.buttons[i]=b end
  b:ClearAllPoints();b:SetPoint("TOPLEFT",pos.x*zoom,-pos.y*zoom);b:SetSize(218*zoom,86*zoom)
  local state=self:Status(chain,n);b:SetText((n.id==node.id and "> "or "")..self:QuestTitle(n.id,n.title).."\n#"..n.id.." · "..state..(n.dungeon and " · dungeon"or ""))
  b:SetScript("OnClick",function()self.selectedQuest=n.id;self:Render(q)end);b:Show()
  local r,g,blue=.35,.38,.43;if state=="Completed"then r,g,blue=.25,.75,.5 elseif state=="In progress"or state=="Turn in"then r,g,blue=AUI:AccentColor()end
  b:SetBackdropBorderColor(r,g,blue,n.id==node.id and 1 or .65)
  width=math.max(width,pos.x+244);height=math.max(height,pos.y+110)
  for _,parent in ipairs(n.requires or {})do
   local previous=positions[parent];local x1,y1=previous.x+218,previous.y+43;local x2,y2=pos.x,pos.y+43;local mid=(x1+x2)/2
   segment(x1,y1,mid-x1,1);segment(mid,math.min(y1,y2),1,math.abs(y2-y1)+1);segment(mid,y2,x2-mid,1)
  end
 end
 self.canvas:SetSize(math.max(400,width*zoom),math.max(320,height*zoom))
 if focus then local pos=positions[node.id];self.scroll:SetHorizontalScroll(math.min(pos.x*zoom,self.scroll:GetHorizontalScrollRange()));self.scroll:SetVerticalScroll(math.min(pos.y*zoom,self.scroll:GetVerticalScrollRange()))end
end
function P:OnPlayerLogin()
 self:Store() -- The quest workspace owns the shared batched event subscription.
end
