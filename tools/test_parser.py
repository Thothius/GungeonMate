"""Quick test of the scrape_infobox parser against live wiki pages."""
import time
import sys
sys.path.insert(0, "tools")

# Import helpers from scrape_infobox without running main()
import importlib.util, types
spec = importlib.util.spec_from_file_location("si", "tools/scrape_infobox.py")
mod  = importlib.util.module_from_spec(spec)
spec.loader.exec_module(mod)

fetch_wikitext   = mod.fetch_wikitext
parse_infobox    = mod.parse_infobox
extract_item_fields = mod.extract_item_fields

tests = [
    "Medkit", "Bomb", "Chaff Grenade", "Aged Bell",
    "Arcane Gunpowder", "Meatbun", "Knife Shield",
    "Bullet Time", "Ice Bomb", "Supply Drop",
    # Passive/companion
    "Homing Bullets", "Ring of Mimic Friendship",
    # Guns
    "Rusty Sidearm", "Polaris",
]

print(f"{'Name':<30} {'sell':>6}  {'recharge':<20}  {'duration'}")
print("-" * 75)
for name in tests:
    wt = fetch_wikitext(name)
    if not wt:
        print(f"{name:<30}  MISS")
        continue
    f = parse_infobox(wt)
    e = extract_item_fields(f)
    sell     = e.get("sell_price", "-")
    recharge = e.get("recharge_time", "-")
    duration = e.get("duration", "-")
    print(f"{name:<30} {sell:>6}  {recharge:<20}  {duration}")
    time.sleep(0.5)
