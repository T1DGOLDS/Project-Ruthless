local addonName, AUI = ...

ProjectRuthless = AUI
AUI.name = addonName
AUI.version = C_AddOns.GetAddOnMetadata(addonName, "Version") or "dev"
AUI.modules = {}

local defaults = {
    enabled = true,
    errorLog = {
        enabled = true,
        entries = {},
        maxEntries = 50,
    },
    elvui = {
        safeTooltip = true,
    },
}

local function ApplyDefaults(target, source)
    for key, value in pairs(source) do
        if type(value) == "table" then
            if type(target[key]) ~= "table" then
                target[key] = {}
            end
            ApplyDefaults(target[key], value)
        elseif target[key] == nil then
            target[key] = value
        end
    end
end

function AUI:RegisterModule(name, module)
    self.modules[name] = module
end

function AUI:Print(message)
    print(("|cff7f5af0Project Ruthless|r: %s"):format(message))
end

function AUI:GetElvUI()
    if type(_G.ElvUI) ~= "table" then
        return nil
    end

    return _G.ElvUI[1]
end

function AUI:ShowStatus()
    local E = self:GetElvUI()
    local elvVersion = E and E.version or "not loaded"
    local tooltipState = ProjectRuthlessDB.elvui.safeTooltip and "enabled" or "disabled"

    self:Print(("v%s | ElvUI: %s | safe tooltip: %s"):format(
        self.version,
        tostring(elvVersion),
        tooltipState
    ))
end

local function HandleSlashCommand(input)
    local command = strtrim(input or ""):lower()

    if command == "" or command == "status" then
        AUI:ShowStatus()
        return
    end

    if command == "tooltip on" then
        ProjectRuthlessDB.elvui.safeTooltip = true
        AUI:Print("Safe tooltip compatibility enabled. Reloading the UI.")
        ReloadUI()
        return
    end

    if command == "tooltip off" then
        ProjectRuthlessDB.elvui.safeTooltip = false
        AUI:Print("Safe tooltip compatibility disabled. This does not re-enable ElvUI tooltips automatically.")
        return
    end

    local errorCommand = command:match("^errors%s*(.*)$")
    if errorCommand ~= nil and AUI.modules.ErrorLog then
        AUI.modules.ErrorLog:HandleCommand(errorCommand)
        return
    end

    AUI:Print("Commands: /pr, /pr status, /pr errors, /pr errors clear, /pr tooltip on, /pr tooltip off")
end

local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("ADDON_LOADED")
eventFrame:RegisterEvent("PLAYER_LOGIN")
eventFrame:SetScript("OnEvent", function(_, event, loadedAddon)
    if event == "ADDON_LOADED" and loadedAddon == addonName then
        ProjectRuthlessDB = ProjectRuthlessDB or {}
        ProjectRuthlessCharDB = ProjectRuthlessCharDB or {}
        ApplyDefaults(ProjectRuthlessDB, defaults)

        SLASH_PROJECTRUTHLESS1 = "/pr"
        SlashCmdList.PROJECTRUTHLESS = HandleSlashCommand

        for _, module in pairs(AUI.modules) do
            if module.OnAddonLoaded then
                module:OnAddonLoaded()
            end
        end
    elseif event == "PLAYER_LOGIN" then
        for _, module in pairs(AUI.modules) do
            if module.OnPlayerLogin then
                module:OnPlayerLogin()
            end
        end

        if not ProjectRuthlessCharDB.welcomed then
            AUI:Print(("v%s loaded. Type /pr for status."):format(AUI.version))
            ProjectRuthlessCharDB.welcomed = true
        end
    end
end)
