@echo off

start "" "D:\Program Files\Genshin Impact\launcher.exe"
rem start "" "C:\Program Files\Genshin Impact\Genshin Impact Game\GenshinImpact.exe"
rem (<- this line is disabled)


ECHO Waiting for GenshinImpact.exe to run.

:NOTRUNNINGYET
tasklist | find /i "GenshinImpact.exe" >nul 2>&1
IF ERRORLEVEL 1 (
  Timeout /T 2 /Nobreak >nul
  GOTO NOTRUNNINGYET
) ELSE (
  ECHO GenshinImpact.exe is running now. Waiting for it to exit.
  Timeout /T 5 /Nobreak >nul
  GOTO ISRUNNINGNOW
)

:ISRUNNINGNOW
tasklist | find /i "GenshinImpact.exe" >nul 2>&1
IF ERRORLEVEL 1 (
  GOTO NOTRUNNINGANYMORE
) ELSE (
  Timeout /T 5 /Nobreak >nul
  GOTO ISRUNNINGNOW
)

:NOTRUNNINGANYMORE
ECHO.
ECHO.
ECHO GenshinImpact.exe is not running anymore. Stopping mhyprot2 now.
ECHO.
sc stop mhyprot2
Timeout /T 2 /Nobreak >nul
