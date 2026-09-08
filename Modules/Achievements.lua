local _, AUI = ...

local Achievements = {
    recentRows = {},
    progressRows = {},
}
AUI:RegisterModule("Achievements", Achievements)

local COLORS = {
    window = {0.025, 0.028, 0.038, 0.985},
    surface = {0.045, 0.049, 0.064, 0.98},
    border = {0.15, 0.16, 0.20, 1},
    text = {0.91, 0.92, 0.96, 1},
    muted = {0.54, 0.57, 0.65, 1},
}

local function Accent()
    local _, class = UnitClass("player")
    local color = class and RAID_CLASS_COLORS[class]
    return color and color.r or 0.5, color and color.g or 0.35, color and color.b or 0.94
end

local function Surface(frame, background)
    frame:SetBackdrop({bgFile="Interface\\Buttons\\WHITE8X8", edgeFile="Interface\\Buttons\\WHITE8X8", edgeSize=1})
    frame:SetBackdropColor(unpack(background or COLORS.surface))
    frame:SetBackdropBorderColor(unpack(COLORS.border))
end

local function Label(parent, text, font, anchor, relativeTo, relativePoint, x, y)
    local label = parent:CreateFontString(nil, "OVERLAY", font or "GameFontNormal")
    label:SetPoint(anchor or "TOPLEFT", relativeTo or parent, relativePoint or anchor or "TOPLEFT", x or 0, y or 0)
    label:SetText(text or "")
    label:SetTextColor(unpack(COLORS.text))
    label:SetJustifyH("LEFT")
    return label
end

local function FormatNumber(value)
    value = tonumber(value)
    if not value then return "—" end
    if BreakUpLargeNumbers then return BreakUpLargeNumbers(value) end
    return tostring(value)
end

local function CountKnownTitles()
    local known = 0
    for titleID = 1, (GetNumTitles and GetNumTitles() or 0) do
        if IsTitleKnown(titleID) then known = known + 1 end
    end
    return known
end

local function Clean(text)
    return (text or ""):lower():gsub("[%p%c]", " "):gsub("%s+", " "):match("^%s*(.-)%s*$")
end

function Achievements:FindStatistic(wantedNames)
    if not GetStatisticsCategoryList or not GetCategoryNumAchievements or not GetStatistic then return nil end
    if not self.statisticIDs then
        self.statisticIDs = {}
        for _, categoryID in ipairs(GetStatisticsCategoryList() or {}) do
            for index = 1, (GetCategoryNumAchievements(categoryID) or 0) do
                local _, skip, statisticID = GetStatistic(categoryID, index)
                if statisticID and not skip then
                    local name = select(2, GetAchievementInfo(statisticID))
                    if name then self.statisticIDs[Clean(name)] = statisticID end
                end
            end
        end
    end
    for _, name in ipairs(wantedNames) do
        local statisticID = self.statisticIDs[Clean(name)]
        if statisticID then
            local quantity = GetStatistic(statisticID)
            if quantity and quantity ~= "" and quantity ~= "--" then return quantity, statisticID end
        end
    end
    return nil
end

function Achievements:GetOverview()
    local total, completed = 0, 0
    if GetNumCompletedAchievements then total, completed = GetNumCompletedAchievements(false) end
    local honorableKills = self:FindStatistic({"Honorable kills", "Total honorable kills", "Lifetime honorable kills"})
    return {
        {label="Achievement points", value=FormatNumber(GetTotalAchievementPoints and GetTotalAchievementPoints() or 0)},
        {label="Achievements", value=("%s / %s"):format(FormatNumber(completed), FormatNumber(total))},
        {label="Titles earned", value=FormatNumber(CountKnownTitles())},
        {label="Honorable kills", value=honorableKills or "—"},
    }
end

function Achievements:GetRecentAchievements(limit)
    local recent = GetLatestCompletedAchievements and {GetLatestCompletedAchievements(false)} or {}
    local results = {}
    for _, achievementID in ipairs(recent) do
        if achievementID and #results < (limit or 5) then
            local _, name, points, completed, month, day, year, _, _, icon = GetAchievementInfo(achievementID)
            if name and completed then
                results[#results + 1] = {
                    id=achievementID, name=name, points=points or 0, icon=icon,
                    date=(month and day and year) and ("%02d/%02d/%02d"):format(day, month, year) or "Completed",
                }
            end
        end
    end
    return results
