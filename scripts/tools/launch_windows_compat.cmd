@echo off
rem Launch the exported game with a conservative renderer on older Windows 10 hardware.
setlocal
set "GAME=%~dp0MoonGame.exe"
if not exist "%GAME%" (
  echo MoonGame.exe not found next to this launcher.
  exit /b 1
)
"%GAME%" --rendering-method gl_compatibility -- --quality=low %*
exit /b %errorlevel%
