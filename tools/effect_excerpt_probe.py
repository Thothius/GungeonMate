"""Sanity-check the effect-tagger excerpt extraction against the real
items.json / guns.json data.

Prints ~15 sample matches so we can confirm excerpts actually carry
numbers (percentages, magnitudes) through to the UI.
"""
import json
import re

SPLIT = re.compile(r'(?:\. |[;\n])\s*')

patterns = {
    'damage_up': [r'increase[sd]? (bullet )?damage(?! (taken|resistance))',
                  r'\+\s*\d+%?\s*damage'],
    'fire_rate_up': [r'increase[sd]? (rate of fire|fire rate)',
                     r'fires? faster'],
    'freeze': [r'freeze[s]? enemies', r'chance to freeze'],
    'heal': [r'heal[s]? (half )?a? heart', r'chance to get hearts'],
    'speed_up': [r'\+\s*\d+%?\s*movement speed',
                 r'increase[sd]? .{0,20}movement speed'],
}


def excerpt_for(text, pats):
    for raw in SPLIT.split(text):
        s = raw.strip()
        if not s:
            continue
        for p in pats:
            if re.search(p, s, re.I):
                clean = re.sub(r'[.;]+$', '', s).strip()
                if len(clean) > 110:
                    clean = clean[:108].rstrip() + '...'
                return clean
    return ''


def run():
    items = json.load(open('assets/data/items.json', encoding='utf-8'))
    guns = json.load(open('assets/data/guns.json', encoding='utf-8'))
    printed = 0
    for src, key in ((items, 'effect'), (guns, 'notes')):
        for entry in src:
            txt = entry.get(key, '')
            if not txt:
                continue
            for tag_id, pats in patterns.items():
                if any(re.search(p, txt, re.I) for p in pats):
                    ex = excerpt_for(txt, pats)
                    if ex:
                        name = entry['name'][:22]
                        print(f'{tag_id:14s} | {name:22s} -> {ex}')
                        printed += 1
                    break
            if printed >= 15:
                return


if __name__ == '__main__':
    run()
