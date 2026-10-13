local _,AUI=...
local S={surfaces=setmetatable({},{__mode="k"}),buttons=setmetatable({},{__mode="k"}),bars=setmetatable({},{__mode="k"}),meters=setmetatable({},{__mode="k"})}
AUI:RegisterModule("ForeverStyle",S)
local WHITE="Interface\\Buttons\\WHITE8X8"
local function usable(frame)return frame and type(frame)~="function"and type(frame.GetObjectType)=="function"and not(frame.IsForbidden and frame:IsForbidden())end
local stripped=setmetatable({},{__mode="k"})
function S:BlizzardArtEnabled()
    local store=ProjectRuthlessCharDB and ProjectRuthlessCharDB.layoutEditor
    return store and store.blizzardArt==true or false
end
local function fade(texture,refresh)
    if not usable(texture)or type(texture.SetTexture)~="function"then return end
    local state=stripped[texture]
    if not state then
        local atlas=type(texture.GetAtlas)=="function"and texture:GetAtlas()
        local asset=type(texture.GetTexture)=="function"and texture:GetTexture()
        state={method=type(atlas)=="string"and "SetAtlas"or "SetTexture",asset=type(atlas)=="string"and atlas or asset}
        stripped[texture]=state
        local function changed(method,_,asset,...)
            if state.busy then return end
            state.method=method;state.asset=asset;state.args={...}
            if not S:BlizzardArtEnabled()then state.busy=true;texture:SetTexture(nil);state.busy=nil end
        end
        hooksecurefunc(texture,"SetTexture",function(...)changed("SetTexture",...)end)
        if type(texture.SetAtlas)=="function"then hooksecurefunc(texture,"SetAtlas",function(...)changed("SetAtlas",...)end)end
    end
    if refresh and not state.busy then
        local atlas=type(texture.GetAtlas)=="function"and texture:GetAtlas()
        local asset=type(texture.GetTexture)=="function"and texture:GetTexture()
        if type(atlas)=="string"then state.method="SetAtlas";state.asset=atlas;state.args={}
        elseif asset~=nil then state.method="SetTexture";state.asset=asset;state.args={}end
    end
    if not S:BlizzardArtEnabled()then state.busy=true;texture:SetTexture(nil);state.busy=nil end
end
-- Only recurse through explicitly decorative subtrees, never an entire HUD tree.
function S:ArtTree(frame,depth)
    if not usable(frame)then return end
    depth=depth or 0;if depth>4 then return end
    if type(frame.SetTexture)=="function"and frame:GetObjectType()~="Frame"then fade(frame);return end
    if type(frame.GetRegions)=="function"then
        for _,region in ipairs({frame:GetRegions()})do if usable(region)and region:GetObjectType()=="Texture"then fade(region)end end
    end
    if type(frame.GetChildren)=="function"then for _,child in ipairs({frame:GetChildren()})do
        if usable(child)and child:GetObjectType()=="Frame"then self:ArtTree(child,depth+1)end
    end end
    -- Explicit keys also support native end-cap containers before layout enumerates children.
    for _,key in ipairs({"Texture","LeftEndCap","RightEndCap"})do fade(frame[key]);local child=frame[key];if usable(child)and type(child.GetChildren)=="function"then self:ArtTree(child,depth+1)end end
end
function S:SetBlizzardArt(enabled)
    if InCombatLockdown()then return false end
    local editor=AUI.modules.LayoutEditor;local store=editor:Store();store.blizzardArt=enabled==true
    local account=editor:AccountLayouts();local profile=store.active and account.layouts[store.active]
    if profile then profile.__art={blizzardArt=store.blizzardArt}end
    if self.resting then self.pendingArt=true;self.pending=true else self:RestoreArt();self:Apply()end
    return true
end
function S:RestoreArt()
    if not self:BlizzardArtEnabled()then return end
    for texture,state in pairs(stripped)do
        state.busy=true
        if state.method=="SetAtlas"and type(state.asset)=="string"then texture:SetAtlas(state.asset,unpack(state.args or {}))else texture:SetTexture(state.asset)end
        state.busy=nil
    end
