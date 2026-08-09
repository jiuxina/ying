@echo off
rem Universal sponsor release build: obfuscation + tree-shaken icons + Worker URL.
rem Uses the live Worker URL by default; override with UNLOCK_API_BASE.
if "%UNLOCK_API_BASE%"=="" (
  set "UNLOCK_API_BASE=https://ying-verify.00000721.xyz"
)
if not exist android\key.properties (
  if "%ANDROID_KEYSTORE_PATH%"=="" (
    echo Missing signing config: create android\key.properties or set ANDROID_KEYSTORE_*
    echo See docs\sponsor-unlock-plan.md for details
    exit /b 1
  )
)
flutter build apk --release --obfuscate --split-debug-info=build/symbols --tree-shake-icons --dart-define=UNLOCK_API_BASE=%UNLOCK_API_BASE%
