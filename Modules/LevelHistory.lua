local _,AUI=...
local L={};AUI:RegisterModule("LevelHistory",L)
local function publicNumber(v)return not (issecretvalue and issecretvalue(v))and type(v)=="number"and v==v and v>=0 and v<math.huge end
local function elapsed(v)
    if not publicNumber(v)then return "Unknown"end
    local seconds=math.floor(v)
    return ("%dh %02dm %02ds"):format(math.floor(seconds/3600),math.floor(seconds/60)%60,seconds%60)
end
function L:Store()
    ProjectRuthlessDB.levelHistory=ProjectRuthlessDB.levelHistory or {version=1,characters={}}
    return ProjectRuthlessDB.levelHistory.characters
end
function L:Character()
    local guid=UnitGUID("player")
    if (issecretvalue and issecretvalue(guid))or type(guid)~="string"then return end
    local records=self:Store();local record=records[guid]
    if not record then record={levels={[1]={played=0,source="origin"}}};records[guid]=record end
    local name,realm=UnitFullName("player");local className,class=UnitClass("player")
    record.name=name;record.realm=realm or GetRealmName();record.class=class;record.className=className
    local cap=type(GetMaxPlayerLevel)=="function"and GetMaxPlayerLevel()
    if publicNumber(cap)and cap>0 then record.cap=cap end
    self.guid=guid;self.record=record
    return record
end
function L:TotalNow()
    if not self.anchor then return end
    return self.anchor.played+math.max(0,GetTime()-self.anchor.time)
end
function L:Mark(level,played,stamp,source)
    if not publicNumber(level)or level<1 or level~=math.floor(level)or not publicNumber(played)then return end
    local record=self.record
    if not record or record.levels[level]then return end
    -- A missing earlier milestone stays unknown; do not interpolate levels.
    record.levels[level]={played=played,at=stamp,source=source}
end
function L:ReceivePlayed(total,thisLevel)
    if not publicNumber(total)or not publicNumber(thisLevel)or thisLevel>total or not self.record then return end
    local now=GetTime();self.anchor={played=total,time=now}
    for _,ding in ipairs(self.pending or {})do
        self:Mark(ding.level,math.max(0,total-(now-ding.time)),ding.at,"observed")
    end
    self.pending={}
    -- The server knows when the current level began, even on an existing character.
    -- Its wall-clock timestamp cannot be reconstructed across offline periods.
    self:Mark(self.level,total-thisLevel,nil,"server baseline")
    self.record.totalPlayed=total;self.record.level=self.level;self.record.lastSeen=GetServerTime()
    self:Refresh()
