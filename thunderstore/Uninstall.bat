@echo off
setlocal
title ReSkate Dark Pop - uninstall
set "HERE=%~dp0"
set "GAME=%HERE%..\.."
if defined RESKATE_MOD_GAME set "GAME=%RESKATE_MOD_GAME%"

if not exist "%HERE%backup\ReSkate.dll" (
  echo There is no backup here, so there is nothing to put back.
  echo To get stock ReSkate again, download it from the ReSkate releases page.
  goto :end
)
if not defined RESKATE_MOD_SKIP_RUNNING_CHECK (
  tasklist /FI "IMAGENAME eq Skate.exe" 2>nul | find /I "Skate.exe" >nul && (
    echo The game is running. Close it and run this again.
    goto :end
  )
  tasklist /FI "IMAGENAME eq ReSkateLauncher.exe" 2>nul | find /I "ReSkateLauncher.exe" >nul && (
    echo The ReSkate launcher is open. Close it and run this again.
    goto :end
  )
)
copy /Y "%HERE%backup\ReSkate.dll" "%GAME%\ReSkate.dll" >nul && copy /Y "%HERE%backup\ReSkateLauncher.exe" "%GAME%\ReSkateLauncher.exe" >nul && (
  echo Your previous ReSkate files are back. You can now delete this mod folder.
) || echo A file could not be copied. Check that the game and the launcher are closed.
:end
echo.
pause
