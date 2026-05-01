@echo off
setlocal enabledelayedexpansion

set "REPO_ROOT=%~dp0"
set "APK_OUTPUT_DIR=%REPO_ROOT%build\app\outputs\flutter-apk\"

set PUB_HOSTED_URL=https://pub.flutter-io.cn
set FLUTTER_STORAGE_BASE_URL=https://storage.flutter-io.cn

echo ======================================================
echo [0/5] Building Android APKs (ABI Split Release)
echo ======================================================

echo [1/5] Cleaning project...
call flutter clean
if errorlevel 1 (
  echo [ERROR] flutter clean failed
  goto :error
)

echo [2/5] Fetching dependencies...
call flutter pub get
if errorlevel 1 (
  echo [ERROR] flutter pub get failed
  goto :error
)

echo [3/5] Building ABI split release APKs...
call flutter build apk --release --split-per-abi
if errorlevel 1 (
  echo [ERROR] flutter build apk failed
  goto :error
)

echo [4/5] Renaming APK files...
if not exist "%APK_OUTPUT_DIR%" (
  echo [ERROR] Output directory not found: %APK_OUTPUT_DIR%
  goto :error
)

pushd "%APK_OUTPUT_DIR%"

for /f "tokens=2 delims==" %%v in ('findstr /r "^version:" "%REPO_ROOT%pubspec.yaml"') do (
  for /f "tokens=1 delims=+" %%a in ("%%v") do set VERSION=%%a
)

if not defined VERSION set VERSION=1.0.0

if exist "app-armeabi-v7a-release.apk" (
  move /y "app-armeabi-v7a-release.apk" "ying-v%VERSION%-armeabi-v7a.apk" >nul
  echo   - ying-v%VERSION%-armeabi-v7a.apk
)

if exist "app-arm64-v8a-release.apk" (
  move /y "app-arm64-v8a-release.apk" "ying-v%VERSION%-arm64-v8a.apk" >nul
  echo   - ying-v%VERSION%-arm64-v8a.apk
)

if exist "app-x86_64-release.apk" (
  move /y "app-x86_64-release.apk" "ying-v%VERSION%-x86_64.apk" >nul
  echo   - ying-v%VERSION%-x86_64.apk
)

popd

echo [5/5] Opening output directory...
if exist "%APK_OUTPUT_DIR%" (
  start "" "%APK_OUTPUT_DIR%"
) else (
  echo [WARN] Output directory not found: %APK_OUTPUT_DIR%
)

echo.
echo ======================================================
echo Build Complete!
echo Version: %VERSION%
echo APKs location: %APK_OUTPUT_DIR%
echo ======================================================
goto :end

:error
echo.
echo ======================================================
echo Build FAILED! Check the errors above.
echo ======================================================

:end
pause
