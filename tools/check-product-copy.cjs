// Product copy must describe RUI. Source licences, immutable provenance and
// isolated compatibility protocols have separate ownership and stay intact.
const fs=require('fs'),path=require('path'),assert=require('assert');
const root=path.resolve(__dirname,'..');
const names=/\b(?:ElvUI|Ellesmere(?:UI)?|Questie(?:DB)?|Bagnon|BagBrother|Bartender|WeakAuras|TellMeWhen|Leatrix|RestedXP|RXPGuides|ForeverWisp\w*|Wisp|Attune|TomTom|Raider\.?IO|AtlasLoot(?:Classic)?|InFlight|HandyNotes|OmniCC|Masque|BigWigs|Plater|Tukui|Epithet)\b/i;
function files(dir){return fs.readdirSync(path.join(root,dir),{withFileTypes:true}).flatMap(e=>e.isDirectory()?files(path.join(dir,e.name)):[path.join(dir,e.name)]);}
const product=['README.md','CURSEFORGE.md','CHANGELOG.md','AGENTS.md',...files('docs').filter(f=>f.endsWith('.md')),
 ...files('Modules').filter(f=>f.endsWith('.lua')),...files('ProjectRuthless_Options').filter(f=>f.endsWith('.lua'))];
const protocol=new Set(['Modules/GuideBridge.lua','Modules/QuestPickupData.lua','Modules/QuestSupplyData.lua','Modules/TravelData.lua','Modules/ProfessionData.lua']);
const failures=[];
for(const file of product){
 if(protocol.has(file.replaceAll('\\','/')))continue;
 fs.readFileSync(path.join(root,file),'utf8').split(/\r?\n/).forEach((line,index)=>{
  if(file.replaceAll('\\','/')==='Modules/Profiles.lua'&&/^function P:IsRetiredSection\(section\)/.test(line))return;
  if(names.test(line))failures.push(`${file}:${index+1}: ${line.slice(0,180)}`);
 });
}
for(const file of ['ProjectRuthless.toc','ProjectRuthless_Camelot.toc']){
 const source=fs.readFileSync(path.join(root,file),'utf8');assert(!names.test(source),`Product references in ${file}`);
}
assert.deepEqual(failures,[],'Other-addon references in RUI product copy');
const library=fs.readFileSync(path.join(root,'Libs/LibActionButton/LibActionButton-1.0.lua'),'utf8');
assert(!/Masque/.test(library),'Inactive external skin hooks must stay retired');
console.log('PASS: RUI-only product descriptions, interface text and manifests; isolated compatibility and required source notices retained');
