@echo off
chcp 65001 >nul
echo ========================================
echo Enhanced API 在线编译服务
echo ========================================
echo.

echo 💡 无需本地Go环境的编译方案
echo.

echo 🌐 方案1: GitHub Actions 自动编译
echo   - 推送代码到GitHub自动编译
echo   - 生成Linux版本到Releases

echo.
echo 🌐 方案2: 在线Go编译平台
echo   - 使用第三方在线编译服务
echo   - 支持交叉编译

echo.
echo 🌐 方案3: Docker编译（推荐）
echo   - 使用Docker容器编译
echo   - 无需安装Go环境

echo.
echo 📋 Docker编译命令:
echo docker run --rm -v "%cd%":/src -w /src golang:1.23.4 go build -ldflags="-s -w" -o x-ui-linux

echo.
echo 选择您的方案:
echo 1. 安装Go语言环境
echo 2. 使用Docker编译
echo 3. 使用GitHub Actions
echo 4. 下载预编译版本

echo.
set /p choice=请输入选项 (1-4): 

if "%choice%"=="1" (
    echo.
    echo 🔽 正在打开Go下载页面...
    start https://golang.org/dl/go1.23.4.windows-amd64.msi
    echo ✅ 安装后重启命令行并运行: .\setup_local_build_env.bat
) else if "%choice%"=="2" (
    echo.
    echo 🐳 Docker编译方案:
    echo.
    echo 1. 安装Docker Desktop: https://docker.com/products/docker-desktop
    echo 2. 运行编译命令:
    echo    docker run --rm -v "%cd%":/src -w /src golang:1.23.4 go build -ldflags="-s -w" -o x-ui-linux
    echo 3. 编译完成后上传 x-ui-linux 到服务器
) else if "%choice%"=="3" (
    echo.
    echo 🚀 GitHub Actions方案:
    echo.
    echo 1. 推送代码到GitHub
    echo 2. GitHub会自动编译并发布到Releases
    echo 3. 服务器运行: bash (curl -Ls .../deploy_from_github_release.sh)
) else if "%choice%"=="4" (
    echo.
    echo 📦 预编译版本方案:
    echo.
    echo 如果GitHub上已有发布版本，直接在服务器运行:
    echo bash ^(curl -Ls https://raw.githubusercontent.com/WCOJBK/x-ui-api-main/main/deploy_from_github_release.sh^)
)

echo.
pause
