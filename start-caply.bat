@echo off
REM ── Caply local server ──
REM The on-device AI needs the app served over http(s), not opened as a file.
cd /d "%~dp0"
echo Starting Caply at http://localhost:8765 ...
start "" http://localhost:8765

where python >nul 2>nul
if %errorlevel%==0 (
  python -m http.server 8765
  goto :eof
)
where py >nul 2>nul
if %errorlevel%==0 (
  py -m http.server 8765
  goto :eof
)
where npx >nul 2>nul
if %errorlevel%==0 (
  npx --yes serve -l 8765 .
  goto :eof
)
echo Could not find Python or Node. Install one of them, or host the folder on GitHub Pages.
pause
