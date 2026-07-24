$content = Get-Content builds/VERSION_HISTORY.md -Raw
$newEntry = @"
## **v1.8.24** - Huntress Health Stats Toggle (July 24, 2026)
**File:** TBD
**Build:** 76
### Huntress Dashboard
- Huntress dashboard now has an ALL/HP toggle button next to the header label.
- ALL mode: full pickup weight distribution (heart, key, shield, box, blank).
- HP mode: health-focused stats - heart drop chance per room, lost health without dog, heart weight, rooms per heart.
- Toggle uses animated container with filled/outlined heart icon.
- Special Panels toggle icon changed to view_agenda for better recognizability.
---

"@
$content = $newEntry + $content
Set-Content -Path builds/VERSION_HISTORY.md -Value $content -NoNewline
