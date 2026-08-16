# AGENTS.md

## 种子数据约定

种子数据位于仓库根的 `assets/data/`，是产品云（qtcloud-product）的演示数据源。**每个产品一个 JSON 文件，便于单独修改**：

```
assets/data/
├── manifest.json               # 产品清单（products: [产品唯一命名...]）
└── products/
    ├── qtcloud-devops.json     # 量潮DevOps云
    ├── qtcloud-product.json    # 量潮产品云
    └── qtcloud-code.json       # 量潮编程云
```

- 文件名为产品的唯一命名（`qtcloud-devops` 等），用于 URL 与识别场景；文件内 `title` 字段为前台展示标题（量潮DevOps云 等）。
- **CLI 负责加工种子数据**：生成、校验、更新 `assets/data/` 下的数据文件（新增/删除产品时同步更新 `manifest.json`）。
- **Studio 只负责渲染**：`src/studio` 先读 manifest 清单，再按清单加载各产品文件并渲染，不内嵌数据、不修改数据。

> 实现说明：`src/studio/assets` 是指向仓库根 `assets/` 的符号链接（git 可跟踪），
> 因此 Flutter 包内资产路径（`assets/data/manifest.json`、`assets/data/products/`）即仓库根的数据文件。
> Windows 检出需要启用 git 符号链接支持（core.symlinks=true）。

## 目录结构

- `assets/data/` — 种子数据（JSON，CLI 加工）
- `docs/` — 产品文档（MyST Markdown，发布到 GitHub Pages）
- `src/studio/` — QtCloud Studio（Flutter 应用，渲染种子数据）
- `examples/` — 示例与工具脚本