end
function S:ApplySettings()self:Queue()end
function S:Surface(frame,accent,opacity,key)
    if not usable(frame)then return end
    local bg=self.surfaces[frame]
    if not bg then
        bg=CreateFrame("Frame",nil,frame,"BackdropTemplate");self.surfaces[frame]=bg
        bg:SetAllPoints(frame);bg:EnableMouse(false)
        local level=frame:GetFrameLevel()
        if not(issecretvalue and issecretvalue(level))and type(level)=="number"then bg:SetFrameLevel(math.max(0,level-1))else bg:SetFrameLevel(0)end
        bg:SetBackdrop({bgFile=WHITE,edgeFile=WHITE,edgeSize=1})
        local line=bg:CreateTexture(nil,"BORDER");line:SetPoint("TOPLEFT",1,-1);line:SetPoint("TOPRIGHT",-1,-1);line:SetHeight(2);bg.accent=line
    end
    AUI:StyleSurface(bg,"window",opacity or .78,key or "Options")
    local r,g,b=AUI:AccentColor();bg:SetBackdropBorderColor(.16,.17,.21,.8)
    bg.accent:SetColorTexture(r,g,b,accent and .9 or 0)
    return bg
end
function S:Button(button,micro,inventory)
    if not usable(button)then return end
    self.buttons[button]=true
    self.buttonArtHooks=self.buttonArtHooks or setmetatable({},{__mode="k"})
    if not micro and not self.buttonArtHooks[button]then
        self.buttonArtHooks[button]=true
        for _,method in ipairs({"SetNormalTexture","SetNormalAtlas"})do if type(button[method])=="function"then hooksecurefunc(button,method,function()
            fade(button.NormalTexture,true)
            if type(button.GetNormalTexture)=="function"then fade(button:GetNormalTexture(),true)end
        end)end end
    end
    self:Surface(button,false,.9,inventory and "Backpack"or micro and "Micro"or (button==MainMenuBarBackpackButton or (type(button.GetName)=="function"and (button:GetName()or ""):match("^CharacterBag")))and "BagButtons"or "ActionBars")
    for _,key in ipairs({"FloatingBG","SlotBackground","SlotArt","Background","PushedBackground","Border","IconBorder","NormalTexture"})do if key~="IconBorder"or not inventory then fade(button[key])end end
    if not micro and type(button.GetName)=="function"then
        local name=button:GetName();if type(name)=="string"then for _,suffix in ipairs({"NormalTexture","NormalTexture2","FloatingBG"})do fade(_G[name..suffix])end end
    end
    if not micro and type(button.GetNormalTexture)=="function"then fade(button:GetNormalTexture())end
    local icon=button.icon or button.Icon
    if usable(icon)and icon.SetTexCoord then icon:SetTexCoord(.07,.93,.07,.93)end
    for _,key in ipairs({"HotKey","Count","Name"})do
        local text=button[key]
        if usable(text)and text.SetFontObject then text:SetFontObject(GameFontHighlightSmall);text:SetShadowColor(0,0,0,1);text:SetShadowOffset(1,-1)end
    end
    if not micro then
        for _,method in ipairs({"GetPushedTexture","GetHighlightTexture","GetCheckedTexture"})do
            if type(button[method])=="function"then
                local texture=button[method](button)
                if usable(texture)and type(texture.SetColorTexture)=="function"then texture:SetColorTexture(.65,.7,.8,.2)end
            end
        end
    end
    if not micro then
        for _,method in ipairs({"GetPushedTexture","GetHighlightTexture","GetCheckedTexture"})do
            if type(button[method])=="function"then
                local texture=button[method](button)
                if usable(texture)and type(texture.SetColorTexture)=="function"then texture:SetColorTexture(.65,.7,.8,.2)end
            end
        end
    end
    -- Keep cooldowns, charge counts, checked state, proc alerts and secure clicks.
