@echo off
setlocal enabledelayedexpansion

set "REPO_ROOT=%~dp0"
set "APK_OUTPUT_DIR=%REPO_ROOT%build\app\outputs\flutter-apk\"

echo [0/4] Cleaning project...
call flutter clean
if errorlevel 1 (
  echo [ERROR] flutter clean failed
  pause
  exit /b 1
)

echo [1/4] Fetching dependencies...
call flutter pub get
if errorlevel 1 (
  echo [ERROR] flutter pub get failed
  pause
  exit /b 1
)

echo [2/4] Building ABI split release APKs (arm64-v8a / armeabi-v7a / x86_64)...
call flutter build apk --release --split-per-abi --split-debug-info=build/debug-info --obfuscate --tree-shake-icons
if errorlevel 1 (
  echo [ERROR] flutter build apk failed
  pause
  exit /b 1
)

echo [3/4] Opening output directory...
if exist "%APK_OUTPUT_DIR%" (
  start "" "%APK_OUTPUT_DIR%"
) else (
  echo [WARN] Output directory not found: %APK_OUTPUT_DIR%
)

echo.
echo ======================================================
echo Build Complete!
echo ABI-specific APKs are generated in:
echo %APK_OUTPUT_DIR%
echo   - app-arm64-v8a-release.apk     (64-bit ARM)
echo   - app-armeabi-v7a-release.apk   (32-bit ARM)
echo   - app-x86_64-release.apk        (x86_64)
echo ======================================================
pause
