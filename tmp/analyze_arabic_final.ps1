$path = 'c:\Users\kishi\OneDrive\Documents\music_game_v2\assets\songs_arabic.json'
$outPath = 'c:\Users\kishi\OneDrive\Documents\music_game_v2\tmp\arabic_clues_review.txt'

$json = Get-Content -Path $path -Raw -Encoding utf8 | ConvertFrom-Json
$timeMatchCount = 0
$outputLines = @()

$yearRegex = '\b(19|20)\d{2}\b'
# Using Unicode escaped characters or simple patterns if literal fails
$arabicEraRegex = 'سنة|عام|عقد|قرن|الثمانينات|التسعينات'

foreach ($song in $json) {
    if ($song.facts) {
        $found = $false
        foreach ($fact in $song.facts) {
            if ($fact -match $yearRegex -or $fact -match $arabicEraRegex) { $found = $true; break }
        }
        if ($found) { 
            $timeMatchCount++ 
            $outputLines += "--- $($song.artist) - $($song.title) ---"
            foreach ($f in $song.facts) { $outputLines += $f }
            $outputLines += ""
        }
    }
}
Write-Output "Total Arabic Songs: $($json.Count)"
Write-Output "Songs with Time References: $timeMatchCount"
$outputLines | Out-File -FilePath $outPath -Encoding utf8
