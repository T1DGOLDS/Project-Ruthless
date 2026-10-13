local _,AUI=...
local D={}
AUI:RegisterModule("Diagnostics",D)
local function public(value)return not (issecretvalue and issecretvalue(value))end
local function number(value)return public(value)and type(value)=="number"and value==value and value>=0 and value<math.huge end
local function read(fn,...)
    if type(fn)~="function"then return end
    local ok,value=pcall(fn,...);if ok and public(value)then return value end
end
local function stamp()return type(date)=="function"and date("%Y-%m-%d %H:%M:%S")or "unknown"end
local function shown(value)return number(value)and ("%.3f"):format(value)or "unavailable"end
function D:Store()
    ProjectRuthlessCharDB.developerLog=ProjectRuthlessCharDB.developerLog or {enabled=false,sessions={}}
    local store=ProjectRuthlessCharDB.developerLog;store.sessions=store.sessions or {};return store
end
function D:Metric(name,key)
    local api=C_AddOnProfiler;local metrics=Enum and Enum.AddOnProfilerMetric
    if not api or not metrics or metrics[key]==nil or read(api.IsEnabled)==false then return end
    local value=read(api.GetAddOnMetric,name,metrics[key]);if number(value)then return value end
end
function D:Memory()
    -- Native refresh measures all addons. Pace it, outside combat, only in test mode.
    if InCombatLockdown()then return end
    local api=C_AddOns or {};local refresh=api.UpdateAddOnMemoryUsage or UpdateAddOnMemoryUsage
    local getter=api.GetAddOnMemoryUsage or GetAddOnMemoryUsage
    if type(refresh)~="function"or type(getter)~="function"then return end
    if not pcall(refresh)then return end
    local total,found=0,false
    for _,name in ipairs({AUI.name,"ProjectRuthless_Options","ProjectRuthless_DungeonData"})do
        local value=read(getter,name);if number(value)then total=total+value;found=true end
    end
    if found then return total end