end
function S:Chat(frame,index)
    if not usable(frame)then return end
    self:Surface(frame,true,.7,"Chat")
    frame:SetShadowColor(0,0,0,1);frame:SetShadowOffset(1,-1)
    for _,suffix in ipairs({"Background","BackgroundLeft","BackgroundRight","BackgroundTop","BackgroundBottom","BackgroundTopLeft","BackgroundTopRight","BackgroundBottomLeft","BackgroundBottomRight"})do fade(_G["ChatFrame"..index..suffix])end
    local edit=_G["ChatFrame"..index.."EditBox"]
    if usable(edit)then
        for _,suffix in ipairs({"Left","Mid","Right","FocusLeft","FocusMid","FocusRight"})do fade(_G["ChatFrame"..index.."EditBox"..suffix])end
        self:Surface(edit,false,.95,"Chat")
    end
    local edit=_G["ChatFrame"..index.."EditBox"]
    if usable(edit)then
        for _,suffix in ipairs({"Left","Mid","Right","FocusLeft","FocusMid","FocusRight"})do fade(_G["ChatFrame"..index.."EditBox"..suffix])end
        self:Surface(edit,false,.95,"Chat")
    end
    local tab=_G["ChatFrame"..index.."Tab"]
    if usable(tab)then
        for _,suffix in ipairs({"Left","Middle","Right","ActiveLeft","ActiveMiddle","ActiveRight","HighlightLeft","HighlightMiddle","HighlightRight"})do fade(_G["ChatFrame"..index.."Tab"..suffix]);fade(tab[suffix])end
        self:Surface(tab,false,.65,"Chat")
    end
end
local function xpNumber(value)
    return type(value)=="number"and not(issecretvalue and issecretvalue(value))and value==value and value~=math.huge and value~=-math.huge
end
function S:UpdateRestedXP(frame)
    local fill=frame.ruthlessRestedFill
    if not usable(fill)then return end
    local xp=UnitXP and UnitXP("player")
    local maximum=UnitXPMax and UnitXPMax("player")
    local rested=GetXPExhaustion and GetXPExhaustion()
    local width=frame.StatusBar:GetWidth()
    if not xpNumber(xp)or not xpNumber(maximum)or not xpNumber(rested)or not xpNumber(width)or maximum<=0 or rested<=0 or width<=0
        or IsXPUserDisabled and IsXPUserDisabled() or GameRulesUtil and GameRulesUtil.IsPlayerAtEffectiveMaxLevel and GameRulesUtil.IsPlayerAtEffectiveMaxLevel()then fill:Hide();return end
    local start=math.max(0,math.min(1,xp/maximum))
    local finish=math.max(start,math.min(1,(xp+rested)/maximum))
    if finish<=start then fill:Hide();return end
    fill:ClearAllPoints();fill:SetPoint("TOPLEFT",frame.StatusBar,"TOPLEFT",start*width,0)
    fill:SetPoint("BOTTOMLEFT",frame.StatusBar,"BOTTOMLEFT",start*width,0)
    fill:SetWidth((finish-start)*width);fill:Show()
end
function S:RestedXPTooltip()
    local rested=GetXPExhaustion and GetXPExhaustion()
    if type(rested)=="nil"then rested=0 end
    if not xpNumber(rested)or rested<0 or not GameTooltip then return end
    local amount=BreakUpLargeNumbers and BreakUpLargeNumbers(rested)or string.format("%.0f",rested)
    GameTooltip:AddDoubleLine("Rested bonus XP",amount,.55,.78,1,1,1,1);GameTooltip:Show()
end
function S:InstallRestedXP(frame)
    if usable(frame.ruthlessRestedFill)then return end
    local fill=frame.StatusBar:CreateTexture(nil,"ARTWORK",nil,1);frame.ruthlessRestedFill=fill
    fill:SetColorTexture(.35,.6,.85,.65)
    -- Replace the native prediction art with a precise segment ahead of earned XP.
    frame.ExhaustionLevelFillBar:SetAlpha(0)
    local tick=frame.ExhaustionTick
    if usable(tick)then
        fade(tick.Normal);fade(tick.Highlight)
        tick:HookScript("OnEnter",function()self:RestedXPTooltip()end)
        if type(tick.UpdateTickPosition)=="function"then hooksecurefunc(tick,"UpdateTickPosition",function()self:UpdateRestedXP(frame)end)end
    end
    frame:HookScript("OnSizeChanged",function()self:UpdateRestedXP(frame)end)
    frame:HookScript("OnShow",function()self:UpdateRestedXP(frame)end)
    frame:HookScript("OnEnter",function()self:RestedXPTooltip()end)
    self:UpdateRestedXP(frame)
