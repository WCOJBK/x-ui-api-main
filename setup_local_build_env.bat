@echo off
title Enhanced API Local Build Environment Setup
echo ========================================
echo Enhanced API 本地编译环境设置
echo ========================================

REM 设置颜色变量
set "GREEN=[92m"
set "RED=[91m"
set "BLUE=[94m"
set "YELLOW=[93m"
set "PURPLE=[95m"
set "CYAN=[96m"
set "NC=[0m"

echo.
echo %PURPLE%🔧 本地编译环境设置向导%NC%
echo %PURPLE%为Windows开发者提供Linux交叉编译环境%NC%

echo.
echo %BLUE%📋 设置内容：%NC%
echo 1. 检查Go语言环境
echo 2. 配置交叉编译环境变量
echo 3. 验证项目结构
echo 4. 测试编译功能
echo 5. 生成发布脚本

echo.
echo %BLUE%🔍 1. 检查Go语言环境...%NC%

REM 检查Go是否安装
go version >nul 2>&1
if %ERRORLEVEL% neq 0 (
    echo %RED%❌ Go语言未安装或不在PATH中%NC%
    echo.
    echo %YELLOW%💡 请先安装Go语言：%NC%
    echo   1. 访问: https://golang.org/dl/
    echo   2. 下载Windows版本 ^(推荐go1.23.4^)
    echo   3. 运行安装程序
    echo   4. 重启命令提示符
    echo.
    echo %BLUE%🔗 直接下载链接：%NC%
    echo https://golang.org/dl/go1.23.4.windows-amd64.msi
    echo.
    pause
    exit /b 1
) else (
    for /f "tokens=*" %%i in ('go version') do set "GO_VERSION=%%i"
    echo %GREEN%✅ Go语言已安装: !GO_VERSION!%NC%
)

REM 检查Go版本
for /f "tokens=3" %%a in ('go version') do set "VERSION_NUMBER=%%a"
echo Go版本号: %VERSION_NUMBER%

REM 检查是否为推荐版本
echo %VERSION_NUMBER% | findstr /C:"go1.23" >nul
if %ERRORLEVEL% equ 0 (
    echo %GREEN%✅ Go版本兼容%NC%
) else (
    echo %YELLOW%⚠️ 推荐使用Go 1.23.x版本以获得最佳兼容性%NC%
)

echo.
echo %BLUE%🛠️ 2. 配置交叉编译环境...%NC%

REM 检查当前GOOS和GOARCH
for /f "tokens=*" %%i in ('go env GOOS') do set "CURRENT_GOOS=%%i"
for /f "tokens=*" %%i in ('go env GOARCH') do set "CURRENT_GOARCH=%%i"

echo 当前编译目标: %CURRENT_GOOS%/%CURRENT_GOARCH%
echo 目标编译平台: linux/amd64

REM 设置环境变量文件
echo %GREEN%设置交叉编译环境变量...%NC%

echo @echo off > set_cross_compile.bat
echo REM Enhanced API Cross Compile Environment >> set_cross_compile.bat
echo set GOOS=linux >> set_cross_compile.bat
echo set GOARCH=amd64 >> set_cross_compile.bat
echo set CGO_ENABLED=0 >> set_cross_compile.bat
echo echo 交叉编译环境已设置: %%GOOS%%/%%GOARCH%% ^(CGO: %%CGO_ENABLED%%^) >> set_cross_compile.bat

echo %GREEN%✅ 交叉编译配置文件已创建: set_cross_compile.bat%NC%

echo.
echo %BLUE%📂 3. 验证项目结构...%NC%

REM 检查关键文件
set "REQUIRED_FILES=go.mod main.go"
set "OPTIONAL_DIRS=web database config"

echo 检查必需文件...
for %%f in (%REQUIRED_FILES%) do (
    if exist "%%f" (
        echo %GREEN%✅ %%f%NC%
    ) else (
        echo %RED%❌ %%f 不存在%NC%
        set "MISSING_FILES=1"
    )
)

echo.
echo 检查可选目录...
for %%d in (%OPTIONAL_DIRS%) do (
    if exist "%%d\" (
        echo %GREEN%✅ %%d\%NC%
        dir "%%d" /b | find /c /v "" > temp_count.txt
        set /p FILE_COUNT=<temp_count.txt
        echo     ^|- 包含 !FILE_COUNT! 个文件
        del temp_count.txt
    ) else (
        echo %YELLOW%⚠️ %%d\ 不存在%NC%
    )
)

