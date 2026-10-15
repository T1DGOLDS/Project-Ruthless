local _,AUI=...
AUI=ProjectRuthless or AUI
local Menu=AUI.modules.Menu
function Menu:CreateAuraOptions(parent)
 local panel=self:CreateOptionsPanel(parent,"COMBAT INFORMATION","Auras & cooldowns","Native secure rendering, simple RUI groups and one profile. Edit presentation after combat; preview any time.")
 local scroll=AUI:CreateSmoothScrollFrame(panel);scroll:SetPoint("TOPLEFT",0,-120);scroll:SetSize(650,380)
 local content=CreateFrame("Frame",nil,scroll);content:SetSize(650,1900);scroll:SetScrollChild(content)
 local manager=AUI.modules.AuraManager;local settings=manager:Settings();local y=-8
 local function check(key,label,description)
  local control=self:CreateCheckbox(content,label,description,y,function()return settings[key]end,function(v)settings[key]=v end,"AuraManager",key)
  if control then control:SetHeight(68)end;y=y-76
 end
 local enable=self:CreateCheckbox(content,"Enable native cooldowns","Blizzard owns cooldowns, tracked buff icons/bars, charges and alerts.",y,function()return manager:CooldownEnabled()end,function(v)local _,message=manager:SetCooldownEnabled(v);AUI:Print(message)end)
 if enable then enable:SetHeight(68)end;y=y-76
 self:CreateAction(content,"Choose tracked spells & alerts",18,y,310,function()manager:OpenNative()end)
 self:CreateAction(content,"Preview samples",338,y,290,function()manager:Preview()end);y=y-42
 for i,row in ipairs({{"combat","Combat auras"},{"buffs","Buff focus"},{"minimal","Minimal"}})do local preset=row[1];self:CreateAction(content,row[2],18+(i-1)*205,y,195,function()manager:Preset(preset);self:Refresh()end)end;y=y-44
 check("styleCooldowns","RUI cooldown borders","Thin borders and reduced decorative icon trim; native live rendering stays in charge.")
 check("playerBuffs","Player buff group","Additional movable helpful-aura icons, rendered by Blizzard's secure container.")
 check("playerDebuffs","Player debuff group","Movable harmful auras. Native filtering handles restricted aura data.")
 check("targetDebuffs","Your target debuffs","Harmful auras applied by you, using the native PLAYER filter.")
 check("focus","Focus buff","Match one exact helpful spell ID/rank on the player. Unknown or restricted matches stay hidden.")
 local label=content:CreateFontString(nil,"OVERLAY","GameFontNormalSmall");label:SetPoint("TOPLEFT",18,y-6);label:SetText("Focus spell ID (0 clears the selection)")
 if AUI.modules.Accessibility then AUI.modules.Accessibility:RegisterText(label)end
 local edit=CreateFrame("EditBox",nil,content,"InputBoxTemplate");edit:SetPoint("TOPLEFT",18,y-25);edit:SetSize(190,28);edit:SetText(tostring(settings.focusSpell));edit:SetAutoFocus(false)
 local function apply()
  local id=tonumber(edit:GetText())
  if not id or id%1~=0 or id<0 or id>10000000 then AUI:Print("Enter a whole spell ID from 0 to 10000000.");return end
  settings.focusSpell=id;edit:ClearFocus();manager:ApplySettings()
 end
 edit:SetScript("OnEnterPressed",apply);self:CreateAction(content,"Set focus spell",220,y-25,200,apply)
 AUI.modules.SettingsRegistry:Register("auras",edit,"Focus spell ID","Exact spell rank for the player helpful focus group",y,"text");y=y-78
 local function slider(key,label,description,min,max,step)
  self:CreateSlider(content,label,description,y,min,max,step,function(v)return tostring(v)end,function()return settings[key]end,function(v)settings[key]=v end,"AuraManager",key);y=y-80
 end
 slider("iconSize","Aura icon size","Custom groups; native viewer scale uses Edit Mode.",16,48,1)
 slider("spacing","Aura icon spacing","Spacing between custom group icons.",0,12,1)
 slider("limit","Maximum group icons","Extra auras remain in the native interface.",1,24,1)
 check("expirationFirst","Expiring auras first","Use Blizzard's secure expiration ordering, without reading timers in RUI.")
 check("partyBuffs","Party buffs","Helpful icons beside each party member.")
 check("partyDebuffs","Party debuffs","Native-classified debuffs beside each member.")
 check("partyDispels","Party dispel emphasis","Larger icons use native dispel classification for the current character.")
 check("expiring","Expiring self buffs","Existing self-buff countdowns; restricted timing is unavailable rather than guessed.")
 slider("expirationThreshold","Expiring-buff threshold","Remaining seconds while aura timing is public.",5,60,1)
 self:CreateAction(content,"Move aura / cooldown groups",18,y,300,function()AUI.modules.LayoutEditor:Show()end)
 self:CreateAction(content,"Background colours & opacity",328,y,300,function()self:SelectTab("backgrounds")end);y=y-44
 local status=content:CreateFontString(nil,"OVERLAY","GameFontNormalSmall");status:SetPoint("TOPLEFT",18,y);status:SetWidth(590);status:SetJustifyH("LEFT")
 if AUI.modules.Accessibility then AUI.modules.Accessibility:RegisterText(status)end
 local recheck
 local function refresh()
  local lines={};for _,row in ipairs(manager:Checks())do lines[#lines+1]=row.status.." · "..row.message.."\n"..row.setting end
  status:SetText(table.concat(lines,"\n\n"))
  if recheck then
   local height=status:GetStringHeight();recheck:ClearAllPoints();recheck:SetPoint("TOPLEFT",18,y-height-16);content:SetHeight(-y+height+64)
  end
 end
 panel:HookScript("OnShow",refresh);recheck=self:CreateAction(content,"Check configuration",18,y-190,220,refresh)
 status.RefreshValue=refresh;self.optionControls[#self.optionControls+1]=status
 content:SetHeight(-y+300);self.panels.auras=panel;refresh()
end
