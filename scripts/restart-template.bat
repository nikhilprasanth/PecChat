@echo off
title Petrocil Chat - Restart
echo Restarting Petrocil Chat (keeps all data)...
docker compose restart api
echo Done.
pause
