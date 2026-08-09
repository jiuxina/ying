@echo off
setlocal enabledelayedexpansion

rem ABI-split release build (arm64-v8a / armeabi-v7a / x86_64).
rem Uses the live Worker URL by default; override with UNLOCK_API_BASE.
set "REPO_ROOT=%~dp0"
set "APK_OUTPUT_DIR=%REPO_ROOT%build\app\outputs\flutter-apk\"
set "RELEASE_OUTPUT_DIR=%REPO_ROOT%..\outputs\release-apks"
if "%UNLOCK_API_BASE%"=="" set "UNLOCK_API_BASE=https://ying-verify.00000721.xyz"

echo [0/4] Cleaning project...
call flutter clean
if errorlevel 1 (
  echo [ERROR] flutter clean failed
  if not defined NO_PAUSE pause
  exit /b 1
)

echo [1/4] Fetching dependencies...
call flutter pub get
if errorlevel 1 (
  echo [ERROR] flutter pub get failed
  if not defined NO_PAUSE pause
  exit /b 1
)

echo [2/4] Building ABI split release APKs (arm64-v8a / armeabi-v7a / x86_64)...
call flutter build apk --release --split-per-abi --split-debug-info=build/debug-info --obfuscate --tree-shake-icons --dart-define=UNLOCK_API_BASE=%UNLOCK_API_BASE%
if errorlevel 1 (
  echo [ERROR] flutter build apk failed
  if not defined NO_PAUSE pause
  exit /b 1
)

echo [3/4] Collecting APKs to %RELEASE_OUTPUT_DIR%...
if not exist "%RELEASE_OUTPUT_DIR%" mkdir "%RELEASE_OUTPUT_DIR%"
copy /Y "%APK_OUTPUT_DIR%app-*-release.apk" "%RELEASE_OUTPUT_DIR%" >nul
if errorlevel 1 (
  echo [ERROR] Failed to copy APKs
  if not defined NO_PAUSE pause
  exit /b 1
)

echo [4/4] Opening output directory...
if exist "%APK_OUTPUT_DIR%" (
  start "" "%APK_OUTPUT_DIR%"
)

echo.
echo ======================================================
echo Build Complete!
echo ABI-specific APKs are generated in:
echo %APK_OUTPUT_DIR%
echo Release copies:
echo %RELEASE_OUTPUT_DIR%
echo   - app-arm64-v8a-release.apk     (64-bit ARM)
echo   - app-armeabi-v7a-release.apk   (32-bit ARM)
echo   - app-x86_64-release.apk        (x86_64)
echo ======================================================
if not defined NO_PAUSE pause
