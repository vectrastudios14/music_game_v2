$path = 'c:\Users\kishi\OneDrive\Documents\music_game_v2\assets\songs_arabic.json'
# Re-reading with explicit UTF8
$json = Get-Content -Path $path -Raw -Encoding utf8 | ConvertFrom-Json

foreach ($song in $json) {
    if ($song.facts -and $song.facts.Count -gt 0) {
        $newFacts = @()
        
        foreach ($fact in $song.facts) {
            $s = $fact
            
            # 1. Arabic Decade Neutralization
            $s = $s -replace 'الثمانينات', 'تلك الفترة'
            $s = $s -replace 'التسعينات', 'تلك الفترة'
            $s = $s -replace 'السبعينات', 'تلك الفترة'
            $s = $s -replace 'الستينات', 'تلك الفترة'
            $s = $s -replace 'الخمسينات', 'تلك الفترة'
            $s = $s -replace 'ثمانينات', 'تلك الفترة'
            $s = $s -replace 'تسعينات', 'تلك الفترة'
            $s = $s -replace 'سبعينات', 'تلك الفترة'
            $s = $s -replace 'ستينات', 'تلك الفترة'
            $s = $s -replace 'خمسينات', 'تلك الفترة'
            
            # 2. Chronological word removal
            $s = $s -replace 'منذ', 'بعد'
            $s = $s -replace 'الألفية', 'الفترة الحديثة'
            
            # 3. Numeric Year Redaction
            # Match 19XX or 20XX and replace with "time of release" in Arabic
            $s = $s -replace '\b(19|20)\d{2}\b', 'وقت صدورها'
            
            $newFacts += $s
        }
        
        # Deduplicate
        $song.facts = $newFacts | Select-Object -Unique
    }
}

# Writing back with UTF8 NO BOM (standard for web/apps)
$jsonString = $json | ConvertTo-Json -Depth 10
[System.IO.File]::WriteAllText($path, $jsonString, [System.Text.Encoding]::UTF8)

Write-Output "Arabic Cleansing Complete."