if defined MISSING_FILES (
    echo.
    echo %RED%❌ 项目结构不完整%NC%
    echo %BLUE%💡 请确保在正确的项目目录中运行此脚本%NC%
    pause
    exit /b 1
)

echo.
echo %BLUE%🧪 4. 测试编译功能...%NC%

REM 设置测试编译环境
call set_cross_compile.bat

echo 开始测试编译...
echo %CYAN%编译命令: go build -ldflags="-s -w" -o test-x-ui%NC%

go build -ldflags="-s -w" -o test-x-ui 2>build_error.log
if %ERRORLEVEL% equ 0 (
    echo %GREEN%✅ 测试编译成功%NC%
    
    REM 检查生成的文件
    if exist "test-x-ui" (
        for %%F in (test-x-ui) do (
            set /a size=%%~zF/1024/1024
            echo 生成文件大小: !size! MB
        )
        
        REM 清理测试文件
        del test-x-ui
    )
    
    REM 清理错误日志
    if exist "build_error.log" del build_error.log
    
) else (
    echo %RED%❌ 测试编译失败%NC%
    echo.
    echo %YELLOW%错误信息：%NC%
    if exist "build_error.log" (
        type build_error.log
        del build_error.log
    )
    echo.
    echo %BLUE%💡 可能的解决方案：%NC%
    echo 1. 运行 go mod tidy 更新依赖
    echo 2. 检查代码语法错误
    echo 3. 确保所有import路径正确
    echo.
    pause
    exit /b 1
)

echo.
echo %BLUE%📦 5. 生成便捷脚本...%NC%

REM 生成快速编译脚本
echo %GREEN%创建快速编译脚本...%NC%

