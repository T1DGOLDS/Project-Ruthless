local addonName, AUI = ...

AndrewUI = AUI
AUI.name = addonName
AUI.version = C_AddOns.GetAddOnMetadata(addonName, "Version") or "dev"
AUI.modules = {}

local defaults = {
    enabled = true,
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
    print(("|cff7f5af0AndrewUI|r: %s"):format(message))
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
    local tooltipState = AndrewUIDB.elvui.safeTooltip and "enabled" or "disabled"

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
        AndrewUIDB.elvui.safeTooltip = true
        AUI:Print("Safe tooltip compatibility enabled. Reloading the UI.")
        ReloadUI()
        return
    end

    if command == "tooltip off" then
        AndrewUIDB.elvui.safeTooltip = false
        AUI:Print("Safe tooltip compatibility disabled. This does not re-enable ElvUI tooltips automatically.")
        return
    end

    AUI:Print("Commands: /aui, /aui status, /aui tooltip on, /aui tooltip off")
end

local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("ADDON_LOADED")
eventFrame:RegisterEvent("PLAYER_LOGIN")
eventFrame:SetScript("OnEvent", function(_, event, loadedAddon)
    if event == "ADDON_LOADED" and loadedAddon == addonName then
        AndrewUIDB = AndrewUIDB or {}
        AndrewUICharDB = AndrewUICharDB or {}
        ApplyDefaults(AndrewUIDB, defaults)

        SLASH_ANDREWUI1 = "/aui"
        SlashCmdList.ANDREWUI = HandleSlashCommand

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

        if not AndrewUICharDB.welcomed then
            AUI:Print(("v%s loaded. Type /aui for status."):format(AUI.version))
            AndrewUICharDB.welcomed = true
        end
    end
end)
