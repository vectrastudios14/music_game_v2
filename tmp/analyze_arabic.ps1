$json = Get-Content 'c:\Users\kishi\OneDrive\Documents\music_game_v2\assets\songs_arabic.json' -Raw | ConvertFrom-Json
$timeMatchCount = 0
$outputLines = @()

# Updated regex for Arabic years and era words
$yearRegex = '\b(19|20)\d{2}\b'
$arabicEraRegex = 'سنة|عام|عقد|قرن|الألفية|الثمانينات|التسعينات|السبعينات|الستينات|الخمسينات|حقبة|عشر سنوات|منذ'

foreach ($song in $json) {
    if ($song.facts) {
        $found = $false
        foreach ($fact in $song.facts) {
            if ($fact -match $yearRegex -or $fact -match $arabicEraRegex) {
                $found = $true
                break
            }
        }
        if ($found) { 
            $timeMatchCount++ 
            $outputLines += "--- $($song.artist) - $($song.title) ---"
            foreach ($fact in $song.facts) { $outputLines += $fact }
            $outputLines += ""
        }
    }
}
Write-Output "Total Arabic Songs: $($json.Count)"
Write-Output "Songs with Time References: $timeMatchCount"
$outputLines | Set-Content -Path 'c:\Users\kishi\OneDrive\Documents\music_game_v2\tmp\arabic_clues_review.txt' -Encoding utf8
