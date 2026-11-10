"""Compile curated public Forever journal facts. No web requests in the addon."""
import json
from pathlib import Path
ROOT=Path(__file__).resolve().parent.parent
def lua(v):
    if v is None:return 'nil'
    if isinstance(v,bool):return str(v).lower()
    if isinstance(v,str):return json.dumps(v,ensure_ascii=False)
    if isinstance(v,list):return '{'+','.join('['+str(i+1)+']='+lua(x) for i,x in enumerate(v) if x is not None)+'}'
    if isinstance(v,dict):return '{'+','.join('['+(str(int(k)) if str(k).isdigit()else lua(k))+']='+lua(x)for k,x in sorted(v.items(),key=lambda x:str(x[0])))+'}'
    return str(v)
data=json.loads((ROOT/'Assets/DungeonJournal/facts.json').read_text(encoding='utf8'))
assert len(data['records'])==35
for r in data['records'].values():
    assert r['source'].startswith('https://www.wowhead.com/forever/')
    assert 1<=r['LevelRange'][1]<=r['LevelRange'][2]<=60
    for boss in r['items']:
        assert all(isinstance(row[1],int)and row[1]>0 for row in boss['loot']['NORMAL'])
source='-- Generated factual Forever journal metadata. See Assets/DungeonJournal/SOURCES.md.\nRUI_DungeonSource='+lua(data)+'\n'
target=ROOT/'ProjectRuthless_DungeonData/WowheadRecords.lua'
import sys
if '--check'in sys.argv:
    assert target.read_text(encoding='utf8')==source,'Regenerate the dungeon journal'
else:target.write_text(source,encoding='utf8')
