const assert=require('assert'),fs=require('fs'),path=require('path');
const root=path.resolve(__dirname,'..'),{sourceDigest,validate}=require('../tools/check-release-gates.cjs');
const digest=sourceDigest(),data=JSON.parse(fs.readFileSync(path.join(root,'validation/live-gates.json'))),version=JSON.parse(fs.readFileSync(path.join(root,'package.json'))).version;
assert.doesNotThrow(()=>validate(data,version,digest,false));
const pending=structuredClone(data);for(const gate of pending.gates){gate.status='pending';gate.evidence='';}
assert.equal(validate(pending,version,digest,false).length,6);assert.throws(()=>validate(pending,version,digest,true));
const pass=structuredClone(data);Object.assign(pass,{sourceDigest:digest,reviewer:'test fixture',testedAt:'2026-10-13T00:00:00Z'});for(const gate of pass.gates){gate.status='pass';gate.evidence='test fixture only';}
assert.deepEqual(validate(pass,version,digest,true),[]);assert.throws(()=>validate(pass,'different',digest,true));assert.throws(()=>validate(pass,version,'changed',true));
pass.gates[0].evidence='';assert.throws(()=>validate(pass,version,digest,true));pass.gates[0]=pass.gates[1];assert.throws(()=>validate(pass,version,digest,false));
const release=fs.readFileSync(path.join(root,'.github/workflows/release.yml'),'utf8');assert(release.includes('needs: validate')&&release.includes('overwrite_files: false')&&release.includes('check-release-gates.cjs'));
const pack=fs.readFileSync(path.join(root,'tools/package.ps1'),'utf8');assert(!pack.includes('Remove-Item -LiteralPath $releaseRoot'));assert(pack.includes('Refusing to overwrite'));
const os=require('os'),{spawnSync}=require('child_process'),fixture=fs.mkdtempSync(path.join(os.tmpdir(),'rui-package-'));
try{
  for(const dir of ['Modules','Assets','docs','ProjectRuthless_Options','ProjectRuthless_DungeonData','release'])fs.mkdirSync(path.join(fixture,dir),{recursive:true});
  for(const file of ['Core.lua','README.md','CHANGELOG.md','LICENSE','Modules/fixture.lua','Assets/fixture.txt','docs/fixture.md'])fs.writeFileSync(path.join(fixture,file),'fixture');
  for(const file of ['ProjectRuthless.toc','ProjectRuthless_Camelot.toc','ProjectRuthless_Options/ProjectRuthless_Options.toc','ProjectRuthless_DungeonData/ProjectRuthless_DungeonData.toc'])fs.writeFileSync(path.join(fixture,file),'## Version: '+version+'\n');
  fs.writeFileSync(path.join(fixture,'package.json'),JSON.stringify({version}));fs.writeFileSync(path.join(fixture,'release/old.zip'),'preserved old release');
  const shell=process.platform==='win32'?path.join(process.env.SystemRoot,'System32/WindowsPowerShell/v1.0/powershell.exe'):'pwsh';
  const args=['-NoProfile','-NonInteractive','-File',path.join(root,'tools/package.ps1'),'-RepositoryRoot',fixture];
  const build=spawnSync(shell,args,{encoding:'utf8'});assert.equal(build.status,0,build.stderr||build.error);
  const archive=path.join(fixture,'release','ProjectRuthless-'+version+'.zip'),before=fs.readFileSync(archive);
  assert.equal(fs.readFileSync(path.join(fixture,'release/old.zip'),'utf8'),'preserved old release');
  assert.equal(fs.readdirSync(path.join(fixture,'release')).filter(name=>name.startsWith('.staging-')).length,0);
  assert.notEqual(spawnSync(shell,args,{encoding:'utf8'}).status,0);assert(before.equals(fs.readFileSync(archive)));
  assert.notEqual(spawnSync(shell,[...args,'-Version','0.0.0'],{encoding:'utf8'}).status,0);
}finally{
  assert(path.resolve(fixture).startsWith(path.resolve(os.tmpdir())+path.sep+'rui-package-'));fs.rmSync(fixture,{recursive:true,force:true});
}
console.log('PASS: six build-specific live gates, evidence/digest validation, stable blocking, beta disclosure, validation-before-publish and archive preservation.');
