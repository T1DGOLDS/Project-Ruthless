local _,AUI=...
local G={}
AUI:RegisterModule("FeatureGuide",G)
-- Product help lives with the feature it describes. This account preference is
-- deliberately outside exported interface profiles and character setup state.
function G:Store()
 if type(ProjectRuthlessDB.introduction)~="table"then ProjectRuthlessDB.introduction={}end
 return ProjectRuthlessDB.introduction
end
G.tour={
 {title="Welcome to Ruthless UI",body="Keep the familiar WoW controls and discover the tools built around them.\n\nUse RUI Settings to search for an option by what you want to do. Your map holds quests, routes, dungeon information and preparation.\n\nThis short introduction shows where to begin. The full feature guide stays in settings whenever you need it."},
 {title="Make the interface yours",body="Edit Mode moves and scales your interface, with coordinates, a grid, snapping and alignment guides.\n\nProfiles save your settings, layout and chat together. You can choose an account default for new characters.\n\nQuick setup offers portrait and readability choices. It keeps a saved layout intact."},
 {title="Find the less obvious tools",body="The Spellbook includes macros, autocomplete, future skills and pet abilities. Macro templates explain targeting and common utility commands before you create them.\n\nBags can sort whenever you open them. Auction tools keep character searches and shopping lists. The damage meter includes fight history and breakdowns.\n\nBrowse all features below for instructions and the matching settings."},
 {title="Plan the next part of your journey",body="Use the main map to browse quests, choose a walkthrough, prepare supplies and inspect dungeons. The side tracker keeps your current task close by.\n\nFlight timers learn completed routes. Repair warnings can remind you before equipment breaks.\n\nSome game data varies by phase or is unavailable to addons. RUI labels missing data and estimates so you can tell what is known."},
}
G.topics={
 {id="professions",title="Profession guides, recipes and crafting profit",page="professions",location="Professions shortcut / micro-menu button, or Map > Professions",body="Professions has its own window and settings page, separate from Spellbook. Choose any profession, including gathering skills. Recipes includes published future recipes and your observed native crafting catalog. Leveling shows skill ranges, learning sources and estimated crafts. Sources includes vendor recipe information, trainers and gathering zones where recorded. Profit compares material value with saved realm auction prices, after the sale fee you enter. Owned materials keep their value; extra cash for missing materials is separate. Select a recipe and Add plan, then use Shopping to send its materials to the auction tools. Manual prices, old or missing quotes, bound outputs and data gaps stay clearly identified. Open native crafting to refresh schematics; nothing crafts, buys or posts automatically."},
 {id="profiles",title="One profile for your whole interface",page="profiles",location="Profiles",body="Save settings, Edit Mode placement, chat tabs and their filters as one named profile. Loading it applies that whole setup. The separate default-for-new-characters choice controls which saved setup a new character starts with; it does not replace existing characters' layouts. Profiles include recovery copies. The introduction's Don't show again choice belongs to your account, independently of profiles."},
 {id="layout",title="Precise movement, snapping and backgrounds",page="general",location="Appearance",body="Open RUI Edit Mode from the game menu to drag elements, enter coordinates, scale frames and use grid or element snapping. Saved layouts keep the chat dock together. Directly draggable windows such as the backpack, auction house, repair warning and flight timer also retain their positions. Appearance controls set common charcoal colour and opacity; individual background overrides let one surface differ. Decorative Blizzard art has its own setting."},
 {id="future",title="Future skills, ranks, prices and pet abilities",page="spellbook",location="Spellbook & macros",body="The normal spellbook shortcut opens RUI's book. Search learned and future skills, grouped by specialization and acquisition level where metadata is known. Future ranks retain training requirements and recorded prices; unknown values remain labelled. Right-click a spell to pin it. The missing-from-bars filter helps find unplaced abilities. A Pet section appears for pet abilities when the client supplies them; professions retain their native controls."},
 {id="autocomplete",title="Macro autocomplete and explanations",page="spellbook",location="Spellbook & macros",body="In Spellbook > Macros, autocomplete suggests slash commands, conditions and spell names as you type. Use Up/Down to choose and Tab to insert; Enter remains a new line in the editor. Validation explains likely problems rather than silently changing the macro. Macro history retains earlier saved versions and rank updates. Suggestions do not cast spells or bypass normal macro limits."},
 {id="templates",title="Explained utility and targeting macros",page="spellbook",location="Spellbook & macros",body="Use the macro Templates tools for common utilities and targeting patterns. Utility examples include target markers, pings and reload; spell patterns include mouseover, target-of-target and cursor placement where supported. Read the explanation, replace any spell placeholder and review class examples. Macro creation still respects bank capacity, combat restrictions, spell availability and group permissions. A template does not execute when you browse it."},
 {id="ranks",title="Automatic spell-rank upgrades",page="spellbook",location="Spellbook & macros",body="Automatic macro rank updates can replace explicit older spell ranks when a higher rank is learned, with previous text kept in History. Spellbook & macros controls macro updates; Action bars controls normal-spell rank upgrades. These controls are separate so deliberate downranking remains possible. Edits that require protected changes wait until combat ends; rankless macros continue to use the game's normal rank selection."},
 {id="units",title="Unit frames, target-of-target and attack timers",page="unitframes",location="Unit frames",body="Player, target, pet and party frames share RUI styling. Party members can use separate blocks or a grouped background. Target-of-target frames and casts help reveal who your target is attacking. Player casting and attack timers share their display space: casts take priority, with main-hand, off-hand or ranged timing shown when available. Latency bands provide the same visual cue as normal casts."},
 {id="auras",title="Auras, dispels and cooldown management",page="auras",location="Auras & cooldowns",body="Choose player buffs, debuffs, target debuffs and a focused aura, then adjust icon size, spacing, count and ordering. Party buffs/debuffs sit beside their member; dispellable effects receive emphasis through native classification. Expiring self-buffs provide a short-duration reminder. Cooldown controls use supported native tools where available. Check feature status here if a group is hidden or unavailable; this is a focused manager, not arbitrary WeakAuras scripting."},
 {id="nameplates",title="Nameplate effects and quest icons",page="unitframes",location="Unit frames",body="RUI nameplates keep native unit behavior with cleaner bars and configurable personal effect size. Numbered native cooldown timers help read your own damage-over-time effects when timing is supplied. Quest indicators distinguish kill, kill-to-loot and interaction objectives without using the space above the plate for every quest hint. Restricted or unavailable data is omitted rather than guessed."},
 {id="bags",title="Combined bags, search and sort on opening",page="bags",location="Bags & inventory",body="The combined backpack includes the reagent bag. Search, manual Sort and bag assignments use Blizzard's normal inventory functions. Enable Auto-sort bags when opened to sort on each opening; combat defers the protected work. Choose the number of columns, drag the header to position the bag and save it with your profile. Turning auto-sort off preserves manual organization."},
 {id="auctions",title="Auction searches, shopping and price history",page="auctionhouse",location="Auction house",body="The auction house keeps native buying and selling with RUI Tools integrated into its bottom navigation. Save character-specific searches, choose a default and use shopping lists or quest supplies. Search filters and recent searches can be retained. A manual full-market snapshot supports fast local searching of returned prices; cached observations are not guaranteed current market prices. Purchases and posts remain explicit player actions."},
 {id="meter",title="Damage meter and fight breakdowns",page="health",location="Combat & utilities",body="The RUI damage meter offers live totals, fight history and spell breakdowns with compact class-coloured bars. Use its controls to choose the metric or fight and inspect an entry for detail. Enable or move the meter in settings. Its available detail comes from the client's supported combat data; it does not claim every Details feature or hidden combat value."},
 {id="quests",title="Quest browsing and map markers",page="mapquests",location="Map & quests",body="The main map is the place to browse available quests, active quests and known prerequisite progress. Select an objective to link the side tracker and map focus. Filters control quest starts, low-level stories and account-completed content. Known pickup points and objective-type icons supplement native areas. Eligibility, coordinates and phase information can be incomplete; an uncertain pickup is not a promise that the server will offer it."},
 {id="guides",title="Walkthroughs and your current task",page="mapquests",location="Map & quests",body="Choose a route in the map's Guides library. RUI's own authored route and explicitly selected supported guide providers remain separate choices. The current step explains the action; skip, restore, previous and next controls let you manage the route instead of selecting a random quest to drive it. Quest acceptance, completion and known prerequisites guide progress. A route's level/faction/content coverage should match the character you are playing."},
 {id="dungeons",title="Dungeon atlas, bosses, loot and preparation",page="mapquests",location="Map & quests",body="Open Dungeon atlas in the map to browse an instance's maps, bosses, loot and related quests. Use the preparation and quest information before travelling so prerequisites or required items are not missed. Native floors are used when available; reference maps do not fabricate your position. Drop rates and source information belong with the loot when verified; unavailable or non-Forever values must remain clearly identified."},
 {id="supplies",title="Buy quest supplies before travelling",page="mapquests",location="Map & quests",body="The map's Supplies tools organize recorded quest-item needs by destination. Check what you already carry and what remains before entering a new zone or dungeon. Tradeable quest supplies can also be browsed from auction tools; merchant reminders appear only for relevant offered items. An item list is preparation information, not automatic purchase or a guarantee that every quest objective is tradeable."},
 {id="travel",title="Square minimap, flight timers and spirit healers",page="mapquests",location="Map & quests",body="Map icon filters control racial markers, flights, instances and gathering tracking. The square minimap retains native blue quest areas and alerts. Flight timers show measured routes when available; a leading ~ means an estimate, while an unknown trip shows elapsed time. Drag the timer to move it. Spirit-healer locations can show on the world map; optional nearest-healer outlines are estimates, while the game's current release destination is distinguished when supplied."},
 {id="repair",title="Movable repair warning and reminders",page="health",location="Combat & utilities",body="The repair warning shows the lowest equipped item's durability and a per-item hover list. It starts at 30% by default; change the threshold, reminders or optional sound in settings. A fresh low state and an item breaking can alert once without repeating on every inventory update. Preview the warning to position it while fully repaired, or drag it directly when visible. Its position saves with your layout."},
 {id="history",title="Level-by-level playtime history",page="health",location="Combat & utilities",body="Leveling history records character identity and available played-time milestones so you can review time spent reaching levels and compare your recorded characters. Historical times before recording began can be unknown; a missing milestone is not reconstructed as a precise result. The stored history is separate from presentation profiles, so changing your layout does not erase it."},
 {id="chat",title="Chat tabs travel with your profile",page="chat",location="Chat",body="Use the normal chat-tab menus for channels, message filters and font settings. Complete RUI profiles include permanent extra tabs and their settings, plus dock order and selection. Temporary conversation tabs remain temporary. Edit Mode treats the main chat dock as one unit rather than giving every possible tab a separate mover."},
 {id="accessibility",title="Readability and familiar game controls",page="accessibility",location="Accessibility",body="Increase RUI text size, use higher-contrast backgrounds and choose static portraits or reduced motion. Settings search can jump directly to a control; Tab, Enter, arrow keys and Page Up/Down support settings navigation. Native accessibility, audio assist, subtitles and colourblind options remain available through their own categories. Supported keyboard/readability controls are not a claim of complete screen-reader parity."},
 {id="diagnostics",title="Feature checks, error reports and performance",page="errors",location="Help & diagnostics",body="Configuration checks explain settings or missing capabilities that prevent a feature from appearing. Macro validation provides its own actionable text. Capture Lua errors and create a local bug report with steps, expected behavior and actual behavior. /pr record on and /pr record off collect a bounded performance session; /pr report presents it. Frame gaps alone do not prove RUI caused them, and no report is uploaded automatically. Manual live checks remain your acceptance record, not automatic certification."},
}
function G:OpenGuide()
 if self.frame then self.frame:Hide()end
 local menu=AUI.modules.Menu;if menu and menu.Show then menu:Show("features")end
