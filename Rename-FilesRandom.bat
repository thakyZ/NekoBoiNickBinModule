:: renameFilesRandom.bat  [filter]  [/s]
@echo off
setlocal disableDelayedExpansion

:: Parse and validate arguments
set "option="
set "filter="
if "%~3" neq "" (
  >&2 echo ERROR: Too many arguments
  exit /b 1
)
if /i "%~1" equ "/S" (set "option=/S") else if "%~1" neq "" set "filter=%~1"
if /i "%~2" equ "/S" (set "option=/S") else if "%~2" neq "" (
  if defined filter (
    >&2 echo ERROR: Only one filter allowed
    exit /b 1
  ) else set "filter=%~2"
)
if "%filter:~0,1%" equ "/" (
  >&2 echo ERROR: Invalid option %filter%
  exit /b 1
)
if not defined filter set "filter=*"

:: Convert a directory filter into a file filter with wildcards
if exist "%filter%\" set "filter=%filter%\*"

:: Determine source if /S option not specified
set "src="
if not defined option for /f "eol=: delims=" %%F in ("%filter%") do set "src=%%~dpF"

:: Rename the specified files
set "chars=abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
for /f "eol=: delims=" %%F in ('dir /a-d /b %option% "%filter%"') do call :renameFile "%%F"
exit /b

:renameFile
setlocal
if not defined src set "src=%~dp1"
set "old=%~nx1"
set "ext=%~x1"
setlocal enableDelayedExpansion
:retry
set "name="
for /l %%N in (1 1 8) do (
  set /a I=!random!%%36
  for %%I in (!I!) do set "name=!name!!chars:~%%I,1!"
)
if exist "!src!!name!!ext!" goto :retry
ren "!src!!old!" "!name!!ext!"