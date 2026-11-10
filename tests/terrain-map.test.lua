local AUI={modules={}}
function AUI:RegisterModule(name,m)self.modules[name]=m end
assert(load(DATA))('ProjectRuthless',AUI)
assert(load(TERRAIN))('ProjectRuthless',AUI)
local t=AUI.modules.TerrainMap
assert(AUI.ForeverTerrainTiles[0][1590]==204208)
assert(AUI.ForeverTerrainTiles[2991][1622]==7198902)
local unit=1600/3
local mapID,kind,world=2521,3,2991
local left,top,w,h=25.5,22.5,2,2
local view={left=0,right=1,top=0,bottom=1}
CreateVector2D=function(x,y)return {x=x,y=y}end
C_Map={
 GetMapInfo=function()return {mapType=kind}end,
 GetWorldPosFromMapPos=function(_,p)
  local x,y=(32-top-p.y*h)*unit,(32-left-p.x*w)*unit
  return world,{GetXY=function()return x,y end}
 end,
}
local created=0
local function texture()
 created=created+1
 return {SetTexture=function(self,id)self.id=id end,GetTexture=function(self)return self.id end,
 Hide=function(self)self.shown=false end,Show=function(self)self.shown=true end,ClearAllPoints=function()end,
 SetPoint=function()end,SetSize=function(self,x,y)self.w=x;self.h=y end,
 SetTexCoord=function(self,...)self.uv={...}end}
end
local canvas={GetSize=function()return 1000,800 end,GetFrameLevel=function()return 10 end}
CreateFrame=function()return {CreateTexture=texture,EnableMouse=function()end,SetAllPoints=function()end,
 SetFrameLevel=function(self,l)self.level=l end,Hide=function()end,Show=function()end}end
t.map={IsShown=function()return true end,GetMapID=function()return mapID end,GetCanvas=function()return canvas end,
 GetViewRect=function()return view end,pinFrameLevelsManager={GetFrameLevelStart=function()return 1900 end}}
t.button={SetText=function(self,v)self.text=v end}
ProjectRuthlessCharDB={terrainMap=true}
t:Render()
local clipped=t.tiles[25*64+22]
assert(clipped.id==7198902 and math.abs(clipped.uv[1]-.5)<.0001 and math.abs(clipped.uv[3]-.5)<.0001)
assert(t.layer.level==1901 and created==9)
view={left=.7,right=1,top=.7,bottom=1}
t:Render()
assert(t.tiles[25*64+22]==nil and clipped.id==nil)
kind=4;t:Render();assert(next(t.tiles)==nil and t.button.text=='Terrain unavailable')
kind=3;view={left=0,right=1,top=0,bottom=1};t:Render();assert(created==9)
ProjectRuthlessCharDB.terrainMap=false;t:Render();assert(next(t.tiles)==nil and t.button.text=='Terrain: Off')
print('PASS: Forever tile IDs, world projection, edge clipping, viewport culling, texture reuse and parchment fallback')