end
function S:TrackingBar(frame)
    if not usable(frame)then return end
    fade(frame.BarFrameTexture);fade(frame.BarDividerTexture)
    fade(frame.BarFrameTexture);fade(frame.BarDividerTexture)
    local bar=frame.StatusBar
    if not usable(bar)then return end
    bar:SetStatusBarTexture(WHITE);self:Surface(frame,false,.95,"XP")
    fade(bar.Underlay);fade(bar.Overlay)
    if usable(bar.Background)then bar.Background:SetColorTexture(.035,.039,.052,0)end
    if usable(frame.ExhaustionLevelFillBar)then self:InstallRestedXP(frame);bar:SetStatusBarColor(AUI:AccentColor())end
    if not self.bars[frame]then
        self.bars[frame]=true
        if type(frame.UpdateStatusBarTextures)=="function"then hooksecurefunc(frame,"UpdateStatusBarTextures",function()
            if InCombatLockdown()or self.resting then self.pending=true else self:TrackingBar(frame)end
        end)end
    end
    -- Native XP, rested values, reputation colors, tooltips and animation remain.
end
function S:SkinNativeDialog(dialog,key)
    if not usable(dialog)then return end
    local slice=dialog.NineSlice
    if usable(slice)and type(slice.GetRegions)=="function"then for _,region in ipairs({slice:GetRegions()})do fade(region)end end
    for _,key in ipairs({"Bg","Background","Border","TopTileStreaks"})do fade(dialog[key])end
    self:Surface(dialog,true,.97,key or "Professions")
    local buttons=dialog.Buttons
    if usable(buttons)and type(buttons.GetChildren)=="function"then for _,button in ipairs({buttons:GetChildren()})do self:Button(button)end end
end
function S:InventoryItem(button)
    if not usable(button)then return end
    if InCombatLockdown()or self.resting then self.pending=true;return end
    self:Button(button,false,true)
    fade(button.ItemSlotBackground)
    -- Native quality, quest, junk, cooldown and lock indicators remain authoritative.
end
function S:BagSettings()
    ProjectRuthlessCharDB.ruiBags=ProjectRuthlessCharDB.ruiBags or {}
    return ProjectRuthlessCharDB.ruiBags
end
function S:SortOnOpen(frame)
    if not self:BagSettings().autoSort then self.pendingBagSort=nil;return end
    if InCombatLockdown()or self.resting then self.pendingBagSort=frame;return end
    self.pendingBagSort=nil
    if usable(frame)and frame:IsShown()and C_Container and type(C_Container.SortBags)=="function"then C_Container.SortBags()end
end
function S:BagMenu()
    if self.bagMenuInstalled or not Menu or type(Menu.ModifyMenu)~="function"then return end
    self.bagMenuInstalled=true
    Menu.ModifyMenu("MENU_CONTAINER_FRAME_COMBINED",function(_,root)
        root:CreateDivider();root:CreateTitle("RUI inventory")
        root:CreateCheckbox("Auto-sort when opened",function()return self:BagSettings().autoSort==true end,function()local settings=self:BagSettings();settings.autoSort=not settings.autoSort;if not settings.autoSort then self.pendingBagSort=nil end end)
        local columns=root:CreateButton("Columns")
        for _,count in ipairs({8,10,12})do
            columns:CreateRadio(tostring(count),function()return (self:BagSettings().columns or 10)==count end,function()self:BagSettings().columns=count;self:InventoryFrame(ContainerFrameCombinedBags)end)
        end
    end)
end
function S:RestoreBackpackPosition()
    local frame=ContainerFrameCombinedBags
    if not usable(frame)or self.bagDragging or self.bagPositioning or InCombatLockdown()or self.resting then return end
    local editor=AUI.modules.LayoutEditor
    local value=editor:Store().elements.backpack
    if value then self.bagPositioning=true;editor:Apply("backpack",value);self.bagPositioning=nil end
end
function S:BackpackMovement(frame)
    if frame~=ContainerFrameCombinedBags then return end
    local editor=AUI.modules.LayoutEditor
    editor:Attach("backpack","Backpack",frame)
    if not self.bagDragHeader then
        frame:SetMovable(true);frame:SetClampedToScreen(true)
        local header=CreateFrame("Frame",nil,frame);self.bagDragHeader=header
        header:SetPoint("TOPLEFT",frame,"TOPLEFT",4,-2);header:SetPoint("TOPRIGHT",frame,"TOPRIGHT",-84,-2);header:SetHeight(24)
        header:EnableMouse(true);header:RegisterForDrag("LeftButton")
        header:SetScript("OnDragStart",function()
            if InCombatLockdown()or self.resting then return end
            self.bagDragging=true;frame:StartMoving()
        end)
        local function stop()
            if not self.bagDragging then return end
            frame:StopMovingOrSizing();self.bagDragging=nil
            if InCombatLockdown()then return end
            local value=editor:Capture(frame)
            if value then editor:Store().elements.backpack=value end
        end
        header:SetScript("OnDragStop",stop);frame:HookScript("OnHide",stop)
        if type(UpdateContainerFrameAnchors)=="function"then
            hooksecurefunc("UpdateContainerFrameAnchors",function()self:RestoreBackpackPosition()end)
        end
    end
    self:RestoreBackpackPosition()
