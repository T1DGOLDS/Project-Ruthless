local AUI={modules={},isForever=true};function AUI:RegisterModule(n,m)self.modules[n]=m end
local now,stamp,guid,level,class=100,1800000000,'Player-A',1,'Warrior'
GetTime=function()return now end;GetServerTime=function()return stamp end
UnitGUID=function()return guid end;UnitFullName=function()return 'Name-'..guid,'Realm'end
GetRealmName=function()return 'Realm'end;UnitClass=function()return class,class end
UnitLevel=function()return level end;GetMaxPlayerLevel=function()return 60 end
local requests=0;RequestTimePlayed=function()requests=requests+1 end
date=function(_,t)return tostring(t)end
local frame={};function frame:RegisterEvent()end;function frame:SetScript(_,fn)self.event=fn end
CreateFrame=function()return setmetatable({},{__index=frame})end
ProjectRuthlessDB={}
assert(load(SOURCE))('RUI',AUI);local l=AUI.modules.LevelHistory
l:OnPlayerLogin();assert(requests==1 and l.record.cap==60)
l:ReceivePlayed(50,50);assert(l.record.levels[1].played==0)
now=150;stamp=stamp+50;l:LevelUp(2);assert(l.record.levels[2].played==100 and l.record.levels[2].at==stamp)
l:LevelUp(2);assert(l.record.levels[2].played==100)
now=160;l.events.event(nil,'PLAYER_LOGOUT');assert(l.record.totalPlayed==110)
-- Reconnect after days offline: only the new server baseline is used.
now=5000;stamp=stamp+100000;level=3;l.anchor=nil;l:OnPlayerLogin();l:ReceivePlayed(500,20)
assert(l.record.levels[3].played==480 and not l.record.levels[3].at)
assert(l:Range(l.record,2,3)==380 and l:Range(l.record,3,4)==nil)
now=5010;l:LevelUp(5);assert(not l.record.levels[4]and l:Range(l.record,4,5)==nil)
-- Dings before the login reply are resolved against the same session clock.
guid='Player-B';class='Mage';level=1;now=100;l.anchor=nil;l:OnPlayerLogin()
now=120;l:LevelUp(2);now=125;l:ReceivePlayed(105,5)
assert(l.record.levels[2].played==100)
local fastest,classes=l:Compare(1,2);assert(fastest.seconds==100 and #classes==2)
l.record.levels[10]={played=900,source='observed'};l.record.level=10
ProjectRuthlessDB.levelHistory.characters['Player-A'].levels[10]={played=1800,source='observed'}
fastest,classes=l:Compare(1,10);assert(fastest.guid=='Player-B'and classes[1].name=='Warrior'and classes[1].count==1)
assert(l:Report(1,10):find('Fastest:',1,true)and l:Report(1,10):find('Unknown',1,true))
local restricted={};issecretvalue=function(v)return v==restricted end
l:ReceivePlayed(restricted,0);l:LevelUp(restricted);assert(l.level==2)
print('PASS: server played baseline, recorded level timestamps, duplicate events, logout, offline exclusion, missing levels, delayed reply, account/class range comparisons and secret guards')
-- Reloading must discard the prior session anchor before the response arrives.
now=90000;l:OnPlayerLogin();assert(l:TotalNow()==nil)
