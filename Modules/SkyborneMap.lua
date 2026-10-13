local _,AUI=...
local L={}
AUI:RegisterModule("SkyborneMap",L)
local TEMPLATE="RUILeylinePinTemplate"
local function read(fn,...)
    if type(fn)~="function"then return end
    local ok,a,b=pcall(fn,...)
    if not ok or issecretvalue and (issecretvalue(a)or issecretvalue(b))then return end
    return a,b
end
function L:Locations(mapID)
    local _,race=read(UnitRace,"player")
    if race~="Skyborne"then return {}end
    local faction=read(UnitFactionGroup,"player")
    local key=faction=="Alliance"and "LeyLines"or faction=="Horde"and "ElementalConvergences"
    local nodes=key and AUI.SkyborneMapNodes and AUI.SkyborneMapNodes[key]
    return nodes and nodes[mapID]or {},faction=="Alliance"and "Ley Line"or "Elemental Convergence"
end
function L:Install()
    if self.provider or not WorldMapFrame or not MapCanvasDataProviderMixin or not MapCanvasPinMixin then return end
    for key,value in pairs(MapCanvasPinMixin)do if RUILeylinePinMixin[key]==nil then RUILeylinePinMixin[key]=value end end
    local provider=CreateFromMixins(MapCanvasDataProviderMixin);self.provider=provider
    function provider:RemoveAllData()self:GetMap():RemoveAllPinsByTemplate(TEMPLATE)end
    function provider:RefreshAllData()
        self:RemoveAllData()
        local map=self:GetMap();local points,label=L:Locations(map:GetMapID())
        for _,point in ipairs(points)do map:AcquirePin(TEMPLATE,point[1],point[2],label)end
    end
    WorldMapFrame:AddDataProvider(provider)
end
function L:OnPlayerLogin()
    if not AUI.isForever then return end
    local _,race=read(UnitRace,"player");if race~="Skyborne"then return end
    self:Install()
    if not self.provider then
        local events=CreateFrame("Frame");events:RegisterEvent("ADDON_LOADED")
        events:SetScript("OnEvent",function()self:Install();if self.provider then events:UnregisterEvent("ADDON_LOADED")end end)
    end
end
-- Native map canvas owns scaling, panning, zooming and pin lifetime.
RUILeylinePinMixin={}
function RUILeylinePinMixin:OnLoad()
    self:UseFrameLevelType("PIN_FRAME_LEVEL_AREA_POI");self:SetScalingLimits(1,1,1.2)
    self.Icon:SetAtlas("MagePortalAlliance")
end
function RUILeylinePinMixin:OnAcquired(x,y,label)
    self.label=label;self.x=x;self.y=y;self:SetPosition(x,y)
end
function RUILeylinePinMixin:OnMouseEnter()
    GameTooltip:SetOwner(self,"ANCHOR_RIGHT");GameTooltip:SetText(self.label)
    GameTooltip:AddLine(("%.1f, %.1f"):format(self.x*100,self.y*100),.8,.8,.85)
    GameTooltip:AddLine("Known location; availability depends on your current phase.",.6,.65,.75,true);GameTooltip:Show()
end
function RUILeylinePinMixin:OnMouseLeave()GameTooltip:Hide()end
