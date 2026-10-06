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

function MapQuests:RefreshWorldMap()
    if not WorldMapFrame or not WorldMapFrame:IsShown() then return end
    local mapID=WorldMapFrame.GetMapID and WorldMapFrame:GetMapID()
    if mapID and C_QuestLine and C_QuestLine.RequestQuestLinesForMap then C_QuestLine.RequestQuestLinesForMap(mapID) end
    if WorldMapFrame.RefreshAllDataProviders then WorldMapFrame:RefreshAllDataProviders() end
end

function MapQuests:ApplySettings()
    local settings=Settings()
    if not settings then return end
    if InCombatLockdown() then self.pendingApply=true; return end
    self.pendingApply=false

    local enabled=settings.enabled==true
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
    events:RegisterEvent("PLAYER_REGEN_ENABLED")
    events:RegisterEvent("QUESTLINE_UPDATE")
    events:SetScript("OnEvent",function(_,event)
        if event=="PLAYER_ENTERING_WORLD" then C_Timer.After(1,function() MapQuests:ApplySettings() end)
        elseif event=="PLAYER_REGEN_ENABLED" and MapQuests.pendingApply then MapQuests:ApplySettings()
        elseif event=="QUESTLINE_UPDATE" and Settings() and Settings().enabled then MapQuests:RefreshWorldMap() end
    end)
    self.events=events
end
