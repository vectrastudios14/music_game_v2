@echo off
title Arabic Library Expansion Monitor
color 0A
cwd

:loop
cls
echo ===================================================
echo     ARABIC MUSIC LIBRARY EXPANSION MONITOR
echo ===================================================
echo.
echo [1] STATUS:
type expansion_log_arabic.txt | findstr /C:"Total Added"
echo.
echo [2] RECENT LOG ACTIVITY (Live):
echo ---------------------------------------------------
powershell -Command "Get-Content -Path 'expansion_log_arabic.txt' -Tail 15 -Wait"
goto loop
