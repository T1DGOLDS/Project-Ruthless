local AUI={isForever=true,modules={}}
function AUI:RegisterModule(k,v)self.modules[k]=v end
local race,faction='Human','Alliance'
function UnitRace()return race,race end
function UnitFactionGroup()return faction end
function CreateFromMixins(...)local r={};for i=1,select('#',...)do for k,v in pairs(select(i,...))do r[k]=v end end;return r end
assert(load(DATA))('RUI',AUI);assert(load(SOURCE))('RUI',AUI)
local module=AUI.modules.SkyborneMap
module:OnPlayerLogin();assert(module.provider==nil)
race='Skyborne';assert(#module:Locations(1433)==5)
faction='Horde';assert(#module:Locations(1433)==0 and #module:Locations(1413)==14)
local count=0;for _,zones in pairs(AUI.SkyborneMapNodes)do for map,points in pairs(zones)do assert(type(map)=='number');for _,p in ipairs(points)do assert(p[1]>=0 and p[1]<=1 and p[2]>=0 and p[2]<=1);count=count+1 end end end
local pins,removed,adds={},0,0
WorldMapFrame={GetMapID=function()return 1413 end,RemoveAllPinsByTemplate=function(_,template)assert(template=='RUILeylinePinTemplate');pins={};removed=removed+1 end,AcquirePin=function(_,template,x,y,label)assert(template=='RUILeylinePinTemplate');pins[#pins+1]={x=x,y=y,label=label}end,AddDataProvider=function(self,p)p.owningMap=self;adds=adds+1 end}
MapCanvasDataProviderMixin={GetMap=function(self)return self.owningMap end};MapCanvasPinMixin={SetPosition=function(self,x,y)self.position={x,y}end}
module:Install();module:Install();assert(adds==1)
module.provider:RefreshAllData();assert(#pins==14 and pins[1].label=='Elemental Convergence')
faction='Alliance';module.provider:RefreshAllData();assert(#pins==2 and pins[1].label=='Ley Line')
race='Human';module.provider:RefreshAllData();assert(#pins==0)
race='Skyborne';WorldMapFrame.GetMapID=function()return 999999 end;module.provider:RefreshAllData();assert(#pins==0)
assert(RUILeylinePinMixin.SetPosition and RUILeylinePinMixin.OnClick==nil)
print('PASS: '..count..' validated Skyborne location facts, faction/race/zone isolation, idempotent native provider, native pin cleanup isolation and passive pins')
