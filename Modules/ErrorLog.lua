local _, AUI = ...

local ErrorLog = {
    handlingError = false,
    pendingNotices = {},
    noticeScheduled = false,
    noticeCooldown = {},
}
AUI:RegisterModule("ErrorLog", ErrorLog)

local function GetStore()
    return ProjectRuthlessDB and ProjectRuthlessDB.errorLog
end

-- A cumulative observation counter survives retention trimming and Clear log.
-- It describes captured errors from all addons, not proven RUI failures.
function ErrorLog:GetCapturedCount()
    local store=GetStore();if not store then return end
    if type(store.capturedTotal)~="number"then
        local count=0;for _,entry in ipairs(store.entries or {})do count=count+(type(entry.count)=="number"and entry.count or 1)end
        store.capturedTotal=count
    end
    return store.capturedTotal
end

local function GetSource(message, stack)
    local text = tostring(message or "") .. "\n" .. tostring(stack or "")
    local addon = text:match("[/\\]AddOns[/\\]([^/\\]+)")
    if addon then
        return addon
    end

    if text:match("Interface[/\\]FrameXML") or text:match("Interface[/\\]AddOns[/\\]Blizzard_") then
        return "Blizzard UI"
    end

    return "Unknown addon"
end

-- Inspect taint provenance only after this specific failure; never read cooldowns.
function ErrorLog:ActionBarTaintDetails()
    if not AUI.isForever or type(issecurevariable)~="function"then return end
    local lines={};local function check(owner,key,label)
        local ok,clean,source=pcall(issecurevariable,owner,key)
        if ok and clean==false then lines[#lines+1]=label.." = "..(type(source)=="string"and source or "tainted")end
    end
    for _,name in ipairs({"ActionButton_UpdateCooldown","ActionButton_ApplyCooldown","ActionBarButtonEventsFrame"})do check(_G,name,name)end
    local registry=ActionBarButtonEventsFrame
    if registry then
        check(registry,"frames","ActionBarButtonEventsFrame.frames");check(registry,"OnEvent","ActionBarButtonEventsFrame.OnEvent")
        if type(registry.frames)=="table"then
            for key in pairs(registry.frames)do check(registry.frames,key,"ActionBarButtonEventsFrame.frames["..tostring(key).."]")end
        end
    end
    for _,prefix in ipairs({"ActionButton","MultiBarBottomLeftButton","MultiBarBottomRightButton","MultiBarRightButton","MultiBarLeftButton","MultiBar5Button","MultiBar6Button","MultiBar7Button"})do
        for i=1,12 do local name=prefix..i;local button=_G[name]
            if button then for _,key in ipairs({"action","spellID","cooldown","chargeCooldown","lossOfControlCooldown","enableLOCCooldown","OnEvent"})do check(button,key,name.."."..key)end end
        end
    end
    if #lines==0 then return "No tainted action-button fields found; upstream execution taint still requires a live taint log."end
    return table.concat(lines,"\n",1,math.min(#lines,32))
end
local function FormatEntry(entry, index)
    return ("Project Ruthless Lua Error #%d\nTime: %s\nCount: %d\n\n%s\n\nStack:\n%s"):format(
        index,
        entry.time or "unknown",
        entry.count or 1,
        entry.message or "unknown error",
        (entry.stack or "stack unavailable")..(entry.actionBarTaint and "\n\nAction-bar taint provenance:\n"..entry.actionBarTaint or "")
    )
end

function ErrorLog:Record(message)
    local store = GetStore()
    if not store or not store.enabled or self.handlingError then
        return
    end

    self.handlingError = true

    local ok = pcall(function()
        local captured=self:GetCapturedCount()
        local text = tostring(message or "unknown error")
        local stack = debugstack and debugstack(3, 20, 20) or "stack unavailable"
        local entries = store.entries
        local latest = entries[#entries]

        if latest and latest.message == text and latest.stack == stack then
            latest.count = (latest.count or 1) + 1
            latest.time = date("%Y-%m-%d %H:%M:%S")
        else
            entries[#entries + 1] = {
                time = date("%Y-%m-%d %H:%M:%S"),
                message = text,
                stack = stack,
                count = 1,
                actionBarTaint = text:find("SetCooldown",1,true)and self:ActionBarTaintDetails()or nil,
            }
        end

        store.capturedTotal=captured+1
        self:QueueNotice(GetSource(text, stack), 1)

        while #entries > store.maxEntries do
            table.remove(entries, 1)
        end
    end)

    self.handlingError = false
    return ok
end

function ErrorLog:QueueNotice(source, count)
    self.pendingNotices[source] = (self.pendingNotices[source] or 0) + (count or 1)
    if self.noticeScheduled then
        return
    end

    self.noticeScheduled = true
    C_Timer.After(1.5, function()
        ErrorLog:FlushNotices()
    end)
end

function ErrorLog:FlushNotices()
    self.noticeScheduled = false
    local now = GetTime()

    for source, count in pairs(self.pendingNotices) do
        self.pendingNotices[source] = nil
        local lastNotice = self.noticeCooldown[source]
        if not lastNotice or now - lastNotice >= 30 then
            if count >= 3 then
                AUI:Print(("%s is causing lots of Lua errors. See /pr errors."):format(source))
            else
                AUI:Print(("%s caused a Lua error. See /pr errors."):format(source))
            end
            self.noticeCooldown[source] = now
        end
    end
end

function ErrorLog:Install()
    if self.installed then
        return
    end

    local earlyCapture = _G.ProjectRuthlessEarlyCapture
    if earlyCapture and earlyCapture.entries then
        local store = GetStore()
        local captured=self:GetCapturedCount()
        local importedBySource = {}
        for _, entry in ipairs(earlyCapture.entries) do
            store.entries[#store.entries + 1] = entry
            local source = GetSource(entry.message, entry.stack)
            importedBySource[source] = (importedBySource[source] or 0) + (entry.count or 1)
            captured=captured+(entry.count or 1)
        end
        store.capturedTotal=captured
        while #store.entries > store.maxEntries do
            table.remove(store.entries, 1)
        end
        wipe(earlyCapture.entries)
        earlyCapture.forwardOnly = true

        for source, count in pairs(importedBySource) do
            self:QueueNotice(source, count)
        end
    end

    seterrorhandler(function(message)
        ErrorLog:Record(message)
    end)

    self.installed = true
end

function ErrorLog:CreateViewer()
    if self.viewer then
        return self.viewer
    end

    local frame = CreateFrame("Frame", "ProjectRuthlessErrorLogFrame", UIParent, "BasicFrameTemplateWithInset")
    frame:SetSize(760, 520)
    frame:SetPoint("CENTER")
    frame:SetFrameStrata("DIALOG")
    frame:SetClampedToScreen(true)
    frame:SetMovable(true)
    frame:EnableMouse(true)
    frame:RegisterForDrag("LeftButton")
    frame:SetScript("OnDragStart", frame.StartMoving)
    frame:SetScript("OnDragStop", frame.StopMovingOrSizing)
    frame.TitleText:SetText("Project Ruthless — Lua Error Log")

    local scroll = AUI:CreateSmoothScrollFrame(frame)
    scroll:SetPoint("TOPLEFT", 12, -34)
    scroll:SetPoint("BOTTOMRIGHT", -30, 12)

    local editBox = CreateFrame("EditBox", nil, scroll)
    editBox:SetMultiLine(true)
    editBox:SetAutoFocus(false)
    editBox:SetFontObject(ChatFontNormal)
    editBox:SetWidth(700)
    editBox:SetTextInsets(8, 8, 8, 8)
    editBox:SetScript("OnEscapePressed", function()
        frame:Hide()
    end)
    scroll:SetScrollChild(editBox)
    AUI:ConfigureScrollingEditBox(editBox,scroll,1)

    frame.editBox = editBox
    self.viewer = frame
    if UISpecialFrames then UISpecialFrames[#UISpecialFrames+1]="ProjectRuthlessErrorLogFrame"end
    return frame
end

function ErrorLog:GetFormattedText()
    local store = GetStore()
    local entries = store and store.entries or {}
    local output = {}

    if #entries == 0 then
        output[1] = "No Lua errors have been captured."
    else
        for index = #entries, 1, -1 do
            output[#output + 1] = FormatEntry(entries[index], index)
        end
    end

    return table.concat(output, "\n\n----------------------------------------\n\n"), #entries
end

function ErrorLog:Show()
    if AUI.modules.Menu then
        AUI.modules.Menu:Show("errors")
        return
    end

    local text = self:GetFormattedText()
    local viewer = self:CreateViewer()
    viewer.editBox:SetText(text)
    viewer.editBox:SetCursorPosition(0)
    viewer:Show()
end

function ErrorLog:HandleCommand(command)
    local store = GetStore()
    command = strtrim(command or ""):lower()

    if command == "clear" then
        self:GetCapturedCount()
        wipe(store.entries)
        AUI:Print("Lua error log cleared.")
        if AUI.modules.Menu and AUI.modules.Menu.frame and AUI.modules.Menu.frame:IsShown() then
            AUI.modules.Menu:Refresh()
        elseif self.viewer and self.viewer:IsShown() then
            self:Show()
        end
        return
    end

    if command == "on" then
        store.enabled = true
        AUI:Print("Lua error logging enabled.")
        return
    end

    if command == "off" then
        store.enabled = false
        AUI:Print("Lua error logging disabled.")
        return
    end

    if command == "test" then
        error("Project Ruthless error logger test")
        return
    end

    if command == "" or command == "show" then
        local _, count = self:GetFormattedText()
        self:Show()
        AUI:Print(("Showing %d captured Lua error(s)."):format(count))
        return
    end

    AUI:Print("Error commands: /pr errors, /pr errors clear, /pr errors test, /pr errors on, /pr errors off")
end

function ErrorLog:OnPlayerLogin()
    if not self.installed then self:Install()end
end
