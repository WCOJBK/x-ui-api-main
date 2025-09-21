@echo off
chcp 65001 >nul
title Enhanced API Local Builder
echo ========================================
echo Enhanced API Local Builder
echo ========================================
echo.

echo 💡 Local build solution for Enhanced API
echo.

echo 🔍 1. Checking Go environment...
go version >nul 2>&1
if %ERRORLEVEL% neq 0 (
    echo ❌ Go language not installed or not in PATH
    echo.
    echo 💡 Please install Go first:
    echo   1. Visit: https://golang.org/dl/
    echo   2. Download: go1.23.4.windows-amd64.msi
    echo   3. Run installer with default settings
    echo   4. Restart command prompt
    echo.
    echo 🔗 Direct download link:
    echo https://golang.org/dl/go1.23.4.windows-amd64.msi
    echo.
    echo 🚀 Alternative: Use GitHub Actions for automatic build
    echo    Just push code to GitHub and it will build automatically
    echo.
    pause
    exit /b 1
)

for /f "tokens=*" %%i in ('go version') do set "GO_VERSION=%%i"
echo ✅ Go installed: %GO_VERSION%

echo.
echo 🛠️ 2. Setting up cross-compilation environment...
set GOOS=linux
set GOARCH=amd64
set CGO_ENABLED=0

echo Target platform: %GOOS%/%GOARCH%
echo CGO enabled: %CGO_ENABLED%

echo.
echo 📂 3. Checking project structure...
if not exist "go.mod" (
    echo ❌ go.mod not found
    echo Please run this script in the project root directory
    pause
    exit /b 1
)
echo ✅ go.mod found

if not exist "main.go" (
    echo ❌ main.go not found
    pause
    exit /b 1
)
echo ✅ main.go found

echo.
echo 📥 4. Downloading dependencies...
go mod tidy
if %ERRORLEVEL% neq 0 (
    echo ❌ Failed to download dependencies
    pause
    exit /b 1
)
echo ✅ Dependencies updated

echo.
echo 🔨 5. Building Enhanced API for Linux...
echo Building Enhanced API...
go build -ldflags="-s -w -X main.version=v1.0.0-enhanced" -o x-ui-linux
if %ERRORLEVEL% neq 0 (
    echo ❌ Build failed
    pause
    exit /b 1
)

echo ✅ Build successful!

if exist "x-ui-linux" (
    for %%F in (x-ui-linux) do (
        set /a size=%%~zF/1024/1024
        echo File size: !size! MB
    )
) else (
    echo ❌ Build file not found
    exit /b 1
)

echo.
echo 📦 6. Creating release package...
if exist "release" rmdir /s /q release
mkdir release

copy x-ui-linux release\
if exist "web" xcopy /e /i /q web release\web
if exist "*.sh" copy *.sh release\

echo version=v1.0.0-enhanced > release\VERSION
echo build_time=%date% %time% >> release\VERSION
echo build_platform=windows-local >> release\VERSION
echo target_platform=linux-amd64 >> release\VERSION

echo # Enhanced API Linux Release > release\README.md
echo. >> release\README.md
echo ## Quick Deployment >> release\README.md
echo. >> release\README.md
echo 1. Upload to server >> release\README.md
echo 2. chmod +x x-ui-linux >> release\README.md
echo 3. Run deployment script >> release\README.md

echo.
echo 🗜️ 7. Creating archive...
cd release
powershell -Command "Compress-Archive -Path '*' -DestinationPath '../x-ui-enhanced-linux-amd64.zip'"
cd ..

echo.
echo ╔════════════════════════════════════════════╗
echo ║ ✅ Enhanced API Build Complete!           ║
echo ║                                            ║
echo ║ 📁 Output: release\                        ║
echo ║ 📦 Archive: x-ui-enhanced-linux-amd64.zip ║
echo ║ 🚀 Target: Linux AMD64                    ║
echo ║                                            ║
echo ╚════════════════════════════════════════════╝

echo.
echo 📋 Next steps:
echo 1. Upload x-ui-enhanced-linux-amd64.zip to GitHub
echo 2. Run on server: 
echo    bash (curl -Ls .../deploy_from_github_release.sh)

echo.
echo 🎊 Build completed successfully!
pause
