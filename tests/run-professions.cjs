const fs=require('fs'),path=require('path'),assert=require('assert');
const root=path.resolve(__dirname,'..'),{lua,lauxlib,lualib,to_luastring,to_jsstring}=require('fengari'),parser=require('luaparse');
const L=lauxlib.luaL_newstate();lualib.luaL_openlibs(L);
for(const [key,file]of [['DATA','Modules/ProfessionData.lua'],['MODEL','Modules/Professions.lua'],['UI','Modules/ProfessionUI.lua']]){
 const source=fs.readFileSync(path.join(root,file),'utf8');parser.parse(source,{luaVersion:'5.1'});
 assert(!/SetScript\("OnUpdate"|CraftRecipe\(|BuyCommodity\(|PostItem\(|SendSearchQuery\(/.test(source),'Profession planning must not poll, craft or trade');
 lua.lua_pushstring(L,to_luastring(source));lua.lua_setglobal(L,to_luastring(key));
}
const data=JSON.parse(fs.readFileSync(path.join(root,'Assets/Professions/facts.json'),'utf8'));
assert.equal(Object.keys(data.professions).length,12);assert.equal(data.summary.recipes,1008);
for(const p of Object.values(data.professions)){
 assert(p.steps.length>0);assert(p.overview.startsWith('https://www.wowhead.com/forever/'));
 for(const r of p.recipes){assert(r.id>0);assert(!r.skill||r.skill<=300);for(const m of r.materials||[])assert(m.quantity>0);}
 if(!p.gathering){let at=1;for(const s of p.steps){assert.equal(s.from,at,`${p.name} guide gap`);at=s.to;}assert.equal(at,300);}
}
const toc=fs.readFileSync(path.join(root,'ProjectRuthless_Camelot.toc'),'utf8');
assert(toc.indexOf('Modules\\Professions.lua')<toc.indexOf('Modules\\ProfessionUI.lua'));
const book=fs.readFileSync(path.join(root,'Modules/Spellbook.lua'),'utf8');
const foreverTabs=book.match(/if AUI\.isForever then\s+self:CreateTab\(frame,"general"[\s\S]*?\n    else/)[0];
assert(!foreverTabs.includes('"professions"'),'Forever Spellbook must contain no profession tab');
assert(!fs.readFileSync(path.join(root,'Modules/ProfessionUI.lua'),'utf8').includes('AUI.modules.Spellbook'),'Profession window must not depend on Spellbook');
assert(book.includes('if AUI.isForever and mode=="professions"then mode="class"end'),'Retired saved tab must migrate safely');
const native=process.env.PR_WOW_FOREVER_SOURCE;
if(native){
 const docs=fs.readFileSync(path.join(native,'Blizzard_APIDocumentationGenerated/TradeSkillUIDocumentation.lua'),'utf8');
 for(const method of ['GetBaseProfessionInfo','GetRecipeInfo','GetRecipeSchematic','GetRecipeOutputItemData'])assert(docs.includes(`Name = "${method}"`));
 const template=fs.readFileSync(path.join(native,'Blizzard_ProfessionsTemplates/Blizzard_Professions.lua'),'utf8');assert(template.includes('C_TradeSkillUI.GetFilteredRecipeIDs()'));
 const bindings=fs.readFileSync(path.join(native,'Blizzard_FrameXML/Bindings_Camelot.xml'),'utf8');
 assert(/<Binding name="TOGGLEPROFESSIONBOOK"[^>]*>\s*ToggleProfessionsBook\(\);/.test(bindings));
 const micro=fs.readFileSync(path.join(native,'Blizzard_MicroMenu/Mainline/MainMenuBarMicroButtons.lua'),'utf8');
 assert(/function ProfessionMicroButtonMixin:OnClick[\s\S]*?ToggleProfessionsBook\(\)/.test(micro));
}
if(lauxlib.luaL_dostring(L,to_luastring(fs.readFileSync(path.join(__dirname,'professions.test.lua'),'utf8')))!==lua.LUA_OK)throw Error(to_jsstring(lua.lua_tostring(L,-1)));
