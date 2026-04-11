$path = 'c:\Users\kishi\OneDrive\Documents\music_game_v2\assets\songs.json'
$json = Get-Content $path -Raw | ConvertFrom-Json

foreach ($song in $json) {
    if ($song.facts -ne $null) {
        # Check if it's already an array/list. 
        # In PowerShell, we can check basic types.
        if ($song.facts -is [string]) {
            $song.facts = @($song.facts)
        }
    } else {
        $song.facts = @()
    }
}

# Use -Depth to ensure it doesn't truncate sub-objects
$json | ConvertTo-Json -Depth 10 | Set-Content $path -Encoding utf8
Write-Output "Library Data Structure Restored."
