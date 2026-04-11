$json = Get-Content 'c:\Users\kishi\OneDrive\Documents\music_game_v2\assets\songs.json' -Raw | ConvertFrom-Json
$matchingSongs = @()

$yearRegex = '\b(19|20)\d{2}\b'
$eraRegex = '\b\d{2}''?s\b|nineties|eighties|seventies|sixties|fifties|era|decade|century|millennium'

foreach ($song in $json) {
    if ($song.facts) {
        $hasTimeClue = $false
        foreach ($fact in $song.facts) {
            if ($fact -match $yearRegex -or $fact -match $eraRegex) {
                $hasTimeClue = $true
                break
            }
        }
        if ($hasTimeClue) {
            $matchingSongs += $song
        }
    }
}

# Export matching songs to a JSON for review
$matchingSongs | ConvertTo-Json -Depth 10 | Out-File 'c:\Users\kishi\OneDrive\Documents\music_game_v2\tmp\songs_to_fix.json'
Write-Output "Found $($matchingSongs.Count) songs to fix."
