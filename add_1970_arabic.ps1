$jsonPath = "assets/songs_arabic.json"
$inputPath = "songs_to_add.json"

if (-not (Test-Path $inputPath)) { Write-Error "$inputPath not found"; exit }

# Load input songs
$songsToAdd = Get-Content $inputPath -Raw -Encoding UTF8 | ConvertFrom-Json

# Load existing library
if (-not (Test-Path $jsonPath)) { 
    Write-Host "Creating new library file..."
    $currentLibrary = @() 
}
else {
    $currentLibrary = Get-Content $jsonPath -Raw -Encoding UTF8 | ConvertFrom-Json
}

# Determine ID start (find max id number)
$maxId = 0
foreach ($song in $currentLibrary) {
    if ($song.id -match "ara_1970_(\d+)") {
        $num = [int]$matches[1]
        if ($num -gt $maxId) { $maxId = $num }
    }
}
$idCounter = $maxId + 1

foreach ($song in $songsToAdd) {
    try {
        # Check if already exists (by title/artist match to be extra safe)
        $existing = $currentLibrary | Where-Object { $_.title -eq $song.Title -and $_.artist -eq $song.Artist }
        if ($existing) {
            Write-Host "Skipping '$($song.Title)' - already in library." -ForegroundColor Cyan
            continue
        }

        $encodedQuery = [System.Web.HttpUtility]::UrlEncode($song.Query)
        $url = "https://itunes.apple.com/search?term=$encodedQuery&entity=song&limit=1"
        
        Write-Host "Searching for: $($song.Title)..."
        try {
            $response = Invoke-RestMethod -Uri $url -Method Get -ErrorAction Stop
        }
        catch {
            Write-Warning "iTunes API request failed for $($song.Title). Using empty metadata."
            $response = $null
        }

        $link = ""
        $artworkUrl = ""
        # Default to Arabic Classic style, can be updated later
        $styles = @("Arabic Classic")

        if ($response -and $response.resultCount -gt 0) {
            $track = $response.results[0]
            $link = $track.previewUrl
            # Get high res artwork
            if ($track.artworkUrl100) {
                $artworkUrl = $track.artworkUrl100 -replace "100x100", "600x600"
            }
        }
        else {
            Write-Warning "No iTunes match for: $($song.Title)"
        }

        # Construct new song object
        $newSong = [PSCustomObject]@{
            id         = "ara_1970_$idCounter"
            artist     = $song.Artist
            title      = $song.Title
            artistAr   = $song.ArtistAr
            titleAr    = $song.TitleAr
            year       = "1970"
            styles     = $styles
            link       = $link
            artworkUrl = $artworkUrl
            facts      = @()
            gender     = $null
        }

        $currentLibrary += $newSong
        Write-Host "Added: $($song.Title) (ID: ara_1970_$idCounter)"
        $idCounter++

    }
    catch {
        Write-Error "Error processing $($song.Title): $_"
    }
}

# Use System.IO.File for safe UTF-8 write
$utf8NoBOM = New-Object System.Text.UTF8Encoding($false)
$jsonString = $currentLibrary | ConvertTo-Json -Depth 10
[System.IO.File]::WriteAllText((Get-Item $jsonPath).FullName, $jsonString, $utf8NoBOM)

Write-Host "Done. Total songs: $($currentLibrary.Count)"
