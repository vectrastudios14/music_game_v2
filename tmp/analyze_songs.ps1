$json = Get-Content 'c:\Users\kishi\OneDrive\Documents\music_game_v2\assets\songs.json' -Raw | ConvertFrom-Json
$timeMatchCount = 0
foreach ($song in $json) {
    if ($song.facts) {
        $found = $false
        foreach ($fact in $song.facts) {
            # Use \b for era/decade to avoid matching generation/literature
            if ($fact -match '\b(19|20)\d{2}\b' -or $fact -match '\b\d{2}''?s\b|nineties|eighties|seventies|sixties|fifties|\bera\b|\bdecade\b|century|millennium') {
                $found = $true
                break
            }
        }
        if ($found) { $timeMatchCount++ }
    }
}
Write-Output "Total English Songs: $($json.Count)"
Write-Output "Songs with Time References: $timeMatchCount"
