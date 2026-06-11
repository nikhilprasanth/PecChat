@echo off
setlocal enabledelayedexpansion
title Petrocil Chat - Deployment Packager
color 0B

echo.
echo  ============================================
echo   Petrocil Chat  ^|  Deployment Packager
echo  ============================================
echo.

echo Checking Docker...
docker info >nul 2>&1
if errorlevel 1 (
    echo.
    echo  ERROR: Docker Desktop is not running.
    echo  Start it and try again.
    echo.
    pause
    exit /b 1
)

set "DEPLOY=%~dp0petrocil-deploy"

echo Preparing output folder...
if exist "%DEPLOY%" rd /s /q "%DEPLOY%"
for %%d in (saved-images assets data-node logs uploads images meili_data_v1.35.1 skill) do (
    mkdir "%DEPLOY%\%%d"
)

echo.
echo Saving Docker images (this takes several minutes)...
echo.

echo [1/5] LibreChat...
docker save registry.librechat.ai/danny-avila/librechat-dev:latest -o "%DEPLOY%\saved-images\librechat.tar"
if errorlevel 1 goto :err

echo [2/5] MongoDB...
docker save mongo:8.0.20 -o "%DEPLOY%\saved-images\mongodb.tar"
if errorlevel 1 goto :err

echo [3/5] Meilisearch...
docker save getmeili/meilisearch:v1.35.1 -o "%DEPLOY%\saved-images\meilisearch.tar"
if errorlevel 1 goto :err

echo [4/5] VectorDB...
docker save pgvector/pgvector:0.8.0-pg15-trixie -o "%DEPLOY%\saved-images\vectordb.tar"
if errorlevel 1 goto :err

echo [5/5] RAG API...
docker save registry.librechat.ai/danny-avila/librechat-rag-api-dev-lite:latest -o "%DEPLOY%\saved-images\rag_api.tar"
if errorlevel 1 goto :err

echo.
echo Copying assets and config...
copy "%~dp0client\public\assets\logo.png"                      "%DEPLOY%\assets\logo.png"           >nul
copy "%~dp0client\public\assets\favicon-32x32.png"            "%DEPLOY%\assets\favicon-32x32.png"   >nul
copy "%~dp0client\public\assets\favicon-16x16.png"            "%DEPLOY%\assets\favicon-16x16.png"   >nul
copy "%~dp0client\public\assets\apple-touch-icon-180x180.png" "%DEPLOY%\assets\apple-touch-icon-180x180.png" >nul
copy "%~dp0scripts\petrocil-theme.css"                        "%DEPLOY%\assets\petrocil-theme.css"  >nul
copy "%~dp0scripts\petrocil-index.html"                        "%DEPLOY%\index.html"                 >nul
copy "%~dp0.env"                                               "%DEPLOY%\.env"                       >nul
copy "%~dp0librechat.yaml"                                     "%DEPLOY%\librechat.yaml"             >nul
copy "%~dp0docker-compose.yml"                                 "%DEPLOY%\docker-compose.yml"         >nul
copy "%~dp0scripts\deploy-template.bat"                        "%DEPLOY%\deploy.bat"                 >nul
copy "%~dp0scripts\stop-template.bat"                          "%DEPLOY%\stop.bat"                   >nul
copy "%~dp0scripts\restart-template.bat"                       "%DEPLOY%\restart.bat"                >nul
copy "%~dp0scripts\deploy-override.yml"                        "%DEPLOY%\docker-compose.override.yml" >nul

echo.
echo  ============================================
echo   Package ready:  petrocil-deploy\
echo.
echo   To deploy on the air-gapped PC:
echo     1. Install Docker Desktop
echo     2. Copy the petrocil-deploy\ folder
echo     3. Double-click  deploy.bat
echo     4. Open  http://localhost:9090
echo  ============================================
echo.
pause
exit /b 0

:err
echo.
echo  ERROR: Failed to save a Docker image.
echo  Make sure Docker is running and all images
echo  are pulled  (run: docker compose pull)
echo.
pause
exit /b 1
