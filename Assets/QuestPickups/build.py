"""Rebuild RUI's lazy pickup data from the packaged editable factual subset.

Data follows the upstream GPLv3 permission and historical-contributor caveat;
see UPSTREAM-LICENSE.md. This builder needs only Python, no game/addon installed.
"""
import argparse,json
from pathlib import Path
def lua(v):
    if v is None:return 'nil'
    if isinstance(v,bool):return 'true' if v else 'false'
    if isinstance(v,(int,float)):return str(v)
    if isinstance(v,str):return json.dumps(v,ensure_ascii=False)
    if isinstance(v,list):return '{'+','.join(map(lua,v))+'}'
    return '{'+','.join('['+lua(int(k) if str(k).lstrip('-').isdigit() else k)+']='+lua(x) for k,x in v.items())+'}'
def build(source):
    d=json.loads(source.read_text(encoding='utf8'));assert d['schema']==1 and d['flavor']=='Forever'
    summary={k:d[k] for k in ('revision','retrieved','flavor')}
    summary.update(d['coverage'])
    summary.update(quests=len(d['quests']),located=sum(bool(q['sites']) for q in d['quests'].values()),maps=len(d['byMap']))
    return ('-- Generated factual quest metadata; GPLv3 permission/caveat: Assets/QuestPickups/UPSTREAM-LICENSE.md\n'
      'local _,AUI=...\nlocal D={};AUI:RegisterModule("QuestPickupData",D)\nD.summary='+lua(summary)+'\n'
      'function D:Get()\nif self.data then return self.data end\nself.data='+lua(d)+'\nreturn self.data\nend\n')
if __name__=='__main__':
    folder=Path(__file__).resolve().parent
    parser=argparse.ArgumentParser(description=__doc__);parser.add_argument('--check',action='store_true');args=parser.parse_args()
    target=folder.parent.parent/'Modules/QuestPickupData.lua';result=build(folder/'Reference.json')
    if args.check:assert target.read_text(encoding='utf8')==result;print('PASS: current Forever pickup data matches editable source')
    else:target.write_text(result,encoding='utf8')
