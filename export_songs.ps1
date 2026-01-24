# Export Songs from Old Dart File to New JSON Format

$sourceFile = "..\music-game-flutter\lib\data\song_data.dart"
$targetFile = "assets\songs.json"

if (-not (Test-Path $sourceFile)) {
    Write-Error "Source file not found at $sourceFile"
    exit
}

Write-Host "Reading song data..."
$content = Get-Content $sourceFile -Encoding UTF8

# Regex to capture fields
$regex = [regex]"Song\(\s*id:\s*['`"]([^'`"]*)['`"],\s*title:\s*['`"](.*?)['`"],\s*artist:\s*['`"](.*?)['`"],\s*link:\s*['`"](.*?)['`"],\s*year:\s*['`"]([^'`"]*)['`"],\s*styles:\s*(\[.*?\])"

$songs = @()

foreach ($line in $content) {
    if ($line -match "Song\(") {
        $m = $regex.Match($line)
        if ($m.Success) {
            $song = @{
                id     = $m.Groups[1].Value
                title  = $m.Groups[2].Value
                artist = $m.Groups[3].Value
                link   = $m.Groups[4].Value
                year   = $m.Groups[5].Value
                styles = $m.Groups[6].Value.Trim('[', ']') -replace "'", "" -split ", "
            }
            $songs += $song
        }
    }
}

Write-Host "Found $($songs.Count) songs."

# Convert to JSON
$json = $songs | ConvertTo-Json -Depth 5

# Ensure assets dir exists
if (-not (Test-Path "assets")) { mkdir "assets" }

$json | Set-Content $targetFile -Encoding UTF8
Write-Host "Exported to $targetFile" -ForegroundColor Green
