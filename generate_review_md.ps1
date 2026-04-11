$jsonPath = "assets/songs_arabic.json"
$mdPath = "C:\Users\kishi\.gemini\antigravity\brain\a5f0ac58-4e2c-4182-b3cc-11a2c846f4ae\arabic_songs_review.md"

if (-not (Test-Path $jsonPath)) { Write-Error "$jsonPath not found"; exit }

# Load JSON
$songs = Get-Content $jsonPath -Raw -Encoding UTF8 | ConvertFrom-Json

# Sort by Year, then ID
$songs = $songs | Sort-Object -Property year, id

# Build Markdown Content
$mdContent = @"
# Arabic Songs Library Review (Round 2)

Please review the remaining Arabic songs.
- To **DELETE** a song, mark the checkbox [x].
- To **UPDATE** the Arabic metadata, edit the `Title (Ar)` and `Artist (Ar)` columns.
- Click the **Link** to preview the song.

| DELETE | ID | Artist (En) | Title (En) | Title (Ar) | Artist (Ar) | Link |
| :---: | :--- | :--- | :--- | :--- | :--- | :--- |
"@

foreach ($song in $songs) {
    $artist = $song.artist
    $title = $song.title
    $titleAr = if ($song.titleAr) { $song.titleAr } else { $song.title }
    $artistAr = if ($song.artistAr) { $song.artistAr } else { $song.artist }
    $link = $song.link
    $id = $song.id

    $mdContent += "`n| [ ] | $id | $artist | $title | $titleAr | $artistAr | [Play]($link) |"
}

$mdContent += "`n"
$mdContent | Set-Content $mdPath -Encoding UTF8

Write-Host "Regenerated review file with $($songs.Count) songs."