end
function S:InventoryLayout(frame)
    if frame~=ContainerFrameCombinedBags or self.inventoryLayingOut or InCombatLockdown()or self.resting then return end
    local enumerate=frame.EnumerateValidItems or frame.EnumerateItems
    if type(enumerate)~="function"then return end
    self.inventoryLayingOut=true
    local columns=self:BagSettings().columns
    if columns~=8 and columns~=10 and columns~=12 then columns=10 end
    local size,gap,pad,top=36,2,8,58
    local count=0
    for _,button in enumerate(frame)do
        if usable(button)then
            local index=count;count=count+1
            button:ClearAllPoints();button:SetSize(size,size)
            button:SetPoint("TOPLEFT",frame,"TOPLEFT",pad+(index%columns)*(size+gap),-top-math.floor(index/columns)*(size+gap))
            local icon=button.icon or button.Icon
            if usable(icon)then icon:ClearAllPoints();icon:SetPoint("TOPLEFT",button,"TOPLEFT",2,-2);icon:SetPoint("BOTTOMRIGHT",button,"BOTTOMRIGHT",-2,2)end
            self:InventoryItem(button)
        end
    end
    local extra=0
    if ContainerFrameSettingsManager and type(ContainerFrameSettingsManager.GetTokenTrackerIfShown)=="function"then
        local tracker=ContainerFrameSettingsManager:GetTokenTrackerIfShown(frame)
        if usable(tracker)then local height=tracker:GetHeight();if type(height)=="number"and not(issecretvalue and issecretvalue(height))then extra=height end end
    end
    frame:SetSize(pad*2+columns*(size+gap)-gap,top+math.max(1,math.ceil(count/columns))*(size+gap)-gap+26+extra)
    if usable(frame.MoneyFrame)then
        local border=frame.MoneyFrame.Border
        if usable(border)then
            if type(border.GetRegions)=="function"then for _,region in ipairs({border:GetRegions()})do fade(region)end end
            if type(border.GetChildren)=="function"then for _,child in ipairs({border:GetChildren()})do if type(child.GetRegions)=="function"then for _,region in ipairs({child:GetRegions()})do fade(region)end end end end
        end
        frame.MoneyFrame:ClearAllPoints();frame.MoneyFrame:SetPoint("BOTTOMLEFT",frame,"BOTTOMLEFT",8,7+extra);frame.MoneyFrame:SetPoint("BOTTOMRIGHT",frame,"BOTTOMRIGHT",-8,7+extra)
    end
    if not usable(frame.ruiSlotCount)then frame.ruiSlotCount=frame:CreateFontString(nil,"OVERLAY","GameFontHighlightSmall")end
    frame.ruiSlotCount:ClearAllPoints();frame.ruiSlotCount:SetPoint("BOTTOMLEFT",frame,"BOTTOMLEFT",10,10+extra)
    local free=0
    if C_Container and type(C_Container.GetContainerNumFreeSlots)=="function"then
        for bag=0,4 do local n=C_Container.GetContainerNumFreeSlots(bag);if type(n)=="number"and not(issecretvalue and issecretvalue(n))then free=free+n end end
    end
    frame.ruiSlotCount:SetText(free.." free / "..count)
    if type(frame.LayoutAddSlots)=="function"then frame:LayoutAddSlots()end
    self.inventoryLayingOut=nil
    self:RestoreBackpackPosition()
