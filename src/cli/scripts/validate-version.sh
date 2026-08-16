#!/usr/bin/env bash
# 校验版本号格式：vX.Y.Z 或 scope/vX.Y.Z（semver）
set -euo pipefail

VERSION="${1:-}"
if [ -z "$VERSION" ]; then
  echo "用法: $0 <版本号>  例如: $0 cli/v0.1.0"
  exit 1
fi

if echo "$VERSION" | grep -Eq '^([a-z0-9_-]+/)?v[0-9]+\.[0-9]+\.[0-9]+(-[0-9A-Za-z.-]+)?$'; then
  echo "✅ 版本号格式正确: $VERSION"
else
  echo "❌ 版本号格式错误: $VERSION（应为 vX.Y.Z 或 scope/vX.Y.Z）"
  exit 1
fi
