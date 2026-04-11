$logFile = "expansion_log_arabic.txt"

Write-Host "`n=== MUSIC LIBRARY EXPANSION DASHBOARD ===" -ForegroundColor Cyan
Write-Host "Monitoring $logFile..." -ForegroundColor Gray
Write-Host "Press Ctrl+C to exit dashboard (Background process will continue)" -ForegroundColor DarkGray
Write-Host "============================================`n"

if (!(Test-Path $logFile)) {
    Write-Host "Waiting for log file to be created..." -ForegroundColor Yellow
    while (!(Test-Path $logFile)) { Start-Sleep 1 }
}

Get-Content $logFile -Wait | ForEach-Object {
    if ($_ -match "\[SAFETY\]") {
        Write-Host $_ -ForegroundColor Yellow
    }
    elseif ($_ -match "\[\+\] Added") {
        Write-Host $_ -ForegroundColor Green
    }
    elseif ($_ -match "Need .* more") {
        Write-Host $_ -ForegroundColor Cyan
    }
    elseif ($_ -match "Checking album") {
        Write-Host $_ -ForegroundColor Gray
    }
    else {
        Write-Host $_
    }
}