end
function S:InventoryFrame(frame)
    if not usable(frame)then return end
    if InCombatLockdown()or self.resting then self.pending=true;return end
    self:SkinNativeDialog(frame,"Backpack")
    if usable(frame.Bg)then frame.Bg:SetAlpha(0)end
    if usable(frame.PortraitContainer)then fade(frame.PortraitContainer.portrait)end
    local title=usable(frame.TitleContainer)and frame.TitleContainer.TitleText
    if usable(title)then
        title:SetFontObject(GameFontNormalSmall);title:SetTextColor(AUI:AccentColor())
        if frame==ContainerFrameCombinedBags or frame==ContainerFrame1 then title:SetText("Backpack")end
    end
    if usable(frame.TitleContainer)then
        frame.TitleContainer:ClearAllPoints();frame.TitleContainer:SetPoint("TOPLEFT",frame,"TOPLEFT",8,-1);frame.TitleContainer:SetPoint("TOPRIGHT",frame,"TOPRIGHT",-82,-1)
    end
    for _,key in ipairs({"Background1Slot","Portrait","PortraitOverlay","PortraitFrame"})do fade(frame[key])end
    if usable(frame.PortraitButton)then
        local menu=frame.PortraitButton
        menu:ClearAllPoints();menu:SetPoint("TOPRIGHT",frame,"TOPRIGHT",-30,-2);menu:SetSize(46,18)
        self:Surface(menu,false,.95,"Backpack");menu:SetNormalFontObject(GameFontNormalSmall);menu:SetText("Bags")
        if type(frame.PortraitButton.GetRegions)=="function"then for _,region in ipairs({frame.PortraitButton:GetRegions()})do if region:GetObjectType()=="Texture"then fade(region)end end end
    end
    if usable(frame.CloseButton)then
        self:Button(frame.CloseButton);frame.CloseButton:SetNormalFontObject(GameFontHighlight);frame.CloseButton:SetText("×")
    end
    local search=frame.SearchBox or (BagItemSearchBox and BagItemSearchBox:GetParent()==frame and BagItemSearchBox)
    if usable(search)then
        for _,key in ipairs({"Left","Middle","Right"})do fade(search[key])end
        self:Surface(search,false,.95,"Backpack")
        if frame==ContainerFrameCombinedBags and usable(BagItemAutoSortButton)then
            search:ClearAllPoints();search:SetPoint("TOPLEFT",frame,"TOPLEFT",10,-37);search:SetPoint("RIGHT",BagItemAutoSortButton,"LEFT",-8,0)
        end
    end
    if type(frame.EnumerateItems)=="function"then
        for _,button in frame:EnumerateItems()do self:InventoryItem(button)end
    end
    self:InventoryLayout(frame)
    self:BackpackMovement(frame)
    self.inventoryFrames=self.inventoryFrames or setmetatable({},{__mode="k"})
    if not self.inventoryFrames[frame]then
        self.inventoryFrames[frame]=true
        if type(frame.Update)=="function"then hooksecurefunc(frame,"Update",function()self:InventoryFrame(frame)end)end
        if type(frame.UpdateName)=="function"then hooksecurefunc(frame,"UpdateName",function()self:InventoryFrame(frame)end)end
        if frame==ContainerFrameCombinedBags then
            for _,method in ipairs({"UpdateFrameSize","UpdateItemLayout","UpdateCurrencyFrames"})do if type(frame[method])=="function"then hooksecurefunc(frame,method,function()self:InventoryLayout(frame)end)end end
        end
        frame:HookScript("OnShow",function()self:InventoryFrame(frame);if frame==ContainerFrameCombinedBags then self:SortOnOpen(frame)end end)
        frame:HookScript("OnHide",function()if self.pendingBagSort==frame then self.pendingBagSort=nil end end)
    end
end
function S:Inventory()
    self:BagMenu()
    -- Native buttons keep their bag/slot identity and item actions.
    if ProjectRuthlessCharDB and not ProjectRuthlessCharDB.ruiNativeBagsInitialized and C_CVar and C_CVar.SetCVar then
        C_CVar.SetCVar("combinedBags", "1")
        ProjectRuthlessCharDB.ruiNativeBagsInitialized=true
    end
    self:InventoryFrame(ContainerFrameCombinedBags)
    if usable(BagItemAutoSortButton)then
        self:Button(BagItemAutoSortButton)
        if type(BagItemAutoSortButton.GetRegions)=="function"then for _,region in ipairs({BagItemAutoSortButton:GetRegions()})do if region:GetObjectType()=="Texture"then fade(region)end end end
        BagItemAutoSortButton:SetSize(42,22);BagItemAutoSortButton:SetNormalFontObject(GameFontNormalSmall);BagItemAutoSortButton:SetText("Sort")
    end
    for i=1,NUM_CONTAINER_FRAMES or 13 do self:InventoryFrame(_G["ContainerFrame"..i])end
    if self.pendingBagSort then self:SortOnOpen(self.pendingBagSort)end
