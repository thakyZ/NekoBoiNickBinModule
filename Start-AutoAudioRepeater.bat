@echo off
SET mypath=%~dp0
::ECHO %mypath:~0,-1%
::START /min "" "C:\Progra~1\Virtual Audio Cable\audiorepeater.exe" /Config:"%mypath:~0,-1%\AutoAudioRepeater.cfg" /AutoStart
pwsh -NoProfile -Command "%mypath:~0,-1%\Start-AutoAudioRepeater.ps1"