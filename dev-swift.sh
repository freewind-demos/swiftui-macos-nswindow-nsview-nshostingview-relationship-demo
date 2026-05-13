#!/usr/bin/env bash
# 自动重编并重启 app；有 fswatch 时持续监听。
set -euo pipefail

# 固定用本机完整 Xcode。
export DEVELOPER_DIR=/System/Volumes/Data/Applications/Xcode.app/Contents/Developer

# 切到项目根目录。
ROOT="$(cd "$(dirname "$0")" && pwd)"

# 固定 app 名。
APP_NAME="SwiftUINSWindowNSViewNSHostingViewRelationshipDemo"

# 固定 Debug 产物路径。
APP_PATH="${ROOT}/build/DerivedData/Build/Products/Debug/${APP_NAME}.app"

# 定义一次构建并重启流程。
run_once() {
  cd "$ROOT"
  ./scripts/build.sh
  pkill -x "$APP_NAME" >/dev/null 2>&1 || true
  open "$APP_PATH"
}

# 没有 fswatch 时只跑一次。
if ! command -v fswatch >/dev/null 2>&1; then
  echo "warning: fswatch not found; run once only"
  run_once
  exit 0
fi

# 先跑首轮。
run_once

# 监听源码与工程配置变更。
fswatch -o "$ROOT/Sources" "$ROOT/project.yml" | while read -r _; do
  run_once
done
