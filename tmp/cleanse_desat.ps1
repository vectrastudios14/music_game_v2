$path = 'c:\Users\kishi\OneDrive\Documents\music_game_v2\assets\songs.json'
$json = Get-Content $path -Raw | ConvertFrom-Json

foreach ($song in $json) {
    if ($song.facts -and $song.facts.Count -gt 0) {
        $cleanFacts = @()
        
        foreach ($fact in $song.facts) {
            $s = $fact
            
            # 1. Neutralize chrono-words
            $s = $s -replace 'the era', 'the period'
            $s = $s -replace 'its era', 'the time'
            $s = $s -replace 'the decade', 'history'
            $s = $s -replace 'past century', 'years past'
            $s = $s -replace 'modern era', 'modern music'
            $s = $s -replace 'landmark era', 'landmark moment'
            $s = $s -replace 'golden era', 'heyday'
            $s = $s -replace 'the game section', 'the game'
            
            # 2. Catch any lingering numbers (1900-2099)
            $s = $s -replace '\b(19|20)\d{2}\b', '[TIME]'
            $s = $s -replace '\[TIME\]', 'its release' # Final polish

            $cleanFacts += $s
        }
        
        $song.facts = $cleanFacts | Select-Object -Unique
    }
}

$json | ConvertTo-Json -Depth 10 | Set-Content $path -Encoding utf8
Write-Output "Deep Desat Complete."
