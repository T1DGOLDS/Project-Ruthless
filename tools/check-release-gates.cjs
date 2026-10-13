const fs=require('fs'),path=require('path'),crypto=require('crypto');
const root=path.resolve(__dirname,'..'),ids=['installation','profiles','combat','information','accessibility','performance'];
function sourceDigest(base=root){
  const hash=crypto.createHash('sha256'),files=[];
  function walk(dir){for(const item of fs.readdirSync(dir,{withFileTypes:true})){const full=path.join(dir,item.name);if(item.isDirectory())walk(full);else files.push(full);}}
  for(const dir of ['Modules','Assets','ProjectRuthless_Options','ProjectRuthless_DungeonData'])walk(path.join(base,dir));
  for(const file of ['Core.lua','ProjectRuthless.toc','ProjectRuthless_Camelot.toc'])files.push(path.join(base,file));
  for(const full of files.sort()){const name=path.relative(base,full).split(path.sep).join('/');let bytes=fs.readFileSync(full);if(/\.(lua|xml|toc|md|txt|cjs)$/.test(name))bytes=Buffer.from(bytes.toString('utf8').replace(/^\uFEFF/,'').replace(/\r\n/g,'\n'));hash.update(name+'\0');hash.update(bytes);hash.update('\0');}
  return hash.digest('hex');
}
function validate(data,version,digest,stable){
  if(data.version!==version||data.interface!==16001)throw Error('Live gate build/client does not match this release.');
  if(!Array.isArray(data.gates)||data.gates.length!==ids.length||ids.some(id=>data.gates.filter(g=>g.id===id).length!==1))throw Error('All six live gates must be present exactly once.');
  for(const gate of data.gates)if(!['pending','pass','fail'].includes(gate.status)||typeof gate.check!=='string'||!gate.check.trim()||typeof gate.evidence!=='string')throw Error('Invalid live gate: '+gate.id);
  if(stable){
    if(data.sourceDigest!==digest||typeof data.reviewer!=='string'||!data.reviewer.trim()||typeof data.testedAt!=='string'||!Number.isFinite(Date.parse(data.testedAt)))throw Error('Stable release requires a reviewer, date and matching tested-source digest.');
    for(const gate of data.gates)if(gate.status!=='pass'||!gate.evidence.trim())throw Error('Stable release blocked: '+gate.id+' has no passing live evidence.');
  }
  return data.gates.filter(g=>g.status!=='pass').map(g=>g.id+': '+g.status);
}
module.exports={sourceDigest,validate,ids};
if(require.main===module){try{
  const version=JSON.parse(fs.readFileSync(path.join(root,'package.json'))).version,index=process.argv.indexOf('--tag'),tag=index>=0?process.argv[index+1]:null;
  if(tag&&tag!=='v'+version)throw Error('Release tag and package version differ.');
  const stable=tag?!version.includes('-'):process.argv.includes('--stable'),digest=sourceDigest();
  const pending=validate(JSON.parse(fs.readFileSync(path.join(root,'validation/live-gates.json'))),version,digest,stable);
  console.log((stable?'PASS: stable live acceptance verified.':'Experimental build; live acceptance: '+pending.join(', '))+'\nSource digest: '+digest);
}catch(error){console.error(error.message);process.exitCode=1;}}
