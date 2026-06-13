"""
Scrape missing infobox fields from the ETG wiki and patch items.json / guns.json.

Fields extracted per active item:
  recharge_time  – "200 damage" / "5 kills" / "10s" / "2 rooms" / "Single-Use"
  duration       – how long the active effect lasts, if present
  sell_price     – coins the Sell Creep pays

Fields extracted per passive/companion item:
  sell_price

Fields extracted per gun:
  sell_price

Run from the gungeon_mate/ root:
  python tools/scrape_infobox.py [--dry-run] [--items-only] [--guns-only]

Progress is saved to tools/scrape_progress.json so interrupted runs resume.
Delay: 0.5s between requests to avoid hammering the wiki.
"""

import json
import re
import time
import argparse
from pathlib import Path
from urllib.request import urlopen, Request
from urllib.parse import quote
from urllib.error import HTTPError, URLError

# ── Config ──────────────────────────────────────────────────────────────────
DATA       = Path("assets/data")
PROGRESS   = Path("tools/scrape_progress.json")
API_BASE   = "https://enterthegungeon.fandom.com/api.php"
DELAY      = 0.5
MAX_RETRY  = 3
USER_AGENT = "GungeonMateDataBot/1.0 (companion app data patch)"

# JSON name -> wiki page title overrides
WIKI_NAME_MAP = {
    "C4 (Item)":          "C4",
    "Orange":             "Orange_(item)",
    "Decoy":              "Decoy_(item)",
    "Singularity":        "Singularity_(item)",
    "Box":                "Box_(item)",
    "Ticket":             "Ticket_(item)",
    "Drill":              "Drill_(item)",
    "Spice":              "Spice_(item)",
    "Shadow Clone":       "Shadow_Clone",
    "Double Vision":      "Double_Vision_(item)",
    "Boomerang":          "Boomerang_(item)",
    "Magazine Rack":      "Magazine_Rack",
}

# ── Fetch ────────────────────────────────────────────────────────────────────

def fetch_wikitext(page_title: str) -> "str | None":
    encoded = quote(page_title.replace(" ", "_"), safe=":()")
    url = (f"{API_BASE}?action=parse&page={encoded}"
           f"&prop=wikitext&format=json&redirects=1")
    for attempt in range(MAX_RETRY):
        try:
            req = Request(url, headers={"User-Agent": USER_AGENT})
            with urlopen(req, timeout=15) as resp:
                data = json.loads(resp.read().decode("utf-8"))
            if "error" in data:
                return None
            return data["parse"]["wikitext"]["*"]
        except (HTTPError, URLError, KeyError, json.JSONDecodeError) as e:
            if attempt < MAX_RETRY - 1:
                time.sleep(2 ** attempt)
            else:
                print(f"  WARN: fetch failed for '{page_title}': {e}")
                return None
    return None


# ── Infobox parser ───────────────────────────────────────────────────────────

def _split_top_level_pipes(text: str) -> list:
    """Split `text` on `|` characters that are at nesting depth 0.
    Handles nested {{ }} and [[ ]] so inner pipes are not treated as
    field separators (e.g. {{RechargeDmg|200|266}} is kept intact).
    """
    parts, buf, depth = [], [], 0
    i = 0
    while i < len(text):
        ch = text[i]
        nxt = text[i+1] if i + 1 < len(text) else ""
        if ch == "{" and nxt == "{":
            depth += 1; buf.append("{{"); i += 1
        elif ch == "}" and nxt == "}":
            depth -= 1; buf.append("}}"); i += 1
        elif ch == "[" and nxt == "[":
            depth += 1; buf.append("[["); i += 1
        elif ch == "]" and nxt == "]":
            depth -= 1; buf.append("]]"); i += 1
        elif ch == "|" and depth == 0:
            parts.append("".join(buf)); buf = []
        else:
            buf.append(ch)
        i += 1
    if buf:
        parts.append("".join(buf))
    return parts


