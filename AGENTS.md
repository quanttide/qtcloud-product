# AGENTS.md

## 种子数据约定

种子数据位于仓库根的 `assets/data/`（如 `assets/data/products.json`），是产品云（qtcloud-product）的演示数据源。

- **CLI 负责加工种子数据**：生成、校验、更新 `assets/data/` 下的数据文件（如从领域仓库扫描产品结构并输出 JSON）。
- **Studio 只负责渲染**：`src/studio` 通过 `rootBundle` 加载种子数据并渲染，不内嵌数据、不修改数据。

> 实现说明：`src/studio/assets` 是指向仓库根 `assets/` 的符号链接（git 可跟踪），
> 因此 Flutter 包内资产路径 `assets/data/products.json` 即仓库根的数据文件。
> Windows 检出需要启用 git 符号链接支持（core.symlinks=true）。

## 目录结构

- `assets/data/` — 种子数据（JSON，CLI 加工）
- `docs/` — 产品文档（MyST Markdown，发布到 GitHub Pages）
- `src/studio/` — QtCloud Studio（Flutter 应用，渲染种子数据）
- `examples/` — 示例与工具脚本
