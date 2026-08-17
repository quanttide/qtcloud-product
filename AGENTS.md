# AGENTS.md

## 种子数据约定

种子数据位于 `src/studio/assets/data/`（Flutter 包内资产目录，唯一数据源），是产品云（qtcloud-product）的演示数据源。**每个产品一个 JSON 文件，便于单独修改**：

```
src/studio/assets/data/
├── manifest.json               # 产品清单（products: [产品唯一命名...]）
└── products/
    ├── qtcloud-devops.json     # 量潮DevOps云
    ├── qtcloud-product.json    # 量潮产品云
    ├── qtcloud-code.json       # 量潮编程云
    ├── qtcloud.json            # 量潮云
    ├── qtcloud-secret.json     # 量潮机密云
    └── qthealth.json           # 量潮健康
```

- 文件名为产品的唯一命名（`qtcloud-devops` 等），用于 URL 与识别场景；文件内 `title` 字段为前台展示标题（量潮DevOps云 等）。
- **CLI 负责加工种子数据**：生成、校验、更新 `src/studio/assets/data/` 下的数据文件（新增/删除产品时同步更新 `manifest.json`）。
- **Studio 只负责渲染**：`src/studio` 先读 manifest 清单，再按清单加载各产品文件并渲染，不内嵌数据、不修改数据。
- **Provider 只负责服务**：`src/provider` 以只读 API 服务种子数据（`/manifest`、`/products`、`/products/{name}`），
  数据契约与 Studio 渲染模型对齐（见 `src/provider/docs/index.md`）；本地开发用 `DATA_DIR` 直读本目录。

> 实现说明：`src/studio/assets/` 是真实目录（git 跟踪），Flutter 资产声明
> （`assets/data/manifest.json`、`assets/data/products/`）相对包根解析，即该目录下的数据文件。

## 目录结构

- `src/studio/assets/data/` — 种子数据（JSON，CLI 加工）
- `docs/` — 产品文档（MyST Markdown，发布到 GitHub Pages）
- `src/studio/` — QtCloud Studio（Flutter 应用，渲染种子数据）
- `src/provider/` — QtCloud Provider（Go 服务端，只读服务种子数据，结构对齐 qtcloud-secret）
- `examples/` — 示例与工具脚本
