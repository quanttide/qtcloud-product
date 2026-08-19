# 量潮产品云命令行工具（`qtcloud-product-cli`）

以用户故事为中心梳理需求：管理用户故事文档、生成用户故事地图、制定版本计划，并为 QtCloud Studio 加工渲染数据。

## 安装

### 前置依赖

- **Rust 工具链**：`rustup` + `cargo`
- **git**：仓库操作（tag / push / 工作区检测）
- **gh**（可选）：`release publish` 创建 GitHub Release 时需要

### 从源码安装

```bash
git clone https://github.com/quanttide/qtcloud-product.git
cd apps/qtcloud-product/src/cli
cargo install --path .
```

## 用法

### 快速导览

```bash
qtcloud-product requirement list/show/add/edit/remove/status   # 需求梳理
qtcloud-product story status/map/export                        # 用户故事地图
qtcloud-product roadmap status/plan                            # 版本计划
qtcloud-product release status/audit/publish                   # 发布管理
qtcloud-product doctor status                                  # 环境诊断
qtcloud-product status / audit / help                          # 概览与导览
```

按功能模块的完整命令、数据格式与规则见 [docs/](docs/index.md)（模块文档）。

### 需求梳理（核心）

```bash
qtcloud-product requirement list              # 列出用户故事
qtcloud-product requirement show <id>         # 查看用户故事详情
qtcloud-product requirement add --title "..." # 添加用户故事
qtcloud-product requirement edit <id> --phase future
qtcloud-product requirement remove <id>       # 删除用户故事
qtcloud-product requirement status            # 需求梳理状态（按活动聚合）
```

用户故事以 Markdown 文档管理，位于 `docs/dev-guide/prd/stories/stories/<activity>/`：

```markdown
---
title: 编辑用户故事
activity: user_story
task: 细化用户故事
phase: mvp        # mvp | future
status: done      # todo | inProgress | done
---

作为产品经理，我希望能够编辑用户故事的标题与描述，以便维护需求的最新状态。
```

无 frontmatter 的旧文档也兼容：id 取文件名、标题取首个 `# ` 标题。

### 用户故事地图

```bash
qtcloud-product story status                  # 活动/任务/故事统计
qtcloud-product story status --product qtcloud-devops
qtcloud-product story map                     # 生成三层故事地图视图
qtcloud-product story map --product qtcloud-devops
qtcloud-product story export                  # 导出 Studio 渲染数据
qtcloud-product story export --product qtcloud-devops
qtcloud-product story export --stdout         # 仅打印，不写文件
```

`story export` 按仓库约定加工 `assets/data/`：更新 `products/<id>.json`
（保留人工维护的 title / tagline / designIdea / mvpLinePosition），并同步
`manifest.json` 产品清单。其他产品文件不受影响。

**多产品约定**：每个产品的故事文档位于 `docs/stories/<产品id>/<活动>/`
（活动目录含 README.md 任务列表 + 故事文档）。qtcloud-product 兼容历史路径
`docs/dev-guide/prd/stories/stories/`。完整案例见
[examples/seed-workflow.md](examples/seed-workflow.md)。

### 版本计划

```bash
qtcloud-product roadmap status                # 版本计划状态
qtcloud-product roadmap plan                  # 生成 MVP / 未来迭代计划
qtcloud-product roadmap plan --output docs/dev-guide/prd/stories/roadmaps/README.md
```

### 发布

```bash
qtcloud-product release status                # 版本号 / CHANGELOG / 标签 / 工作区
qtcloud-product release audit -v v0.1.0       # 发布预检
qtcloud-product release publish               # 自动检测版本 + 发布
qtcloud-product release publish -v cli/v0.1.0 # 指定版本（scope 前缀）
qtcloud-product release publish --dry-run     # 仅预览，不执行
qtcloud-product release publish -y            # 跳过确认
```

版本号格式 `vX.Y.Z`，可选 scope 前缀（如 `cli/v0.1.0`，与 qtcloud-devops 的 tag 约定一致）。

### 概览与诊断

```bash
qtcloud-product status                        # 聚合所有 status
qtcloud-product audit                         # 聚合所有 audit
qtcloud-product doctor status                 # 检查外部工具链
qtcloud-product help                          # 快速导览
```

## 规则

- 用户故事文档是需求的事实源；Studio 只渲染，不修改数据
- `story export` 保留人工维护字段，仅重建故事地图结构
- `release publish` 走三阶段：预检 → 确认 → 执行；预检不通过即中止
- 网络 git 操作（push / ls-remote）使用系统 git 命令，而非 git2

## 开发

```bash
cargo test          # 单元测试 + CLI 集成测试
cargo build         # 构建
cargo run -- release status
```

## 相关文档

- [文档索引](docs/index.md) — 按模块组织的完整文档
- [架构：status / audit / action](docs/architecture.md)
- [规格对比：事件风暴规格 vs 当前 CLI](docs/specification-gap.md)
- [路线图](ROADMAP.md)
- [变更记录](CHANGELOG.md)
