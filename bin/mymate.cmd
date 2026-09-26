@echo off
setlocal
rem mymate.cmd - Windows shim so `mymate` works from cmd and PowerShell.
set "SCRIPT=%~dp0mymate"
set "BASH=%ProgramFiles%\Git\bin\bash.exe"
if not exist "%BASH%" set "BASH=%ProgramFiles(x86)%\Git\bin\bash.exe"
if not exist "%BASH%" set "BASH=%LOCALAPPDATA%\Programs\Git\bin\bash.exe"
if not exist "%BASH%" set "BASH=%LOCALAPPDATA%\Programs\Git\usr\bin\bash.exe"
if not exist "%BASH%" (
  echo mymate: Git for Windows bash.exe not found 1>&2
  exit /b 1
)
"%BASH%" "%SCRIPT%" %*
set "RC=%ERRORLEVEL%"
endlocal & exit /b %RC%
