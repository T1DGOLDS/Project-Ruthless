local _,AUI=...
local L={}
AUI:RegisterModule("LiveChecks",L)
L.gates={
 {id="installation",title="Installation",page="setup",steps="1. Load only the three bundled RUI folders and reload.\n2. Check fresh-character setup, familiar starting positions and disabled decorative art.\n3. Return to an existing character and verify its layout is retained."},
 {id="profiles",title="Profiles & recovery",page="profiles",steps="1. Save two disposable profiles with different positions, colours, chat tabs and bag settings.\n2. Switch from Settings and Edit Mode; test Undo, Cancel, overwrite recovery and export/import.\n3. Set a new-character default, test a new character, then reload an existing one.\n4. In combat, profile writes must be refused without changing your setup."},
 {id="combat",title="Combat safety",page="unitframes",steps="1. Enter and leave combat repeatedly. Test actions, cooldowns, forms/stances, pets and target changes.\n2. Test main-hand, offhand, ranged attacks and queued melee abilities.\n3. Browse map, spellbook, RUI settings and previews during combat.\n4. Change presentation preferences: protected edits must wait. Check fresh errors and blocked-action messages."},
 {id="information",title="Information",page="mapquests",steps="1. Verify native quest starts, turn-ins, pins and blue areas; press M twice.\n2. Test RUI route order, held objectives, map selection and missing-location explanations.\n3. Check party/target frames, portraits, auras, dispels, cooldowns, rested XP and tooltips.\n4. Check native meter categories/session controls in combat. Missing quest data must stay labelled; it must not become invented locations."},
 {id="accessibility",title="Accessibility",page="accessibility",steps="1. Try 100%, 125% and 150% text, long labels and a small screen.\n2. Test keyboard settings search/navigation, focus, readable contrast and reduced motion.\n3. Verify the client's native accessibility/audio/chat choices still work.\n4. Record anything clipped, inaccessible or dependent on colour alone. Do not assume screen-reader parity."},
 {id="performance",title="Performance",page="errors",steps="1. Use /pr record on for matched idle, travel, five-player combat, map/bag opening and quest/loot bursts.\n2. Compare recent RUI CPU, spikes, memory growth and measured-operation counts in /pr report.\n3. Repeat with recording off to account for recorder overhead.\n4. Test other addons separately if needed. Whole-game frame gaps and addon presence alone do not establish RUI's cost or a conflict."},
}
local function public(v)return not(issecretvalue and issecretvalue(v))end
local function stamp()return date and date("%Y-%m-%d %H:%M:%S")or "unknown"end
function L:Identity()
 local ok,_,build,_,interface=pcall(GetBuildInfo)
 if not ok or not public(build)or not public(interface)or type(build)~="string"or build==""or type(interface)~="number"then return end
 return tostring(AUI.version),tostring(build),interface
end
function L:Store()
 ProjectRuthlessCharDB.liveChecks=ProjectRuthlessCharDB.liveChecks or {runs={}}
 local store=ProjectRuthlessCharDB.liveChecks;store.runs=store.runs or {};return store
