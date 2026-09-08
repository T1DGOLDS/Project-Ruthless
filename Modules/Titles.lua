local _, AUI = ...

local Titles = {
    filtered = {},
    achievementMatches = {},
    searchFinished = {},
    searchJobs = {},
    sortModes = { "alphabetical", "recent", "expansion" },
}
AUI:RegisterModule("Titles", Titles)

local function Settings()
    return ProjectRuthlessDB.titles
end

local function Clean(text)
    return strtrim((text or ""):gsub("%%s", ""):gsub("[%p%c]", " "):gsub("%s+", " ")):lower()
end

local FACTION_EQUIVALENTS = {
    ["flame warden"]="flame keeper", ["flame keeper"]="flame warden",
    ["the justicar"]="conqueror", ["justicar"]="conqueror",
    ["the conqueror"]="justicar", ["conqueror"]="justicar",
    ["of the alliance"]="of the horde", ["of the horde"]="of the alliance",
    ["hero of the alliance"]="hero of the horde", ["hero of the horde"]="hero of the alliance",
    ["veteran of the alliance"]="veteran of the horde", ["veteran of the horde"]="veteran of the alliance",
    ["defender of the alliance"]="defender of the horde", ["defender of the horde"]="defender of the alliance",
    ["guardian of the alliance"]="guardian of the horde", ["guardian of the horde"]="guardian of the alliance",
    ["soldier of the alliance"]="soldier of the horde", ["soldier of the horde"]="soldier of the alliance",
    ["the alliance slayer"]="the horde slayer", ["the horde slayer"]="the alliance slayer",
    ["private"]="scout", ["scout"]="private", ["corporal"]="grunt", ["grunt"]="corporal",
    ["master sergeant"]="senior sergeant", ["senior sergeant"]="master sergeant",
    ["sergeant major"]="first sergeant", ["first sergeant"]="sergeant major",
    ["knight"]="stone guard", ["stone guard"]="knight",
    ["knight lieutenant"]="blood guard", ["blood guard"]="knight lieutenant",
    ["knight captain"]="legionnaire", ["legionnaire"]="knight captain",
    ["knight champion"]="centurion", ["centurion"]="knight champion",
    ["lieutenant commander"]="champion", ["champion"]="lieutenant commander",
    ["commander"]="lieutenant general", ["lieutenant general"]="commander",
    ["marshal"]="general", ["general"]="marshal", ["field marshal"]="warlord", ["warlord"]="field marshal",
    ["grand marshal"]="high warlord", ["high warlord"]="grand marshal",
}

local function DisplayTitle(titleID)
    local raw = GetTitleName(titleID)
    if not raw then return "Unknown title" end
    local ok, result = pcall(string.format, raw, UnitName("player"))
    return ok and result or raw:gsub("%%s", UnitName("player") or "")
end

function Titles:GetDisplayTitle(titleID)
    if not titleID or titleID == 0 then return "No Title" end
    return DisplayTitle(titleID)
end

local DateValue

