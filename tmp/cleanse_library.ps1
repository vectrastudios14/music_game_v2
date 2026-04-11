$path = 'c:\Users\kishi\OneDrive\Documents\music_game_v2\assets\songs.json'
$json = Get-Content $path -Raw | ConvertFrom-Json

$yearRegex = '\b(19|20)\d{2}\b'
$eraRegex = '\b\d{2}''?s\b|nineties|eighties|seventies|sixties|fifties|era|decade|century|millennium'

foreach ($song in $json) {
    if ($song.facts -and $song.facts.Count -gt 0) {
        $newFacts = @()
        $badFacts = @()
        $cleanFacts = @()

        # Categorize existing facts
        foreach ($fact in $song.facts) {
            if ($fact -match $yearRegex -or $fact -match $eraRegex) {
                $badFacts += $fact
            } else {
                $cleanFacts += $fact
            }
        }

        # Logic: 
        # 1. If we have clean facts, just use those and discard bad ones
        # 2. If we ONLY have bad facts, try to sanitize them
        
        if ($cleanFacts.Count -gt 0) {
            $newFacts = $cleanFacts
        } else {
            foreach ($fact in $badFacts) {
                $sanitized = $fact
                
                # REPLACEMENTS
                # Specific Year redactions
                $sanitized = $sanitized -replace 'in (19|20)\d{2}', 'upon release'
                $sanitized = $sanitized -replace 'since (19|20)\d{2}', 'since release'
                $sanitized = $sanitized -replace 'from (19|20)\d{2}', 'from that era'
                $sanitized = $sanitized -replace 'back in (19|20)\d{2}', 'back then'
                $sanitized = $sanitized -replace '(19|20)\d{2} Grammy', 'Grammy'
                $sanitized = $sanitized -replace 'the (19|20)\d{2} film', 'the film'
                $sanitized = $sanitized -replace '\b(19|20)\d{2}\b', '[YEAR]' # Fallback for unknown patterns
                
                # Era redactions
                $sanitized = $sanitized -replace 'the \d{2}''?s', 'the era'
                $sanitized = $sanitized -replace 'the nineties', 'the era'
                $sanitized = $sanitized -replace 'the eighties', 'the era'
                $sanitized = $sanitized -replace 'the seventies', 'the era'
                $sanitized = $sanitized -replace 'the sixties', 'the era'
                
                $newFacts += $sanitized
            }
        }

        # Update the song object
        $song.facts = $newFacts
    }
}

# Save the updated library
$json | ConvertTo-Json -Depth 10 | Set-Content $path -Encoding utf8
Write-Output "Cleansing Complete."
