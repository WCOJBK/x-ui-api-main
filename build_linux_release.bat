@echo off
echo ========================================
echo Enhanced API Linux Release Builder
echo ========================================
echo.

REM 设置颜色
set "GREEN=[92m"
set "RED=[91m"
set "BLUE=[94m"
set "YELLOW=[93m"
set "NC=[0m"

echo %BLUE%🔧 检查本地Go环境...%NC%
go version
if %ERRORLEVEL% neq 0 (
    echo %RED%❌ 请先安装Go语言环境%NC%
    echo 下载地址: https://golang.org/dl/
    pause
    exit /b 1
)

echo.
echo %BLUE%📂 当前目录内容：%NC%
dir /b

echo.
echo %BLUE%🔨 开始交叉编译Linux AMD64版本...%NC%

REM 设置交叉编译环境
set GOOS=linux
set GOARCH=amd64
set CGO_ENABLED=0

echo 目标平台: %GOOS%/%GOARCH%
echo CGO状态: %CGO_ENABLED%

echo.
echo %BLUE%📦 清理旧文件...%NC%
if exist "release" rmdir /s /q release
mkdir release
mkdir release\linux-amd64

echo.
echo %BLUE%📥 下载依赖...%NC%
go mod tidy
if %ERRORLEVEL% neq 0 (
    echo %RED%❌ 依赖下载失败%NC%
    pause
    exit /b 1
)

echo.
echo %BLUE%🔨 编译Enhanced API可执行文件...%NC%
go build -ldflags="-s -w -X main.version=v1.0.0-enhanced" -o release/linux-amd64/x-ui
if %ERRORLEVEL% neq 0 (
    echo %RED%❌ 编译失败%NC%
    pause
    exit /b 1
)

echo %GREEN%✅ 编译成功%NC%

echo.
echo %BLUE%📋 检查编译结果...%NC%
dir release\linux-amd64

REM 显示文件大小
for %%F in (release\linux-amd64\x-ui) do (
    set /a size=%%~zF/1024/1024
    echo 可执行文件大小: !size! MB
)

echo.
echo %BLUE%📂 复制Web资源...%NC%
if exist "web" (
    echo 复制web目录...
    xcopy /e /i /q web release\linux-amd64\web
    echo %GREEN%✅ Web资源复制完成%NC%
) else (
    echo %YELLOW%⚠️ web目录不存在，跳过%NC%
)

if exist "x-ui.sh" (
    echo 复制启动脚本...
    copy x-ui.sh release\linux-amd64\
    echo %GREEN%✅ 启动脚本复制完成%NC%
)

echo.
echo %BLUE%📦 创建部署包...%NC%

REM 创建版本信息文件
echo version=v1.0.0-enhanced > release\linux-amd64\VERSION
echo build_time=%date% %time% >> release\linux-amd64\VERSION
echo build_os=windows >> release\linux-amd64\VERSION
echo target_os=linux >> release\linux-amd64\VERSION
echo target_arch=amd64 >> release\linux-amd64\VERSION

REM 创建部署说明
echo # Enhanced API Linux Release > release\linux-amd64\README.md
echo. >> release\linux-amd64\README.md
echo ## 快速部署 >> release\linux-amd64\README.md
echo. >> release\linux-amd64\README.md
echo ```bash >> release\linux-amd64\README.md
echo # 1. 停止旧服务 >> release\linux-amd64\README.md
echo systemctl stop x-ui >> release\linux-amd64\README.md
echo. >> release\linux-amd64\README.md
echo # 2. 备份数据 >> release\linux-amd64\README.md
echo cp /usr/local/x-ui/x-ui.db /tmp/x-ui.db.backup 2^>/dev/null ^|^| true >> release\linux-amd64\README.md
echo. >> release\linux-amd64\README.md
echo # 3. 创建目录 >> release\linux-amd64\README.md
echo mkdir -p /usr/local/x-ui >> release\linux-amd64\README.md
echo. >> release\linux-amd64\README.md
echo # 4. 复制文件 >> release\linux-amd64\README.md
echo cp x-ui /usr/local/x-ui/ >> release\linux-amd64\README.md
echo chmod +x /usr/local/x-ui/x-ui >> release\linux-amd64\README.md
echo cp -r web /usr/local/x-ui/ 2^>/dev/null ^|^| true >> release\linux-amd64\README.md
echo. >> release\linux-amd64\README.md
echo # 5. 恢复数据 >> release\linux-amd64\README.md
echo cp /tmp/x-ui.db.backup /usr/local/x-ui/x-ui.db 2^>/dev/null ^|^| true >> release\linux-amd64\README.md
echo. >> release\linux-amd64\README.md
echo # 6. 启动服务 >> release\linux-amd64\README.md
echo systemctl start x-ui >> release\linux-amd64\README.md
echo ``` >> release\linux-amd64\README.md

echo.
echo %BLUE%🗜️ 创建压缩包...%NC%
cd release
powershell -Command "Compress-Archive -Path 'linux-amd64\*' -DestinationPath 'x-ui-enhanced-linux-amd64.zip'"
cd ..

if exist "release\x-ui-enhanced-linux-amd64.zip" (
    echo %GREEN%✅ 压缩包创建成功%NC%
    
    for %%F in (release\x-ui-enhanced-linux-amd64.zip) do (
        set /a zip_size=%%~zF/1024/1024
        echo 压缩包大小: !zip_size! MB
    )
) else (
    echo %RED%❌ 压缩包创建失败%NC%
)

echo.
echo %GREEN%╔════════════════════════════════════════════╗%NC%
echo %GREEN%║ 🎉 Linux Release 编译完成！               ║%NC%
echo %GREEN%║                                            ║%NC%
echo %GREEN%║ 📁 输出目录: release\linux-amd64\          ║%NC%
echo %GREEN%║ 📦 压缩包: x-ui-enhanced-linux-amd64.zip  ║%NC%
echo %GREEN%║ 🚀 可执行文件: x-ui                       ║%NC%
echo %GREEN%║                                            ║%NC%
echo %GREEN%╚════════════════════════════════════════════╝%NC%

echo.
echo %BLUE%📋 接下来的步骤：%NC%
echo 1. 上传 release/x-ui-enhanced-linux-amd64.zip 到 GitHub
echo 2. 在服务器运行部署脚本
echo 3. 享受Enhanced API功能

echo.
echo %YELLOW%💡 GitHub上传方式：%NC%
echo - 方式1: GitHub网页 → Releases → Create new release
echo - 方式2: git add release/ ^&^& git commit ^&^& git push
echo - 方式3: 使用GitHub CLI: gh release create

echo.
echo %BLUE%🔗 生成的文件：%NC%
dir release /s

echo.
pause
