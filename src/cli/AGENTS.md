# AGENTS

## 特殊文件

- README：面向用户
- CONTRIBUTING：面向开发者
- AGENTS.md：AI 操作指南

## 设计决策

### 以用户故事为中心梳理需求

本 CLI 的领域核心是用户故事（对应 Studio 的三层故事地图模型：
用户活动 → 用户任务 → 用户故事）。所有需求梳理命令围绕用户故事文档展开，
其他能力（故事地图、版本计划、发布）都是用户故事的视图或加工。

用户故事文档的元数据采用 YAML frontmatter（title / activity / task / phase /
status），解析与写入都在 `requirement` 模块内完成，不引入 serde_yaml 之外的
格式依赖——frontmatter 是简化键值解析，支持的值有限且固定。

### 种子数据加工在 story export，不设独立 seed 模块

仓库约定「CLI 负责加工种子数据、Studio 只负责渲染」，但加工能力归属
`story export`：从用户故事文档生成故事地图数据，更新
`assets/data/products/<id>.json` 并同步 `assets/data/manifest.json`。
不引入「seed」抽象层，避免与领域模型（用户故事）脱节。

**多产品约定**：每个产品的故事文档位于 `docs/stories/<产品id>/<活动>/`
（活动目录含 README.md 任务列表 + 故事文档，故事文档用 YAML frontmatter 声明
activity / task / phase / status）。qtcloud-product 兼容历史路径
`docs/dev-guide/prd/stories/stories/`（`stories_root_for` 回退）。
`story status / map / export` 均支持 `--product`。

建模参考（qtcloud-devops 案例，见 examples/seed-workflow.md）：
「lifecycle 是一个 Activity、八个阶段是 Task、具体功能是 Story」——
一个活动承载生命周期（plan → code → build → test → release → deploy →
operate → monitor 八阶段任务），其他活动（如 platform 管理平台）承载底座能力。

`story export` 只重建故事地图结构（activities / tasks / stories），
人工维护的 title / tagline / designIdea / mvpLinePosition 在未显式覆盖时
从现有文件保留，防止加工过程破坏演示数据。

### 网络 git 操作用 CLI 而非 git2

任何需要网络的 git 操作（push、fetch、pull、ls-remote 等）必须用
`std::process::Command::new("git")`，不要用 git2 crate。

原因：git2 缺少 credential callback 配置，连接 GitHub HTTPS 时会报
"authentication required but no callback set"。系统 git 命令使用用户已配置的
credential helper（如 `gh auth setup-git`），不存在此问题。

`git2` 的使用范围：仅限纯本地操作（读配置、查日志、创建本地 tag、rev-parse 等）。
当前初始化版本不引入 git2，全部走系统 git。

### release 三阶段架构

`release publish` 分为 Plan（只读预检）→ Confirm（交互确认）→ Execute（只写）
三个阶段。预检未通过即中止，绝不带病发布。dry-run 只走 Plan + 预览。

### status / audit / action 三分法

| 类别 | 读 source | 读契约/门禁 | 写（副作用） |
|------|-----------|-------------|-------------|
| **status** | ✅ 当前状态 | ❌ | ❌ |
| **audit** | ✅ 源码/系统 | ✅ 标准/门禁 | ❌ |
| **action** | ✅ | ✅ | ✅ 执行 |

### 双轨命令组织：动词工作流 + 名词原子操作

名词层（requirement / story / roadmap / release / doctor）是原子对象操作，
保持现状兼容；动词层（clarify / design / plan / accept / operate）是阶段工作流，
围绕工作流程深度组织，是演进方向。

- 动词子命令 = 阶段的流程步骤，按执行顺序排列（如 clarify：capture → classify → adjust → review → finalize）
- 动词 = 工作台：不带参数运行显示该阶段当前状态 + 下一步建议（聚合各名词 status）
- **动词编排，名词执行**：动词内部委托名词实现，不复制名词逻辑
- 动词是流程门禁：`clarify finalize` 前置检查不通过即拒绝进入下一阶段（规格 R3/R8 在流程层强制）
- 跨阶段聚合动作（status / audit / help）与 release 保持现状

## 命令一览

- 名词层：`requirement list / show / add / edit / remove / status` — 用户故事管理
- 名词层：`story status / map / export` — 故事地图视图与数据加工
- 名词层：`roadmap status / plan` — 版本计划
- 名词层：`release status / audit / publish` — 发布管理
- 名词层：`doctor status` — 环境诊断
- 动词层（演进）：`clarify / design / plan / accept / operate` — 阶段工作流
- `status / audit / help` — 概览与导览