end
function G:BuildSettings(menu,parent)
 local flow=menu:CreateFlowPage(parent,"features","RUI feature guide","A practical tour of the tools beyond the familiar WoW interface. Each section links to its settings.")
 flow:Action("Back to Help",function()menu:SelectTab("errors")end)
 flow:Action("Show the introduction",function()self:Show(true)end,"Replay the short welcome at any time.")
 flow:Check("Don't show introduction on login","This account choice stays separate from saved interface profiles.",function()return self:Store().dontShowAgain==true end,function(value)self:Store().dontShowAgain=value==true end)
 for _,entry in ipairs(self.topics)do local topic=entry
  flow:Section(topic.title);flow:Note(topic.body)
  local label="Settings: "..topic.title
  local button=flow:Action(label,function()menu:SelectTab(topic.page)end,"Find it in "..topic.location..".")
  local registry=AUI.modules.SettingsRegistry
  if registry then registry:Register("features",button,label,topic.body.." "..topic.location,flow.y,"action","FeatureGuide",topic.id)end
 end
 flow:Reflow();return flow.panel
end
function G:Layout()
 local frame=self.frame;if not frame then return end
 local height=math.max(430,120+(self.copy:GetStringHeight()or 160)+190)
 frame:SetHeight(height)
 local access=AUI.modules.Accessibility
 if access then frame:SetScale(access:FitWindow(frame,(ProjectRuthlessDB.general or {}).windowScale or 1))end
