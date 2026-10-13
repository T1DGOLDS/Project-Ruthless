do (function()
if NATIVE_MAP_OWNER_SOURCE then
 assert(load(NATIVE_MAP_OWNER_SOURCE))()
 local nativeMap={shown=false};local log={shown=false}
 function log:IsShown()return self.shown end;function log:Show()self.shown=true end
 function log:SetAlpha(a)self.alpha=a end;function log:EnableMouse()end;function log:ClearAllPoints()end;function log:SetPoint()end
 function nativeMap:IsShown()return self.shown end;function nativeMap:IsMaximized()return false end
 function nativeMap:ShouldBeMaximized()return false end;function nativeMap:ShouldBeMinimized()return true end
 local flag=false;function nativeMap:ShouldShowQuestLogPanel()return flag end
 nativeMap.QuestLog=log
 nativeMap.GetOpenDisplayState=QuestLogOwnerMixin.GetOpenDisplayState
 nativeMap.HandleUserActionToggleSelf=QuestLogOwnerMixin.HandleUserActionToggleSelf
 function nativeMap:SetDisplayState(state)
  if state==1 then self.shown=false
  else self.shown=true;log.shown=state==3 end
 end
 local originalMap=WorldMapFrame;WorldMapFrame=nativeMap
 q.nativeMapLog=log;q.mapPanel=node();q.mapTabBar=node();q.mapResize=nil;q.mapTabs={}
 q.LayoutMap=function()end
 ProjectRuthlessDB.questWorkspace.enabled=true
 for _,busy in ipairs({false,true})do
  combat=busy
  for _,openLog in ipairs({false,true})do
   flag=openLog
   for _,page in ipairs({'Quests','Settings'})do
    q.mapPage=page;nativeMap.shown=false
    nativeMap:HandleUserActionToggleSelf();q:SyncMapPage()
    assert(nativeMap.shown and log.shown==flag)
    nativeMap:HandleUserActionToggleSelf();assert(not nativeMap.shown)
   end
  end
 end
 combat=false;WorldMapFrame=originalMap
 print('PASS: exact native M-toggle logic opens/closes across native log preferences, custom pages and combat; RUI does not replace the toggle')
end
end)()end
