const fs=require('fs'),path=require('path'),cp=require('child_process'),assert=require('assert');
const root=path.resolve(__dirname,'..'),reference=JSON.parse(fs.readFileSync(path.join(root,'validation/native-source.json'),'utf8'));
assert(reference.branch==='forever'&&/^[a-f0-9]{40}$/.test(reference.revision),'Invalid Forever source reference');
const ci=fs.readFileSync(path.join(root,'.github/workflows/ci.yml'),'utf8');
assert(ci.includes('ref: '+reference.revision),'CI native revision differs from the reviewed source');
const gates=JSON.parse(fs.readFileSync(path.join(root,'validation/live-gates.json'),'utf8'));
assert(gates.nativeRevision===reference.revision,'Live gate native revision differs from reviewed source');
function git(args){const out=cp.spawnSync('git',args,{encoding:'utf8',timeout:30000,windowsHide:true});if(out.error||out.status!==0)throw Error('Cannot verify native source: '+(out.error?.message||out.stderr));return out.stdout.trim();}
if(process.env.PR_WOW_FOREVER_SOURCE){
 const checkout=path.resolve(process.env.PR_WOW_FOREVER_SOURCE,'../..');
 assert(git(['-C',checkout,'rev-parse','HEAD'])===reference.revision,'Native test checkout is stale or differs from reviewed Forever source');
 const native=fs.readFileSync(path.join(process.env.PR_WOW_FOREVER_SOURCE,'Blizzard_UIPanels_Game/Mainline/ContainerFrame.lua'),'utf8');
 assert(native.includes('function ContainerFrameItemButtonMixin:Initialize(containerFrame, bag, slot)'),'Reviewed native initializer contract missing');
}
if(process.argv.includes('--check-remote')){
 const head=git(['ls-remote','--heads',reference.repository,'refs/heads/'+reference.branch]).split(/\s+/)[0];
 assert(head===reference.revision,'Forever source has changed. Review/update the source pin and API contracts before validating a release.');
}
console.log('PASS: reviewed Forever source, test checkout and CI/live-gate references agree'+(process.argv.includes('--check-remote')?' with the current remote head':'')+'.');
