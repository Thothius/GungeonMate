"""Quick verification of the patched JSON data."""
import json

items = json.load(open("assets/data/items.json", encoding="utf-8"))
guns  = json.load(open("assets/data/guns.json",  encoding="utf-8"))

actives = [i for i in items if i.get("type", "").lower() == "active"]
has_recharge = sum(1 for i in actives if i.get("recharge_time"))
has_sell_items = sum(1 for i in items if i.get("sell_price"))
has_sell_guns  = sum(1 for g in guns  if g.get("sell_price"))

print(f"Active items : {len(actives)} total, {has_recharge} now have recharge_time")
print(f"Items sell_price: {has_sell_items}/{len(items)}")
print(f"Guns  sell_price: {has_sell_guns}/{len(guns)}")

print()
samples_items = ["Bomb", "Medkit", "Aged Bell", "Bullet Time", "Homing Bullets", "Knife Shield"]
for s in samples_items:
    it = next((i for i in items if i["name"] == s), None)
    if it:
        r = it.get("recharge_time", "-")
        sp = it.get("sell_price", "-")
        d  = it.get("duration", "-")
        print(f"  {s:<30} sell={sp:<4}  recharge={r:<22}  duration={d}")

print()
samples_guns = ["Polaris", "Blasphemy", "Casey", "Patriot", "Finished Gun"]
for s in samples_guns:
    g = next((g for g in guns if g["name"] == s), None)
    if g:
        sp = g.get("sell_price", "-")
        print(f"  {s:<30} sell={sp}")
