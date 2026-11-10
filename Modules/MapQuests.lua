local _, AUI = ...

local MapQuests = { pendingApply = false }
AUI:RegisterModule("MapQuests", MapQuests)

local function Settings()
    return ProjectRuthlessDB and ProjectRuthlessDB.mapQuests
end

local function SetTrackingFilter(filterID, enabled)
    if not filterID or not C_Minimap or not C_Minimap.SetTracking then return false end
    local index = MinimapUtil and MinimapUtil.GetFilterIndexForFilterID and MinimapUtil.GetFilterIndexForFilterID(filterID)
    if not index and C_Minimap.GetNumTrackingTypes and C_Minimap.GetTrackingFilter then
        for trackingIndex=1,C_Minimap.GetNumTrackingTypes() do
            local filter=C_Minimap.GetTrackingFilter(trackingIndex)
            if filter and filter.filterID==filterID then index=trackingIndex break end
        end
    end
    if not index then return false end
    C_Minimap.SetTracking(index,enabled==true)
    return true
end

local gatheringSpells={trackHerbs={[2383]=true,[8387]=true},trackOre={[2580]=true,[8388]=true}}
function MapQuests:GatherTracking(key,enabled)
    if not C_Minimap or not C_Minimap.GetTrackingInfo or not C_Minimap.GetNumTrackingTypes then return false end
    for index=1,C_Minimap.GetNumTrackingTypes()do
        local info=C_Minimap.GetTrackingInfo(index)
        if info and gatheringSpells[key][info.spellID]then
            if enabled~=nil and info.active~=enabled then C_Minimap.SetTracking(index,enabled)end
            return info.active==true
        end
    end
    return false
end

local hookedProviders=setmetatable({},{__mode="k"})
function MapQuests:InstallIconFilters()
    local map=WorldMapFrame
    if not map or type(map.dataProviders)~="table"then return end
    for provider in pairs(map.dataProviders)do
        local refresh=provider.RefreshAllData
        local key=(FlightPointDataProviderMixin and refresh==FlightPointDataProviderMixin.RefreshAllData and "showFlights")
            or (QuestOfferDataProviderMixin and refresh==QuestOfferDataProviderMixin.RefreshAllData and "enabled")
        if key and not hookedProviders[provider]then
            hookedProviders[provider]=true
            hooksecurefunc(provider,"RefreshAllData",function(current)
                local settings=Settings()
                if settings and settings[key]==false then current:RemoveAllData()end
            end)
        end
    end
end

function MapQuests:RefreshWorldMap(request)
    if not WorldMapFrame or not WorldMapFrame:IsShown() then return end
    self:InstallIconFilters()
    local mapID=WorldMapFrame.GetMapID and WorldMapFrame:GetMapID()
    if request~=false and mapID and C_QuestLine and C_QuestLine.RequestQuestLinesForMap then C_QuestLine.RequestQuestLinesForMap(mapID) end
    if WorldMapFrame.RefreshAllDataProviders then WorldMapFrame:RefreshAllDataProviders() end
    local locations=AUI.modules.QuestLocations
    if locations and locations.points then locations:DrawAreas()end
end

function MapQuests:ApplySettings(key)
    local settings=Settings()
    if not settings then return end
    local visual=({showSpiritHealers="SpiritHealers",showSpiritCoverage="SpiritHealers",flightTimer="FlightTimer",squareMinimap="ForeverMinimap"})[key or ""]
    if visual then local module=AUI.modules[visual];if module then module:ApplySettings(key)end;return end
    if not key then for _,name in ipairs({"SpiritHealers","FlightTimer","ForeverMinimap"})do local module=AUI.modules[name];if module and module.ApplySettings then module:ApplySettings()end end end
    if InCombatLockdown() then self.pendingApply=true; return end
    self.pendingApply=false

    if AUI.isForever then
        self:InstallIconFilters()
        if not key or key=="trackHerbs"or key=="trackOre"then
            for tracking in pairs(gatheringSpells)do
                if (not key or key==tracking)and settings[tracking]~=nil then self:GatherTracking(tracking,settings[tracking])end
            end
        end
        if key=="trackHerbs"or key=="trackOre"then return end
        if SetCVar and (not key or key=="showInstances")then SetCVar("showDungeonEntrancesOnMap",settings.showInstances==false and "0"or "1")end
        if key=="showSkyborne"or key=="showFlights"or key=="showInstances"then self:RefreshWorldMap(false);return end
    end
    local enabled=settings.enabled==true
    -- This is the native master switch for both quest pins and blue objective blobs.
    if SetCVar then SetCVar("questPOI",enabled and "1" or "0") end
    if SetCVar then SetCVar("questPOILocalStory",enabled and settings.showLocalStories and "1" or "0") end
    if Enum and Enum.MinimapTrackingFilter then
        SetTrackingFilter(Enum.MinimapTrackingFilter.TrivialQuests,enabled and settings.showTrivial)
        SetTrackingFilter(Enum.MinimapTrackingFilter.AccountCompletedQuests,enabled and settings.showAccountCompleted)
    end
    self:RefreshWorldMap()
end

function MapQuests:OnPlayerLogin()
    self:ApplySettings()
    local events=CreateFrame("Frame")
    events:RegisterEvent("PLAYER_ENTERING_WORLD")
    if AUI.isForever then events:RegisterEvent("ADDON_LOADED")end
    events:RegisterEvent("PLAYER_REGEN_ENABLED")
    events:RegisterEvent("QUESTLINE_UPDATE")
    events:SetScript("OnEvent",function(_,event,addon)
        if event=="ADDON_LOADED"and addon=="Blizzard_WorldMap"then MapQuests:InstallIconFilters()
        elseif event=="PLAYER_ENTERING_WORLD" then C_Timer.After(1,function() MapQuests:ApplySettings() end)
        elseif event=="PLAYER_REGEN_ENABLED" and MapQuests.pendingApply then MapQuests:ApplySettings()
        elseif event=="QUESTLINE_UPDATE" and Settings() and Settings().enabled then
            if not MapQuests.refreshScheduled and WorldMapFrame and WorldMapFrame:IsShown()then
                MapQuests.refreshScheduled=true;C_Timer.After(0,function()MapQuests.refreshScheduled=nil;MapQuests:RefreshWorldMap(false)end)
            end
        end
    end)
    self.events=events
end
