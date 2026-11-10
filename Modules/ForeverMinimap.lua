local _,AUI=...
local M={};AUI:RegisterModule("ForeverMinimap",M)
local WHITE="Interface\\Buttons\\WHITE8X8"
function M:IsSquare()return not(ProjectRuthlessDB and ProjectRuthlessDB.mapQuests and ProjectRuthlessDB.mapQuests.squareMinimap==false)end
function M:ApplySettings()
 if not AUI.isForever or not Minimap or not MinimapCluster then return end
 if InCombatLockdown()then self.pending=true;return end
 self.pending=nil
 -- Forever documents SetMaskTexture, but no getter. Its current native
 -- fixed/rotated modes both use this mask; do not require an absent getter.
 if not self.originalMask then self.originalMask=Minimap.GetMaskTexture and Minimap:GetMaskTexture()or "ui-hud-minimap-frame-generic-mask"end
 if self:IsSquare()then Minimap:SetMaskTexture(WHITE)
 elseif self.originalMask then Minimap:SetMaskTexture(self.originalMask)end
 local style=AUI.modules.ForeverStyle
 local art=style and style:BlizzardArtEnabled()==true
 -- These rings are rendered by the minimap engine, not the compass texture.
 -- Their circular fringe remains visible through a square terrain mask.
 -- Preserve the useful filled quest areas; suppress only decorative rims.
 if self:IsSquare()or not art then
  for _,name in ipairs({"SetArchBlobRingScalar","SetArchBlobRingAlpha","SetQuestBlobRingScalar","SetQuestBlobRingAlpha","SetTaskBlobRingScalar","SetTaskBlobRingAlpha"})do
   if type(Minimap[name])=="function"then Minimap[name](Minimap,0)end
  end
 end
 -- Only decoration is removed. The map, tracking blips, quest blobs,
 -- mail/queue alerts, zone text and native button handlers stay intact.
 for _,region in ipairs({MinimapCompassTexture,MinimapCompassTextureUnderlay})do
  region:SetAlpha(not self:IsSquare()and art and 1 or 0)
 end
 if not art and style then
  local header=MinimapCluster.ZoneTextButton
  if header then style:ArtTree(header.StateTexture);style:ArtTree(header.AddTexture);style:Surface(header,false,nil,"Map")end
  local diel=MinimapCluster.DielFrame
  if diel and diel.GetRegions then for _,region in ipairs({diel:GetRegions()})do
   if region.GetAtlas and region:GetAtlas()=="UI-HUD-Minimap-Frame-Cycle"then style:ArtTree(region)end
  end end
 end
 if not self.border then
  local frame=CreateFrame("Frame",nil,Minimap,"BackdropTemplate");self.border=frame
  frame.ignoreInLayout=true;frame:SetPoint("TOPLEFT",Minimap,"TOPLEFT",-1,1);frame:SetPoint("BOTTOMRIGHT",Minimap,"BOTTOMRIGHT",1,-1)
  frame:SetFrameLevel(Minimap:GetFrameLevel()+1);frame:EnableMouse(false)
  frame:SetBackdrop({edgeFile=WHITE,edgeSize=1});frame:SetBackdropBorderColor(.16,.17,.21,1)
 end
 self.border:SetShown(self:IsSquare())
end
function M:Install()
 if self.hooked or not MinimapCluster or type(MinimapCluster.UpdateMinimapConfig)~="function"then return end
 self.hooked=true
 hooksecurefunc(MinimapCluster,"UpdateMinimapConfig",function()
  if not M.queued then M.queued=true;C_Timer.After(0,function()M.queued=nil;M:ApplySettings()end)end
 end)
end
function M:OnPlayerLogin()
 if not AUI.isForever then return end
 self:Install();self:ApplySettings();self.events=CreateFrame("Frame")
 for _,event in ipairs({"ADDON_LOADED","PLAYER_ENTERING_WORLD","PLAYER_REGEN_ENABLED"})do self.events:RegisterEvent(event)end
 self.events:SetScript("OnEvent",function(_,event,name)
  if event=="ADDON_LOADED"and name~="Blizzard_Minimap"then return end
  self:Install();self:ApplySettings()
 end)
end