def _interpret_recharge(raw: str) -> str:
    """Turn ETG wiki recharge templates into human-readable strings.

    ETG wiki uses:
      {{RechargeDmg|N|...}} – N damage dealt to enemies (Normal difficulty)
      {{RechargeSec|N|...}} – N seconds
      {{RechargeKill|N|...}} – N kills
      {{RechargeRoom|N|...}} – 1 room (N is usually 1)
      Single-Use             – consumed on use
    """
    raw = raw.strip()

    # Template-based recharge
    m = re.search(r"\{\{Recharge(Dmg|Sec|Kill|Room)\|(\d+(?:\.\d+)?)", raw, re.IGNORECASE)
    if m:
        kind = m.group(1).lower()
        val  = m.group(2)
        # Remove trailing .0
        if val.endswith(".0"):
            val = val[:-2]
        if kind == "dmg":
            return f"{val} damage"
        if kind == "sec":
            return f"{val}s"
        if kind == "kill":
            return f"{val} kills"
        if kind == "room":
            return f"{val} room{'s' if val != '1' else ''}"

    # Plain text — strip wiki markup first
    plain = re.sub(r"\{\{[^}]*\}\}", "", raw)          # remove remaining templates
    plain = re.sub(r"\[\[(?:[^|\]]*\|)?([^\]]+)\]\]", r"\1", plain)  # links
    plain = re.sub(r"<[^>]+>", "", plain)
    plain = re.sub(r"\s+", " ", plain).strip()

    if not plain:
        return ""
    return plain


def parse_infobox(wikitext: str) -> dict:
    """Extract the first infobox block and return a key→value dict.
    Handles ETG's inline multi-field lines (|sold=16|quality={{...}}}).
    """
    # Find the first top-level {{ ... }} block
    depth, start, end = 0, -1, -1
    for i in range(len(wikitext) - 1):
        if wikitext[i:i+2] == "{{":
            if depth == 0: start = i
            depth += 1
        elif wikitext[i:i+2] == "}}":
            depth -= 1
            if depth == 0: end = i + 2; break
    if start == -1 or end == -1:
        return {}

    # Strip the outer {{ ... }} delimiters so the field-separator pipes
    # inside the infobox are at depth 0 for _split_top_level_pipes.
    block = wikitext[start + 2 : end - 2]
    segments = _split_top_level_pipes(block)

    fields: dict = {}
    for seg in segments:
        seg = seg.strip()
        if "=" not in seg:
            continue
        key, _, val = seg.partition("=")
        key = key.strip().lower()
        val = val.strip()
        if key and val:
            fields[key] = val

    return fields


def extract_item_fields(fields: dict) -> dict:
    result: dict = {}

    # Sell price: ETG wiki uses "sold"
    for k in ("sold", "sell creep price", "sell price", "sell_price", "value"):
        v = fields.get(k, "").strip()
        if v:
            m = re.match(r"(\d+)", v)
            if m:
                result["sell_price"] = m.group(1)
            break

    # Recharge
    for k in ("recharge", "active recharge", "charge"):
        v = fields.get(k, "").strip()
        if v:
            interpreted = _interpret_recharge(v)
            if interpreted:
                result["recharge_time"] = interpreted
            break

    # Duration
    for k in ("duration", "active duration", "effect duration"):
        v = fields.get(k, "").strip()
        if v:
            clean = re.sub(r"\{\{[^}]*\}\}", "", v)
            clean = re.sub(r"\s+", " ", clean).strip()
            if clean:
                result["duration"] = clean
            break

    return result


# ── Main ─────────────────────────────────────────────────────────────────────