end

function Achievements:GetCategoryProgress(limit)
    local results = {}
    local allCategories = GetCategoryList and GetCategoryList() or {}
    for _, categoryID in ipairs(ACHIEVEMENTUI_SUMMARYCATEGORIES or {}) do
        if #results >= (limit or 5) then break end
        local name = GetCategoryInfo(categoryID)
        local total, completed = GetCategoryNumAchievements(categoryID, true)
        for _, childID in ipairs(allCategories) do
            local _, parentID = GetCategoryInfo(childID)
            if parentID == categoryID then
                local childTotal, childCompleted = GetCategoryNumAchievements(childID, true)
                total = (total or 0) + (childTotal or 0)
                completed = (completed or 0) + (childCompleted or 0)
            end
        end
        if name and total and total > 0 then
            results[#results + 1] = {id=categoryID, name=name, total=total, completed=completed or 0}
        end
    end
    return results
end

function Achievements:CreateMetricCard(index)
    local card = CreateFrame("Frame", nil, self.dashboard, "BackdropTemplate")
    card:SetSize(116, 64)
    card:SetPoint("TOPLEFT", self.dashboard, "TOPLEFT", 12 + (index - 1) * 122, -62)
    Surface(card)
    card.value = Label(card, "", "GameFontNormalLarge", "TOPLEFT", card, "TOPLEFT", 10, -11)
    card.value:SetWidth(96)
    card.label = Label(card, "", "GameFontNormalSmall", "BOTTOMLEFT", card, "BOTTOMLEFT", 10, 9)
    card.label:SetWidth(96); card.label:SetTextColor(unpack(COLORS.muted))
    return card
end

function Achievements:CreateRecentRow(index)
    local row = CreateFrame("Button", nil, self.dashboard, "BackdropTemplate")
    row:SetSize(296, 48)
    row:SetPoint("TOPLEFT", self.dashboard, "TOPLEFT", 12, -162 - (index - 1) * 52)
    Surface(row)
    row.icon = row:CreateTexture(nil, "ARTWORK")
    row.icon:SetSize(34, 34); row.icon:SetPoint("LEFT", 7, 0)
    row.name = Label(row, "", "GameFontNormal", "TOPLEFT", row, "TOPLEFT", 49, -9)
    row.name:SetWidth(185); row.name:SetWordWrap(false)
    row.meta = Label(row, "", "GameFontNormalSmall", "BOTTOMLEFT", row, "BOTTOMLEFT", 49, 8)
    row.meta:SetWidth(230); row.meta:SetTextColor(unpack(COLORS.muted))
    row:SetScript("OnClick", function(button)
        if not button.achievementID then return end
        AchievementFrameBaseTab_OnClick(1)
        AchievementFrame_SelectAchievement(button.achievementID)
    end)
    row:SetScript("OnEnter", function(button)
        local r, g, b = Accent(); button:SetBackdropBorderColor(r, g, b, 0.85)
        if button.achievementID and GameTooltip.SetAchievementByID then
            GameTooltip:SetOwner(button, "ANCHOR_RIGHT"); GameTooltip:SetAchievementByID(button.achievementID); GameTooltip:Show()
        end
    end)
    row:SetScript("OnLeave", function(button) button:SetBackdropBorderColor(unpack(COLORS.border)); GameTooltip:Hide() end)
    return row
end

function Achievements:CreateProgressRow(index)
    local row = CreateFrame("Frame", nil, self.dashboard)
    row:SetSize(174, 46)
    row:SetPoint("TOPRIGHT", self.dashboard, "TOPRIGHT", -12, -162 - (index - 1) * 52)
    row.name = Label(row, "", "GameFontNormalSmall", "TOPLEFT", row, "TOPLEFT", 0, -2)
    row.name:SetWidth(130); row.name:SetWordWrap(false)
    row.count = Label(row, "", "GameFontNormalSmall", "TOPRIGHT", row, "TOPRIGHT", 0, -2)
    row.count:SetJustifyH("RIGHT"); row.count:SetTextColor(unpack(COLORS.muted))
    row.track = CreateFrame("StatusBar", nil, row, "BackdropTemplate")
    row.track:SetPoint("BOTTOMLEFT", 0, 8); row.track:SetPoint("BOTTOMRIGHT", 0, 8); row.track:SetHeight(8)
    row.track:SetStatusBarTexture("Interface\\Buttons\\WHITE8X8"); Surface(row.track, {0.02,0.022,0.03,1})
    local r, g, b = Accent(); row.track:SetStatusBarColor(r, g, b, 0.9)
    return row
end

function Achievements:CreateDashboard()
    if self.dashboard or not AchievementFrameStats then return end
    local dashboard = CreateFrame("Frame", "ProjectRuthlessAchievementDashboard", AchievementFrame, "BackdropTemplate")
    dashboard:SetAllPoints(AchievementFrameStats)
    dashboard:SetFrameLevel(AchievementFrameStats:GetFrameLevel() + 2)
    Surface(dashboard, COLORS.window)
    dashboard:Hide()
    self.dashboard = dashboard

    local r, g, b = Accent()
    local overline = Label(dashboard, "YOUR LEGACY", "GameFontNormalSmall", "TOPLEFT", dashboard, "TOPLEFT", 12, -12)
    overline:SetTextColor(r, g, b)
    local title = Label(dashboard, UnitName("player") or "Character", "GameFontNormalHuge", "TOPLEFT", dashboard, "TOPLEFT", 12, -30)
    title:SetWidth(300)
    self.identity = Label(dashboard, "", "GameFontNormalSmall", "TOPRIGHT", dashboard, "TOPRIGHT", -12, -34)
    self.identity:SetJustifyH("RIGHT"); self.identity:SetTextColor(unpack(COLORS.muted))

    self.metricCards = {}
    for index = 1, 4 do self.metricCards[index] = self:CreateMetricCard(index) end
    local recentTitle = Label(dashboard, "RECENT MILESTONES", "GameFontNormalSmall", "TOPLEFT", dashboard, "TOPLEFT", 12, -143)
    recentTitle:SetTextColor(r, g, b)
    local progressTitle = Label(dashboard, "CATEGORY PROGRESS", "GameFontNormalSmall", "TOPRIGHT", dashboard, "TOPRIGHT", -12, -143)
    progressTitle:SetTextColor(r, g, b); progressTitle:SetJustifyH("RIGHT")
    for index = 1, 5 do
        self.recentRows[index] = self:CreateRecentRow(index)
        self.progressRows[index] = self:CreateProgressRow(index)
    end
    local empty = Label(dashboard, "Complete an achievement to begin your recent history.", "GameFontNormalSmall", "TOPLEFT", dashboard, "TOPLEFT", 20, -176)
    empty:SetWidth(270); empty:SetTextColor(unpack(COLORS.muted)); empty:Hide(); self.emptyRecent = empty

    dashboard:SetScript("OnShow", function() self:Refresh() end)
    dashboard:RegisterEvent("ACHIEVEMENT_EARNED")
    dashboard:RegisterEvent("CRITERIA_UPDATE")
    dashboard:SetScript("OnEvent", function() if dashboard:IsShown() then self:Refresh() end end)

    local toggle = AUI:CreateButton(AchievementFrame.HeaderDetails)
    toggle:SetSize(112, 24); toggle:SetPoint("TOPLEFT", AchievementFrame.HeaderDetails, "TOPLEFT", 6, -8)
    toggle:SetScript("OnClick", function()
        if dashboard:IsShown() then self:ShowNativeStatistics() else self:ShowDashboard() end
    end)
    toggle:Hide(); self.toggle = toggle
end

function Achievements:Refresh()
    if not self.dashboard then return end
    local specIndex = GetSpecialization and GetSpecialization()
    local specName = specIndex and select(2, GetSpecializationInfo(specIndex))
    self.identity:SetText(("Level %d  %s"):format(UnitLevel("player") or 0, specName or (UnitClass("player") or "")))
    for index, metric in ipairs(self:GetOverview()) do
        local card = self.metricCards[index]
        card.value:SetText(metric.value); card.label:SetText(metric.label)
    end
    local recent = self:GetRecentAchievements(5)
    self.emptyRecent:SetShown(#recent == 0)
    for index, row in ipairs(self.recentRows) do
        local achievement = recent[index]
        row:SetShown(achievement ~= nil)
        if achievement then
            row.achievementID = achievement.id; row.icon:SetTexture(achievement.icon)
            row.name:SetText(achievement.name)
            row.meta:SetText(("%s  •  %d points"):format(achievement.date, achievement.points))
        end
    end
    local progress = self:GetCategoryProgress(5)
    for index, row in ipairs(self.progressRows) do
        local category = progress[index]
        row:SetShown(category ~= nil)
        if category then
            row.categoryID = category.id; row.name:SetText(category.name)
            row.count:SetText(("%d%%"):format(math.floor(category.completed / category.total * 100 + 0.5)))
            row.track:SetMinMaxValues(0, category.total); row.track:SetValue(category.completed)
        end
    end
end

function Achievements:ShowDashboard()
    if not self:IsEnabled() or not AchievementFrame or AchievementFrame.isComparison then return end
    self:CreateDashboard()
    if not self.dashboard then return end
    AchievementFrame_ShowSubFrame()
    self.dashboard:Show(); self.toggle:SetText("Browse details"); self.toggle:Show(); self:Refresh()
end

function Achievements:ShowNativeStatistics()
    if not self.dashboard then return end
    self.dashboard:Hide(); self.toggle:SetText("Dashboard"); self.toggle:Show()
    AchievementFrame_ShowSubFrame(AchievementFrameStats)
    AchievementFrameStats_UpdateDataProvider()
end

function Achievements:IsEnabled()
    return ProjectRuthlessDB and ProjectRuthlessDB.enabled and ProjectRuthlessDB.achievements.enabled
end

function Achievements:Install()
    if self.installed or not AchievementFrame or not AchievementFrameStats then return end
    self.installed = true
    self:CreateDashboard()
    hooksecurefunc("AchievementFrameBaseTab_OnClick", function(tabIndex)
        if tabIndex == 3 and not AchievementFrame.isComparison then
            if self:IsEnabled() then self:ShowDashboard() elseif self.toggle then self.toggle:Hide() end
        elseif self.dashboard then
            self.dashboard:Hide(); self.toggle:Hide()
        end
    end)
    hooksecurefunc("AchievementFrameCategories_OnCategoryChanged", function()
        if AchievementFrame.selectedTab == 3 and self.dashboard and self.dashboard:IsShown() then self:ShowNativeStatistics() end
    end)
    hooksecurefunc("AchievementFrame_SetComparisonMode", function(isComparison)
        if not self.dashboard then return end
        if isComparison then self.dashboard:Hide(); self.toggle:Hide()
        elseif AchievementFrame.selectedTab == 3 and self:IsEnabled() then self:ShowDashboard() end
    end)
    AchievementFrame:HookScript("OnHide", function() if self.dashboard then self.dashboard:Hide(); self.toggle:Hide() end end)
    if AchievementFrame:IsShown() and AchievementFrame.selectedTab == 3 and self:IsEnabled() then self:ShowDashboard() end
end

function Achievements:Show()
    if AchievementFrame_LoadUI then AchievementFrame_LoadUI() end
    self:Install()
    if not AchievementFrame then return end
    ShowUIPanel(AchievementFrame)
    AchievementFrameBaseTab_OnClick(3)
end

function Achievements:ApplySettings()
    if not self.installed then return end
    if AchievementFrame and AchievementFrame:IsShown() and AchievementFrame.selectedTab == 3 then
        if self:IsEnabled() then self:ShowDashboard() else self.dashboard:Hide(); self.toggle:Hide(); AchievementFrame_ShowSubFrame(AchievementFrameStats) end
    end
end

function Achievements:OnPlayerLogin()
    self:Install()
    local events = CreateFrame("Frame")
    events:RegisterEvent("ADDON_LOADED")
    events:SetScript("OnEvent", function(_, _, addon)
        if addon == "Blizzard_AchievementUI" then self:Install() end
    end)
    self.events = events
end
