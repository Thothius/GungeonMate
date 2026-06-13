"""Deep data completeness audit. Run from gungeon_mate/ root."""
import json
from pathlib import Path

DATA = Path("assets/data")
guns  = json.load(open(DATA / "guns.json",  encoding="utf-8"))
items = json.load(open(DATA / "items.json", encoding="utf-8"))
syns  = json.load(open(DATA / "synergies.json", encoding="utf-8"))

# ── GUNS ────────────────────────────────────────────────────────────────────
print(f"=== GUNS ({len(guns)} total) ===")
crit = ["damage", "dps", "magazine_size", "ammo_capacity",
        "fire_rate", "reload_time", "class"]
for f in crit:
    missing = [g["name"] for g in guns if not str(g.get(f, "")).strip()]
    if missing:
        print(f"  {f}: {len(missing)} empty  → {missing[:6]}")
    else:
        print(f"  {f}: OK (all filled)")

no_wiki = [g["name"] for g in guns
           if not g.get("wiki", {}).get("notes")
           and not g.get("wiki", {}).get("effects")]
print(f"  no wiki content: {len(no_wiki)}")

no_icon = [g["name"] for g in guns
           if not g.get("icon", "").strip()
           or g["icon"].startswith("http")]
print(f"  missing/remote icon: {len(no_icon)} → {no_icon[:5]}")

# ── ITEMS ────────────────────────────────────────────────────────────────────
print()
print(f"=== ITEMS ({len(items)} total) ===")

no_effect = [i["name"] for i in items if not str(i.get("effect", "")).strip()]
print(f"  empty effect field: {len(no_effect)}")

actives = [i for i in items if str(i.get("type", "")).lower() == "active"]
print(f"  total active items: {len(actives)}")

# Figure out the actual recharge field name from sample
sample_keys = list(actives[0].keys()) if actives else []
print(f"  active item keys: {sample_keys}")

# Check every possible spelling
def recharge(i):
    for k in ("recharge_time", "rechargeTime", "recharge", "charge_time"):
        v = str(i.get(k, "")).strip()
        if v:
            return v
    return ""

no_recharge = [i["name"] for i in actives if not recharge(i)]
print(f"  active items with no recharge data: {len(no_recharge)} → {no_recharge[:8]}")

no_sell = [i["name"] for i in items if not str(i.get("sell_price", "")).strip()]
print(f"  missing sell_price: {len(no_sell)}")

no_quality = [i["name"] for i in items if not str(i.get("quality", "")).strip()]
print(f"  missing quality: {len(no_quality)}")

no_icon_items = [i["name"] for i in items
                 if not i.get("icon", "").strip()
                 or i["icon"].startswith("http")]
print(f"  missing/remote icon: {len(no_icon_items)} → {no_icon_items[:5]}")

# ── SYNERGIES ────────────────────────────────────────────────────────────────
print()
print(f"=== SYNERGIES ({len(syns)} total) ===")

no_eff = [s["name"] for s in syns if not str(s.get("effect", "")).strip()]
print(f"  no effect text: {len(no_eff)} → {no_eff[:6]}")

no_req = [s["name"] for s in syns if not s.get("requires")]
print(f"  no requires list: {len(no_req)} → {no_req[:6]}")

# Synergies where requires has only 1 item (likely incomplete)
one_req = [s["name"] for s in syns
           if len(s.get("requires", [])) == 1
           and not s.get("any_of")]
print(f"  requires exactly 1 item (possibly incomplete): {len(one_req)} → {one_req[:6]}")

# ── LOCAL ICON COVERAGE ──────────────────────────────────────────────────────
print()
print("=== ICONS ===")
assets_root = Path("assets")
guns_local  = [g for g in guns  if g.get("icon","").strip() and not g["icon"].startswith("http")]
items_local = [i for i in items if i.get("icon","").strip() and not i["icon"].startswith("http")]
print(f"  guns  with local icon: {len(guns_local)}/{len(guns)}")
print(f"  items with local icon: {len(items_local)}/{len(items)}")
