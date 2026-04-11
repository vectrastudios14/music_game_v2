@echo off
echo Starting Music Library Expansion...
start /B py expand_library.py
echo Expansion process started in background.
echo.
echo Launching Dashboard...
PowerShell -ExecutionPolicy Bypass -File .\expansion_dashboard.ps1
pause
