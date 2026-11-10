local _,AUI=...
AUI=ProjectRuthless or AUI
local Menu=AUI.modules.Menu
function Menu:CreateAuraOptions(parent)
 local f=self:CreateFlowPage(parent,"auras","Auras & cooldowns","Choose what to track, then adjust its presentation. Configuration checks explain why a group may be hidden.")
 local manager=AUI.modules.AuraManager;manager:Settings()
 local settings=self:LiveSettings("auraManager")
 local function check(key,label,description)
  return f:Check(label,description,function()return settings[key]end,function(v)settings[key]=v end,"AuraManager",key)
 end
 local function slider(key,label,description,min,max,step)
  return f:Slider(label,description,min,max,step,tostring,function()return settings[key]end,function(v)settings[key]=v end,"AuraManager",key)
 end
 f:Section("Cooldown manager")
 f:Check("Enable native cooldowns","Show the game's tracked spell cooldowns, buffs, charges and alerts.",function()return manager:CooldownEnabled()end,function(v)local _,message=manager:SetCooldownEnabled(v);if message then AUI:Print(message)end end)
 f:Action("Choose tracked spells & alerts",function()manager:OpenNative()end)
 f:Action("Preview samples",function()manager:Preview()end)
 check("styleCooldowns","RUI cooldown borders","Use thin borders and reduced decorative trim.")
 f:Section("Player & target groups")
 check("playerBuffs","Player buff group","Show an extra movable group of your helpful effects.")
 check("playerDebuffs","Player debuff group","Show your harmful effects in a movable group.")
 check("targetDebuffs","Your target debuffs","Show harmful effects you applied to your current target.")
 check("focus","Focus buff","Track one exact helpful spell ID and rank on yourself.")
 f:Note("Focus spell ID · 0 clears the selection")
 local holder=CreateFrame("Frame",nil,f.content);holder:SetSize(610,40)
 local edit=CreateFrame("EditBox",nil,holder,"InputBoxTemplate");edit:SetPoint("TOPLEFT",6,-4);edit:SetSize(390,28);edit:SetAutoFocus(false)
 if AUI.modules.Accessibility then AUI.modules.Accessibility:RegisterText(edit)end
 local function apply()
  local id=tonumber(edit:GetText())
  if not id or id%1~=0 or id<0 or id>10000000 then AUI:Print("Enter a whole spell ID from 0 to 10000000.");return end
  settings.focusSpell=id;edit:ClearFocus();manager:ApplySettings("focusSpell")
 end
 edit:SetScript("OnEscapePressed",function(box)box:ClearFocus()end);edit:SetScript("OnEnterPressed",apply)
 edit.RefreshValue=function(box)if not box.HasFocus or not box:HasFocus()then box:SetText(tostring(settings.focusSpell or 0))end end
 edit:RefreshValue();self.optionControls[#self.optionControls+1]=edit
 local applyButton=self:CreateAction(holder,"Set focus spell",418,-4,192,apply)
 AUI.modules.SettingsRegistry:Register("auras",edit,"Focus spell ID","Exact helpful spell ID and rank; zero clears the selection",f.y,"text","AuraManager","focusSpell")
 f:Add(holder,40)
 f:Children(holder,{{edit,-4},{applyButton,-4}})
 f:Section("Custom group layout")
 slider("iconSize","Aura icon size","Size of icons in RUI aura groups. Native cooldown viewers use Edit Mode.",16,48,1)
 slider("spacing","Aura icon spacing","Gap between icons in RUI aura groups.",0,12,1)
 slider("limit","Maximum group icons","Additional auras remain available in the normal game interface.",1,24,1)
 check("expirationFirst","Expiring auras first","Order group icons by time remaining when supported by the game.")
 f:Section("Party auras")
 check("partyBuffs","Party buffs","Show helpful effects beside each party member.")
 check("partyDebuffs","Party debuffs","Show harmful effects beside each party member.")
 check("partyDispels","Party dispel emphasis","Enlarge debuffs the game classifies as relevant for dispelling.")
 f:Section("Expiring self buffs")
 check("expiring","Expiring self buffs","Show short remaining buff countdowns when the game exposes their timing.")
 slider("expirationThreshold","Expiring-buff threshold","Show buffs with this many seconds remaining or less.",5,60,1)
 if C_CVar and C_CVar.GetCVar and C_CVar.SetCVar and C_CVar.GetCVar("nameplateAuraScale")then
  f:Section("Nameplate auras")
  f:Slider("Nameplate aura size","Scale buffs and debuffs on enemy nameplates. Saved by the game.",.7,1.4,.1,function(v)return ("%d%%"):format(math.floor(v*100+.5))end,
   function()return tonumber(C_CVar.GetCVar("nameplateAuraScale"))or 1 end,
   function(v)local value=("%.1f"):format(v);AUI:AfterCombat("nameplateAuraScale",function()if tonumber(C_CVar.GetCVar("nameplateAuraScale"))~=tonumber(value)then C_CVar.SetCVar("nameplateAuraScale",value)end end)end)
 end
 f:Section("Presets & placement","Presets change the options above. They do not replace your saved frame positions.")
 for _,row in ipairs({{"combat","Combat auras"},{"buffs","Buff focus"},{"minimal","Minimal"}})do local preset=row[1];f:Action(row[2],function()manager:Preset(preset);self:Refresh()end)end
 f:Action("Move aura / cooldown groups",function()self.frame:Hide();AUI.modules.LayoutEditor:Show()end)
 f:Action("Aura backgrounds",function()self:SelectTab("backgrounds")end)
 f:Section("Configuration checks")
 local status=f:Note("")
 status.RefreshValue=function(label)
  local lines={};for _,row in ipairs(manager:Checks())do lines[#lines+1]=row.status.." · "..row.message.."\n"..row.setting end
  label:SetText(table.concat(lines,"\n\n"))
 end
 self.optionControls[#self.optionControls+1]=status;status:RefreshValue()
 f:Action("Check configuration",function()status:RefreshValue();f:Reflow()end)
 f:Reflow()
end
