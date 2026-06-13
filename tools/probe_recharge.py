"""Probe active items to see if recharge times exist in effect/wiki text."""
import json, re
from pathlib import Path

items = json.load(open(Path("assets/data/items.json"), encoding="utf-8"))
actives = [i for i in items if str(i.get("type", "")).lower() == "active"]

def flatten_wiki(item):
    parts = []
    wiki = item.get("wiki", {})
    for section in wiki.values():
        if not isinstance(section, list):
            continue
        for block in section:
            if not isinstance(block, dict):
                continue
            for tok in block.get("tokens", []):
                if tok.get("t") == "text":
                    parts.append(tok.get("v", ""))
            for sub in block.get("sub", []):
                for tok in sub.get("tokens", []):
                    if tok.get("t") == "text":
                        parts.append(tok.get("v", ""))
    return " ".join(parts)

# Patterns that hint at recharge
recharge_pat = re.compile(
    r"(\d+(?:\.\d+)?\s*s(?:econd)?s?\b"
    r"|\d+\s*kill"
    r"|\d+\s*(?:damage|dmg)"
    r"|cooldown[^.]{0,60}"
    r"|recharge[^.]{0,60}"
    r"|charges?\s+\d+"
    r"|upon use[^.]{0,60})",
    re.IGNORECASE,
)

print("Active items with recharge hints in effect/wiki:\n")
found = 0
for i in actives:
    effect = i.get("effect", "")
    wiki_text = flatten_wiki(i)
    combined = effect + " " + wiki_text
    matches = recharge_pat.findall(combined)
    if matches:
        found += 1
        print(f"  {i['name']}: {matches[:3]}")

print(f"\nTotal actives: {len(actives)}, with any recharge hint: {found}")

# Also check sell price hints
print("\n--- SELL PRICE check ---")
sell_pat = re.compile(r"sell[^.]{0,40}", re.IGNORECASE)
guns = json.load(open(Path("assets/data/guns.json"), encoding="utf-8"))
print(f"Guns with sell_price in JSON: {sum(1 for g in guns if g.get('sell_price'))}")
print(f"Items with sell_price in JSON: {sum(1 for i in items if i.get('sell_price'))}")

# Quality distribution of items
from collections import Counter
q_dist = Counter(i.get("quality", "") for i in items)
print(f"\nItem quality distribution: {dict(q_dist)}")
q_dist_guns = Counter(g.get("quality", "") for g in guns)
print(f"Gun quality distribution: {dict(q_dist_guns)}")

# Check local icon coverage
print("\n--- ICON check ---")
assets = Path("assets")
icons_dir = assets / "icons"
if icons_dir.exists():
    all_icons = list(icons_dir.rglob("*.png"))
    print(f"Total local icon PNGs: {len(all_icons)}")
    print(f"Subdirectories: {[d.name for d in icons_dir.iterdir() if d.is_dir()]}")
else:
    print("assets/icons/ does not exist")
    for d in assets.iterdir():
        if d.is_dir():
            count = len(list(d.rglob("*")))
            print(f"  {d.name}/: {count} files")
