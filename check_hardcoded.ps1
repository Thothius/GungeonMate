$paths = @(
    'assets/images/items/cat_bullet_king_throne.webp',
    'assets/images/guns/gunderfury.webp',
    'assets/images/guns/triple_gun.webp',
    'assets/images/guns/evolver.webp',
    'assets/animations/Tailor_idle.gif'
)
foreach ($p in $paths) {
    $full = Join-Path 'x:\GungeonMate\gungeon_mate' $p
    if (Test-Path $full) { Write-Host "OK: $p" }
    else { Write-Host "MISSING: $p" }
}

# Check wallpaper assets
Write-Host "`n--- Wallpaper Still ---"
$stillDir = 'x:\GungeonMate\gungeon_mate\assets\images\wallpapers\still'
if (Test-Path $stillDir) {
    Get-ChildItem $stillDir | ForEach-Object { Write-Host "  $($_.Name)" }
} else {
    Write-Host "  DIR MISSING"
}

# Check animation assets
Write-Host "`n--- Animations ---"
$animDir = 'x:\GungeonMate\gungeon_mate\assets\animations'
if (Test-Path $animDir) {
    Get-ChildItem $animDir | ForEach-Object { Write-Host "  $($_.Name)" }
} else {
    Write-Host "  DIR MISSING"
}

# Check dog assets used in dice game
Write-Host "`n--- Dog Assets ---"
$dogPaths = @(
    'assets/images/dogs/dog_idle.webp',
    'assets/images/dogs/dog_happy.webp'
)
foreach ($p in $dogPaths) {
    $full = Join-Path 'x:\GungeonMate\gungeon_mate' $p
    if (Test-Path $full) { Write-Host "OK: $p" }
    else { Write-Host "MISSING: $p" }
}
