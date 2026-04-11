$path = 'c:\Users\kishi\OneDrive\Documents\music_game_v2\assets\songs.json'
$json = Get-Content $path -Raw | ConvertFrom-Json

foreach ($song in $json) {
    if ($song.facts -and $song.facts.Count -gt 0) {
        $cleanFacts = @()
        
        foreach ($fact in $song.facts) {
            $s = $fact
            
            # 1. Broad Era patterns with strict word boundaries
            # Handle "the time R&B era" and other artifacts first
            $s = $s -replace 'the time R&B era', 'R&B history'
            $s = $s -replace 'the time track', 'classic track'
            $s = $s -replace 'the time dance scene', 'dance scene'
            $s = $s -replace 'the time ''Baby-Making'' R&B era', 'Baby-Making R&B style'
            
            # Clean up the word "era" and "decade" specifically
            # We use \b to avoid matching "generation"
            $s = $s -replace '\bthe era\b', 'the period'
            $s = $s -replace '\bits era\b', 'the time'
            $s = $s -replace '\bdecade\b', 'period'
            $s = $s -replace '\bera\b', 'period'
            
            # Fix "erat century" which was a bug from 21st -> era-t
            $s = $s -replace 'erat century', 'modern period'
            $s = $s -replace 'erat', 'period'
            
            # 2. Final Year check (ensure no 4-digit years remain)
            $s = $s -replace '\b(19|20)\d{2}\b', 'release'

            $cleanFacts += $s
        }
        
        $song.facts = $cleanFacts | Select-Object -Unique
    }
}

$json | ConvertTo-Json -Depth 10 | Set-Content $path -Encoding utf8
Write-Output "Surgical Cleanup Complete."
