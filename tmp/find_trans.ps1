$content = Get-Content "C:\Users\kishi\.gemini\antigravity\brain\86a56aea-492a-4428-aef4-d1f52f6e6d99\.system_generated\logs\transcript.jsonl" -Encoding utf8
foreach ($line in $content) {
    if ($line.Contains("setup_screen.dart") -and ($line.Contains("multi_replace_file_content") -or $line.Contains("replace_file_content"))) {
        Write-Output "--- MATCH ---"
        Write-Output $line
    }
}
