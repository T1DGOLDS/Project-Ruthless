local _,AUI=...
local T={tiles={},spare={}}
AUI:RegisterModule("TerrainMap",T)
local YARDS=1600/3
local function public(v)return not(issecretvalue and issecretvalue(v))end
local function number(v)return public(v)and type(v)=="number"and v==v and math.abs(v)<1e7 end
local function read(fn,...)
    if type(fn)~="function"then return end
    local ok,a,b=pcall(fn,...)
    if ok and public(a)and public(b)then return a,b end
end
local function edge(v)return math.max(0,math.min(1,v))end

function T:Bounds(mapID)
    if not number(mapID)or not C_Map or not CreateVector2D then return end
    local info=read(C_Map.GetMapInfo,mapID)
    local kind=info and info.mapType
    if not number(kind)or (kind~=2 and kind~=3)then return end
    local world,top=read(C_Map.GetWorldPosFromMapPos,mapID,CreateVector2D(0,0))
    local other,bottom=read(C_Map.GetWorldPosFromMapPos,mapID,CreateVector2D(1,1))
    if not number(world)or world~=other or not top or not bottom then return end
    local data=AUI.ForeverTerrainTiles and AUI.ForeverTerrainTiles[world]
    if not data then return end
    local north,west=read(top.GetXY,top)
    local south,east=read(bottom.GetXY,bottom)
    if not(number(north)and number(west)and number(south)and number(east))then return end
    local l,t=32-west/YARDS,32-north/YARDS
    local w,h=(west-east)/YARDS,(north-south)/YARDS
    if w<=0 or h<=0 or w>64 or h>64 then return end
    return data,l,t,w,h
end

function T:Clear()
    self.drawKey=nil
    for id,tex in pairs(self.tiles)do
        tex:Hide();tex:SetTexture(nil)
        self.spare[#self.spare+1]=tex;self.tiles[id]=nil
    end
    if self.layer then self.layer:Hide()end
end

function T:Render()
    local map=self.map
    if not map or not map:IsShown()or not ProjectRuthlessCharDB then return end
    if not ProjectRuthlessCharDB.terrainMap then self.button:SetText("Terrain: Off");self:Clear();return end
    local canvas=read(map.GetCanvas,map)
    local width,height
    if canvas then width,height=read(canvas.GetSize,canvas)end
    local data,l,t,w,h=self:Bounds(read(map.GetMapID,map))
    if not data or not(number(width)and number(height))or width<=0 or height<=0 then
        self.button:SetText("Terrain unavailable");self:Clear();return
    end
    local view=read(map.GetViewRect,map)
    local a,b,c,d=0,1,0,1
    if view and number(view.left)and number(view.right)and number(view.top)and number(view.bottom)then
        a,b,c,d=edge(view.left),edge(view.right),edge(view.top),edge(view.bottom)
    end
    local firstCol,lastCol=math.max(0,math.floor(l+a*w)),math.min(63,math.ceil(l+b*w)-1)
    local firstRow,lastRow=math.max(0,math.floor(t+c*h)),math.min(63,math.ceil(t+d*h)-1)
    local drawKey=table.concat({l,t,w,h,width,height,firstCol,lastCol,firstRow,lastRow},":")
    if self.drawData==data and self.drawKey==drawKey then return end
    local visible={}
    for col=firstCol,lastCol do for row=firstRow,lastRow do
        local key=col*64+row
        if data[key]then visible[key]=data[key]end
    end end
    for key,tex in pairs(self.tiles)do
        if not visible[key]then
            tex:Hide();tex:SetTexture(nil);self.spare[#self.spare+1]=tex;self.tiles[key]=nil
        end
    end
    if not next(visible)then self.button:SetText("Terrain unavailable");self:Clear();return end
    if not self.layer then
        local layer=CreateFrame("Frame",nil,canvas)
        layer:EnableMouse(false);layer:SetAllPoints(canvas)
        local levels=map.pinFrameLevelsManager
        local exploration=levels and read(levels.GetFrameLevelStart,levels,"PIN_FRAME_LEVEL_MAP_EXPLORATION")
        layer:SetFrameLevel(number(exploration)and exploration+1 or canvas:GetFrameLevel()+2)
        self.layer=layer
    end
    for key,file in pairs(visible)do
        local col,row=math.floor(key/64),key%64
        local x0,x1=edge((col-l)/w),edge((col+1-l)/w)
        local y0,y1=edge((row-t)/h),edge((row+1-t)/h)
        local tex=self.tiles[key]
        if not tex then
            tex=table.remove(self.spare)or self.layer:CreateTexture(nil,"ARTWORK")
            tex:SetTexture(file,"CLAMP","CLAMP","TRILINEAR");tex:Show();self.tiles[key]=tex
        elseif tex:GetTexture()~=file then tex:SetTexture(file,"CLAMP","CLAMP","TRILINEAR")end
        tex:ClearAllPoints()
        tex:SetPoint("TOPLEFT",self.layer,"TOPLEFT",x0*width,-y0*height)
        tex:SetSize((x1-x0)*width,(y1-y0)*height)
        tex:SetTexCoord(edge(l+x0*w-col),edge(l+x1*w-col),edge(t+y0*h-row),edge(t+y1*h-row))
    end
    self.drawData=data;self.drawKey=drawKey
    self.layer:Show();self.button:SetText("Terrain: On")
end

function T:Queue()
    if self.queued or not self.map:IsShown()then return end
    self.queued=true
    C_Timer.After(.05,function()self.queued=nil;self:Render()end)
end
function T:Install()
    local map=WorldMapFrame
    if self.map or not map or type(map.GetCanvas)~="function"or not map.ScrollContainer then return end
    self.map=map
    local button=AUI:CreateButton(map)
    button:SetSize(134,24);button:SetPoint("BOTTOMLEFT",map.ScrollContainer,"BOTTOMLEFT",12,12)
    button:SetText("Terrain: Off");self.button=button
    button:SetScript("OnClick",function()
        ProjectRuthlessCharDB.terrainMap=not ProjectRuthlessCharDB.terrainMap
        self:Render()
    end)
    button:HookScript("OnEnter",function()
        GameTooltip:SetOwner(button,"ANCHOR_TOP")
        GameTooltip:SetText("Map terrain")
        GameTooltip:AddLine("Switch between parchment and the game's outdoor minimap terrain. Unsupported views use parchment.",1,1,1,true)
        GameTooltip:Show()
    end)
    button:HookScript("OnLeave",function()GameTooltip:Hide()end)
    map:HookScript("OnShow",function()self:Queue()end)
    map:HookScript("OnHide",function()self:Clear()end)
    for _,method in ipairs({"OnMapChanged","OnCanvasPanChanged","OnCanvasScaleChanged","OnCanvasSizeChanged"})do
        if type(map[method])=="function"then hooksecurefunc(map,method,function()
            if ProjectRuthlessCharDB and ProjectRuthlessCharDB.terrainMap then self:Queue()end
        end)end
    end
    self:Queue()
end
function T:OnPlayerLogin()
    if not AUI.isForever then return end
    self:Install()
    if self.map then return end
    local events=CreateFrame("Frame")
    events:RegisterEvent("ADDON_LOADED")
    events:SetScript("OnEvent",function(_,_,name)
        if name=="Blizzard_WorldMap"then self:Install();if self.map then events:UnregisterAllEvents()end end
    end)
end