end
function D:Sample()
    local session=self.session;if not session then return end
    local now=GetTime();local sample={seconds=now-session.started,cpu=self:Metric(AUI.name,"RecentAverageTime"),peak=self:Metric(AUI.name,"PeakTime"),over5=self:Metric(AUI.name,"CountTimeOver5Ms"),over50=self:Metric(AUI.name,"CountTimeOver50Ms"),combat=self.combat==true}
    sample.optionsCPU=self:Metric("ProjectRuthless_Options","RecentAverageTime")
    sample.dataCPU=self:Metric("ProjectRuthless_DungeonData","RecentAverageTime")
    local fps=read(GetFramerate);if number(fps)then sample.fps=fps end
    if not self.nextMemory or now>=self.nextMemory then
        local memory=self:Memory()
        if number(memory)then
            sample.memoryKB=memory;session.firstMemoryKB=session.firstMemoryKB or memory;session.lastMemoryKB=memory
            session.peakMemoryKB=math.max(session.peakMemoryKB or 0,memory);self.nextMemory=now+30
        elseif not InCombatLockdown()then self.nextMemory=now+30 end
    end
    if number(sample.cpu)then session.cpuSum=(session.cpuSum or 0)+sample.cpu;session.cpuSamples=(session.cpuSamples or 0)+1 end
    if number(sample.over5)then session.firstOver5=session.firstOver5 or sample.over5;session.over5=sample.over5 end
    if number(sample.over50)then session.firstOver50=session.firstOver50 or sample.over50;session.over50=sample.over50 end
    session.samples[#session.samples+1]=sample;if #session.samples>240 then table.remove(session.samples,1)end
    session.duration=sample.seconds;session.lastSeen=stamp()
end
function D:Start()
    if self.session then return end
    local store=self:Store();store.enabled=true
    local version,build,_,interface=GetBuildInfo()
    local session={version=AUI.version,client=version,build=build,interface=interface,started=GetTime(),time=stamp(),samples={},frames=0,frameMS=0,maxFrameMS=0,framesOver50=0,framesOver100=0}
    store.sessions[#store.sessions+1]=session;while #store.sessions>5 do table.remove(store.sessions,1)end
    self.session=session;self.nextMemory=nil;self.combat=InCombatLockdown()
    if not self.events then self.events=CreateFrame("Frame")end
    self.events:RegisterEvent("PLAYER_REGEN_DISABLED");self.events:RegisterEvent("PLAYER_REGEN_ENABLED");self.events:RegisterEvent("PLAYER_LOGOUT")
    self.events:SetScript("OnEvent",function(_,event)
        if event=="PLAYER_LOGOUT"then self:Stop(true)else self.combat=event=="PLAYER_REGEN_DISABLED";self:Sample()end
    end)
    self.events:SetScript("OnUpdate",function(_,elapsed)
        if not number(elapsed)then return end
        local ms=elapsed*1000;session.frames=session.frames+1;session.frameMS=session.frameMS+ms;session.maxFrameMS=math.max(session.maxFrameMS,ms)
        if ms>50 then session.framesOver50=session.framesOver50+1 end
        if ms>100 then session.framesOver100=session.framesOver100+1 end
    end)
    self:Sample();self.timer=C_Timer.NewTicker(2,function()self:Sample()end)
end
function D:Stop(keepEnabled)
    if self.session then self:Sample();self.session.stopped=stamp()end
    self.session=nil;if self.timer then self.timer:Cancel();self.timer=nil end
    if self.events then self.events:UnregisterAllEvents();self.events:SetScript("OnUpdate",nil);self.events:SetScript("OnEvent",nil)end
    if not keepEnabled then self:Store().enabled=false end
end
function D:OnPlayerLogin()if AUI.isForever and self:Store().enabled then self:Start()end end
function D:Checks()
    local rows={}
    local function add(status,message,setting)rows[#rows+1]={status=status,message=message,setting=setting}end
    local quest=ProjectRuthlessDB.questWorkspace or {}
    if quest.enabled==false then add("INFO","RUI quest tracker is off by choice.","Map & quests > Compact quest workspace")end
    local source=quest.guideSource or "RUI"
    if source~="RUI"then
        local workspace=AUI.modules.QuestWorkspace
        if not workspace or not workspace:ReadGuide()then add("WARNING","Selected guide has no readable current step. It may be stopped, unavailable or unsupported.","Map > Library > Guide source")end
    end
    if not CustomAuraContainerGroupDefaultOptions then add("WARNING","Native party aura templates are unavailable in this client; party aura containers cannot be initialized.","Unit frames > Party auras (client capability)")end
    add("INFO",AUI.modules.UnifiedProfiles and "Settings and Edit Mode share account profiles. Legacy partial saves are labelled; save again to capture a complete setup."or "Settings profiles and layout profiles are separate in this client.","Profiles / Edit Mode")
    local api=C_AddOns
    if api and type(api.IsAddOnLoaded)=="function"then
        -- Detection only. Never load, hook, disable or rewrite these addons.
        for _,name in ipairs({"ElvUI","EllesmereUI","EllesmereUIActionBars","EllesmereUIUnitFrames","NDui","GW2_UI","Cell","Bagnon","Leatrix_Plus","Leatrix_Maps"})do
            local loaded=read(api.IsAddOnLoaded,name)
            if loaded==true then add("POSSIBLE CONFLICT",name.." is loaded and may control overlapping UI features. Presence alone does not prove a conflict.","Help > Compatibility")end
        end
    end
    return rows
end
function D:Report(notes)
    local lines={"RUI BUG REPORT", "Created: "..stamp(),"Version: "..tostring(AUI.version),"Interface: "..tostring(AUI.interfaceVersion),"Combat: "..tostring(InCombatLockdown()),"Steps / expected / actual: "..tostring(notes or ""),"","CONFIGURATION CHECKS"}
    for _,check in ipairs(self:Checks())do lines[#lines+1]=check.status..": "..check.message.." ["..check.setting.."]"end
    lines[#lines+1]="";lines[#lines+1]="LOCAL PERFORMANCE RECORDINGS"
    lines[#lines+1]="Sampled recent CPU averages are ms/tick, not total CPU. Native peaks/counters span the application session. Frame gaps include the entire game and are not attributed to RUI."
    lines[#lines+1]="Memory is native per-addon sampled KiB; exact allocation counts are not exposed. Test recording adds overhead. No data is sent automatically."
    for _,session in ipairs(self:Store().sessions)do
        lines[#lines+1]=("%s | RUI %s | client %s build %s | %.1fs"):format(session.time,tostring(session.version),tostring(session.client),tostring(session.build),session.duration or 0)
        local mean=session.cpuSamples and session.cpuSamples>0 and session.cpuSum/session.cpuSamples
        lines[#lines+1]="Mean of sampled recent RUI CPU: "..shown(mean).."; mean frame gap: "..shown(session.frames>0 and session.frameMS/session.frames).." ms; largest gap: "..shown(session.maxFrameMS).." ms; gaps >50/100ms: "..tostring(session.framesOver50).."/"..tostring(session.framesOver100)
        lines[#lines+1]="RUI main-addon CPU ticks >5/50ms during recording: "..shown(session.over5 and session.over5-session.firstOver5).."/"..shown(session.over50 and session.over50-session.firstOver50)
        lines[#lines+1]="RUI package memory first/last/peak KiB: "..shown(session.firstMemoryKB).."/"..shown(session.lastMemoryKB).."/"..shown(session.peakMemoryKB)
        lines[#lines+1]="seconds,combat,recent_main_ms,options_ms,data_ms,app_session_main_peak_ms,fps,memory_KiB"
        for i=math.max(1,#session.samples-59),#session.samples do local s=session.samples[i]
            lines[#lines+1]=table.concat({shown(s.seconds),tostring(s.combat),shown(s.cpu),shown(s.optionsCPU),shown(s.dataCPU),shown(s.peak),shown(s.fps),shown(s.memoryKB)},",")
        end
    end
    local errors=AUI.modules.ErrorLog
    lines[#lines+1]="";lines[#lines+1]="CAPTURED LUA ERRORS (may include other addons)"
    if errors and errors.GetFormattedText then lines[#lines+1]=errors:GetFormattedText()end
    return table.concat(lines,"\n")
end
function D:Show()
    if not self.frame then
        local f=CreateFrame("Frame","ProjectRuthlessBugReporter",UIParent,"BackdropTemplate");f:SetSize(700,540);f:SetPoint("CENTER");f:SetFrameStrata("DIALOG");f:SetClampedToScreen(true)
        f:SetBackdrop({bgFile="Interface\\Buttons\\WHITE8X8",edgeFile="Interface\\Buttons\\WHITE8X8",edgeSize=1});AUI:StyleSurface(f,"window",1,"Options");f:SetBackdropBorderColor(unpack(AUI.Theme.border))
        local title=f:CreateFontString(nil,"OVERLAY","GameFontNormalLarge");title:SetPoint("TOPLEFT",16,-14);title:SetText("RUI · Testing & bug report")
        local label=f:CreateFontString(nil,"OVERLAY","GameFontHighlightSmall");label:SetPoint("TOPLEFT",16,-45);label:SetText("Describe the steps, expected result and actual result. Copy the report to share it.")
        self.notes=CreateFrame("EditBox",nil,f,"InputBoxTemplate");self.notes:SetPoint("TOPLEFT",20,-70);self.notes:SetSize(650,26);self.notes:SetAutoFocus(false);self.notes:SetMaxLetters(1500)
        local scroll=AUI:CreateSmoothScrollFrame(f);scroll:SetPoint("TOPLEFT",12,-112);scroll:SetPoint("BOTTOMRIGHT",-12,58)
        self.copy=CreateFrame("EditBox",nil,scroll);self.copy:SetMultiLine(true);self.copy:SetAutoFocus(false);self.copy:SetFontObject(ChatFontNormal);self.copy:SetWidth(640);self.copy:SetTextInsets(8,8,8,8);scroll:SetScrollChild(self.copy);AUI:ConfigureScrollingEditBox(self.copy,scroll,1)
        local function refresh()self.copy:SetText(self:Report(self.notes:GetText()));self.copy:SetCursorPosition(0)end
        for i,row in ipairs({{"Record on",function()self:Start();refresh()end},{"Record off",function()self:Stop();refresh()end},{"Refresh report",refresh},{"Select report",function()refresh();self.copy:SetFocus();self.copy:HighlightText()end},{"Close",function()f:Hide()end}})do
            local button=AUI:CreateButton(f);button:SetPoint("BOTTOMLEFT",12+(i-1)*136,16);button:SetSize(128,26);button:SetText(row[1]);button:SetScript("OnClick",row[2])
        end
        self.copy:SetScript("OnEscapePressed",function()f:Hide()end);self.notes:SetScript("OnEscapePressed",function()self.notes:ClearFocus()end)
        if UISpecialFrames then UISpecialFrames[#UISpecialFrames+1]="ProjectRuthlessBugReporter"end;self.frame=f
    end
    self.copy:SetText(self:Report(self.notes:GetText()));self.copy:SetCursorPosition(0);self.frame:Show()
end
function D:HandleCommand(command)
    if command=="record on"then self:Start();AUI:Print("Local test recording enabled. Use /pr report to copy results; /pr record off stops it.")
    elseif command=="record off"then self:Stop();AUI:Print("Recording stopped; results retained locally.")
    else self:Show()end
end
