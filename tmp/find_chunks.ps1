$content = Get-Content "tmp_parsed_setup_edits_utf8.txt" -Encoding utf8
foreach ($line in $content) {
    if ($line.Contains("ReplacementChunks")) {
        Write-Output "=== CHUNK ==="
        Write-Output $line
    }
}
