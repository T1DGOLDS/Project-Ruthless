assert(load(ACCESSIBILITY_SOURCE))('ProjectRuthless',AUI)
local access=AUI.modules.Accessibility
ProjectRuthlessDB.accessibility={animatedPortraits=false}
local portraitUpdates=0;SetPortraitTexture=function(texture,unit)texture.unit=unit;portraitUpdates=portraitUpdates+1 end
local hud=AUI.modules.ForeverHUD;hud:RefreshPortraits('player')
local player=hud.registered.player;assert(player.ruiStaticPortrait.shown and not player.ruiPortrait.shown and portraitUpdates>0)
ProjectRuthlessDB.accessibility.animatedPortraits=true;hud:RefreshPortraits('player');assert(player.ruiPortrait.shown and not player.ruiStaticPortrait.shown)
ProjectRuthlessDB.accessibility.reducedMotion=true;hud:RefreshPortraits('player');assert(not player.ruiPortrait.shown and player.ruiStaticPortrait.shown)
assert(load(FIRSTRUN_SOURCE))('ProjectRuthless',AUI)
local setup=AUI.modules.FirstRun;setup.useNativePlacement=true
setup.nativePlacement.castplayer={x=-25,y=-200,scale=1,width=250,height=24}
ProjectRuthlessCharDB.activeProfile=nil;ProjectRuthlessCharDB.layoutEditor.elements.castplayer=nil
setup:PlaceReplacement('castplayer',hud.castFrames.castplayer)
assert(math.abs(ProjectRuthlessCharDB.layoutEditor.elements.castplayer.x+25)<.001)
setup.nativePlacement.castplayer.x=50;setup:PlaceReplacement('castplayer',hud.castFrames.castplayer)
assert(math.abs(ProjectRuthlessCharDB.layoutEditor.elements.castplayer.x+25)<.001)
print('PASS: static/live/ reduced-motion portraits use native texture rendering; native starter placement persists and never replaces an explicit saved element')
