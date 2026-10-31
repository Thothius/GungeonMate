@echo off
title GungeonMate — Design Lab server
rem Serve gungeon_mate/ so design-lab can reach real assets (fonts, icons).
rem Lab URL: http://localhost:8619/design-lab/
cd /d "%~dp0\.."
echo Serving gungeon_mate at http://localhost:8619/design-lab/
python -m http.server 8619
pause
