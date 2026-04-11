@echo off
echo Starting Arabic Music Library Expansion...
start /B py expand_library_arabic.py
echo Arabic Expansion process started in background.
echo.
echo Launching Dashboard (Arabic)...
PowerShell -ExecutionPolicy Bypass -Command "& { \$logFile = 'expansion_log_arabic.txt'; . .\expansion_dashboard.ps1 }"
pause
