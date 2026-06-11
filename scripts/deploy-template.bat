@echo off
title Petrocil Chat - Deploy
color 0A

echo.
echo  ============================================
echo   Petrocil Chat  ^|  Air-Gapped Deployment
echo  ============================================
echo.

echo Checking Docker Desktop...
docker info >nul 2>&1
if errorlevel 1 (
    echo.
    echo  ERROR: Docker Desktop is not running.
    echo  Start Docker Desktop then run this again.
    echo.
    pause
    exit /b 1
)

echo.
echo Loading images (this takes several minutes)...
echo.

echo [1/5] LibreChat...
docker load -i saved-images\librechat.tar

echo [2/5] MongoDB...
docker load -i saved-images\mongodb.tar

echo [3/5] Meilisearch...
docker load -i saved-images\meilisearch.tar

echo [4/5] VectorDB...
docker load -i saved-images\vectordb.tar

echo [5/5] RAG API...
docker load -i saved-images\rag_api.tar

echo.
echo Starting Petrocil Chat...
docker compose up -d

echo.
echo  ============================================
echo   Done!  Open: http://localhost:9090
echo.
echo   Make sure llama.cpp is running on
echo   port 8095 before sending messages.
echo  ============================================
echo.
pause
