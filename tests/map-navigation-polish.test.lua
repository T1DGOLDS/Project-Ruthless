;(function()
 local oldForever=AUI.isForever;AUI.isForever=true
 local saved={}
 for _,key in ipairs({"mapPanel","mapTabBar","mapTabs","mapUtilities","mapResize","mapHeading","mapScroll","mapContent","mapCopy","mapControls","mapPage","mapBack","mapHistory"})do saved[key]=q[key];q[key]=nil end
 local oldHook=hooksecurefunc;hooksecurefunc=nil;q:InstallMap();hooksecurefunc=oldHook
 assert(#q.mapTabs==6 and #q.mapUtilities==2)
 local names={};for _,tab in ipairs(q.mapTabs)do names[tab.page]=true end
 assert(names.Quests and names.Available and names.Library and names.Dungeons and names.Supplies and names["Dungeon atlas"])
 assert(not names.Settings and not names.Tools and not names.Professions and not names.Chapters)
 q.mapPage="Quests";q:SelectMapPage("Settings")
 assert(AUI.modules.Menu.page=="mapquests"and q.mapPage=="Quests","Old settings shortcuts must reach the one canonical settings page")
 q:SelectMapPage("Tools");assert(q.mapHeading:GetText()=="Quest actions")
 assert(q.mapBack:IsShown()and q.mapBack.destination=='‹ Quest log')
 assert(q:MapNavigationPage("Chapters")=="Library")
 local oldVertical=q.mapScroll.SetVerticalScroll;local offset
 q.mapScroll.ScrollTo=function(self,value)self:SetVerticalScroll(value)end
 q.mapScroll.SetVerticalScroll=function(_,value)offset=value end
 q:SelectMapPage("Quests");assert(offset==0,"Changing pages must reset the old scroll offset")
 assert(not q.mapBack:IsShown())
 q.mapHistory={};q:SelectMapPage("Available");q:SelectMapPage("Library");q:SelectMapPage("Supplies")
 q:BackMapPage();assert(q.mapPage=="Library");q:BackMapPage();assert(q.mapPage=="Available")
 q.mapHistory={};q:SelectMapPage("Library");q:SelectMapPage("Chapters");q:ReturnMapPage("Library")
 q:BackMapPage();assert(q.mapPage=="Available","Parent Back must not bounce back into its child")
 q.mapScroll.SetVerticalScroll=oldVertical
 for _,key in ipairs({"mapPanel","mapTabBar","mapTabs","mapUtilities","mapResize","mapHeading","mapScroll","mapContent","mapCopy","mapControls","mapPage","mapBack","mapHistory"})do q[key]=saved[key]end
 AUI.isForever=oldForever
 print("PASS: six map content tabs, separate actions/settings, canonical legacy links, guide grouping and page-scroll reset")
end)()