def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--dry-run",    action="store_true",
                    help="Print changes without writing to disk")
    ap.add_argument("--items-only", action="store_true")
    ap.add_argument("--guns-only",  action="store_true")
    args = ap.parse_args()

    progress: dict = {}
    if PROGRESS.exists():
        try:
            progress = json.loads(PROGRESS.read_text(encoding="utf-8"))
        except Exception:
            progress = {}

    items_data = json.loads((DATA / "items.json").read_text(encoding="utf-8"))
    guns_data  = json.loads((DATA / "guns.json").read_text(encoding="utf-8"))

    items_changed = guns_changed = 0

    # ── ITEMS ────────────────────────────────────────────────────────────────
    if not args.guns_only:
        print(f"\n{'='*60}")
        print(f"Scraping {len(items_data)} items...")
        print("=" * 60)
        for item in items_data:
            name = item["name"]
            cached = progress.get(f"item:{name}")
            if cached is not None:
                for k, v in cached.items():
                    if not item.get(k):
                        item[k] = v
                continue

            wiki_title = WIKI_NAME_MAP.get(name, name)
            print(f"  {name} -> {wiki_title}", end="  ", flush=True)
            time.sleep(DELAY)

            wt = fetch_wikitext(wiki_title)
            if wt is None:
                print("MISS")
                progress[f"item:{name}"] = {}
                continue

            extracted = extract_item_fields(parse_infobox(wt))
            progress[f"item:{name}"] = extracted

            changed = []
            for k, v in extracted.items():
                if not item.get(k):
                    item[k] = v
                    changed.append(f"{k}={v!r}")
                    items_changed += 1
            print(f"OK  {', '.join(changed) if changed else '(no new fields)'}")

            if not args.dry_run:
                PROGRESS.write_text(
                    json.dumps(progress, indent=2, ensure_ascii=False),
                    encoding="utf-8"
                )

    # ── GUNS ─────────────────────────────────────────────────────────────────
    if not args.items_only:
        print(f"\n{'='*60}")
        print(f"Scraping {len(guns_data)} guns...")
        print("=" * 60)
        for gun in guns_data:
            name = gun["name"]
            cached = progress.get(f"gun:{name}")
            if cached is not None:
                for k, v in cached.items():
                    if not gun.get(k):
                        gun[k] = v
                continue

            wiki_title = WIKI_NAME_MAP.get(name, name)
            print(f"  {name} -> {wiki_title}", end="  ", flush=True)
            time.sleep(DELAY)

            wt = fetch_wikitext(wiki_title)
            if wt is None:
                print("MISS")
                progress[f"gun:{name}"] = {}
                continue

            # For guns, only pull sell_price
            all_fields = extract_item_fields(parse_infobox(wt))
            extracted  = {k: v for k, v in all_fields.items() if k == "sell_price"}
            progress[f"gun:{name}"] = extracted

            changed = []
            for k, v in extracted.items():
                if not gun.get(k):
                    gun[k] = v
                    changed.append(f"{k}={v!r}")
                    guns_changed += 1
            print(f"OK  {', '.join(changed) if changed else '(no new fields)'}")

            if not args.dry_run:
                PROGRESS.write_text(
                    json.dumps(progress, indent=2, ensure_ascii=False),
                    encoding="utf-8"
                )

    # ── Summary & write ───────────────────────────────────────────────────────
    print(f"\n{'='*60}")
    print(f"Items: {items_changed} fields added")
    print(f"Guns:  {guns_changed} fields added")

    if args.dry_run:
        print("DRY RUN -- nothing written.")
        return

    if not args.guns_only:
        bak = DATA / "items.json.bak"
        (DATA / "items.json").rename(bak)
        (DATA / "items.json").write_text(
            json.dumps(items_data, indent=2, ensure_ascii=False),
            encoding="utf-8",
        )
        print(f"Written items.json  (backup: {bak})")

    if not args.items_only:
        bak = DATA / "guns.json.bak"
        (DATA / "guns.json").rename(bak)
        (DATA / "guns.json").write_text(
            json.dumps(guns_data, indent=2, ensure_ascii=False),
            encoding="utf-8",
        )
        print(f"Written guns.json   (backup: {bak})")


if __name__ == "__main__":
    main()
