// Read-only audit against the installed Forever database, never external guide prose.
const fs=require('fs'),path=require('path'),crypto=require('crypto');
const root=path.resolve(__dirname,'..'),parser=require(path.join(root,'node_modules/luaparse'));
const source=fs.readFileSync(path.join(root,'Modules/AuthoredGuideData.lua'),'utf8');
const metadataPath=process.argv[2]||'C:/World of Warcraft/_classic_beta_/Interface/AddOns/QuestieDB/QuestieDB_Camelot.toc';
const metadata=fs.readFileSync(metadataPath,'utf8');
function decode(b){let p=0;function read(){const h=b[p++],major=h>>5,a=h&31;let n=a;if(a===24)n=b[p++];else if(a===25){n=b.readUInt16BE(p);p+=2}else if(a===26){n=b.readUInt32BE(p);p+=4}else if(a===27){n=Number(b.readBigUInt64BE(p));p+=8}if(major===0)return n;if(major===1)return -1-n;if(major===2||major===3){const s=b.subarray(p,p+n);p+=n;return s.toString('utf8')}if(major===4){const arr=[];for(let i=0;i<n;i++)arr.push(read());return arr}if(major===5){const o={};for(let i=0;i<n;i++){const k=read();o[k]=read()}return o}if(major===7)return a===21?true:a===20?false:null;throw Error('Unsupported CBOR '+h)}return read()}
function value(n){if(n.type==='StringLiteral')return JSON.parse(n.raw);if(n.type==='NumericLiteral')return n.value;if(n.type==='TableConstructorExpression')return n.fields.every(f=>f.type==='TableValue')?n.fields.map(f=>value(f.value)):Object.fromEntries(n.fields.map(f=>[value(f.key),value(f.value)]));throw Error(n.type)}
const ast=parser.parse(source,{luaVersion:'5.1',encodingMode:'none'}),ret=ast.body[1].init[0].body[0];
const routes=value(ret.arguments[0]),facts=value(ret.arguments[1]),db={};
for(const m of metadata.matchAll(/^## X-Quest-(\d+)-(\d+|S): (.+)$/gm)){const r=db[m[1]]||={};const v=decode(Buffer.from(m[3].trim(),'base64'));if(m[2]==='S')Object.assign(r,v);else r[m[2]]=v;}
function check(ok,message){if(!ok)throw Error(message)}
const ids=new Set(),routeIDs=new Set(),areas=new Set();let continuations=0;
for(const r of routes){
 check(!routeIDs.has(r.id),'Duplicate route '+r.id);routeIDs.add(r.id);areas.add(r.area);
 check(r.faction==='Alliance'||r.faction==='Horde','Unsupported faction '+r.id);
 check(r.min<=r.max&&r.max<=30&&r.hubs.length>0,'Invalid route range '+r.id);
 const seen=new Set();
 for(const h of r.hubs){
  check(h.min>=r.min&&h.max<=r.max&&h.min<=h.max,'Invalid chapter range '+r.id);
  for(const id of h.quests){const q=db[id],f=facts[id];
   check(q&&f,'Unknown quest '+id);
   check(f.title===q[1]&&f.min===q[4]&&f.level===q[5],'Stale quest facts '+id);
   check(!q[7]&&q[5]<=30&&q[4]<=h.max,'Class/level restriction '+r.id+':'+id);
   check(q[6]!== (r.faction==='Alliance'?8589934770:4294967373),'Wrong faction '+r.id+':'+id);
   if(r.min>=20){
    check(!seen.has(id),'Repeated chapter quest '+r.id+':'+id);
    check((q[12]||[]).every(x=>seen.has(x)),'Missing grouped prerequisite '+r.id+':'+id);
    check(!(q[13]||[]).length||q[13].some(x=>seen.has(x)),'Missing alternative prerequisite '+r.id+':'+id);
   }
   seen.add(id);ids.add(String(id));
  }
 }
 if(r.min>=20)continuations++;
}
check(Object.keys(facts).every(id=>ids.has(id)),'Unused quest facts');
console.log(JSON.stringify({result:'PASS',routes:routes.length,zones:areas.size,quests:ids.size,level20RoutesAndDetours:continuations,metadataPath,metadataVersion:metadata.match(/^## Version: (.+)$/m)?.[1].trim(),metadataSHA256:crypto.createHash('sha256').update(metadata).digest('hex')},null,2));
