$objShell = New-Object -ComObject WScript.Shell
$desktop = [Environment]::GetFolderPath('Desktop')
$shortcut = $objShell.CreateShortcut("$desktop\Musica.lnk")
$shortcut.TargetPath = "C:\Users\kishi\OneDrive\Documents\music_game_v2\build\windows\x64\runner\Release\music_game_v2.exe"
$shortcut.WorkingDirectory = "C:\Users\kishi\OneDrive\Documents\music_game_v2\build\windows\x64\runner\Release\"
$shortcut.IconLocation = "C:\Users\kishi\OneDrive\Documents\music_game_v2\windows\runner\resources\app_icon.ico"
$shortcut.Description = "Launch Musica V2"
$shortcut.Save()
