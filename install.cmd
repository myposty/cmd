@echo off
REM Lanzador para Windows: corre install.sh con el Git Bash correcto,
REM evitando el `bash` de WSL (que en este equipo esta roto).
REM Uso desde PowerShell o CMD:   .\install.cmd     (o solo:  install)

set "GITBASH=C:\Program Files\Git\bin\bash.exe"
if not exist "%GITBASH%" set "GITBASH=%ProgramFiles%\Git\bin\bash.exe"
if not exist "%GITBASH%" (
  echo No encontre Git Bash. Instala Git para Windows: https://git-scm.com/download/win
  exit /b 1
)

"%GITBASH%" "%~dp0install.sh" %*
