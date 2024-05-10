@echo off
SET mypath=%~dp0
where /q pwsh
SET exitcode=1
IF ERRORLEVEL 1 (
    powershell -noprofile -c " & ""%mypath%\.kdiff3-wsl.ps1"" %* "
    SET exitcode=%ERRORLEVEL%
) ELSE (
    pwsh -noprofile -c " & ""%mypath%\.kdiff3-wsl.ps1"" %* "
    SET exitcode=%ERRORLEVEL%
)

IF "%exitcode%"=="1" (
  EXIT /B
)