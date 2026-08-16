# 案例：qtcloud-devops 种子数据建模与 CLI 加工

> 目标：把 qtcloud-devops 的种子数据（`assets/data/products/qtcloud-devops.json`）
> 按「lifecycle 是一个 Activity、八个阶段是 Task、具体功能是 Story」重新建模，
> 并全程使用 qtcloud-product CLI 加工，验证 CLI 设计。
>
> 完整流程：**手动建模 → 故事文档 → CLI 生成 → 校验 → 反思**。

## 1. 建模决策（手动修改种子数据）

先手动把 `assets/data/products/qtcloud-devops.json` 的 storyMap 重写为：

```
storyMap
├── lifecycle（🔄 阶段/生命周期管理）
│   ├── lifecycle-task-1  plan 计划     → 查看迭代计划与待办、从审计自动生成规划
│   ├── lifecycle-task-2  code 编码     → 同步子模块、了解子模块状态、代码质量审查
│   ├── lifecycle-task-3  build 构建    → 构建状态、清理产物、构建审计
│   ├── lifecycle-task-4  test 测试     → 测试状态、运行与覆盖率、质量审计
│   ├── lifecycle-task-5  release 发布  → 发布预检、发布版本、查看状态
│   ├── lifecycle-task-6  deploy 部署   → CI 构建与测试、自动分发到注册源
│   ├── lifecycle-task-7  operate 运营  → 环境诊断、契约状态、退役过时版本
│   └── lifecycle-task-8  monitor 监控  → 概览状态、概览审计
└── platform（🛠 管理平台）
    ├── platform-task-1  配置契约       → 维护契约配置
    ├── platform-task-2  管理组件       → cli / provider / studio 三个 scope
    └── platform-task-3  管理分发渠道   → crates.io / PyPI / pub.dev
```

要点：

- **八阶段取自 DevOps 生命周期**：plan → code → build → test → release →
  deploy → operate → monitor（[PlanetScale 八阶段 DevOps](https://planetscale.com/blog/the-eight-phases-of-devops)）。
- **任务标题 = 命令名 + 中文**（`plan 计划`），命令名与 qtcloud-devops CLI
  子命令一一对应。
- **id 规则**：任务 `lifecycle-task-N`、故事 `lifecycle-plan-1` 语义化命名，
  与 CLI 生成规则对齐（见下），保证「手动改」与「CLI 生成」可复现一致。

## 2. 建立故事文档（CLI 的输入源）

CLI 按约定从 `docs/stories/<产品>/<活动>/` 扫描故事文档：

```
docs/stories/qtcloud-devops/
├── lifecycle/
│   ├── README.md               # 活动标题 + 任务列表（八阶段）
│   ├── lifecycle-plan-1.md     # frontmatter: task: plan 计划
│   ├── lifecycle-plan-2.md
│   └── ...
└── platform/
    ├── README.md               # 活动标题 + 任务列表（配置契约/管理组件/管理分发渠道）
    └── platform-contract-1.md
```

故事文档格式（Markdown + YAML frontmatter）：

```markdown
---
title: 查看迭代计划与待办
activity: lifecycle
task: plan 计划
phase: mvp
status: done
---

ROADMAP / BUGS / TODO
```

## 3. 用 CLI 生成种子数据

```bash
# 预览故事地图（不写文件）
qtcloud-product story map --product qtcloud-devops

# 生成/更新种子数据：重建 storyMap + 同步 manifest.json
qtcloud-product story export --product qtcloud-devops
# → ✅ 已导出故事地图数据 → assets/data/products/qtcloud-devops.json（28 个用户故事）
```

生成结果（与手动建模一致）：

```
activities: [('lifecycle', '阶段/生命周期管理', 8), ('platform', '管理平台', 3)]
total stories: 28
manifest: ['qtcloud-devops', 'qtcloud-product', 'qtcloud-code']
```

`story export` 的保留策略：**只重建 storyMap 结构，人工维护的
`title` / `tagline` / `designIdea` / `mvpLinePosition` 原样保留**，
因此反复生成不会丢失产品定位信息。

## 4. 校验

```bash
qtcloud-product audit          # 概览审计：种子数据文件 + manifest + 发布预检
qtcloud-product story status --product qtcloud-devops
qtcloud-product requirement list   # 当前仓库（qtcloud-product）的需求
```

## 5. 设计反思

| 环节 | 发现 | 结论 |
|------|------|------|
| 手动建模 | 旧 id（`devops-story-N`）无语义 | 采用语义化 id（`lifecycle-plan-1`） |
| CLI 生成 | 「文件名即 story id」规则 | 强制文档语义化命名，避免无意义编号 |
| 保留策略 | export 覆盖 storyMap 但不碰人工字段 | 可反复加工，不破坏定位信息 |
| 任务解析 | 活动 README 的任务列表是任务唯一来源 | 任务增删只需改 README |
| 多产品 | 第一个版本只支持 qtcloud-product | 增加 `--product` 参数，故事根 `docs/stories/<id>/` |
| 历史兼容 | qtcloud-product 文档在旧路径 | `stories_root_for` 回退 `docs/dev-guide/prd/stories/stories` |

## 6. 相关代码

- CLI 入口：`src/cli/src/story/export.rs`（`stories_root_for` / `build_product` / `export`）
- 故事文档解析：`src/cli/src/requirement/model.rs`（`scan_activities` / `scan_stories`）
- 库 API 示例：`src/cli/examples/devops_export.rs`（`cargo run --example devops_export`）
