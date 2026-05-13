#!/usr/bin/env bash
# 直接转发到 release 构建。
set -euo pipefail
exec "$(cd "$(dirname "$0")" && pwd)/build.sh" release
