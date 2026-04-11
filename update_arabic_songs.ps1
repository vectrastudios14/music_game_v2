$jsonPath = "assets/songs_arabic.json"
$mdPath = "C:\Users\kishi\.gemini\antigravity\brain\a5f0ac58-4e2c-4182-b3cc-11a2c846f4ae\arabic_songs_review.md"

if (-not (Test-Path $jsonPath)) { Write-Error "$jsonPath not found"; exit }
if (-not (Test-Path $mdPath)) { Write-Error "$mdPath not found"; exit }

# Load JSON
$jsonContent = Get-Content $jsonPath -Raw -Encoding UTF8 | ConvertFrom-Json
$songsMap = @{}
foreach ($song in $jsonContent) {
    $songsMap[$song.id] = $song
}

# Read MD
$lines = Get-Content $mdPath -Encoding UTF8
$deletedCount = 0
$updatedCount = 0

$tableStarted = $false
foreach ($line in $lines) {
    if ($line.Trim().StartsWith("| DELETE |")) {
        $tableStarted = $true
        continue
    }
    if (-not $tableStarted) { continue }
    if ($line.Trim().StartsWith("| :---")) { continue }
    if (-not $line.Trim().StartsWith("|")) { continue }

    $parts = $line.Split("|")
    # 0="", 1="[ ]", 2="ID", 3="Artist", 4="Title", 5="TitleAr", 6="ArtistAr", ...
    
    if ($parts.Count -lt 7) { continue }
    
    $check = $parts[1].Trim()
    $id = $parts[2].Trim()
    $titleAr = $parts[5].Trim()
    $artistAr = $parts[6].Trim()

    if (-not $songsMap.ContainsKey($id)) { continue }

    if ($check -match "\[x\]" -or $check -match "\[X\]") {
        $songsMap.Remove($id)
        $deletedCount++
    }
    else {
        $song = $songsMap[$id]
        if ($song.titleAr -ne $titleAr -or $song.artistAr -ne $artistAr) {
            $song.titleAr = $titleAr
            $song.artistAr = $artistAr
            $updatedCount++
        }
    }
}

# Save
$finalList = $songsMap.Values | Sort-Object -Property year, id
$finalList | ConvertTo-Json -Depth 10 | Set-Content $jsonPath -Encoding UTF8

Write-Host "Success! Deleted: $deletedCount, Updated Metadata: $updatedCount"
