local AUI = {modules={}}
function AUI:RegisterModule(name, module) self.modules[name]=module end
function AUI:Print(message) self.message=message end
ProjectRuthlessDB={spellbook={autoUpdateRanks=true}}
Constants={MacroConsts={MAX_ACCOUNT_MACROS=120}}
local combat=false
function InCombatLockdown() return combat end
local timers={}
C_Timer={After=function(_,callback) timers[#timers+1]=callback end}
function CreateFrame()
    return {RegisterEvent=function() end,SetScript=function(self,_,callback) self.callback=callback end}
end
local ready=true
C_Spell={GetSpellInfo=function() return {name="Fireball"} end,GetSpellSubtext=function() return ready and "Rank 3" or "" end}
local macros={[1]={"Account",42,"#showtooltip Fireball(Rank 1)\n/cast [@target,harm] !Fireball(Rank 2)"},[121]={"Character",43,"/castsequence reset=target Fireball(Rank 1), Frostbolt(Rank 1)"}}
function GetNumMacros() return 1,1 end
function GetMacroInfo(index) local m=macros[index]; if m then return m[1],m[2],m[3] end end
local writes,backups={},{}
function EditMacro(index,name,icon,body)
    assert(not combat); assert(name==nil and icon==nil)
    assert(backups[#backups].index==index and backups[#backups].body==macros[index][3])
    writes[#writes+1]={index=index,body=body}; macros[index][3]=body
end
AUI.modules.Spellbook={BackupMacro=function(_,index,reason) backups[#backups+1]={index=index,body=macros[index][3],reason=reason} end}
assert(load(MACRO_RANKS_SOURCE))("ProjectRuthless",AUI)
local ranks=AUI.modules.MacroRanks
local function same(body) assert(ranks:UpdateBody(body,"Fireball","Rank 3")==body,body) end
same('/say Fireball(Rank 1)\n/run print("Fireball(Rank 1)")\n/cast Fireball\n/cast Fireball(Rank 4)')
same('/cast Greater Fireball(Rank 1)\n/cast Fireball(Other 1)\n/cast Frostbolt(Rank 1)')
assert(ranks:UpdateBody('/cast [mod:alt]Fireball(Rank 1); [nomod] Fireball(Rank 2)',"Fireball","Rank 3")== '/cast [mod:alt]Fireball(Rank 3); [nomod] Fireball(Rank 3)')
assert(ranks:UpdateBody('/castrandom Fireball(Rank 1),Fireball(Rank 2)\n/use Fireball(Rank 1)',"Fireball","Rank 3")== '/castrandom Fireball(Rank 3),Fireball(Rank 3)\n/use Fireball(Rank 3)')
assert(ranks:UpdateBody('/cast Boule de feu(Rang 1)',"Boule de feu","Rang 2")== '/cast Boule de feu(Rang 2)')
ranks:OnPlayerLogin()
local function flush() local pending=timers; timers={}; for _,callback in ipairs(pending) do callback() end end
ranks.events.callback(nil,"LEARNED_SPELL_IN_SKILL_LINE",133)
combat=true; flush(); assert(#writes==0 and ranks.pending[133])
combat=false; ready=false; ranks.events.callback(nil,"PLAYER_REGEN_ENABLED"); flush(); assert(#writes==0 and ranks.pending[133])
ready=true; ranks.events.callback(nil,"SPELL_TEXT_UPDATE",133); flush()
assert(#writes==2 and #backups==2 and not ranks.pending[133])
assert(macros[1][1]=="Account" and macros[1][2]==42)
assert(macros[121][3]=='/castsequence reset=target Fireball(Rank 3), Frostbolt(Rank 1)')
ranks.events.callback(nil,"LEARNED_SPELL_IN_SKILL_LINE",133); flush(); assert(#writes==2)
macros[1][3]='/cast Fireball(Rank 1)'; AUI.modules.Spellbook.selectedMacro=1; AUI.modules.Spellbook.macroDirty=true
ranks.events.callback(nil,"LEARNED_SPELL_IN_SKILL_LINE",133); flush(); assert(#writes==2 and ranks.pending[133])
AUI.modules.Spellbook.macroDirty=false; ranks.events.callback(nil,"UPDATE_MACROS"); flush(); assert(#writes==3)
ProjectRuthlessDB.spellbook.autoUpdateRanks=false; macros[1][3]='/cast Fireball(Rank 1)'
ranks.events.callback(nil,"LEARNED_SPELL_IN_SKILL_LINE",133); flush(); assert(#writes==3)
print('PASS: event-driven account/character rank writes, exact preserved fields, pre-write history, parsing boundaries, localization, combat/data/draft deferral, duplicate events, and disabled mode')