end
function L:LevelUp(level)
    if not publicNumber(level)or level<1 then return end
    if self.level and level<=self.level then return end
    self.level=level
    if not self.record then return end
    self.record.level=level
    local total=self:TotalNow();local stamp=GetServerTime()
    if total then self:Mark(level,total,stamp,"observed")else
        self.pending=self.pending or {};self.pending[#self.pending+1]={level=level,time=GetTime(),at=stamp}
    end
    self:Refresh()
end
function L:Range(record,first,last)
    local a,b=record.levels[first],record.levels[last]
    if not a or not b or not publicNumber(a.played)or not publicNumber(b.played)or b.played<a.played then return end
    return b.played-a.played
end
function L:Compare(first,last)
    local fastest,classes=nil,{}
    for guid,record in pairs(self:Store())do
        local seconds=self:Range(record,first,last)
        if seconds then
            if not fastest or seconds<fastest.seconds then fastest={guid=guid,record=record,seconds=seconds}end
            local class=record.className or record.class or "Unknown"
            local row=classes[class]or {name=class,total=0,count=0};classes[class]=row
            row.total=row.total+seconds;row.count=row.count+1
        end
    end
    local rows={};for _,row in pairs(classes)do row.average=row.total/row.count;rows[#rows+1]=row end
    table.sort(rows,function(a,b)if a.average==b.average then return a.name<b.name end;return a.average>b.average end)
    return fastest,rows
end
function L:Report(first,last)
    local lines={("LEVELING HISTORY   |   %d → %d"):format(first,last),"Played time includes AFK time, as /played does. Offline time is excluded.",""}
    local fastest,classes=self:Compare(first,last)
    lines[#lines+1]=fastest and ("Fastest: %s — %s"):format(fastest.record.name,elapsed(fastest.seconds))or "Fastest: no complete record for this range yet."
    lines[#lines+1]="Class averages for this range (slowest first):"
    for _,row in ipairs(classes)do lines[#lines+1]=("  %s   %s   ·   %d character(s)"):format(row.name,elapsed(row.average),row.count)end
    if #classes==0 then lines[#lines+1]="  No qualifying characters yet."end
    lines[#lines+1]="";lines[#lines+1]="CHARACTERS"
    local records={};for guid,record in pairs(self:Store())do records[#records+1]={guid=guid,record=record}end
    table.sort(records,function(a,b)return (a.record.name or "")<(b.record.name or "")end)
    for _,row in ipairs(records)do local r=row.record
        local cap=r.cap;local capped=cap and self:Range(r,1,cap)
        lines[#lines+1]=("%s · %s · Lv %s | %d–%d: %s | 1–%s: %s"):format(r.name or "?",r.className or "?",r.level or "?",first,last,elapsed(self:Range(r,first,last)),cap or "max",elapsed(capped))
    end
    local selected=self:Store()[self.selected or self.guid]
    if selected then
        lines[#lines+1]="";lines[#lines+1]="LEVELS · "..(selected.name or "?")
        for level=2,selected.level or 1 do local mark=selected.levels[level]
            local when=mark and mark.at and date("%Y-%m-%d %H:%M:%S",mark.at)or "Timestamp unknown"
            lines[#lines+1]=("%d → %d   %s   |   Total: %s   |   %s"):format(level-1,level,elapsed(self:Range(selected,level-1,level)),elapsed(mark and mark.played),when)
        end
    end
    lines[#lines+1]="";lines[#lines+1]="Missing older levels stay unknown. Recorded level-ups use a session clock anchored to server /played (second-level precision)."
    return table.concat(lines,"\n")
end
function L:Refresh()
    if not self.frame or not self.frame:IsShown()then return end
    local first,last=tonumber(self.first:GetText()),tonumber(self.last:GetText())
    if not publicNumber(first)or not publicNumber(last)or first<1 or last<=first or last>200 or first~=math.floor(first)or last~=math.floor(last)then self.body:SetText("Enter two whole levels, from 1 up to your desired ending level.");return end
    self.body:SetText(self:Report(first,last));self.content:SetHeight(math.max(360,self.body:GetStringHeight()+20))
end
function L:CharacterMenu(anchor)
    if not MenuUtil then return end
    MenuUtil.CreateContextMenu(anchor,function(_,root)
        root:CreateTitle("Level history for character")
        local rows={};for guid,record in pairs(self:Store())do rows[#rows+1]={guid=guid,record=record}end
        table.sort(rows,function(a,b)return (a.record.name or "")<(b.record.name or "")end)
        for _,row in ipairs(rows)do local guid=row.guid
            root:CreateRadio((row.record.name or "?").." · "..(row.record.realm or ""),function()return (self.selected or self.guid)==guid end,function()self.selected=guid;self:Refresh()end)
        end
    end)
end
function L:Show()
    if not self.frame then
        local f=CreateFrame("Frame","ProjectRuthlessLevelHistory",UIParent,"BackdropTemplate");self.frame=f
        f:SetSize(790,540);f:SetPoint("CENTER");f:SetClampedToScreen(true);f:SetFrameStrata("DIALOG")
        f:SetBackdrop({bgFile="Interface\\Buttons\\WHITE8X8",edgeFile="Interface\\Buttons\\WHITE8X8",edgeSize=1});AUI:StyleSurface(f,"window",.97)
        f:SetMovable(true);f:EnableMouse(true);f:RegisterForDrag("LeftButton");f:SetScript("OnDragStart",function()f:StartMoving()end);f:SetScript("OnDragStop",function()f:StopMovingOrSizing()end)
        local title=f:CreateFontString(nil,"OVERLAY","GameFontNormalLarge");title:SetPoint("TOPLEFT",18,-16);title:SetText("RUI · Leveling history");title:SetTextColor(AUI:AccentColor())
        local function button(text,x,width,fn)local b=AUI:CreateButton(f);b:SetPoint("TOPLEFT",x,-48);b:SetSize(width,24);b:SetText(text);b:SetScript("OnClick",fn);return b end
        local function input(x,value)local box=CreateFrame("EditBox",nil,f,"InputBoxTemplate");box:SetPoint("TOPLEFT",x,-48);box:SetSize(45,24);box:SetAutoFocus(false);box:SetMaxLetters(3);box:SetText(value);box:SetScript("OnEnterPressed",function(b)b:ClearFocus();self:Refresh()end);return box end
        self.first=input(24,"1");self.last=input(88,"10")
        button("Compare",146,90,function()self:Refresh()end)
        button("1–max",244,80,function()self.first:SetText("1");self.last:SetText(tostring(self.record and self.record.cap or 60));self:Refresh()end)
        button("Character",332,130,function(b)self:CharacterMenu(b)end)
        local close=AUI:CreateButton(f);close:SetPoint("TOPRIGHT",-12,-12);close:SetSize(24,24);close:SetText("×");close:SetScript("OnClick",function()f:Hide()end)
        local scroll=AUI:CreateSmoothScrollFrame(f);scroll:SetPoint("TOPLEFT",18,-88);scroll:SetPoint("BOTTOMRIGHT",-24,18)
        local child=CreateFrame("Frame",nil,scroll);child:SetWidth(730);scroll:SetScrollChild(child)
        local body=child:CreateFontString(nil,"OVERLAY","GameFontNormalSmall");body:SetPoint("TOPLEFT");body:SetWidth(718);body:SetJustifyH("LEFT");body:SetSpacing(5);self.body=body
        self.content=child
        if UISpecialFrames then UISpecialFrames[#UISpecialFrames+1]="ProjectRuthlessLevelHistory"end
    end
    self.frame:Show();self:Refresh()
end
function L:OnPlayerLogin()
    if not AUI.isForever then return end
    self.anchor=nil;self:Character();self.level=UnitLevel("player");self.pending={}
    local events=CreateFrame("Frame");self.events=events
    for _,event in ipairs({"TIME_PLAYED_MSG","PLAYER_LEVEL_UP","PLAYER_LOGOUT"})do events:RegisterEvent(event)end
    events:SetScript("OnEvent",function(_,event,a,b)
        if event=="TIME_PLAYED_MSG"then self:ReceivePlayed(a,b)
        elseif event=="PLAYER_LEVEL_UP"then self:LevelUp(a)
        elseif self.record then self.record.totalPlayed=self:TotalNow()or self.record.totalPlayed;self.record.lastSeen=GetServerTime()end
    end)
    -- One baseline request per login; level-up recording itself needs no polling.
    if type(RequestTimePlayed)=="function"then RequestTimePlayed()end
end
