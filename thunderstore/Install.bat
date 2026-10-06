@echo off
setlocal
title ReSkate Dark Pop - install
set "HERE=%~dp0"
set "GAME=%HERE%..\.."
if defined RESKATE_MOD_GAME set "GAME=%RESKATE_MOD_GAME%"

echo ReSkate Dark Pop @MOD@ (built on ReSkate @BASE@)
echo.
if not exist "%GAME%\Skate.exe" (
  echo This folder has to be inside the game's Mods folder:
  echo     ...\steamapps\common\Skate\Mods\^<author^>-ReSkate_DarkPop
  echo Move it there and run this again.
  goto :fail
)
if not exist "%GAME%\ReSkate.dll" (
  echo ReSkate is not installed in this game folder yet. Install ReSkate and run it once first.
  goto :fail
)
if not defined RESKATE_MOD_SKIP_RUNNING_CHECK (
  tasklist /FI "IMAGENAME eq Skate.exe" 2>nul | find /I "Skate.exe" >nul && (
    echo The game is running. Close it and run this again.
    goto :fail
  )
  tasklist /FI "IMAGENAME eq ReSkateLauncher.exe" 2>nul | find /I "ReSkateLauncher.exe" >nul && (
    echo The ReSkate launcher is open. Close it and run this again.
    goto :fail
  )
)
rem Keep the first ReSkate files found (the stock ones) so Uninstall.bat can put them back.
rem An existing backup is never overwritten: this mod updates itself, so the files now in the
rem game folder are not the stock ones any more.
if not exist "%HERE%backup\ReSkate.dll" (
  mkdir "%HERE%backup" 2>nul
  copy /Y "%GAME%\ReSkate.dll" "%HERE%backup\ReSkate.dll" >nul || goto :copyfail
  copy /Y "%GAME%\ReSkateLauncher.exe" "%HERE%backup\ReSkateLauncher.exe" >nul || goto :copyfail
  echo Your current ReSkate files were saved in the "backup" folder here.
)
copy /Y "%HERE%ReSkate.dll" "%GAME%\ReSkate.dll" >nul || goto :copyfail
copy /Y "%HERE%ReSkateLauncher.exe" "%GAME%\ReSkateLauncher.exe" >nul || goto :copyfail
echo.
echo Installed. Start ReSkateLauncher.exe as usual; in game press Insert, open SKATER and find the Dark Pop switches under BOOSTS.
echo To remove it, run Uninstall.bat.
echo.
pause
exit /b 0

:copyfail
echo.
echo A file could not be copied. Check that the game and the launcher are closed.
:fail
echo.
pause
exit /b 1