end
function S:ProfessionUnlearnButton(button)
    if not usable(button)then return end
    button:SetSize(24,24)
    self:Surface(button,false,.96,"Professions")
    if usable(button.Icon)and type(button.Icon.SetAtlas)=="function"then
        button.Icon:SetAtlas("Profession-button-red-crossmark",true);button.Icon:Show()
    end
    if usable(button.Overlay)and type(button.Overlay.SetAtlas)=="function"then
        button.Overlay:SetAtlas("Profession-button-red-crossmark-pressed",true)
    end
    if not button.ruiUnlearnMark then
        local mark=button:CreateFontString(nil,"OVERLAY","GameFontNormalLarge")
        mark:SetPoint("CENTER",0,1);mark:SetText("×");mark:SetTextColor(.95,.24,.20,1)
        button.ruiUnlearnMark=mark
        -- Blizzard owns visibility, the click script and the UNLEARN_SKILL
        -- confirmation. This fallback mark only keeps that native action visible.
        button:HookScript("OnShow",function(self)S:ProfessionUnlearnButton(self)end)
    end
    button.ruiUnlearnMark:Show()
end
function S:ProfessionCard(card,primary)
    if not usable(card)then return end
    fade(card.Background);self:Surface(card,primary,primary and .88 or .8,"Professions")
    local rank=card.StatusBar
    if usable(rank)then
        fade(rank.Background);fade(rank.Border);fade(rank.Flare)
        self:Surface(rank,false,.94,"Professions")
        -- Fill, mask and rank text remain native and continue to update.
    end
    for _,button in ipairs(card.spellButtons or {})do
        -- Camelot uses IconTexture, not the action-button Icon field.
        if usable(button)then
            local icon=button.IconTexture or button.Icon
            if usable(icon)then
                icon:ClearAllPoints();icon:SetPoint("TOPLEFT",3,-3);icon:SetPoint("BOTTOMRIGHT",-3,3)
                icon:SetTexCoord(.07,.93,.07,.93)
            end
            fade(button.IconTextureOverlay);fade(button.Flash)
            local normal=type(button.GetNormalTexture)=="function"and button:GetNormalTexture()
            fade(normal)
            self:Surface(button,false,.96,"Professions")
        end
    end
    if primary then self:ProfessionUnlearnButton(card.UnlearnButton)end
end
function S:Professions()
    if InCombatLockdown()or self.resting then self.pending=true;return end
    local frame=ProfessionsFrame
    if not usable(frame)then return end
    self:SkinNativeDialog(frame)
    local book=frame.BookPage
    local content=usable(book)and book.ProfessionsContentFrame
    if usable(book)then
        self:Surface(book,false,.86,"Professions")
        -- Named parchment textures are not fields on BookPage.
        fade(ProfessionsBookPage1);fade(ProfessionsBookPage2)
    end
    if usable(content)then
        self:ProfessionCard(content.PrimaryProfession1,true)
        self:ProfessionCard(content.PrimaryProfession2,true)
        for i=1,3 do self:ProfessionCard(content["SecondaryProfession"..i],false)end
    end
    local craft=frame.CraftingPage
    if usable(craft)then
        self:Surface(craft,false,.88,"Professions")
        if usable(craft.RecipeList)then self:Surface(craft.RecipeList,false,.9,"Professions")end
        if usable(craft.SchematicForm)then self:Surface(craft.SchematicForm,false,.82,"Professions")end
    end
    if not self.professionsHooked then
        self.professionsHooked=true
        frame:HookScript("OnShow",function()S:Professions()end)
        if usable(book)and type(book.Update)=="function"then hooksecurefunc(book,"Update",function()S:Professions()end)end
    end
end
function S:Details()
    local details=Details or _detalhes
    if type(details)~="table"or type(details.GetAllInstances)~="function"then return end
    local ok,instances=pcall(details.GetAllInstances,details)
    if ok and type(instances)=="table"then
        for _,instance in ipairs(instances)do
            if usable(instance.baseframe)then
                self:Surface(instance.baseframe,true,.78,"Meters")
                if not self.meters[instance]then
                    self.meters[instance]=true
                    if type(instance.SetBackgroundColor)=="function"then instance:SetBackgroundColor(.025,.028,.035)end
                    if type(instance.SetBackgroundAlpha)=="function"then instance:SetBackgroundAlpha(0)end
                end
            end
        end
    end
    if not self.detailsHooked and type(details.CreateInstance)=="function"then
        self.detailsHooked=true;hooksecurefunc(details,"CreateInstance",function()self:Queue()end)
    end