function Titles:GetEarnedTitles(query)
    local results = {}
    local cleanedQuery = Clean(query)
    if cleanedQuery == "" or Clean("No Title"):find(cleanedQuery, 1, true) then
        results[#results + 1] = { id=0, name="No Title" }
    end
    for titleID = 1, GetNumTitles() do
        if IsTitleKnown(titleID) then
            local name = DisplayTitle(titleID)
            if cleanedQuery == "" or Clean(name):find(cleanedQuery, 1, true) then
                results[#results + 1] = { id=titleID, name=name }
            end
        end
    end
    self:BuildAchievementMatches()
    local db = Settings()
    table.sort(results, function(a, b)
        local af, bf = db.favorites[a.id] == true, db.favorites[b.id] == true
        if af ~= bf then return af end
        if a.id == 0 then return true end
        if b.id == 0 then return false end
        if db.sort == "recent" then
            local av = DateValue(self.achievementMatches[a.id], db.firstSeen[a.id])
            local bv = DateValue(self.achievementMatches[b.id], db.firstSeen[b.id])
            if av ~= bv then return av > bv end
        end
        return a.name:lower() < b.name:lower()
    end)
    return results
end

function Titles:IsFavorite(titleID)
    return titleID and titleID > 0 and Settings().favorites[titleID] == true
end

function Titles:GetSortMode()
    return Settings().sort == "recent" and "recent" or "alphabetical"
end

function Titles:ToggleSortMode()
    local db = Settings()
    db.sort = db.sort == "recent" and "alphabetical" or "recent"
end

function Titles:GetVariantLines(titleID)
    local lines = {}
    if not titleID or titleID == 0 then return lines end
    local data = _G.EpithetData and _G.EpithetData.titlesByID
    local record = data and data[titleID]
    if not record then return lines end
    if record.faction then
        local foundEquivalent = false
        for otherID, other in pairs(data) do
            if otherID ~= titleID and other.faction and other.faction ~= record.faction
                and record.achievement_id and other.achievement_id == record.achievement_id then
                local label = other.faction == "Horde" and "Horde equivalent" or "Alliance equivalent"
                lines[#lines + 1] = { label=label, value=DisplayTitle(otherID) }
                foundEquivalent = true
                break
            end
        end
        if not foundEquivalent then
            local wanted = FACTION_EQUIVALENTS[Clean(record.text)]
            if wanted then
                for otherID, other in pairs(data) do
                    if Clean(other.text) == wanted then
                        local label = other.faction == "Horde" and "Horde equivalent" or "Alliance equivalent"
                        lines[#lines + 1] = { label=label, value=DisplayTitle(otherID) }
                        foundEquivalent = true
                        break
                    end
                end
            end
        end
        if not foundEquivalent then
            local otherFaction = record.faction == "Horde" and "Alliance" or "Horde"
            lines[#lines + 1] = { label=otherFaction .. " equivalent", value="Equivalent name unavailable" }
        end
    end
    if record.achievement_id then
        for otherID, other in pairs(data) do
            if otherID ~= titleID and other.achievement_id == record.achievement_id
                and other.faction == record.faction and other.text ~= record.text then
                local label = UnitSex("player") == 3 and "Male form" or "Female form"
                lines[#lines + 1] = { label=label, value=DisplayTitle(otherID) }
                break
            end
        end
    end
    return lines
end


function Titles:ShowTitleTooltip(owner, titleID)
    GameTooltip:SetOwner(owner, "ANCHOR_RIGHT")
    GameTooltip:AddLine(self:GetDisplayTitle(titleID), 1, 0.82, 0)
    if titleID == 0 then
        GameTooltip:AddLine("Removes the currently equipped title.", 0.8, 0.82, 0.88, true)
        GameTooltip:AddLine("Left-click to select", 0.45, 0.65, 0.95)
        GameTooltip:Show()
        return
    end

    self:BuildAchievementMatches()
    local record = _G.EpithetData and _G.EpithetData.titlesByID and _G.EpithetData.titlesByID[titleID]
    local match = self.achievementMatches[titleID]
    local dateText, source = self:GetDateInfo(titleID)
    if record then
        local context = record.exp and tostring(record.exp):upper() or nil
        if record.cat then context = context and (context .. "  •  " .. record.cat) or record.cat end
        if context then GameTooltip:AddLine(context, 0.62, 0.65, 0.72) end
        if record.kind then GameTooltip:AddDoubleLine("Source", record.kind, 0.62,0.65,0.72, 0.9,0.9,0.95) end
    end
    GameTooltip:AddDoubleLine("Earned", dateText, 0.62,0.65,0.72, 0.9,0.9,0.95)
    GameTooltip:AddLine(source, 0.48, 0.51, 0.58, true)
    if match and match.id then
        local link = GetAchievementLink and GetAchievementLink(match.id)
        GameTooltip:AddLine(link or ("Achievement: " .. (match.name or "Unknown")), 0.35, 0.75, 1, true)
    elseif not self.searchFinished[titleID] then
        GameTooltip:AddLine("Achievement link: searching Blizzard records…", 0.48, 0.51, 0.58, true)
        self:StartLazyAchievementSearch(titleID)
    else
        GameTooltip:AddLine("Achievement link unavailable", 0.48, 0.51, 0.58)
    end
    for _, variant in ipairs(self:GetVariantLines(titleID)) do
        GameTooltip:AddDoubleLine(variant.label, variant.value, 0.65,0.68,0.75, 1,1,1)
    end
    GameTooltip:AddLine(" ")
    GameTooltip:AddLine("Left-click to equip", 0.45, 0.65, 0.95)
    GameTooltip:AddLine("Click the star to favourite", 0.45, 0.65, 0.95)
    if match and match.id then GameTooltip:AddLine("Right-click to open achievement", 0.45, 0.65, 0.95) end
    GameTooltip:Show()
end

DateValue = function(match, firstSeen)
    if match and match.year then
        local year = match.year < 100 and (2000 + match.year) or match.year
        return (year * 10000) + (match.month * 100) + match.day
    end
    return firstSeen or 0
end

function Titles:InitializeKnownTitles()
    local db = Settings()
    if db.initialized then return end
    for titleID = 1, GetNumTitles() do
        if IsTitleKnown(titleID) then
            db.knownAtInstall[titleID] = true
        end
    end
    db.initialized = true
end

function Titles:RecordNewTitle(titleID)
    if titleID and titleID > 0 then
        Settings().firstSeen[titleID] = time()
        self:Refresh()
    end
end

function Titles:ScanForNewTitles()
    local db = Settings()
    local foundNew = false
    for titleID = 1, GetNumTitles() do
        if IsTitleKnown(titleID) and not db.knownAtInstall[titleID] then
            db.knownAtInstall[titleID] = true
            db.firstSeen[titleID] = db.firstSeen[titleID] or time()
            foundNew = true
        end
    end
    if foundNew then self:Refresh() end
end

function Titles:BuildAchievementMatches()
    if self.achievementScanComplete then return end
    self.achievementScanComplete = true
    local data = _G.EpithetData and _G.EpithetData.titlesByID
    if not data then return end
    for titleID, record in pairs(data) do
        local achievementID = record.achievement_id
        if achievementID then
            local _, name, _, completed, month, day, year = GetAchievementInfo(achievementID)
            self.achievementMatches[titleID] = { id=achievementID, name=name or record.achievement, completed=completed, month=month, day=day, year=year, expansion=record.exp }
        end
    end
end

function Titles:StartLazyAchievementSearch(titleID)
    if self.searchJobs[titleID] or self.searchFinished[titleID] then return end
    local categories = GetCategoryList and GetCategoryList() or {}
    local target = Clean(GetTitleName(titleID))
    local job = { category=1, index=1 }
    self.searchJobs[titleID] = job
    local function Finish(match)
        self.searchJobs[titleID] = nil
        self.searchFinished[titleID] = true
        if match then self.achievementMatches[titleID] = match end
        if self.provenance and self.provenance:IsShown() and self.provenance.titleID == titleID then self:ShowProvenance(titleID) end
        self:Refresh()
    end
    local function Tick()
        local processed = 0
        while job.category <= #categories and processed < 60 do
            local categoryID = categories[job.category]
            local count = GetCategoryNumAchievements(categoryID, true) or 0
            if job.index > count then
                job.category = job.category + 1
                job.index = 1
            else
                local achievementID, name, _, completed, month, day, year, _, _, _, rewardText = GetAchievementInfo(categoryID, job.index)
                job.index = job.index + 1
                processed = processed + 1
                if achievementID and rewardText and Clean(rewardText):find(target, 1, true) then
                    Finish({ id=achievementID, name=name, completed=completed, month=month, day=day, year=year, categoryID=categoryID })
                    return
                end
            end
        end
        if job.category > #categories then Finish(nil) else C_Timer.After(0, Tick) end
    end
    C_Timer.After(0, Tick)
end

function Titles:GetDateInfo(titleID)
    local match = self.achievementMatches[titleID]
    if match and match.completed and match.year and match.year > 0 then
        local year = match.year < 100 and (2000 + match.year) or match.year
        return ("%02d/%02d/%04d"):format(match.day, match.month, year), "Achievement completion"
    end
    local seen = Settings().firstSeen[titleID]
    if seen then
        return date("%d/%m/%Y", seen), "First observed by Project Ruthless"
    end
    return "Unknown", "Legacy title; no reliable date found"
end

function Titles:RebuildFilter()
    self:BuildAchievementMatches()
    wipe(self.filtered)
    local db = Settings()
    local query = Clean(self.searchText)
    for titleID = 1, GetNumTitles() do
        if IsTitleKnown(titleID) and (not db.favoritesOnly or db.favorites[titleID]) then
            local name = DisplayTitle(titleID)
            if query == "" or Clean(name):find(query, 1, true) then
                self.filtered[#self.filtered + 1] = { id = titleID, name = name }
            end
        end
    end

    table.sort(self.filtered, function(a, b)
        if db.sort == "recent" then
            local av = DateValue(self.achievementMatches[a.id], db.firstSeen[a.id])
            local bv = DateValue(self.achievementMatches[b.id], db.firstSeen[b.id])
            if av ~= bv then return av > bv end
        end
        return a.name:lower() < b.name:lower()
    end)
end

function Titles:ToggleFavorite(titleID)
    local favorites = Settings().favorites
    favorites[titleID] = not favorites[titleID] or nil
    self:Refresh()
end

function Titles:Equip(titleID)
    if InCombatLockdown() then
        AUI:Print("Titles cannot be changed during combat.")
        return
    end
    SetCurrentTitle(titleID)
    self.currentTitleID = titleID
    self:Refresh()
end

function Titles:OpenAchievement(achievementID)
    if not achievementID then return end
    if AchievementFrame_LoadUI then AchievementFrame_LoadUI() end
    if AchievementFrame_SelectAchievement then
        AchievementFrame_SelectAchievement(achievementID)
    end
    if AchievementFrame then ShowUIPanel(AchievementFrame) end
end

function Titles:ShowProvenance(titleID)
    local card = self.provenance
    local match = self.achievementMatches[titleID]
    local dateText, source = self:GetDateInfo(titleID)
    card.titleID = titleID
    card.title:SetText(DisplayTitle(titleID))
    card.date:SetText("Earned date: " .. dateText)
    card.source:SetText("Date source: " .. source)
    if match then
        card.achievementID = match.id
        card.achievement:SetText("Achievement: " .. (match.name or "Unknown"))
        card.achievement:Show()
        card.open:Enable()
    else
        card.achievementID = nil
        if self.searchFinished[titleID] then
            card.achievement:SetText("Achievement: no reliable match")
        else
            card.achievement:SetText("Achievement: searching Blizzard records…")
            self:StartLazyAchievementSearch(titleID)
        end
        card.open:Disable()
    end
    card.favorite:SetText(Settings().favorites[titleID] and "Favourited" or "Add favourite")
    card:Show()
end

function Titles:CreatePanel(parent)
    local panel = CreateFrame("Frame", nil, parent)
    panel:SetAllPoints()
    local title = panel:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    title:SetPoint("TOPLEFT", 12, -10)
    title:SetText("Title library")

    local search = CreateFrame("EditBox", nil, panel, "SearchBoxTemplate")
    search:SetSize(260, 28)
    search:SetPoint("TOPLEFT", 12, -42)
    search:SetScript("OnTextChanged", function(box)
        SearchBoxTemplate_OnTextChanged(box)
        self.searchText = box:GetText()
        self:Refresh()
    end)

    local favorite = AUI:CreateButton(panel)
    favorite:SetSize(110, 26)
    favorite:SetPoint("LEFT", search, "RIGHT", 8, 0)
    favorite:SetScript("OnClick", function()
        Settings().favoritesOnly = not Settings().favoritesOnly
        self:Refresh()
    end)
    panel.favoriteButton = favorite

    local sort = AUI:CreateButton(panel)
    sort:SetSize(126, 26)
    sort:SetPoint("LEFT", favorite, "RIGHT", 8, 0)
    sort:SetScript("OnClick", function()
        Settings().sort = Settings().sort == "alphabetical" and "recent" or "alphabetical"
        self:Refresh()
    end)
    panel.sortButton = sort

    local scroll=AUI:CreateListScroll(panel,32,1,function() self:RefreshRows() end)
    scroll:SetPoint("TOPLEFT",12,-82); scroll:SetPoint("BOTTOMRIGHT",-14,70); panel.scroll=scroll
    panel.rows = {}
    for index = 1, 20 do
        local row = CreateFrame("Button", nil, scroll.content)
        row:SetSize(500, 30)
        scroll:PlaceItem(row,index)
        row.favorite = CreateFrame("Button", nil, row)
        row.favorite:SetSize(22, 22)
        row.favorite:SetPoint("LEFT", 2, 0)
        row.favorite.icon = row.favorite:CreateTexture(nil, "ARTWORK")
        row.favorite.icon:SetAtlas("PetJournal-FavoritesIcon")
        row.favorite.icon:SetAllPoints()
        row.favorite:SetScript("OnClick", function()
            self:ToggleFavorite(row.titleID)
        end)
        row.favoriteBackground = row:CreateTexture(nil, "BACKGROUND")
        row.favoriteBackground:SetAllPoints()
        local _, class = UnitClass("player")
        local color = class and RAID_CLASS_COLORS[class]
        row.favoriteBackground:SetColorTexture(color and color.r or 0.5, color and color.g or 0.35, color and color.b or 0.94, 0.12)
        row.favoriteBackground:Hide()
        row.name = row:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
        row.name:SetPoint("LEFT", 34, 0)
        row.name:SetWidth(430)
        row.name:SetJustifyH("LEFT")
        row:SetHighlightTexture("Interface\\Buttons\\WHITE8X8", "ADD")
        row:GetHighlightTexture():SetAlpha(0.06)
        row:SetScript("OnClick", function(button, mouseButton)
            if mouseButton == "RightButton" then self:ShowProvenance(button.titleID) else self:Equip(button.titleID) end
        end)
        row:RegisterForClicks("LeftButtonUp", "RightButtonUp")
        panel.rows[index] = row
    end


    local card = CreateFrame("Frame", nil, panel, "BackdropTemplate")
    card:SetSize(500, 190)
    card:SetPoint("CENTER")
    card:SetFrameLevel(panel:GetFrameLevel() + 10)
    card:SetBackdrop({ bgFile="Interface\\Buttons\\WHITE8X8", edgeFile="Interface\\Buttons\\WHITE8X8", edgeSize=1 })
    card:SetBackdropColor(0.025, 0.028, 0.038, 0.99)
    card:SetBackdropBorderColor(0.5, 0.5, 0.6, 1)
    card.title = card:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge"); card.title:SetPoint("TOPLEFT", 18, -18)
    card.date = card:CreateFontString(nil, "OVERLAY", "GameFontHighlight"); card.date:SetPoint("TOPLEFT", 18, -52)
    card.source = card:CreateFontString(nil, "OVERLAY", "GameFontHighlight"); card.source:SetPoint("TOPLEFT", 18, -76)
    card.achievement = card:CreateFontString(nil, "OVERLAY", "GameFontHighlight"); card.achievement:SetPoint("TOPLEFT", 18, -100)
    card.favorite = AUI:CreateButton(card); card.favorite:SetSize(130, 26); card.favorite:SetPoint("BOTTOMLEFT", 16, 14)
    card.favorite:SetScript("OnClick", function() self:ToggleFavorite(card.titleID); self:ShowProvenance(card.titleID) end)
    card.open = AUI:CreateButton(card); card.open:SetSize(160, 26); card.open:SetPoint("LEFT", card.favorite, "RIGHT", 8, 0); card.open:SetText("Open achievement")
    card.open:SetScript("OnClick", function() self:OpenAchievement(card.achievementID) end)
    local close = CreateFrame("Button", nil, card, "UIPanelCloseButton"); close:SetPoint("TOPRIGHT")
    card:Hide()
    self.provenance = card
    self.panel = panel
    return panel
end

function Titles:RefreshRows()
    if not self.panel then return end
    self.panel.scroll:SetItemCount(#self.filtered)
    local offset = self.panel.scroll:GetItemOffset()
    for index, row in ipairs(self.panel.rows) do
        self.panel.scroll:PlaceItem(row,index)
        local entry = self.filtered[offset + index]
        if entry then
            row.titleID = entry.id
            local isFavorite = Settings().favorites[entry.id]
            row.favorite.icon:SetDesaturated(not isFavorite)
            row.favorite.icon:SetAlpha(isFavorite and 1 or 0.28)
            row.favoriteBackground:SetShown(isFavorite)
            row.name:SetText(entry.name)
            local equipped = entry.id == (self.currentTitleID or GetCurrentTitle())
            row.name:SetTextColor(equipped and 1 or 0.9, equipped and 0.82 or 0.9, equipped and 0.2 or 0.9)
            row:Show()
        else
            row:Hide()
        end
    end
end

function Titles:Refresh()
    if not self.panel then return end
    self:RebuildFilter()
    self.panel.scroll:SetItemCount(#self.filtered)
    self.panel.favoriteButton:SetText(Settings().favoritesOnly and "Favourites" or "All titles")
    self.panel.sortButton:SetText(Settings().sort == "recent" and "Sort: recent" or "Sort: A–Z")
    self:RefreshRows()
end

function Titles:OnPlayerLogin()
    self:InitializeKnownTitles()
    self.currentTitleID = GetCurrentTitle()
    local event = CreateFrame("Frame")
    event:RegisterEvent("KNOWN_TITLES_UPDATE")
    event:RegisterUnitEvent("UNIT_NAME_UPDATE", "player")
    event:SetScript("OnEvent", function(_, eventName, titleID)
        if eventName == "UNIT_NAME_UPDATE" then
            self.currentTitleID = GetCurrentTitle()
            self:Refresh()
        else
            self:ScanForNewTitles()
        end
    end)
    self.eventFrame = event
end
