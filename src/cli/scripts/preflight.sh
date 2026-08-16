#!/usr/bin/env bash
# 发布预检：版本一致性 + CHANGELOG + 干净工作区 + 测试通过
set -euo pipefail

REPO_ROOT="$(git rev-parse --show-toplevel)"
CLI_DIR="$REPO_ROOT/src/cli"

echo "==> 构建与测试"
(cd "$CLI_DIR" && cargo build && cargo test)

echo "==> 发布预检"
(cd "$CLI_DIR" && qtcloud-product release audit)

echo "==> 检查工作区"
if [ -n "$(git -C "$REPO_ROOT" status --porcelain)" ]; then
  echo "⚠  工作区有未提交变更："
  git -C "$REPO_ROOT" status --short
  echo "请先提交变更再发布。"
  exit 1
fi

echo "✅ 预检通过，可以发布：qtcloud-product release publish"
