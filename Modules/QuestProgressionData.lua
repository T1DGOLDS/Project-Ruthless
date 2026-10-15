local _,AUI=...
-- Original RUI presentation. Quest IDs, giver identities, levels and prerequisite
-- facts checked against installed Forever metadata 2026-10-16; live review pending.
-- No Attune code, layout, prose or database is used.
AUI.CreateQuestProgression=function()
 local nodes={}
 local function quest(id,title,level,giver,area,requires,dungeon)
  nodes[#nodes+1]={id=id,title=title,minLevel=level,giver=giver,area=area,requires=requires or {},dungeon=dungeon}
 end
 quest(65,"The Defias Brotherhood",14,"Gryan Stoutmantle","Sentinel Hill, Westfall")
 quest(132,"The Defias Brotherhood",14,"Wiley the Black","Lakeshire, Redridge Mountains",{65})
 quest(135,"The Defias Brotherhood",14,"Gryan Stoutmantle","Sentinel Hill, Westfall",{132})
 quest(141,"The Defias Brotherhood",14,"Master Mathias Shaw","Old Town, Stormwind",{135})
 quest(142,"The Defias Brotherhood",14,"Gryan Stoutmantle","Sentinel Hill, Westfall",{141})
 quest(155,"The Defias Brotherhood",14,"The Defias Traitor","Sentinel Hill, Westfall",{142})
 quest(166,"The Defias Brotherhood",14,"Gryan Stoutmantle","Sentinel Hill, Westfall",{155},true)
 quest(214,"Red Silk Bandanas",14,"Scout Riell","Sentinel Hill, Westfall",{155},true)
 quest(167,"Oh Brother. . .",15,"Wilder Thistlenettle","Dwarven District, Stormwind",nil,true)
 quest(168,"Collecting Memories",14,"Wilder Thistlenettle","Dwarven District, Stormwind",nil,true)
 quest(2040,"Underground Assault",15,"Shoni the Shilent","Dwarven District, Stormwind",nil,true)
 return {{key="rui:deadmines",name="The Deadmines",faction="Alliance",areaID=1581,kind="dungeon",source="RUI requirements · live review pending",nodes=nodes}}
end
