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
echo Loading images (skipped if already present)...
echo.

docker image inspect registry.librechat.ai/danny-avila/librechat-dev:latest >nul 2>&1
if errorlevel 1 (
    echo [1/5] LibreChat  ^(loading...^)
    docker load -i saved-images\librechat.tar
) else (
    echo [1/5] LibreChat  ^(already loaded^)
)

docker image inspect mongo:8.0.20 >nul 2>&1
if errorlevel 1 (
    echo [2/5] MongoDB  ^(loading...^)
    docker load -i saved-images\mongodb.tar
) else (
    echo [2/5] MongoDB  ^(already loaded^)
)

docker image inspect getmeili/meilisearch:v1.35.1 >nul 2>&1
if errorlevel 1 (
    echo [3/5] Meilisearch  ^(loading...^)
    docker load -i saved-images\meilisearch.tar
) else (
    echo [3/5] Meilisearch  ^(already loaded^)
)

docker image inspect pgvector/pgvector:0.8.0-pg15-trixie >nul 2>&1
if errorlevel 1 (
    echo [4/5] VectorDB  ^(loading...^)
    docker load -i saved-images\vectordb.tar
) else (
    echo [4/5] VectorDB  ^(already loaded^)
)

docker image inspect registry.librechat.ai/danny-avila/librechat-rag-api-dev-lite:latest >nul 2>&1
if errorlevel 1 (
    echo [5/5] RAG API  ^(loading...^)
    docker load -i saved-images\rag_api.tar
) else (
    echo [5/5] RAG API  ^(already loaded^)
)

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
