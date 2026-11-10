local _,AUI=...
local P=AUI.modules.Professions
local function label(parent,text,size)
 local f=parent:CreateFontString(nil,"OVERLAY",size or "GameFontHighlightSmall");f:SetJustifyH("LEFT");f:SetText(text or "")
 if AUI.modules.Accessibility then AUI.modules.Accessibility:RegisterText(f)end;return f
end
local function button(parent,text,w,h,click)
 local b=AUI:CreateButton(parent);b:SetSize(w,h);b:SetText(text);b:SetScript("OnClick",click);return b
end
local function money(value)
 if value==nil then return "Unknown"end
 local prefix=value<0 and "−"or "";value=math.floor(math.abs(value)+.5)
 return prefix..("%dg %ds %dc"):format(math.floor(value/10000),math.floor(value/100)%100,value%100)
end
local function edit(parent,w,initial)
 local e=CreateFrame("EditBox",nil,parent,"InputBoxTemplate");e:SetSize(w,24);e:SetAutoFocus(false);e:SetText(initial or "");e:SetMaxLetters(100)
 e:SetScript("OnEscapePressed",function(box)box:ClearFocus()end);return e
end
function P:ProfessionList()
 local list={};local skills=self:Skills()
 for _,p in pairs(self:Data().professions)do list[#list+1]=p end
 table.sort(list,function(a,b)if not not skills[a.id]~=not not skills[b.id]then return skills[a.id]~=nil end;return a.name<b.name end);return list
end
function P:SelectProfession(id)
 self.profession=id;self:Store().selected=id;self.selected=nil;self.recipeID=nil;self.detailAction=nil;self.page=1;self.query="";self.search:SetText("");self:RefreshVisible()
end
function P:SelectView(view)
 self.view=view;self.page=1;self.selected=nil;self.detailAction=nil;self.status:SetText("")
 if view=="Sources"and not self:Data().professions[self.profession].gathering then self.filterMode="Vendor";self.filter:SetText("Filter: Vendor")end
 if view=="Leveling"then
  local rank=self:Skill(self.profession)
  for i,s in ipairs(self:Data().professions[self.profession].steps)do if rank>=s.from and rank<s.to then self.page=math.floor((i-1)/(self.rowsPerPage or 5))+1;break end end
 end
 self:RefreshVisible()
end
function P:ToggleProfessions()
 if self.choices:IsShown()then self.choices:Hide();return end
 local list=self:ProfessionList();local skills=self:Skills()
 for i,p in ipairs(list)do
  local b=self.profChoices[i];if not b then b=button(self.choices,"",220,26);self.profChoices[i]=b end
  local id=p.id;b:ClearAllPoints();b:SetPoint("TOPLEFT",6,-6-(i-1)*28);b:SetText(p.name..(skills[id]and " · "..skills[id].rank or ""));b:SetScript("OnClick",function()self.choices:Hide();self:SelectProfession(id)end);b:Show()
 end
 self.choices:SetSize(232,12+#list*28);self.choices:Show()
end
function P:OpenNative()
 if InCombatLockdown()then self.status:SetText("Open crafting after combat. This catalog remains available.");return end
 local skill=self:Skills()[self.profession]
 if not skill then self.status:SetText("Learn this profession from a trainer first.");return end
 -- Cast only the selected learned profession ability, on a deliberate click.
 local _,_,_,_,count,offset=GetProfessionInfo(skill.index)
 local bank=Enum and Enum.SpellBookSpellBank and Enum.SpellBookSpellBank.Player
 for n=1,count or 0 do
  local index=(offset or 0)+n;local info=C_SpellBook.GetSpellBookItemInfo(index,bank)
  if info and info.name==skill.name then
   C_SpellBook.CastSpellBookItem(index,bank)
   local book=AUI.modules.Spellbook;if book and book.frame then book.frame:Hide()end
   return
  end
 end
 self.status:SetText("Use the native Professions button / K to open crafting. Its controls stay intact.")
end
function P:Row(parent,index,title,subtitle,click,icon,item,spell)
 local r=self.rows[index]
 if not r then
  r=button(parent,"",1,48);r.label:Hide();r.icon=r:CreateTexture(nil,"ARTWORK");r.icon:SetSize(30,30);r.icon:SetPoint("LEFT",5,0)
  r.title=label(r);r.title:SetPoint("TOPLEFT",41,-7);r.title:SetPoint("RIGHT",-6,0);r.title:SetWordWrap(false)
  r.subtitle=label(r);r.subtitle:SetTextColor(.62,.66,.73);r.subtitle:SetPoint("BOTTOMLEFT",41,7);r.subtitle:SetPoint("RIGHT",-6,0);r.subtitle:SetWordWrap(false)
  r:SetScript("OnEnter",function(row)if not row.item and not row.spell then return end;GameTooltip:SetOwner(row,"ANCHOR_RIGHT");if row.item then GameTooltip:SetItemByID(row.item)else GameTooltip:SetSpellByID(row.spell)end;GameTooltip:Show()end)
  r:SetScript("OnLeave",function()GameTooltip:Hide()end);self.rows[index]=r
 end
 local default=self:Data().professions[self.profession].icon
 r:SetSize(parent:GetWidth()-4,48);r:ClearAllPoints();r:SetPoint("TOPLEFT",0,-(index-1)*52);r.title:SetText(title);r.subtitle:SetText(subtitle or "");r.icon:SetTexture(icon or default and "Interface\\Icons\\"..default or 134400);r.item=item;r.spell=spell
 r:SetScript("OnClick",function()self.detailAction=click;self.detailRevision=self.revision;if click then click()end end);r:Show()
end
function P:Details(text)
 self.detail:SetText(text or "");self.detailContent:SetHeight(math.max(1,(self.detail:GetStringHeight()or 1)+12));self.detailScroll:SetVerticalScroll(0)
end
function P:LoadItem(id)
 if C_Item and C_Item.RequestLoadItemDataByID then pcall(C_Item.RequestLoadItemDataByID,id)end
end
function P:SelectRecipe(recipe)
 self.selected=recipe;self.recipeID=recipe.id
 if recipe.output then self:LoadItem(recipe.output)end
 self.priceItem=recipe.output
 self:RenderDetails()
end
function P:SourceLines(recipe)
 local lines={recipe.source or "Source not recorded; check native crafting.",""}
 for _,v in ipairs(recipe.vendors or {})do
  lines[#lines+1]=v.name.." · "..(v.location or "Location not recorded")
  if v.coordinates then lines[#lines+1]=("Coordinates %.1f, %.1f"):format(unpack(v.coordinates))end
 end
 if recipe.recipeItem then lines[#lines+1]="Recipe item: "..self:ItemName(recipe.recipeItem)end
 if recipe.currency then lines[#lines+1]="Unlock uses "..recipe.currency.."; excluded from craft cost."end
 lines[#lines+1]="\nAvailability, reputation, specialization and stock still apply."
 return lines
end
function P:RenderDetails()
 local r=self.selected
 self.priceItem=r and r.output
 self.add:SetEnabled(r~=nil and r.materials~=nil);self.searchAuction:SetEnabled(r~=nil and r.output~=nil)
 if not r then
  local p=self:Data().professions[self.profession]
  self:Details(p.name.."\n\nSelect a recipe or guide step.\n\nCurrent Forever facts: "..self:Data().reviewed..". Native observations override materials and output quantities when you open crafting. Unobserved does not mean unavailable.\n\nSource coverage is incomplete, especially vendor locations and unlock requirements. Nothing crafts, buys or posts automatically.");return
 end
 local lines={r.name,r.skill and "Required skill: "..r.skill or "Required skill not verified",r.learned==true and "Learned · observed in native crafting"or r.learned==false and "Not learned · native observation"or "Learned state not observed",""}
 if r.warning then lines[#lines+1]=r.warning.."\n"end
 for _,requirement in ipairs(r.requirements or {})do if not requirement.met then lines[#lines+1]="Required: "..requirement.name end end
 if r.cooldown then lines[#lines+1]="Recipe was on cooldown when last observed."end
 if self.view=="Sources"then
  for _,s in ipairs(self:SourceLines(r))do lines[#lines+1]=s end
 else
  local count=math.floor(tonumber(self.batch:GetText())or 1);count=math.max(1,math.min(9999,count))
  local estimate=self:Estimate(r,count,{vendor=self:Store().vendor==true,intermediates=self:Store().intermediates==true})
  lines[#lines+1]=("%d craft%s · output %s"):format(count,count==1 and ""or "s",r.yield and (r.yield*count).." × "..(r.output and self:ItemName(r.output)or "effect")or "quantity unverified")
  lines[#lines+1]="Material value: "..money(estimate.total)
  lines[#lines+1]="Extra cash if buying direct: "..money(estimate.cash)
  if r.output then
   local fact=self:Data().items[r.output]
   lines[#lines+1]="Vendor return: "..money(fact and fact.vendorSell and r.yield and fact.vendorSell*r.yield*count)
  end
  lines[#lines+1]="Auction gross: "..money(estimate.gross)
  lines[#lines+1]="After sale fee: "..money(estimate.net)
  lines[#lines+1]="Listing margin: "..money(estimate.margin)
  if estimate.reason then lines[#lines+1]="\n"..estimate.reason end
  if estimate.saleMeta then
   local m=estimate.saleMeta;lines[#lines+1]="Output price: "..m.source..(m.time and m.time>0 and (" · "..math.max(0,math.floor((time()-m.time)/60)).." min old")or "")
  end
  lines[#lines+1]="\nMaterials"
  for _,m in ipairs(estimate.shopping or {})do
   lines[#lines+1]=m.quantity.." × "..self:ItemName(m.id).." · need "..m.need.." · "..money(m.price).." each"
   lines[#lines+1]="  "..m.meta.source
  end
  local warnings={};for warning in pairs(estimate.warnings or {})do warnings[#warnings+1]=warning end;table.sort(warnings)
  for _,warning in ipairs(warnings)do lines[#lines+1]="\n"..warning end
  lines[#lines+1]="\nOwned materials retain their value. Unlock/training fees are separate. Listing margin is an estimate, not a sale guarantee; failed deposits and relisting are extra costs."
  lines[#lines+1]="\nSource: "..(r.source or "Open native crafting for requirements.")
 end
 self:Details(table.concat(lines,"\n"))
end
function P:FilteredRecipes()
 local rows={};local query=(self.query or ""):lower()
 for _,r in ipairs(self:Recipes(self.profession))do
  local term=r.name.." "..(r.source or "").." "..(r.category or "")
  for _,v in ipairs(r.vendors or {})do term=term.." "..v.name.." "..(v.location or "")end
  local filter=self.filterMode or "All"
  if(query==""or term:lower():find(query,1,true))and(filter=="All"or filter=="Learned"and r.learned==true or filter=="Unlearned / unknown"and r.learned~=true or filter=="Vendor"and r.sourceKind=="Vendor")then rows[#rows+1]=r end
 end
 return rows
end
function P:RenderRecipes()
 local rows=self:FilteredRecipes();self:PageRows(rows,function(r,index)
  local icon=r.icon or r.output and(self:Data().items[r.output]or {}).icon
  if type(icon)=="string"then icon="Interface\\Icons\\"..icon end
  self:Row(self.listContent,index,r.name,(r.skill and "Skill "..r.skill.." · "or "")..(r.learned==true and "Learned"or r.sourceKind or "Unobserved"),function()self:SelectRecipe(r)end,icon,r.output,r.id)
 end)
 if self.recipeID then for _,r in ipairs(rows)do if r.id==self.recipeID then self.selected=r;break end end end
 self:RenderDetails()
end
function P:PageRows(rows,render)
 local size=self.rowsPerPage or 7;local pages=math.max(1,math.ceil(#rows/size));self.page=math.min(self.page or 1,pages)
 local first=(self.page-1)*size;for index=1,math.min(size,#rows-first)do render(rows[first+index],index)end
 self.pageLabel:SetText(("%d / %d · %d entries"):format(self.page,pages,#rows));self.prev:SetEnabled(self.page>1);self.next:SetEnabled(self.page<pages)
end
function P:RenderLeveling()
 local p=self:Data().professions[self.profession];local rank=self:Skill(p.id);local recipes={}
 for _,r in ipairs(self:Recipes(p.id))do recipes[r.id]=r end
 local steps={};for _,step in ipairs(p.steps)do
  local r=recipes[step.recipe];local text=r and r.name or step.targets or step.zones
  if text and text:lower():find((self.query or ""):lower(),1,true)then steps[#steps+1]=step end
 end
 self:PageRows(steps,function(step,index)
  local r=recipes[step.recipe];local title=("%d–%d · %s"):format(step.from,step.to,r and r.name or step.targets or "Gathering")
  local subtitle=rank>=step.to and "Passed"or rank>=step.from and "Your current range"or "Upcoming"
  self:Row(self.listContent,index,title,subtitle,function()
   local lines={p.name.." · skill "..step.from.."–"..step.to,""}
   if r then
    self.selected=r;self.add:SetEnabled(r.materials~=nil);self.searchAuction:SetEnabled(r.output~=nil)
    lines[#lines+1]=r.name;lines[#lines+1]="Source: "..(step.source or r.source or "Unrecorded")
    if step.crafts then
     lines[#lines+1]="Full range: about "..step.crafts.." crafts on average."
     local remaining=math.ceil(step.crafts*math.max(0,step.to-math.max(rank,step.from))/(step.to-step.from))
     lines[#lines+1]="Remaining estimate: "..remaining.." crafts (skill-up luck varies).";self.batch:SetText(tostring(math.max(1,remaining)))
    else lines[#lines+1]="Craft count not published. Check skill-up colours in native crafting."end
    lines[#lines+1]="\nPublished full-range materials (not per craft):"
    for _,m in ipairs(step.materials or {})do lines[#lines+1]=m.quantity.." × "..self:ItemName(m.id)end
    lines[#lines+1]="\nAdd plan uses the per-craft schematic and the batch size below. Intermediate materials may feed later steps; do not buy every full-range total separately."
   else self.selected=nil;self.add:SetEnabled(false);self.searchAuction:SetEnabled(false);lines[#lines+1]="Targets: "..(step.targets or "Gather while leveling");lines[#lines+1]="Zones: "..(step.zones or "See resource list")end
   if step.warning then lines[#lines+1]="\n"..step.warning end
   lines[#lines+1]="\nTrain the next profession rank before reaching its cap. Cooking / First Aid use Expert books and Artisan quests. Published route ranges are guidance, not recipe unlock requirements."
   self:Details(table.concat(lines,"\n"))
  end,nil,nil,step.recipe)
 end)
 self:Details(p.name.." leveling\n\nCurrent skill: "..rank.."\nSelect a skill range for materials, learning source and a craft estimate.\n\nThese are reviewed Forever skill/recipe facts from Wowhead, presented by RUI. They are not a cheapest-price optimizer. Gathering guidance has gaps; resource information appears in Sources.")
end
function P:RenderSources()
 local p=self:Data().professions[self.profession]
 if not p.gathering then self:RenderRecipes();return end
 local entries={};for _,t in ipairs(p.trainers)do entries[#entries+1]={trainer=t,name=t.name}end
 for _,r in ipairs(p.resources)do entries[#entries+1]={resource=r,name=r.name}end
 local rows={};for _,e in ipairs(entries)do if e.name:lower():find((self.query or ""):lower(),1,true)then rows[#rows+1]=e end end
 self:PageRows(rows,function(e,index)
  local t=e.trainer;local r=e.resource
  self:Row(self.listContent,index,e.name,t and t.location or r.zones,function()
   local lines={e.name,"",t and "Trainer · "..t.faction or "Gathering resource"}
   lines[#lines+1]=t and t.location or r.zones or "Zones not recorded"
   if t and t.coordinates then lines[#lines+1]=("Coordinates %.1f, %.1f"):format(unpack(t.coordinates))end
   if r then lines[#lines+1]="Required skill: "..(r.skill or "Unrecorded");lines[#lines+1]="Loot: "..r.loot end
   self:Details(table.concat(lines,"\n"));self.sourceRecord=t
  end)
 end)
 self:Details("Trainers & resources\n\nSelect a trainer or resource. Coordinates are shown where recorded; zone names remain searchable.\n\nSpawn locations and endgame gathering routes are not fully recorded.")
end
function P:RenderShopping()
 local rows,gaps=self:Shopping()
 self:PageRows(rows,function(m,index)self:Row(self.listContent,index,m.name,("%d total · %d missing"):format(m.quantity,m.need),function()
  local price,meta=self:PurchasePrice(m.id,self:Store().vendor)
  self.priceItem=m.id;self.priceBox:SetText("");self:Details(m.name.."\n\nTotal required: "..m.quantity.."\nOwned: "..self:Owned(m.id).."\nMissing: "..m.need.."\nUnit value: "..money(price).."\nSource: "..meta.source.."\n\nEnter a manual unit price below, for example 1g20s. Blank clears an override. Manual prices stay with this character and market.")
 end,nil,m.id)end)
 local lines={"Character crafting plan","","Export creates / replaces the 'Profession materials' auction shopping list. It does not buy anything. Bank counts use the client's last available cache.",""}
 for _,plan in pairs(self:Store().plans)do lines[#lines+1]=plan.crafts.." × "..plan.recipe.name end
 if #gaps>0 then lines[#lines+1]="\nUnverified materials: "..table.concat(gaps,", ")end
 self.selected=nil;self.add:SetEnabled(false);self.searchAuction:SetEnabled(false);self:Details(table.concat(lines,"\n"))
end
function P:RefreshVisible()
 if not self.panel or not self.panel:IsVisible()then return end
 local p=self:Data().professions[self.profession];if not p then return end
 local rank,max,learned=self:Skill(p.id);self.profButton:SetText(p.name.." ▾");self.skillLabel:SetText(learned and (rank.." / "..max)or "Preview · not learned")
 for _,row in ipairs(self.rows)do row:Hide()end
 for view,b in pairs(self.tabs)do b:SetText((self.view==view and "› "or "")..view)end
 self.rowsPerPage=math.max(3,math.floor((self.listContent:GetParent():GetHeight()-6)/52))
 self.filter:SetShown(self.view=="Recipes"or self.view=="Sources"and not p.gathering or self.view=="Profit")
 self.export:SetShown(self.view=="Shopping");self.clear:SetShown(self.view=="Shopping")
 self.priceBox:SetShown(self.view=="Shopping"or self.view=="Profit");self.priceSave:SetShown(self.view=="Shopping"or self.view=="Profit");self.priceHint:SetShown(self.view=="Shopping"or self.view=="Profit")
 self.priceHint:SetText(self.view=="Profit"and "Manual output unit price"or "Manual material unit price")
 self.fee:SetText(tostring(self:PriceSettings().fee or ""))
 self.feeLabel:SetShown(self.view=="Profit");self.fee:SetShown(self.view=="Profit");self.feeSave:SetShown(self.view=="Profit")
 self.vendor:SetShown(self.view=="Profit");self.intermediates:SetShown(self.view=="Profit")
 self.sourceRecord=nil;self.priceItem=nil
 if self.view=="Leveling"then self:RenderLeveling()elseif self.view=="Sources"then self:RenderSources()elseif self.view=="Shopping"then self:RenderShopping()else self:RenderRecipes()end
 if self.detailAction and self.detailRevision==self.revision and(self.view=="Leveling"or self.view=="Shopping"or self.view=="Sources"and p.gathering)then self.detailAction()end
end
function P:CreatePanel(spellbook)
 if self.panel then return end
 local panel=CreateFrame("Frame",nil,spellbook.frame);panel:SetPoint("TOPLEFT",18,-108);panel:SetPoint("BOTTOMRIGHT",-18,18);self.panel=panel;self.rows={};self.tabs={};self.view="Recipes"
 self.profButton=button(panel,"Profession ▾",210,26,function()self:ToggleProfessions()end);self.profButton:SetPoint("TOPLEFT")
 self.skillLabel=label(panel);self.skillLabel:SetPoint("LEFT",self.profButton,"RIGHT",8,0)
 self.native=button(panel,"Open crafting",115,26,function()self:OpenNative()end);self.native:SetPoint("TOPRIGHT")
 self.choices=CreateFrame("Frame",nil,panel,"BackdropTemplate");self.choices:SetPoint("TOPLEFT",self.profButton,"BOTTOMLEFT",0,-3);self.choices:SetFrameLevel(panel:GetFrameLevel()+30);AUI:StyleSurface(self.choices,"window",nil,"Professions");self.choices:Hide();self.profChoices={}
 for i,view in ipairs({"Recipes","Leveling","Sources","Profit","Shopping"})do local v=view
  local b=button(panel,v,116,26,function()self:SelectView(v)end);b:SetPoint("TOPLEFT",(i-1)*120,-34);self.tabs[v]=b
 end
 self.search=edit(panel,290,"");self.search:SetPoint("TOPLEFT",6,-68);self.search:SetScript("OnTextChanged",function(box)self.query=box:GetText();self.page=1;self:RefreshVisible()end)
 local hint=label(panel,"Search recipes, sources or zones");hint:SetPoint("LEFT",self.search,"RIGHT",12,0)
 self.filter=button(panel,"Filter: All",200,24,function()
  local modes={"All","Learned","Unlearned / unknown","Vendor"};local index=1;for i,m in ipairs(modes)do if m==self.filterMode then index=i end end
  self.filterMode=modes[index%#modes+1];self.filter:SetText("Filter: "..self.filterMode);self.page=1;self:RefreshVisible()
 end);self.filter:SetPoint("TOPLEFT",0,-100)
 local list=CreateFrame("Frame",nil,panel);list:SetPoint("TOPLEFT",0,-132);list:SetPoint("BOTTOMLEFT",0,104);list:SetWidth(260);list:SetClipsChildren(true)
 self.listContent=CreateFrame("Frame",nil,list);self.listContent:SetAllPoints()
 self.detailScroll=AUI:CreateSmoothScrollFrame(panel);self.detailScroll:SetPoint("TOPLEFT",272,-100);self.detailScroll:SetPoint("BOTTOMRIGHT",-4,198)
 self.detailContent=CreateFrame("Frame",nil,self.detailScroll);self.detailContent:SetWidth(326);self.detailContent:SetHeight(1);self.detailScroll:SetScrollChild(self.detailContent)
 self.detail=label(self.detailContent);self.detail:SetPoint("TOPLEFT",4,-4);self.detail:SetWidth(318);self.detail:SetSpacing(3)
 self.prev=button(panel,"‹",28,24,function()self.page=math.max(1,(self.page or 1)-1);self:RefreshVisible()end);self.prev:SetPoint("BOTTOMLEFT",0,72)
 self.next=button(panel,"›",28,24,function()self.page=(self.page or 1)+1;self:RefreshVisible()end);self.next:SetPoint("BOTTOMLEFT",232,72)
 self.pageLabel=label(panel);self.pageLabel:SetPoint("CENTER",self.prev,"CENTER",116,0)
 local batchLabel=label(panel,"Crafts");batchLabel:SetPoint("BOTTOMLEFT",274,171)
 self.batch=edit(panel,45,"1");self.batch:SetMaxLetters(4);self.batch:SetPoint("BOTTOMLEFT",320,164);self.batch:SetScript("OnEnterPressed",function(box)box:ClearFocus();self:RenderDetails()end)
 self.add=button(panel,"Add plan",90,24,function()if self.selected then local _,why=self:AddPlan(self.selected,tonumber(self.batch:GetText()));self.status:SetText(why);end end);self.add:SetPoint("BOTTOMLEFT",375,164)
 self.searchAuction=button(panel,"Search AH",112,24,function()
  if not self.selected or not self.selected.output then return end
  local a=AUI.modules.AuctionHouse;local _,why=a:ApplyQuery({term=self:ItemName(self.selected.output)},true);self.status:SetText(why)
 end);self.searchAuction:SetPoint("BOTTOMRIGHT",0,164)
 self.feeLabel=label(panel,"Sale fee %");self.feeLabel:SetPoint("BOTTOMLEFT",274,140)
 self.fee=edit(panel,38,"");self.fee:SetMaxLetters(5);self.fee:SetPoint("BOTTOMLEFT",350,133)
 self.feeSave=button(panel,"Set fee",78,24,function()local v=tonumber(self.fee:GetText());if v and self:SetFee(v)then self:RenderDetails()else self.status:SetText("Enter the market's sale fee from 0 to 100%.")end end);self.feeSave:SetPoint("BOTTOMLEFT",400,133)
 self.vendor=button(panel,"Vendor alternative",160,24,function()self:Store().vendor=not self:Store().vendor;self.vendor:SetText((self:Store().vendor and "✓ "or "").."Vendor alternative");self:RenderDetails()end);self.vendor:SetPoint("BOTTOMLEFT",274,40)
 self.intermediates=button(panel,"Craft intermediates",160,24,function()self:Store().intermediates=not self:Store().intermediates;self.intermediates:SetText((self:Store().intermediates and "✓ "or "").."Craft intermediates");self:RenderDetails()end);self.intermediates:SetPoint("BOTTOMRIGHT",0,40)
 self.export=button(panel,"Send to AH shopping",180,24,function()local _,why=self:ExportShopping();self.status:SetText(why)end);self.export:SetPoint("TOPLEFT",0,-100)
 self.clear=button(panel,"Clear plan",100,24,function()self:Store().plans={};self:RefreshVisible()end);self.clear:SetPoint("BOTTOMLEFT",0,40)
 self.priceHint=label(panel,"Manual unit price");self.priceHint:SetPoint("BOTTOMLEFT",274,113)
 self.priceBox=edit(panel,100,"");self.priceBox:SetPoint("BOTTOMLEFT",280,76)
 self.priceSave=button(panel,"Save / clear price",150,24,function()
  if not self.priceItem then self.status:SetText("Select a material or a recipe with an item output.");return end
  local text=self.priceBox:GetText();local value=text~=""and AUI.modules.AuctionHouse:ParseMoney(text)or nil
  if text~=""and not value then self.status:SetText("Use a price such as 1g20s, or leave blank to clear.");return end
  local ok,why=self:SetPrice(self.priceItem,value);self.status:SetText(why or(ok and "Manual price updated."or "Price not saved."));if self.view=="Profit"then self:RenderDetails()else self:RenderShopping()end
 end);self.priceSave:SetPoint("BOTTOMRIGHT",0,76)
 self.status=label(panel);self.status:SetPoint("BOTTOMLEFT",0,0);self.status:SetPoint("RIGHT",0,0);self.status:SetHeight(34);self.status:SetTextColor(.8,.8,.85)
 panel:SetScript("OnHide",function()self.choices:Hide()end)
 local selected=self:Store().selected;self.profession=self:Data().professions[selected]and selected or self:ProfessionList()[1].id
end
function P:ShowInSpellbook(spellbook)
 self:CreatePanel(spellbook);self.panel:Show();self:RefreshVisible()
end
function P:Show(id)
 local book=AUI.modules.Spellbook;book:Show("professions")
 if id and self:Data().professions[id]then self:SelectProfession(id)end
end
function P:RenderMap(q)
 for _,c in ipairs(q.mapControls or {})do c:Hide()end
 q.mapHeading:SetText("Professions");q.mapCopy:SetText("")
 q.mapScroll:ClearAllPoints();q.mapScroll:SetPoint("TOPLEFT",12,-42);q.mapScroll:SetPoint("BOTTOMRIGHT",-30,12)
 local skills=self:Skills();q.dungeonMapButtons=q.dungeonMapButtons or {}
 for i,p in ipairs(self:ProfessionList())do
  local b=q.dungeonMapButtons[i];if not b then b=AUI:CreateButton(q.mapContent);q.dungeonMapButtons[i]=b end
  b:ClearAllPoints();b:SetSize(math.max(140,q.mapContent:GetWidth()),48);b:SetPoint("TOPLEFT",0,-(i-1)*54)
  local id=p.id;local skill=skills[id];b:SetText(p.name.."\n"..(skill and (skill.rank.." / "..skill.max)or "Browse recipes and leveling"));b:SetScript("OnClick",function()self:Show(id)end);b:Show()
 end
 q.mapContent:SetHeight(12*54)
end