end
function L:Current(create)
 local version,build,interface=self:Identity();if not version then return end
 local store=self:Store();local run=store.runs[#store.runs]
 if run and run.version==version and run.build==build and run.interface==interface then return run end
 if not create then return end
 run={version=version,build=build,interface=interface,created=stamp(),results={}}
 store.runs[#store.runs+1]=run;while #store.runs>3 do table.remove(store.runs,1)end
 return run
end
function L:Gate(id)for _,gate in ipairs(self.gates)do if gate.id==id then return gate end end end
function L:Observe()
 local errors=AUI.modules.ErrorLog;local store=ProjectRuthlessDB.errorLog or {}
 local diagnostics=AUI.modules.Diagnostics
 return {errors=errors and errors.GetCapturedCount and errors:GetCapturedCount(),capture=store.enabled==true,recording=diagnostics and diagnostics.session~=nil or false,combat=InCombatLockdown()==true,profile=ProjectRuthlessCharDB.activeProfile}
end
function L:Begin(id)
 if not self:Gate(id)then return false,"Unknown live check."end
 local run=self:Current(true);if not run then return false,"Client build could not be identified."end
 local previous=run.results[id]
 run.results[id]={status="pending",started=stamp(),before=self:Observe(),note=previous and previous.note or ""}
 return true,"Check started. Perform the steps, then record what happened. Nothing passes automatically."
end
function L:SetResult(id,status,note)
 if not self:Gate(id)or (status~="pending"and status~="pass"and status~="fail")then return false,"Invalid live check or result."end
 if type(note)~="string"or #note>1500 then return false,"Use evidence notes of at most 1,500 bytes."end
 note=note:match("^%s*(.-)%s*$")
 if status~="pending"and note==""then return false,"Describe what you tested and what happened before recording Pass or Fail."end
 local run=self:Current(true);if not run then return false,"Client build could not be identified."end
 local result=run.results[id]or {}
 if status~="pending"and not result.started then return false,"Start this check before recording its result."end
 result.status=status;result.note=note;result.updated=stamp();result.after=self:Observe();run.results[id]=result
 return true,"Result recorded for this RUI version and client build. This is your assessment, not automatic certification."
end
function L:Report()
 local lines={"LIVE CHECKS · SELF-REPORTED", "Manual results do not change the repository release gates or establish a matching source digest."}
 local current=self:Current(false)
 if not current then lines[#lines+1]="Current build: all six checks pending; no results recorded."end
 local store=self:Store()
 for i=#store.runs,1,-1 do local run=store.runs[i]
  lines[#lines+1]=(run==current and "CURRENT "or "HISTORICAL ").."RUI "..tostring(run.version).." | client "..tostring(run.build).." | interface "..tostring(run.interface).." | "..tostring(run.created)
  for _,gate in ipairs(self.gates)do local result=run.results[gate.id]or {status="pending"}
   lines[#lines+1]=gate.title..": "..result.status.." | "..(result.updated or result.started or "not started").." | "..(result.note or "")
   if result.before then
    local after=result.after or (run==current and self:Observe());local before=result.before
    if not after then after={}end
    local delta=type(before.errors)=="number"and type(after.errors)=="number"and after.errors>=before.errors and after.errors-before.errors
    lines[#lines+1]="Observed errors since start: "..(delta and tostring(delta)or "unavailable").." (account log, all addons); capture before/after: "..tostring(before.capture).."/"..tostring(after.capture).."; recording before/after: "..tostring(before.recording).."/"..tostring(after.recording)
   end
  end
 end
 return table.concat(lines,"\n")
end
function L:Refresh()
 local run=self:Current(false);local gate=self:Gate(self.selected or "installation")
 local r,g,b=AUI:AccentColor()
 for _,button in ipairs(self.gateButtons)do
  local result=run and run.results[button.gate.id];local status=result and result.status or "pending"
  local selected=button.gate.id==gate.id
  button:SetText((selected and "› "or "")..button.gate.title.." · "..status);button:SetBackdropBorderColor(r,g,b,selected and 1 or .25)
 end
 local result=run and run.results[gate.id]
 self.instructions:SetText(gate.title.."\n\n"..gate.steps.."\n\nPass and Fail require your evidence. Empty error logs and automated tests do not prove the check passed.")
 self.instructionContent:SetHeight(math.max(260,self.instructions:GetStringHeight()+16))
 local version,build=self:Identity()
 self.identity:SetText("RUI "..tostring(version).." · client "..tostring(build).." · current-character results\nManual evidence only; new builds start pending.")
 local state=result and result.started and ("Started "..result.started.." · "..result.status)or "Not started · pending"
 local observed=self:Observe()
 if result and result.before then
  local before=result.before.errors;local delta=type(before)=="number"and type(observed.errors)=="number"and observed.errors>=before and observed.errors-before
  state=state.."\nNew captured errors: "..(delta and tostring(delta)or "unknown").." · capture "..(observed.capture and "on"or "off").." · recording "..(observed.recording and "on"or "off")
 end
 self.state:SetText(state)
end
function L:Select(id)
 if not self:Gate(id)then return false end
 if self.selected then self.drafts[self.selected]=self.notes:GetText()end
 self.selected=id
 local run=self:Current(false);local result=run and run.results[id]
 self.notes:SetText(self.drafts[id]or result and result.note or "");self:Refresh()
end
function L:Show()
 if not self.frame then
  local f=CreateFrame("Frame","ProjectRuthlessLiveChecks",UIParent,"BackdropTemplate");self.frame=f
  f:SetSize(800,600);f:SetPoint("CENTER");f:SetFrameStrata("DIALOG");f:SetClampedToScreen(true)
  f:SetBackdrop({bgFile="Interface\\Buttons\\WHITE8X8",edgeFile="Interface\\Buttons\\WHITE8X8",edgeSize=1});AUI:StyleSurface(f,"window",1,"Options");f:SetBackdropBorderColor(.18,.2,.24,1)
  f:SetMovable(true);f:EnableMouse(true);f:RegisterForDrag("LeftButton");f:SetScript("OnDragStart",f.StartMoving);f:SetScript("OnDragStop",f.StopMovingOrSizing)
  local access=AUI.modules.Accessibility
  local function label(parent,text,x,y,width)
   local t=parent:CreateFontString(nil,"OVERLAY","GameFontHighlightSmall");t:SetPoint("TOPLEFT",x,y);t:SetWidth(width);t:SetJustifyH("LEFT");t:SetText(text)
   if access then access:RegisterText(t)end;return t
  end
  label(f,"RUI · Live checks",18,-18,720);self.identity=label(f,"",18,-44,740)
  self.gateButtons={};self.drafts={}
  for i,gate in ipairs(self.gates)do
   local b=AUI:CreateButton(f);b:SetSize(185,44);b:SetPoint("TOPLEFT",14,-100-(i-1)*50);b.gate=gate
   b:SetScript("OnClick",function()self:Select(gate.id)end);self.gateButtons[#self.gateButtons+1]=b
  end
  local scroll=AUI:CreateSmoothScrollFrame(f);scroll:SetPoint("TOPLEFT",214,-100);scroll:SetSize(566,220)
  local content=CreateFrame("Frame",nil,scroll);content:SetSize(550,300);scroll:SetScrollChild(content);self.instructionContent=content
  self.instructions=label(content,"",0,-4,540)
  self.state=label(f,"",214,-334,550)
  label(f,"Evidence / what happened (required for Pass or Fail)",214,-390,550)
  local noteScroll=AUI:CreateSmoothScrollFrame(f);noteScroll:SetPoint("TOPLEFT",214,-420);noteScroll:SetSize(566,100)
  local notes=CreateFrame("EditBox",nil,noteScroll);self.notes=notes
  notes:SetMultiLine(true);notes:SetAutoFocus(false);notes:SetFontObject(ChatFontNormal);notes:SetWidth(548);notes:SetMaxLetters(1500)
  noteScroll:SetScrollChild(notes);AUI:ConfigureScrollingEditBox(notes,noteScroll,1)
  notes:SetScript("OnEscapePressed",function()notes:ClearFocus()end)
  local function action(text,x,y,width,fn)
   local b=AUI:CreateButton(f);b:SetPoint("BOTTOMLEFT",x,y);b:SetSize(width,28);b:SetText(text);b:SetScript("OnClick",fn);return b
  end
  action("Start check",214,28,120,function()local _,message=self:Begin(self.selected);AUI:Print(message);self:Refresh()end)
  for i,row in ipairs({{"Pass","pass"},{"Fail","fail"},{"Pending","pending"}})do
   action(row[1],344+(i-1)*105,28,95,function()local _,message=self:SetResult(self.selected,row[2],notes:GetText());AUI:Print(message);self:Refresh()end)
  end
  action("Related settings",14,132,185,function()notes:ClearFocus();local gate=self:Gate(self.selected);AUI.modules.Menu:Show(gate.page)end)
  action("Bug report",14,94,185,function()notes:ClearFocus();AUI.modules.Diagnostics:Show()end)
  action("Close",14,28,185,function()f:Hide()end)
  f:SetScript("OnHide",function()self.drafts[self.selected]=notes:GetText();notes:ClearFocus();f:StopMovingOrSizing()end)
  if UISpecialFrames then UISpecialFrames[#UISpecialFrames+1]="ProjectRuthlessLiveChecks"end
 end
 local version,build=self:Identity();local identity=tostring(version)..":"..tostring(build)
 if identity~=self.displayedIdentity then self.drafts={};self.selected=nil;self.displayedIdentity=identity end
 local access=AUI.modules.Accessibility
 if access then self.frame:SetScale(access:FitWindow(self.frame,(ProjectRuthlessDB.general or {}).windowScale or 1))end
 self:Select(self.selected or "installation");self.frame:Show()
end
