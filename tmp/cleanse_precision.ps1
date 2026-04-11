$path = 'c:\Users\kishi\OneDrive\Documents\music_game_v2\assets\songs.json'
$json = Get-Content $path -Raw | ConvertFrom-Json

foreach ($song in $json) {
    if ($song.facts -and $song.facts.Count -gt 0) {
        $cleanFacts = @()
        
        foreach ($fact in $song.facts) {
            $s = $fact
            
            # 1. Fix the "erat" and "st/nd/rd" artifacts
            $s = $s -replace 'erat century', 'modern era'
            $s = $s -replace '21st century', 'modern era'
            $s = $s -replace '20th century', 'past century'
            
            # 2. Broader Era patterns
            $s = $s -replace '(mid|early|late)-\d{2}''?s', 'its era'
            $s = $s -replace '(mid|early|late) \d{2}''?s', 'its era'
            $s = $s -replace '\b\d{2}''?s\b', 'its era'
            $s = $s -replace 'the era section', 'the game'
            $s = $s -replace 'the era era', 'the time'
            
            # 3. Handle [YEAR] placeholders
            # "Won a Grammy in [YEAR]" -> "Won a Grammy"
            $s = $s -replace ' in \[YEAR\]', ''
            $s = $s -replace ' from \[YEAR\]', ''
            $s = $s -replace ' back in \[YEAR\]', ''
            $s = $s -replace ' of \[YEAR\]', ''
            $s = $s -replace ' \(\[YEAR\]\)', ''
            $s = $s -replace '\[YEAR\] ', ''
            $s = $s -replace '\[YEAR\]', 'its release' # Fallback
            
            # 4. Relative Dating
            $s = $s -replace 'a decade after', 'years after'
            $s = $s -replace 'several years after', 'after'
            
            # 5. Specific Song Fixes (Manually found in review)
            if ($song.title -eq "Summer of '69") {
                $s = "The song's title actually refers to a specific feeling of youth and summer, rather than a calendar year."
            }
            
            $cleanFacts += $s
        }
        
        # Deduplicate and remove empty/redundant facts
        $finalFacts = $cleanFacts | Select-Object -Unique
        $song.facts = $finalFacts
    }
}

$json | ConvertTo-Json -Depth 10 | Set-Content $path -Encoding utf8
Write-Output "Precision Cleansing Complete."