end
function S:Apply()
    if not AUI.isForever then return end
    if InCombatLockdown()or self.resting then self.pending=true;return end
    self.pending=nil;self.pendingArt=nil
    self:RestoreArt()
    for _,prefix in ipairs({"ActionButton","MultiBarBottomLeftButton","MultiBarBottomRightButton","MultiBarRightButton","MultiBarLeftButton","MultiBar5Button","MultiBar6Button","MultiBar7Button","PetActionButton","StanceButton"})do
        for i=1,12 do self:Button(_G[prefix..i])end
    end
    for _,name in ipairs({"MainActionBar","MainMenuBar","MultiBarBottomLeft","MultiBarBottomRight","MultiBarRight","MultiBarLeft","MultiBar5","MultiBar6","MultiBar7","PetActionBar","StanceBar","MicroMenu","BagsBar"})do
        local frame=_G[name]
        if usable(frame)then
            -- Buttons supply the charcoal fill; avoid stacking another translucent panel underneath.
            if self.surfaces[frame]then self.surfaces[frame]:Hide()end
            for _,key in ipairs({"BorderArt","BackgroundArt","Background","EndCaps","LeftEndCap","RightEndCap","ArtFrame"})do self:ArtTree(frame[key])end
        end
    end
    for _,name in ipairs(MICRO_BUTTONS or {"CharacterMicroButton","SpellbookMicroButton","TalentMicroButton","QuestLogMicroButton","MainMenuMicroButton","HelpMicroButton"})do self:Button(_G[name],true)end
    for _,name in ipairs({"MainMenuBarArtFrame","MainMenuBarLeftEndCap","MainMenuBarRightEndCap"})do self:ArtTree(_G[name])end
    self:Button(MainMenuBarBackpackButton)
    for i=0,4 do self:Button(_G["CharacterBag"..i.."Slot"])end
    for i=1,NUM_CHAT_WINDOWS or 10 do self:Chat(_G["ChatFrame"..i],i)end
    for _,name in ipairs({"MainStatusTrackingBarContainer","SecondaryStatusTrackingBarContainer","StatusTrackingBarManager"})do
        local frame=_G[name]
        if usable(frame)then
            self:TrackingBar(frame)
            for _,child in ipairs({frame:GetChildren()})do self:TrackingBar(child)end
        end
    end
    self:Inventory()
    self:Professions()
    self:Details()
end
function S:Queue()
    if self.queued then return end
    self.queued=true
    C_Timer.After(.2,function()self.queued=nil;self:Apply()end)
end
function S:OnPlayerLogin()
    if not AUI.isForever then return end
    local editor=AUI.modules.LayoutEditor;local store=editor:Store()
    if store.blizzardArt==nil then store.blizzardArt=false end
    local account=editor:AccountLayouts();local profile=store.active and account.layouts[store.active]
    if profile and not profile.__art then profile.__art={blizzardArt=store.blizzardArt==true}end
    local events=CreateFrame("Frame");self.events=events
    for _,event in ipairs({"ADDON_LOADED","PLAYER_ENTERING_WORLD","PLAYER_REGEN_DISABLED","PLAYER_REGEN_ENABLED","UPDATE_CHAT_WINDOWS"})do events:RegisterEvent(event)end
    events:SetScript("OnEvent",function(_,event,loaded)
        local hud=AUI.modules.ForeverHUD
        local nativeSkin=type(loaded)=="string"and (loaded:match("^Blizzard_Professions")or loaded:match("^Blizzard_SpellBook")or loaded:match("^Blizzard_PlayerSpells")or loaded:match("^Blizzard_Container"))
        if event=="ADDON_LOADED"and hud and not hud:IsRelevantAddon(loaded)and not nativeSkin and loaded~="Details"then return end
        if event=="PLAYER_REGEN_DISABLED"then self.resting=true;self.revision=(self.revision or 0)+1;return end
        if event=="PLAYER_REGEN_ENABLED"then
            local revision=self.revision
            C_Timer.After(3,function()if revision~=self.revision or InCombatLockdown()then return end;self.resting=nil;self:Queue()end)
            return
        end
        self:Queue()
    end)
    self:Queue()
end
