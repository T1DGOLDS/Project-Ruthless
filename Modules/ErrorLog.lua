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

local function FormatEntry(entry, index)
    return ("Project Ruthless Lua Error #%d\nTime: %s\nCount: %d\n\n%s\n\nStack:\n%s"):format(
        index,
        entry.time or "unknown",
        entry.count or 1,
        entry.message or "unknown error",
        entry.stack or "stack unavailable"
    )
end

function ErrorLog:Record(message)
    local store = GetStore()
    if not store or not store.enabled or self.handlingError then
        return
    end

    self.handlingError = true

    local ok = pcall(function()
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
            }
        end

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
        local importedBySource = {}
        for _, entry in ipairs(earlyCapture.entries) do
            store.entries[#store.entries + 1] = entry
            local source = GetSource(entry.message, entry.stack)
            importedBySource[source] = (importedBySource[source] or 0) + (entry.count or 1)
        end
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

    local scroll = CreateFrame("ScrollFrame", nil, frame, "UIPanelScrollFrameTemplate")
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

    frame.editBox = editBox
    self.viewer = frame
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
    C_Timer.After(0, function()
        ErrorLog:Install()
    end)
end
