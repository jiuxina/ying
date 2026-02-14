@echo off
setlocal EnableDelayedExpansion

REM 设置镜像加速下载
set PUB_HOSTED_URL=https://pub.flutter-io.cn
set FLUTTER_STORAGE_BASE_URL=https://storage.flutter-io.cn

REM ------------------------------------------------------------------
REM Configuration
REM ------------------------------------------------------------------
REM Set the version number here (x.x.x format)
set VERSION=1.0.0

REM Calculate version code by removing dots using string replacement
set VERSION_CODE=%VERSION:.=%

echo ==================================================================
echo Building Android APKs
echo Version Name: %VERSION%
echo Version Code: %VERSION_CODE%
echo ==================================================================

REM ------------------------------------------------------------------
REM Build Process
REM ------------------------------------------------------------------
echo Running flutter build apk --split-per-abi --release...
call flutter build apk --split-per-abi --release --build-name=%VERSION% --build-number=%VERSION_CODE%

if %errorlevel% neq 0 (
    echo Build failed!
    exit /b %errorlevel%
)

REM ------------------------------------------------------------------
REM Rename Output Files
REM ------------------------------------------------------------------
set OUTPUT_DIR=build\app\outputs\flutter-apk
echo.
echo Renaming APK files in %OUTPUT_DIR%...

REM Check if output directory exists
if not exist "%OUTPUT_DIR%" (
    echo Error: Output directory not found!
    exit /b 1
)

pushd "%OUTPUT_DIR%"

REM Rename standard split APKs
REM app-armeabi-v7a-release.apk -> ying-v%VERSION%-armeabi-v7a.apk
if exist "app-armeabi-v7a-release.apk" (
    ren "app-armeabi-v7a-release.apk" "ying-v%VERSION%-armeabi-v7a.apk"
    echo Renamed app-armeabi-v7a-release.apk to ying-v%VERSION%-armeabi-v7a.apk
)

REM app-arm64-v8a-release.apk -> ying-v%VERSION%-arm64-v8a.apk
if exist "app-arm64-v8a-release.apk" (
    ren "app-arm64-v8a-release.apk" "ying-v%VERSION%-arm64-v8a.apk"
    echo Renamed app-arm64-v8a-release.apk to ying-v%VERSION%-arm64-v8a.apk
)

REM app-x86_64-release.apk -> ying-v%VERSION%-x86_64.apk
if exist "app-x86_64-release.apk" (
    ren "app-x86_64-release.apk" "ying-v%VERSION%-x86_64.apk"
    echo Renamed app-x86_64-release.apk to ying-v%VERSION%-x86_64.apk
)

popd

echo ==================================================================
echo Build and Rename Complete!
echo APKs are located in: %OUTPUT_DIR%
echo ==================================================================

start "" "%OUTPUT_DIR%"

pause