end
function G:Render()
 if not self.frame then return end
 local page=self.tour[self.page or 1]
 self.heading:SetText(page.title);self.copy:SetText(page.body)
 self.step:SetText(("%d / %d"):format(self.page,#self.tour))
 self.back:SetEnabled(self.page>1);self.next:SetText(self.page==#self.tour and "Finish"or "Next")
 self.tick:SetShown(self:Store().dontShowAgain==true);self:Layout()
end
function G:SetFocus(index)
 local controls=self.keyboardControls;if not controls then return end
 local r,g,b=AUI:AccentColor()
 for _,control in ipairs(controls)do control:SetBackdropBorderColor(.16,.17,.21,1)end
 self.keyboardIndex=index
 if index then controls[index]:SetBackdropBorderColor(r,g,b,1)end
end
function G:Create()
 if self.frame then return end
 local frame=CreateFrame("Frame","RUIIntroductionPopup",UIParent,"BackdropTemplate");self.frame=frame
 frame:SetSize(540,460);frame:SetPoint("CENTER");frame:SetFrameStrata("DIALOG");frame:SetClampedToScreen(true)
 frame:SetBackdrop({bgFile="Interface\\Buttons\\WHITE8X8",edgeFile="Interface\\Buttons\\WHITE8X8",edgeSize=1})
 AUI:StyleSurface(frame,"window",nil,"Options")
 local r,g,b=AUI:AccentColor();frame:SetBackdropBorderColor(r,g,b,.9)
 local function label(font)
  local text=frame:CreateFontString(nil,"OVERLAY",font);text:SetJustifyH("LEFT")
  if AUI.modules.Accessibility then AUI.modules.Accessibility:RegisterText(text)end
  return text
 end
 local brand=label("GameFontNormal");brand:SetPoint("TOPLEFT",24,-24);brand:SetText("RUI  ·  RUTHLESS UI");brand:SetTextColor(r,g,b)
 self.step=label("GameFontDisableSmall");self.step:SetPoint("TOPRIGHT",-58,-26)
 self.heading=label("GameFontNormalLarge");self.heading:SetPoint("TOPLEFT",24,-60);self.heading:SetWidth(492)
 self.copy=label("GameFontHighlight");self.copy:SetPoint("TOPLEFT",24,-110);self.copy:SetWidth(492)
 local function button(text,width,x,y,anchor,fn)
  local control=AUI:CreateButton(frame);control:SetSize(width,32);control:SetPoint(anchor or "BOTTOMLEFT",frame,anchor or "BOTTOMLEFT",x,y);control:SetText(text);control:SetScript("OnClick",fn);return control
 end
 self.back=button("Previous",104,24,82,nil,function()self.page=math.max(1,self.page-1);self:Render()end)
 self.next=button("Next",132,-24,82,"BOTTOMRIGHT",function()if self.page==#self.tour then frame:Hide()else self.page=self.page+1;self:Render()end end)
 local setup=button("Quick setup",168,142,82,nil,function()frame:Hide();AUI.modules.Menu:Show("setup")end)
 local guide=button("Browse all RUI features",492,24,128,nil,function()self:OpenGuide()end)
 local close=button("x",24,-18,-18,"TOPRIGHT",function()frame:Hide()end);close:SetHeight(24)
 local check=button("",492,24,24,nil,function()self:Store().dontShowAgain=not self:Store().dontShowAgain;self:Render()end)
 local box=CreateFrame("Frame",nil,check,"BackdropTemplate");box:SetSize(20,20);box:SetPoint("LEFT",8,0)
 box:SetBackdrop({bgFile="Interface\\Buttons\\WHITE8X8",edgeFile="Interface\\Buttons\\WHITE8X8",edgeSize=1});box:SetBackdropColor(.018,.021,.029,1);box:SetBackdropBorderColor(.35,.38,.44,1)
 self.tick=box:CreateTexture(nil,"ARTWORK");self.tick:SetAtlas("common-icon-checkmark");self.tick:SetSize(16,16);self.tick:SetPoint("CENTER")
 local checkLabel=check:CreateFontString(nil,"OVERLAY","GameFontHighlightSmall");checkLabel:SetPoint("LEFT",40,0);checkLabel:SetText("Don't show again")
 if AUI.modules.Accessibility then AUI.modules.Accessibility:RegisterText(checkLabel)end
 self.keyboardControls={self.back,setup,self.next,guide,check}
 frame:EnableKeyboard(true);frame:SetPropagateKeyboardInput(true)
 frame:SetScript("OnKeyDown",function(_,key)
  frame:SetPropagateKeyboardInput(true)
  if key~="ESCAPE"and GetCurrentKeyBoardFocus and GetCurrentKeyBoardFocus()then return end
  if key=="ESCAPE"then frame:SetPropagateKeyboardInput(false);frame:Hide()
  elseif key=="TAB"then
   local direction=IsShiftKeyDown and IsShiftKeyDown()and -1 or 1
   local index=self.keyboardIndex and (self.keyboardIndex-1+direction)%#self.keyboardControls+1 or direction>0 and 1 or #self.keyboardControls
   self:SetFocus(index);frame:SetPropagateKeyboardInput(false)
  elseif key=="ENTER"or key=="SPACE"then
   local control=self.keyboardIndex and self.keyboardControls[self.keyboardIndex]or self.next
   if control:IsEnabled()then control:GetScript("OnClick")(control)end;frame:SetPropagateKeyboardInput(false)
  elseif key=="LEFT"or key=="RIGHT"then
   local control=key=="LEFT"and self.back or self.next
   if control:IsEnabled()then control:GetScript("OnClick")(control)end;frame:SetPropagateKeyboardInput(false)
  end
 end)
 frame:SetScript("OnShow",function()self:SetFocus(nil);if self.events then self.events:RegisterEvent("PLAYER_REGEN_DISABLED")end end)
 frame:SetScript("OnHide",function()self.keyboardIndex=nil;if self.events then self.events:UnregisterEvent("PLAYER_REGEN_DISABLED")end end)
 UISpecialFrames=UISpecialFrames or {};local found=false
 for _,name in ipairs(UISpecialFrames)do if name=="RUIIntroductionPopup"then found=true end end
 if not found then UISpecialFrames[#UISpecialFrames+1]="RUIIntroductionPopup"end
 frame:Hide()
end
function G:Show(manual)
 if not manual and self:Store().dontShowAgain then return false end
 if InCombatLockdown()then
  self.pending=manual and "manual"or "automatic"
  self.pendingPage=nil
  if self.events then self.events:RegisterEvent("PLAYER_REGEN_ENABLED")end
  return false
 end
 self.pending=nil;self.manual=manual==true;self:Create();self.page=1;self:Render();self.frame:Show();return true
end
function G:OnPlayerLogin()
 if not AUI.isForever then return end
 self.events=CreateFrame("Frame")
 self.events:RegisterEvent("DISPLAY_SIZE_CHANGED");self.events:RegisterEvent("UI_SCALE_CHANGED")
 self.events:SetScript("OnEvent",function(_,event)
  if event=="PLAYER_REGEN_ENABLED"then
   self.events:UnregisterEvent(event);local pending,page=self.pending,self.pendingPage;self.pending=nil;self.pendingPage=nil
   if pending and self:Show(pending=="manual")and page then self.page=page;self:Render()end
  elseif event=="PLAYER_REGEN_DISABLED"then
   if self.frame and self.frame:IsShown()then
    self.pending=self.manual and "manual"or "automatic";self.pendingPage=self.page;self.frame:Hide();self.events:RegisterEvent("PLAYER_REGEN_ENABLED")
   end
  elseif self.frame and self.frame:IsShown()then self:Layout()
  end
 end)
 C_Timer.After(1.25,function()self:Show(false)end)
end
