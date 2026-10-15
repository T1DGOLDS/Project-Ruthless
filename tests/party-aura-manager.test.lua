do
 local h=AUI.modules.ForeverHUD;local row=h.registered.party0
 local applied=0;AUI.modules.AuraManager={ApplyParty=function()applied=applied+1 end}
 CustomAuraContainerAuraProcessingPolicy={ProcessAura=1};AuraUtil={AuraUpdateChangedType={Debuff=2,Dispel=3}}
 h:CreatePartyAuras(row,'player')
 assert(row.ruiAuras[2].groups.party.options.candidateFilters.processedAuraType==2)
 assert(row.ruiAuras[3].groups.party.options.candidateFilters.processedAuraType==3 and applied==1)
 AUI.modules.AuraManager=nil
 print('PASS: managed party aura groups use native debuff/dispel classification rather than a static list of every dispel type')
end
