"""Rebuild the Lua catalogue from its packaged, editable reference source.

Reference.json contains the extracted factual subset and its source revision.
It is GPL-3.0 reference data, separate from RUI's MIT implementation.
This builder reads no installed addons, game files, accounts or network services.
"""
import argparse
import json
from pathlib import Path


def lua(value):
    if value is None:
        return "nil"
    if isinstance(value, bool):
        return "true" if value else "false"
    if isinstance(value, (int, float)):
        return str(value)
    if isinstance(value, str):
        return json.dumps(value, ensure_ascii=False)
    if isinstance(value, list):
        return "{" + ",".join(lua(v) for v in value) + "}"
    return "{" + ",".join(
        "[" + lua(int(k) if str(k).lstrip("-").isdigit() else k) + "]=" + lua(v)
        for k, v in value.items()
    ) + "}"


def build(source):
    data = json.loads(source.read_text(encoding="utf-8"))
    assert data["schema"] == 1
    assert data["clientRecords"] == len(data["quests"])
    return (
        "-- Generated factual reference data. Reference records are not verified Forever requirements.\n"
        "-- CMaNGOS Classic-DB reference data: GPL-3.0, see Assets/QuestSupplies/LICENSE-REFERENCE.txt.\n"
        'local _,AUI=...\nlocal D={};AUI:RegisterModule("QuestSupplyData",D)\n'
        + 'D.summary=' + lua({'clientRecords':data['clientRecords'],'counts':data['counts'],'withheldRecords':data.get('withheldRecords',0),'clientDeclaredRecords':data.get('clientDeclaredRecords',data['clientRecords'])}) + '\n'
        +
        "function D:Get()\nif self.data then return self.data end\nself.data=" + lua(data)
        + "\nreturn self.data\nend\n"
    )


if __name__ == "__main__":
    root = Path(__file__).resolve().parent.parent
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--check", action="store_true")
    parser.add_argument("--source", type=Path, default=root / "Assets/QuestSupplies/Reference.json")
    parser.add_argument("--output", type=Path, default=root / "Modules/QuestSupplyData.lua")
    args = parser.parse_args()
    target = args.output
    result = build(args.source)
    if args.check:
        assert target.read_text(encoding="utf-8") == result, "Rebuild QuestSupplyData.lua"
        print("PASS: quest-supply catalogue matches its editable source")
    else:
        target.write_text(result, encoding="utf-8")
