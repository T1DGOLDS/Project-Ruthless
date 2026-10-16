unpack=table.unpack
local AUI={modules={},version='test.1',interfaceVersion=16001,isForever=true,name='ProjectRuthless'}
function AUI:RegisterModule(name,module)self.modules[name]=module end
function AUI:Print(message)self.lastMessage=message end
function AUI:StyleSurface()end;function AUI:AccentColor()return .4,.6,.8 end
local busy,build,created=false,'70235',0
function InCombatLockdown()return busy end
function GetBuildInfo()return '1.60.1',build,'',16001 end
function GetTime()return 100 end;function date()return '2026-10-16 12:00:00'end
function debugstack()return 'example stack'end
function wipe(t)for k in pairs(t)do t[k]=nil end end
function strtrim(s)return s:match('^%s*(.-)%s*$')end
local secret={};function issecretvalue(v)return v==secret end
local timers={};C_Timer={After=function(_,fn)timers[#timers+1]=fn end}
local proto={};proto.__index=proto
local function frame()return setmetatable({scripts={},shown=true,text='',w=800,h=600},proto)end
function proto:SetScript(key,fn)self.scripts[key]=fn end
function proto:SetPoint()end;function proto:SetAllPoints()end
function proto:ClearAllPoints()end
function proto:SetSize(w,h)self.w=w;self.h=h end;function proto:SetWidth(w)self.w=w end
function proto:SetHeight(h)self.h=h end
function proto:SetText(text)self.text=text end;function proto:GetText()return self.text end
function proto:GetStringHeight()return #self.text/3 end
function proto:SetJustifyH()end;function proto:SetFrameStrata()end;function proto:SetClampedToScreen()end
function proto:SetBackdrop()end;function proto:SetBackdropBorderColor()end
function proto:SetMovable()end;function proto:EnableMouse()end;function proto:RegisterForDrag()end
function proto:StartMoving()self.moving=true end;function proto:StopMovingOrSizing()self.moving=false end
function proto:SetScale(s)self.scale=s end
function proto:SetMultiLine()end;function proto:SetAutoFocus()end;function proto:SetFontObject()end
function proto:SetMaxLetters(n)self.limit=n end;function proto:ClearFocus()self.focus=false end
function proto:SetTextInsets()end;function proto:SetCursorPosition()end;function proto:SetFocus()self.focus=true end;function proto:HighlightText()end
function proto:SetScrollChild(child)self.child=child end
function proto:IsShown()return self.shown end
function proto:Hide()self.shown=false;if self.scripts.OnHide then self.scripts.OnHide()end end
function proto:Show()self.shown=true end
function proto:CreateFontString()return frame()end
local allFrames={}
function CreateFrame(kind,name,parent,template)local f=frame();created=created+1;f.kind=kind;f.name=name;f.parent=parent;f.template=template;allFrames[#allFrames+1]=f;return f end
function AUI:CreateButton(parent)return CreateFrame('Button',nil,parent)end
function AUI:CreateSmoothScrollFrame(parent)return CreateFrame('ScrollFrame',nil,parent)end
function AUI:ConfigureScrollingEditBox(edit,scroll)assert(scroll.child==edit)end
UIParent=frame();UISpecialFrames={}
ProjectRuthlessDB={errorLog={enabled=true,maxEntries=2,entries={{count=5,message='legacy'}}},general={},questWorkspace={guideSource='RUI'}}
ProjectRuthlessCharDB={activeProfile='Main',authoredGuide={route='keep'},developerLog={enabled=false,sessions={}}}
assert(load(ERROR_SOURCE))('ProjectRuthless',AUI)
local errors=AUI.modules.ErrorLog
assert(errors:GetCapturedCount()==5)
errors:Record('new');errors:Record('new');assert(errors:GetCapturedCount()==7 and #ProjectRuthlessDB.errorLog.entries==2)
errors:HandleCommand('clear');assert(#ProjectRuthlessDB.errorLog.entries==0 and errors:GetCapturedCount()==7)
errors:Record('after clear');assert(errors:GetCapturedCount()==8)
ProjectRuthlessDB.errorLog.enabled=false;errors:Record('off');assert(errors:GetCapturedCount()==8)
print('PASS: cumulative error observations retain legacy counts, repeats and retention/clear history; disabled capture adds no invented events')
assert(load(LIVE_SOURCE))('ProjectRuthless',AUI)
local checks=AUI.modules.LiveChecks
assert(created==0 and not ProjectRuthlessCharDB.liveChecks)
local ids={};for _,gate in ipairs(checks.gates)do ids[#ids+1]=gate.id end;assert(table.concat(ids,',')==REQUIRED_IDS)
assert(checks:Current(false)==nil and checks:Report():find('all six checks pending',1,true))
assert(not checks:SetResult('combat','pass','tested'))
assert(not checks:SetResult('invalid','pass','tested'))
assert(not checks:SetResult('combat','pass',string.rep('x',1501)))
assert(checks:Begin('combat'));assert(not checks:SetResult('combat','pass','  '))
busy=true;assert(checks:SetResult('combat','fail','Map did not close during combat.'))
local run=checks:Current(false);assert(run.results.combat.status=='fail'and run.results.combat.after.capture==false)
busy=false;ProjectRuthlessDB.errorLog.enabled=true;assert(checks:Begin('combat'))
errors:Record('observed during test');assert(checks:SetResult('combat','pass','All listed actions tested; the captured error is from another addon.'))
assert(checks:Report():find('Observed errors since start: 1',1,true))
assert(checks:Report():find('Manual results do not change the repository release gates',1,true))
assert(run.results.combat.status=='pass')
AUI.version='test.2';assert(checks:Current(false)==nil);assert(checks:Report():find('HISTORICAL RUI test.1',1,true))
assert(checks:Begin('profiles'));assert(checks:Current(false).results.combat==nil)
build='70236';assert(checks:Current(false)==nil);assert(checks:Begin('installation'))
build='70237';assert(checks:Begin('information'));assert(#checks:Store().runs==3)
assert(ProjectRuthlessCharDB.authoredGuide.route=='keep'and ProjectRuthlessCharDB.activeProfile=='Main')
build=secret;assert(checks:Current(false)==nil and not checks:Begin('combat'));build='70237'
print('PASS: six canonical checks require explicit start/evidence, remain manually assessed, isolate versions/client builds, retain bounded history and never alter profiles/progress')
local related,shown=false,false
AUI.modules.Menu={Show=function(_,page)related=page end}
AUI.modules.Diagnostics={Show=function()shown=true end}
AUI.modules.Accessibility={RegisterText=function(_,text)text.accessible=true end,FitWindow=function()return .8 end}
checks:Show();local first=created;assert(checks.frame.shown and checks.frame.scale==.8 and #checks.gateButtons==6 and #UISpecialFrames==1)
assert(checks.instructions.accessible and checks.notes.limit==1500)
checks.notes:SetText('installation draft');checks:Select('profiles');checks.notes:SetText('profile draft');checks:Select('installation');assert(checks.notes:GetText()=='installation draft')
checks.frame:Hide();assert(checks.notes.focus==false and not checks.frame.moving)
checks:Show();assert(created==first and #UISpecialFrames==1)
checks:Select('profiles')
for _,f in ipairs(allFrames)do
 if f.text=='Related settings'then f.scripts.OnClick()end
 if f.text=='Bug report'then f.scripts.OnClick()end
end
assert(related=='profiles'and shown)
busy=true;checks:Select('combat');assert(checks:Begin('combat'));assert(checks:SetResult('combat','fail','Blocked action observed.'));busy=false
checks:Refresh();assert(checks.state.text:find('capture on',1,true))
AUI.version='test.3';checks:Show();assert(checks.notes:GetText()==''and checks.state.text=='Not started · pending')
assert(not checks.frame.scripts.OnUpdate and #timers==1)
print('PASS: actual live-check window builds lazily, reuses controls, preserves drafts, fits/scales text, links settings/report, clears old-build drafts and browses in combat without gameplay calls')
assert(load(DIAGNOSTICS_SOURCE))('ProjectRuthless',AUI)
local report=AUI.modules.Diagnostics:Report('review')
assert(report:find('LIVE CHECKS · SELF-REPORTED',1,true)and report:find('HISTORICAL',1,true))
AUI.Theme={border={.1,.2,.3,1}}
AUI.modules.Diagnostics:Show();assert(AUI.modules.Diagnostics.frame.scale==.8 and AUI.modules.Diagnostics.description.accessible)
print('PASS: actual bug reporter includes versioned manual test evidence and keeps historical results labelled')
