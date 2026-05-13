#!/usr/bin/env bash
# 固定用完整 Xcode，避免落到 CommandLineTools。
set -euo pipefail

# 切到项目根目录。
ROOT="$(cd "$(dirname "$0")/.." && pwd)"

# 固定工程名，避免再解析 yaml。
PROJECT_NAME="SwiftUINSWindowNSViewNSHostingViewRelationshipDemo"

# 固定用本机完整 Xcode。
export DEVELOPER_DIR=/System/Volumes/Data/Applications/Xcode.app/Contents/Developer

# 回到根目录执行后续命令。
cd "$ROOT"

# 读取构建模式；默认 Debug。
MODE="$(printf '%s' "${1:-debug}" | tr '[:upper:]' '[:lower:]')"

# 先生成 Xcode 工程。
xcodegen generate

# 根据模式选择配置与产物目录。
if [[ "$MODE" == "release" ]]; then
  CONFIGURATION="Release"
  DERIVED_DATA_PATH="${ROOT}/build/ReleaseDerivedData"
  rm -rf "${ROOT}/dist" "${DERIVED_DATA_PATH}"
  mkdir -p "${ROOT}/dist"
else
  CONFIGURATION="Debug"
  DERIVED_DATA_PATH="${ROOT}/build/DerivedData"
  rm -rf "${DERIVED_DATA_PATH}"
fi

# 执行 xcodebuild。
xcodebuild \
  -project "${PROJECT_NAME}.xcodeproj" \
  -scheme "${PROJECT_NAME}" \
  -configuration "${CONFIGURATION}" \
  -derivedDataPath "${DERIVED_DATA_PATH}" \
  CODE_SIGN_IDENTITY="-" \
  CODE_SIGNING_REQUIRED=NO \
  build

# 根据模式输出结果路径。
if [[ "$MODE" == "release" ]]; then
  ditto "${DERIVED_DATA_PATH}/Build/Products/Release/${PROJECT_NAME}.app" "${ROOT}/dist/${PROJECT_NAME}.app"
  echo "Release app: ${ROOT}/dist/${PROJECT_NAME}.app"
else
  echo "Debug app: ${DERIVED_DATA_PATH}/Build/Products/Debug/${PROJECT_NAME}.app"
fi
