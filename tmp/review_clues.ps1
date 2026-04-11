$json = Get-Content 'c:\Users\kishi\OneDrive\Documents\music_game_v2\assets\songs.json' -Raw | ConvertFrom-Json
$outputLines = @()

$yearRegex = '\b(19|20)\d{2}\b'
$eraRegex = '\b\d{2}''?s\b|nineties|eighties|seventies|sixties|fifties|era|decade|century|millennium'

foreach ($song in $json) {
    if ($song.facts) {
        $found = $false
        foreach ($fact in $song.facts) {
            if ($fact -match $yearRegex -or $fact -match $eraRegex) {
                $found = $true
                break
            }
        }
        if ($found) {
            $outputLines += "--- $($song.artist) - $($song.title) ---"
            foreach ($fact in $song.facts) {
                $outputLines += $fact
            }
            $outputLines += ""
        }
    }
}

$outputLines | Select-Object -First 200 | Set-Content -Path 'c:\Users\kishi\OneDrive\Documents\music_game_v2\tmp\clue_facts_review.txt' -Encoding utf8
