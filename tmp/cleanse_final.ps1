$path = 'c:\Users\kishi\OneDrive\Documents\music_game_v2\assets\songs.json'
$json = Get-Content $path -Raw | ConvertFrom-Json

foreach ($song in $json) {
    if ($song.title -eq "Photograph" -and $song.artist -eq "Def Leppard") {
        if ($song.facts) {
            $newFacts = @()
            foreach ($fact in $song.facts) {
                $s = $fact
                $s = $s -replace '20th-century', 'classic'
                $newFacts += $s
            }
            $song.facts = $newFacts
        }
    }
}

$json | ConvertTo-Json -Depth 10 | Set-Content $path -Encoding utf8
Write-Output "Final Clue Removed."
