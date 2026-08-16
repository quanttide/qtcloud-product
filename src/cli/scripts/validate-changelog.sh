#!/usr/bin/env bash
# 校验 CHANGELOG.md：存在版本头且版本号与 Cargo.toml 一致
set -euo pipefail

REPO_ROOT="$(git rev-parse --show-toplevel)"
CLI_DIR="$REPO_ROOT/src/cli"
CHANGELOG="$REPO_ROOT/CHANGELOG.md"

[ -f "$CHANGELOG" ] || { echo "❌ 缺少 $CHANGELOG"; exit 1; }

CARGO_VERSION=$(grep -m1 '^version =' "$CLI_DIR/Cargo.toml" | sed 's/.*"\(.*\)"/\1/')
CHANGELOG_VERSION=$(grep -m1 '^## \[' "$CHANGELOG" | sed 's/## \[\([^]]*\)\].*/\1/')

echo "Cargo.toml 版本: $CARGO_VERSION"
echo "CHANGELOG 版本:  $CHANGELOG_VERSION"

[ "$CARGO_VERSION" = "$CHANGELOG_VERSION" ] || {
  echo "❌ 版本不一致"
  exit 1
}
echo "✅ 版本一致"
