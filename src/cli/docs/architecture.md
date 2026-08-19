# 架构：以用户故事为中心的需求梳理

## 领域模型

qtcloud-product 的领域核心是**用户故事**（对应 Studio 的三层故事地图模型）：

```
用户活动（UserActivity）— 地图的脊柱，如「管理用户故事」
└── 用户任务（UserTask）— 行走的骨骼，如「细化用户故事」
    └── 用户故事（UserStory）— 最小需求单元，如「编辑用户故事」
```

CLI 以用户故事文档为事实源（`docs/dev-guide/prd/stories/stories/<activity>/*.md`），
其余能力（故事地图、版本计划、渲染数据、发布）都是用户故事的视图或加工。

## 模块划分

| 模块 | 职责 | 输入 | 输出 | 文档 |
|------|------|------|------|------|
| `requirement` | 用户故事文档管理（解析/增删改查/状态） | 故事文档 | 结构化用户故事 | [modules/requirement.md](modules/requirement.md) |
| `story` | 故事地图视图与渲染数据加工 | 用户故事 | 地图视图 / `assets/data/` JSON | [modules/story.md](modules/story.md) |
| `roadmap` | 版本计划（MVP / 未来迭代） | 用户故事 | 计划文档 | [modules/roadmap.md](modules/roadmap.md) |
| `release` | 发布管理（status / audit / publish） | git + CHANGELOG + Cargo.toml | tag / Release | [modules/release.md](modules/release.md) |
| `doctor` | 环境诊断 | 工具链 | 诊断报告 | [modules/doctor.md](modules/doctor.md) |
| `source` | git 命令封装 | — | — | — |

## status / audit / action 三分法

所有命令按输入来源和副作用分为三类：

| 类别 | 读 source | 读契约/门禁 | 写（副作用） |
|------|-----------|-------------|-------------|
| **status** | ✅ 当前状态 | ❌ | ❌ |
| **audit** | ✅ 源码/系统 | ✅ 标准/门禁 | ❌ |
| **action** | ✅ | ✅ | ✅ 执行 |

### status — 事实

只读 source（文件系统、git），不做判定。

```
requirement status  用户故事数量/阶段/状态分布
story status        活动/任务/故事三层统计
roadmap status      版本计划目录与故事分布
release status      版本号/CHANGELOG/标签/工作区
doctor status       工具链安装状态
```

输出：数据。无 ❌ 图标，无门禁判定。

### audit — 标准

读 source + 对照标准判定 pass/fail。

```
release audit   版本格式/Cargo.toml/CHANGELOG/工作区/本地tag/远程tag 6 项
audit           聚合：渲染数据校验 + 发布预检
```

输出：✅/❌。门禁不达标退出码 1。

### action — 执行

读 source + 读门禁 + 写。

```
requirement add/edit/remove   写故事文档
story export                  加工 assets/data/ 渲染数据 + 同步 manifest
roadmap plan                  写版本计划文档
release publish               预检 → 确认 → tag → push → GitHub Release
```

## 数据流：用户故事 → Studio 渲染数据

```
docs/dev-guide/prd/stories/         （事实源：用户故事文档）
        │  requirement 模块解析
        ▼
用户故事结构化数据（id/title/activity/task/phase/status）
        │  story export 生成
        ▼
assets/data/products/qtcloud-product.json   （Studio 渲染数据）
assets/data/manifest.json                   （产品清单，同步更新）
        │  Studio 加载
        ▼
StoryMapCanvas 渲染（活动分组 → 任务列 → 故事卡片）
```

`story export` 只重建故事地图结构，人工维护的 `title` / `tagline` /
`designIdea` / `mvpLinePosition` 在未显式覆盖时从现有文件保留。

## 发布流程

三阶段架构（Plan → Confirm → Execute），预检不通过即中止，绝不带病发布。
版本号格式 `vX.Y.Z` 或 `scope/vX.Y.Z`（如 `cli/v0.1.0`）。dry-run 只走
Plan + 预览，不产生任何副作用。详见 [modules/release.md](modules/release.md)。

## 设计决策

- 用户故事文档用 Markdown + YAML frontmatter（简化键值解析，不引入 serde_yaml）
- 网络 git 操作（push / ls-remote）一律走系统 `git` 命令，不用 git2
  （credential helper 兼容性，见 AGENTS.md）
- 发布 tag 前缀约定与 qtcloud-devops 一致（`cli/vX.Y.Z`）

## 相关文档

- [规格对比：事件风暴规格 vs 当前 CLI](specification-gap.md) — 规格与实现的差距及演进方向