echo @echo off > quick_build.bat
echo title Enhanced API Quick Build >> quick_build.bat
echo echo ===================================== >> quick_build.bat
echo echo Enhanced API 快速编译 Linux 版本 >> quick_build.bat
echo echo ===================================== >> quick_build.bat
echo echo. >> quick_build.bat
echo call set_cross_compile.bat >> quick_build.bat
echo echo. >> quick_build.bat
echo echo 正在编译 Enhanced API Linux 版本... >> quick_build.bat
echo echo. >> quick_build.bat
echo go build -ldflags="-s -w -X main.version=v1.0.0-enhanced" -o x-ui-linux >> quick_build.bat
echo if %%ERRORLEVEL%% equ 0 ^( >> quick_build.bat
echo     echo [92m✅ 编译成功！[0m >> quick_build.bat
echo     echo. >> quick_build.bat
echo     echo 生成文件: x-ui-linux >> quick_build.bat
echo     for %%%%F in ^(x-ui-linux^) do ^( >> quick_build.bat
echo         set /a size=%%%%~zF/1024/1024 >> quick_build.bat
echo         echo 文件大小: ^^!size^^! MB >> quick_build.bat
echo     ^) >> quick_build.bat
echo     echo. >> quick_build.bat
echo     echo [94m📦 打包命令：[0m >> quick_build.bat
echo     echo tar -czf x-ui-enhanced-linux-amd64.tar.gz x-ui-linux web/ >> quick_build.bat
echo     echo. >> quick_build.bat
echo ^) else ^( >> quick_build.bat
echo     echo [91m❌ 编译失败[0m >> quick_build.bat
echo ^) >> quick_build.bat
echo pause >> quick_build.bat

echo %GREEN%✅ 快速编译脚本已创建: quick_build.bat%NC%

REM 生成完整打包脚本
echo %GREEN%创建完整打包脚本...%NC%

echo @echo off > package_release.bat
echo title Enhanced API Release Packager >> package_release.bat
echo echo ===================================== >> package_release.bat
echo echo Enhanced API 完整发布打包 >> package_release.bat
echo echo ===================================== >> package_release.bat
echo echo. >> package_release.bat
echo call set_cross_compile.bat >> package_release.bat
echo echo. >> package_release.bat
echo echo 清理旧文件... >> package_release.bat
echo if exist "release" rmdir /s /q release >> package_release.bat
echo mkdir release >> package_release.bat
echo echo. >> package_release.bat
echo echo 编译 Enhanced API... >> package_release.bat
echo go build -ldflags="-s -w -X main.version=v1.0.0-enhanced" -o release/x-ui >> package_release.bat
echo if %%ERRORLEVEL%% neq 0 ^( >> package_release.bat
echo     echo [91m❌ 编译失败[0m >> package_release.bat
echo     pause >> package_release.bat
echo     exit /b 1 >> package_release.bat
echo ^) >> package_release.bat
echo echo [92m✅ 编译成功[0m >> package_release.bat
echo echo. >> package_release.bat
echo echo 复制资源文件... >> package_release.bat
echo if exist "web" xcopy /e /i /q web release\web >> package_release.bat
echo if exist "*.sh" copy *.sh release\ >> package_release.bat
echo echo. >> package_release.bat
echo echo 创建版本信息... >> package_release.bat
echo echo version=v1.0.0-enhanced ^> release\VERSION >> package_release.bat
echo echo build_time=%%date%% %%time%% ^>^> release\VERSION >> package_release.bat
echo echo build_platform=windows-cross-compile ^>^> release\VERSION >> package_release.bat
echo echo target_platform=linux-amd64 ^>^> release\VERSION >> package_release.bat
echo echo. >> package_release.bat
echo echo 创建部署说明... >> package_release.bat
echo echo # Enhanced API Linux Release ^> release\DEPLOY.md >> package_release.bat
echo echo ^> release\DEPLOY.md >> package_release.bat
echo echo ## 部署步骤 ^>^> release\DEPLOY.md >> package_release.bat
echo echo ^>^> release\DEPLOY.md >> package_release.bat
echo echo 1. 上传整个 release 目录到服务器 ^>^> release\DEPLOY.md >> package_release.bat
echo echo 2. chmod +x x-ui ^>^> release\DEPLOY.md >> package_release.bat
echo echo 3. 运行部署脚本 ^>^> release\DEPLOY.md >> package_release.bat
echo echo ^>^> release\DEPLOY.md >> package_release.bat
echo echo 打包完成... >> package_release.bat
echo cd release >> package_release.bat
echo tar -czf ../x-ui-enhanced-linux-amd64.tar.gz * 2^>nul ^|^| ^( >> package_release.bat
echo     echo [93m使用zip打包...[0m >> package_release.bat
echo     powershell -Command "Compress-Archive -Path '*' -DestinationPath '../x-ui-enhanced-linux-amd64.zip'" >> package_release.bat
echo ^) >> package_release.bat
echo cd .. >> package_release.bat
echo echo. >> package_release.bat
echo echo [92m✅ 发布包创建完成！[0m >> package_release.bat
echo dir *.tar.gz *.zip 2^>nul >> package_release.bat
echo echo. >> package_release.bat
echo echo [94m🚀 上传到GitHub后，在服务器运行：[0m >> package_release.bat
echo echo bash ^^(curl -Ls https://raw.githubusercontent.com/WCOJBK/x-ui-api-main/main/deploy_from_github_release.sh^^) >> package_release.bat
echo pause >> package_release.bat

echo %GREEN%✅ 完整打包脚本已创建: package_release.bat%NC%

echo.
echo %BLUE%📋 6. 生成使用说明...%NC%

echo # Enhanced API 本地编译指南 > LOCAL_BUILD_GUIDE.md
echo. >> LOCAL_BUILD_GUIDE.md
echo ## 快速开始 >> LOCAL_BUILD_GUIDE.md
echo. >> LOCAL_BUILD_GUIDE.md
echo 1. **设置环境** >> LOCAL_BUILD_GUIDE.md
echo    ```cmd >> LOCAL_BUILD_GUIDE.md
echo    setup_local_build_env.bat >> LOCAL_BUILD_GUIDE.md
echo    ``` >> LOCAL_BUILD_GUIDE.md
echo. >> LOCAL_BUILD_GUIDE.md
echo 2. **快速编译** >> LOCAL_BUILD_GUIDE.md
echo    ```cmd >> LOCAL_BUILD_GUIDE.md
echo    quick_build.bat >> LOCAL_BUILD_GUIDE.md
echo    ``` >> LOCAL_BUILD_GUIDE.md
echo. >> LOCAL_BUILD_GUIDE.md
echo 3. **完整打包** >> LOCAL_BUILD_GUIDE.md
echo    ```cmd >> LOCAL_BUILD_GUIDE.md
echo    package_release.bat >> LOCAL_BUILD_GUIDE.md
echo    ``` >> LOCAL_BUILD_GUIDE.md
echo. >> LOCAL_BUILD_GUIDE.md
echo ## 高级编译 >> LOCAL_BUILD_GUIDE.md
echo. >> LOCAL_BUILD_GUIDE.md
echo ### 自定义编译 >> LOCAL_BUILD_GUIDE.md
echo ```cmd >> LOCAL_BUILD_GUIDE.md
echo call set_cross_compile.bat >> LOCAL_BUILD_GUIDE.md
echo go build -ldflags="-s -w -X main.version=custom" -o custom-x-ui >> LOCAL_BUILD_GUIDE.md
echo ``` >> LOCAL_BUILD_GUIDE.md
echo. >> LOCAL_BUILD_GUIDE.md
echo ### 支持的目标平台 >> LOCAL_BUILD_GUIDE.md
echo - linux/amd64 ^(默认^) >> LOCAL_BUILD_GUIDE.md
echo - linux/arm64 >> LOCAL_BUILD_GUIDE.md
echo - windows/amd64 >> LOCAL_BUILD_GUIDE.md
echo. >> LOCAL_BUILD_GUIDE.md
echo ## 部署到服务器 >> LOCAL_BUILD_GUIDE.md
echo. >> LOCAL_BUILD_GUIDE.md
echo 1. 上传编译结果到GitHub >> LOCAL_BUILD_GUIDE.md
echo 2. 在服务器运行： >> LOCAL_BUILD_GUIDE.md
echo    ```bash >> LOCAL_BUILD_GUIDE.md
echo    bash ^^^(curl -Ls https://raw.githubusercontent.com/WCOJBK/x-ui-api-main/main/deploy_from_github_release.sh^^^) >> LOCAL_BUILD_GUIDE.md
echo    ``` >> LOCAL_BUILD_GUIDE.md

echo %GREEN%✅ 使用说明已创建: LOCAL_BUILD_GUIDE.md%NC%

echo.
echo %PURPLE%╔═══════════════════════════════════════════════════════════╗%NC%
echo %PURPLE%║%NC% %GREEN%🎉 本地编译环境设置完成！%NC%                            %PURPLE%║%NC%
echo %PURPLE%║%NC%                                                           %PURPLE%║%NC%
echo %PURPLE%║%NC% ✅ Go环境验证通过                                        %PURPLE%║%NC%
echo %PURPLE%║%NC% ✅ 交叉编译配置完成                                      %PURPLE%║%NC%
echo %PURPLE%║%NC% ✅ 项目结构验证通过                                      %PURPLE%║%NC%
echo %PURPLE%║%NC% ✅ 编译功能测试成功                                      %PURPLE%║%NC%
echo %PURPLE%║%NC% ✅ 便捷脚本生成完成                                      %PURPLE%║%NC%
echo %PURPLE%║%NC%                                                           %PURPLE%║%NC%
echo %PURPLE%╚═══════════════════════════════════════════════════════════╝%NC%

echo.
echo %GREEN%🎯 生成的文件：%NC%
dir *.bat *.md 2>nul

echo.
echo %BLUE%📋 接下来的步骤：%NC%
echo.
echo %CYAN%🚀 快速编译：%NC%
echo     quick_build.bat
echo.
echo %CYAN%📦 完整打包：%NC%
echo     package_release.bat
echo.
echo %CYAN%🔄 部署到服务器：%NC%
echo     1. 上传打包结果到GitHub
echo     2. bash ^^^(curl -Ls .../deploy_from_github_release.sh^^^)

echo.
echo %GREEN%💡 优势总结：%NC%
echo 1. ✅ 绕过服务器Go环境问题
echo 2. ✅ 本地控制编译环境
echo 3. ✅ 快速部署预编译版本
echo 4. ✅ GitHub管理发布版本
echo 5. ✅ 一键脚本自动化流程

echo.
echo %YELLOW%🎊 享受无忧的Enhanced API开发体验！%NC%

echo.
pause
