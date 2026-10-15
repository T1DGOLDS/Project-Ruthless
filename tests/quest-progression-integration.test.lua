do (function()
 local selected={source='RUI progression',id=10,level=20,phase='IN PROGRESS',count='',quest='Focused quest',target='Giver',instruction='Do the current task',next={},objectives={}}
 AUI.modules.QuestProgression={Guide=function()return selected end,Store=function()return {active='chain'}end}
 local oldLocations=AUI.modules.QuestLocations
 AUI.modules.QuestLocations={ContextRows=function()error('Active tracker must not scan nearby database quests')end}
 C_QuestLog.GetQuestObjectives=function()return {{text='2/7 current task'}}end
 q.entries={};q:RenderGuide(selected);q:RenderContext()
 assert(q.objectiveCopy.text=='2/7 current task'and not q.nearbyHeading.shown and not q.contextHeading.shown and not q.dungeonHeading.shown)
 for _,row in ipairs(q.rows)do assert(not row.shown)end
 assert(q.returnGuide.shown and q.frame.height<350)
 assert(q:ReadGuide()==selected)
 local oldCollect,oldPins,oldNavigate,oldVisibility=q.Collect,q.RefreshPins,q.Navigate,q.mapPanel.IsVisible
 q.Collect=function()return {{id=99,title='Held quest',level=20,distance=1,complete=false,detail='Current'}}end
 q.RefreshPins=function()end;q.Navigate=function()end;q.mapPanel.IsVisible=function()return false end;q.frame.shown=true
 q.entriesSignature=nil;q.manualPickup={id=10,title='Pickup',level=20,detail='Check giver'}
 originalRefresh(q);originalRefresh(q);assert(#q.entries==2)
 q.manualPickup={id=11,title='Next pickup',level=20,detail='Check giver'};originalRefresh(q)
 assert(#q.entries==2);for _,entry in ipairs(q.entries)do assert(entry.id~=10)end
 q.manualPickup=nil;originalRefresh(q);assert(#q.entries==1 and q.entries[1].id==99)
 q.Collect,q.RefreshPins,q.Navigate,q.mapPanel.IsVisible=oldCollect,oldPins,oldNavigate,oldVisibility
 local p=AUI.modules.QuestProgression;p.revision=0
 function p:Invalidate()self.revision=self.revision+1 end
 local oldAfter,oldRefresh,oldRender,oldAnnounce=C_Timer.After,q.Refresh,q.RenderMapPage,q.AnnounceQuestProgress
 local oldVisible=q.mapPanel.IsVisible;local pending,refreshes,renders={},0,0
 C_Timer.After=function(_,fn)pending[#pending+1]=fn end
 q.Refresh=function()refreshes=refreshes+1 end
 q.RenderMapPage=function()renders=renders+1;p.renderedRevision=p.revision end
 q.AnnounceQuestProgress=function()end;q.mapPanel.IsVisible=function()return true end
 q.eventRefreshQueued=nil;q.eventRefreshForced=nil;q.mapPage='Dungeons'
 for i=1,100 do q.events.scripts.OnEvent(q.events,'QUEST_LOG_UPDATE')end
 assert(#pending==1);pending[1]();assert(p.revision==1 and refreshes==1 and renders==1)
 C_Timer.After,q.Refresh,q.RenderMapPage,q.AnnounceQuestProgress=oldAfter,oldRefresh,oldRender,oldAnnounce;q.mapPanel.IsVisible=oldVisible
 AUI.modules.QuestLocations=oldLocations;AUI.modules.QuestProgression=nil
 print('PASS: actual workspace prioritizes owned progression, limits tracker to current objectives/items without nearby database scans, and batches 100 events into one shared refresh')
end)()end
