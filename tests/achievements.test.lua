unpack = table.unpack
local AUI = {modules={}}
function AUI:RegisterModule(name, module) self.modules[name] = module end

ProjectRuthlessDB = {enabled=true, achievements={enabled=true}}
RAID_CLASS_COLORS = {PALADIN={r=0.96,g=0.55,b=0.73}}
function UnitClass() return "Paladin", "PALADIN" end
function GetNumTitles() return 5 end
function IsTitleKnown(id) return id == 1 or id == 3 or id == 5 end
function GetTotalAchievementPoints() return 12345 end
function GetNumCompletedAchievements() return 2000, 750 end
function GetStatisticsCategoryList() return {9, 10} end
function GetCategoryNumAchievements(category)
    if category == 9 then return 2, 0 end
    if category == 10 then return 1, 0 end
    if category == 92 then return 80, 50 end
    if category == 920 then return 20, 10 end
    if category == 96 then return 400, 100 end
    return 0, 0
end
local categoryStats = {[9]={{"12,345",false,201},{"7",true,202}}, [10]={{"999",false,203}}}
function GetStatistic(a, b)
    if b then return unpack(categoryStats[a][b]) end
    return a == 201 and "12,345" or a == 203 and "999" or "--"
end
local info = {
    [101]={"First milestone",10,true,9,7,26,1001},
    [102]={"Second milestone",20,true,8,7,26,1002},
    [103]={"Incomplete",5,false,nil,nil,nil,1003},
    [201]={"Honorable kills",0,false,nil,nil,nil,nil},
    [203]={"Total damage done",0,false,nil,nil,nil,nil},
}
function GetAchievementInfo(id)
    local row = assert(info[id], "unknown achievement")
    return id, row[1], row[2], row[3], row[4], row[5], row[6], nil, nil, row[7]
end
function GetLatestCompletedAchievements() return 101, 102, 103 end
ACHIEVEMENTUI_SUMMARYCATEGORIES = {92, 96}
function GetCategoryList() return {92, 920, 96} end
function GetCategoryInfo(id)
    if id == 92 then return "General", -1 end
    if id == 920 then return "General child", 92 end
    return "Quests", -1
end

assert(load(ACHIEVEMENTS_SOURCE))("ProjectRuthless", AUI)
local module = AUI.modules.Achievements
assert(module:IsEnabled())
local overview = module:GetOverview()
assert(overview[1].value == "12345")
assert(overview[2].value == "750 / 2000")
assert(overview[3].value == "3")
assert(overview[4].value == "12,345")
local recent = module:GetRecentAchievements(5)
assert(#recent == 2 and recent[1].id == 101 and recent[2].points == 20)
assert(recent[1].date == "07/09/26")
local progress = module:GetCategoryProgress(5)
assert(#progress == 2 and progress[1].completed == 60 and progress[2].total == 400)
ProjectRuthlessDB.achievements.enabled = false
assert(not module:IsEnabled())

local Frame = {}; Frame.__index = Frame
function Frame:SetBackdrop(value) self.backdrop=value end
function Frame:SetBackdropColor(...) self.background={...} end
function Frame:SetBackdropBorderColor(...) self.border={...} end
function Frame:SetPoint(...) self.point={...} end
function Frame:SetAllPoints(target) self.allPoints=target end
function Frame:SetSize(w,h) self.width=w; self.height=h end
function Frame:SetWidth(w) self.width=w end
function Frame:SetHeight(h) self.height=h end
function Frame:SetFrameLevel(level) self.level=level end
function Frame:GetFrameLevel() return self.level or 1 end
function Frame:SetText(value) self.text=value end
function Frame:SetTextColor(...) self.color={...} end
function Frame:SetJustifyH(value) self.justify=value end
function Frame:SetWordWrap(value) self.wordWrap=value end
function Frame:SetTexture(value) self.texture=value end
function Frame:SetStatusBarTexture(value) self.statusTexture=value end
function Frame:SetStatusBarColor(...) self.statusColor={...} end
function Frame:SetMinMaxValues(a,b) self.minimum=a; self.maximum=b end
function Frame:SetValue(value) self.value=value end
function Frame:SetScript(name, callback) self.scripts[name]=callback end
function Frame:HookScript(name, callback) self.scripts[name]=callback end
function Frame:RegisterEvent(event) self.events[event]=true end
function Frame:SetShown(shown) self.shown=shown end
function Frame:Show() self.shown=true; if self.scripts.OnShow then self.scripts.OnShow(self) end end
function Frame:Hide() self.shown=false end
function Frame:IsShown() return self.shown end
function Frame:CreateFontString() return setmetatable({scripts={},events={},shown=true},Frame) end
function Frame:CreateTexture() return setmetatable({scripts={},events={},shown=true},Frame) end
function CreateFrame(_,_,parent) return setmetatable({parent=parent,scripts={},events={},shown=true},Frame) end
function AUI:CreateButton(parent) return CreateFrame("Button",nil,parent) end
AchievementFrame = CreateFrame("Frame")
AchievementFrame.HeaderDetails = CreateFrame("Frame",nil,AchievementFrame)
AchievementFrameStats = CreateFrame("Frame",nil,AchievementFrame)
AchievementFrameStats:SetFrameLevel(3)
GameTooltip = {Hide=function() end, SetOwner=function() end, SetAchievementByID=function() end}
function UnitName() return "Tester" end
function UnitLevel() return 80 end
function GetSpecialization() return 1 end
function GetSpecializationInfo() return 70, "Retribution" end
local shownSubframe, updatedStats, selectedAchievement
function AchievementFrame_ShowSubFrame(frame) shownSubframe=frame end
function AchievementFrameStats_UpdateDataProvider() updatedStats=true end
function AchievementFrameBaseTab_OnClick() end
function AchievementFrame_SelectAchievement(id) selectedAchievement=id end

ProjectRuthlessDB.achievements.enabled = true
module:CreateDashboard()
assert(module.dashboard and not module.dashboard:IsShown(), "dashboard must not cover the default Achievements tab")
assert(#module.metricCards == 4 and #module.recentRows == 5 and #module.progressRows == 5)
module:ShowDashboard()
assert(module.dashboard:IsShown() and module.toggle.text == "Browse details")
module.recentRows[1].scripts.OnClick(module.recentRows[1])
assert(selectedAchievement == 101)
module:ShowNativeStatistics()
assert(not module.dashboard:IsShown() and shownSubframe == AchievementFrameStats and updatedStats)
print("PASS: live overview values, statistic discovery, title count, recent completion filtering, category progress, and dashboard/native switching")
