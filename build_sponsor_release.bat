@echo off
rem 正式赞助版构建：混淆 + 树摇图标 + Worker 地址注入。
rem 使用前先设置 UNLOCK_API_BASE，例如：
rem   set UNLOCK_API_BASE=https://ying-verify.xxx.workers.dev
if "%UNLOCK_API_BASE%"=="" (
  echo 请先设置 UNLOCK_API_BASE 环境变量
  exit /b 1
)
flutter build apk --release --obfuscate --split-debug-info=build/symbols --tree-shake-icons --dart-define=UNLOCK_API_BASE=%UNLOCK_API_BASE%
