@echo off
SET mypath=%~dp0
where /q pwsh
SET exitcode=1
IF ERRORLEVEL 1 (
    powershell -noprofile -c " & ""%mypath%\.gpg-pinentry-loopback.ps1" ""%*"" "
    SET exitcode=%ERRORLEVEL%
) ELSE (
    pwsh -noprofile -c " & ""%mypath%\.gpg-pinentry-loopback.ps1"" ""%*"" "
    SET exitcode=%ERRORLEVEL%
)

IF "%exitcode%"=="1" (
  EXIT /B
)