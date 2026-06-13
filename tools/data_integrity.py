"""One-shot data integrity sweep. Run from gungeon_mate/ root.

Checks:
1. All assets/data/*.json files parse cleanly.
2. Names within each list (guns/items/shrines/gungeoneers) are unique.
3. Synergy `requires` reference real gun/item names.
4. back_refs.json keys + values reference real gun/item names.
5. Icon paths declared on each entity exist on disk.
6. Required `name` field is non-empty everywhere.
7. RichToken refs (kind=item|gun|character|shrine) all resolve.

Exits non-zero if any hard error is detected.
"""
import json
import sys
from pathlib import Path
from collections import Counter

ROOT = Path(__file__).resolve().parent.parent
DATA = ROOT / "assets" / "data"

errors = []
warnings = []


def load(name):
    return json.load(open(DATA / f"{name}.json", encoding="utf-8"))


# 1. Parse
files = ["guns", "items", "synergies", "shrines", "gungeoneers", "back_refs"]
data = {}
for f in files:
    try:
        data[f] = load(f)
        print(f"OK  parse {f}.json")
    except Exception as e:
        errors.append(f"{f}.json parse error: {e}")

# 2. Unique names
for k in ("guns", "items", "shrines", "gungeoneers"):
    names = [x["name"] for x in data[k]]
    counts = Counter(names)
    dupes = [n for n, c in counts.items() if c > 1]
    if dupes:
        errors.append(f"{k}: duplicate names {dupes}")
    else:
        print(f"OK  unique names ({k}: {len(names)})")

# 3. Synergy refs
gun_names = {g["name"].lower() for g in data["guns"]}
item_names = {i["name"].lower() for i in data["items"]}
all_names = gun_names | item_names

syn_missing = []
for s in data["synergies"]:
    for r in s.get("requires", []):
        if isinstance(r, str) and r.lower() not in all_names:
            syn_missing.append((s.get("name"), r))
if syn_missing:
    warnings.append(f"synergy refs missing: {len(syn_missing)}")
    for x in syn_missing[:5]:
        print(f"   warn syn-ref: {x}")
else:
    print(f"OK  synergy refs resolve ({len(data['synergies'])} synergies)")

# 4. back_refs
br = data["back_refs"]
i2r = br.get("item_to_referrers", {})
syn2r = br.get("synergy_to_referrers", {})

bad_keys = [k for k in i2r if k.lower() not in all_names]
bad_vals = [
    (k, v) for k, vs in i2r.items() for v in vs if v.lower() not in all_names
]
if bad_keys:
    warnings.append(f"back_refs item-keys missing: {len(bad_keys)}")
if bad_vals:
    warnings.append(f"back_refs item-values missing: {len(bad_vals)}")
print(
    f"OK  back_refs (item_to_referrers={len(i2r)} entries, "
    f"synergy_to_referrers={len(syn2r)} entries, "
    f"bad_keys={len(bad_keys)}, bad_vals={len(bad_vals)})"
)

# 5. Icon paths
missing_icons = []
for kind in ("guns", "items", "shrines", "gungeoneers"):
    for x in data[kind]:
        ic = (x.get("icon") or "").strip()
        if not ic:
            continue
        candidates = [Path(ic), ROOT / ic, ROOT / "assets" / ic]
        if not any(p.exists() for p in candidates):
            missing_icons.append((kind, x["name"], ic))
if missing_icons:
    warnings.append(f"missing icon files: {len(missing_icons)}")
    for x in missing_icons[:8]:
        print(f"   warn icon: {x}")
else:
    print("OK  all entity icons exist on disk")

# 6. Required fields
for g in data["guns"]:
    if not g.get("name"):
        errors.append(f"gun missing name: {g}")
for i in data["items"]:
    if not i.get("name"):
        errors.append(f"item missing name: {i}")
for s in data["shrines"]:
    if not s.get("name"):
        errors.append(f"shrine missing name: {s}")
for c in data["gungeoneers"]:
    if not c.get("name"):
        errors.append(f"gungeoneer missing name: {c}")

# 7. Rich-token ref integrity (item/gun/character/shrine kinds must resolve)
char_names = {c["name"].lower() for c in data["gungeoneers"]}
shr_names = {s["name"].lower() for s in data["shrines"]}


def walk(obj, out):
    if isinstance(obj, dict):
        if obj.get("t") == "ref":
            out.append((obj.get("kind"), obj.get("v")))
        for v in obj.values():
            walk(v, out)
    elif isinstance(obj, list):
        for v in obj:
            walk(v, out)


refs = []
walk(data["guns"], refs)
walk(data["items"], refs)
walk(data["synergies"], refs)

bad_refs = []
for kind, name in refs:
    if not name:
        continue
    n = name.lower()
    if kind == "gun" and n not in gun_names:
        bad_refs.append((kind, name))
    elif kind == "item" and n not in item_names:
        bad_refs.append((kind, name))
    elif kind == "character" and n not in char_names:
        bad_refs.append((kind, name))
    elif kind == "shrine" and n not in shr_names:
        bad_refs.append((kind, name))
print(f"OK  rich-token refs scanned: {len(refs)}, broken: {len(bad_refs)}")
if bad_refs:
    warnings.append(f"broken rich-token refs: {len(bad_refs)}")
    for x in bad_refs[:8]:
        print(f"   warn ref: {x}")

# Summary
print()
print(f"== Errors:   {len(errors)}")
for e in errors:
    print(f"   {e}")
print(f"== Warnings: {len(warnings)}")
for w in warnings:
    print(f"   {w}")

sys.exit(1 if errors else 0)
