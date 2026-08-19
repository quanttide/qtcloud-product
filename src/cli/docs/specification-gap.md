# 规格对比：事件风暴规格 vs 当前 CLI

> 规格来源：`data/profile/qtcloud-product/specification.md`（基于用户故事地图与产品档案，用事件风暴梳理）
> 本文记录规格与 CLI 实现的差距，作为 CLI 演进方向的依据。

## 核心错位

**CLI 建模的是"用户故事文档集合"，规格建模的是"故事地图聚合 + 产品生命周期"。**

- 规格的领域核心：故事地图（聚合，有状态机：草稿 → 修订中 → 已评审 → 已定稿）+ 产品（生命周期：登记中 → 需求中 → 规格中 → 迭代中 → 运营中）
- CLI 的领域核心：用户故事文档（增删改查 + `phase: mvp | future` 版本分类）

## 差距清单

### 1. 规格的核心流程在 CLI 中不存在：捕捉 → 评审

规格领域事件流：`素材已提交 → 草稿已生成(AI) → 草稿已修订 → 地图已评审 → 地图已定稿`

CLI 现状：`requirement add`（手工录入）→ `story map`（生成视图）。缺：

- **捕捉**：requirement 核心任务"从日志捕捉用户故事、先捕捉出格式、AI 辅助划分层级"——无对应命令
- **评审**：规格 R3"AI 产出必过人审"（需求评审环节）——无评审命令、无"标记不符合用户视角内容"、无地图级"已定稿"状态

**frontmatter 缺字段**：当前只有 `title / activity / task / phase / status`，无法承载规格的：

- R6 素材可追溯 → 缺 `source`（来源日志/访谈）
- R7 画像先行 → 缺 `persona`（用户画像）

### 2. 地图不是聚合，只是视图

- 规格：故事地图是聚合，有状态机，地图作为整体流转、定稿即冻结
- CLI：`story map` 是生成出来的视图——地图无状态、无版本、无"定稿即冻结"
- 后果：规格 R8（明确性检验：模糊需求不得进入下一阶段）无从落地——CLI 无法表达"这张地图还没评审完，不能进迭代"

### 3. 产品生命周期缺失：CLI 只有 mvp/future，没有五阶段

- 规格：产品状态机（登记中 → 需求中 → 规格中 → 迭代中 → 运营中），事件"地图已进入下一阶段"
- CLI：`phase: mvp | future` 是版本分类（MVP 发布线），不是阶段流转；`roadmap plan` 生成版本计划，不是产品生命周期
- `manifest.json` 无产品阶段字段

### 4. 质量门禁只有发布侧，没有需求侧

- CLI 的 status / audit / action 三分法清晰，但 audit 只有 `release audit`（发布预检）
- 规格 R4（视角一致性）、R5（颗粒度一致性）、R8（明确性）是需求质量门禁——CLI 无需求侧 audit（无"检查所有故事是否'用户要…'句式""颗粒度是否一致""是否有来源"）
- status / audit / action 架构恰好能承载需求 audit——缺的是实现，不是架构

### 5. 对齐良好的部分

| 规格元素 | CLI 对应 | 状态 |
|---------|---------|------|
| 读模型：地图画布 | `story status / map / export` | ✅ |
| 迭代：MVP 发布线 | `roadmap plan`（mvpLinePosition / phase） | ✅ |
| 跨产品组合 | `--product` 多产品 + manifest | ⚠️ 有清单，无成熟度/投入/时间线视图 |
| 事件风暴：规格活动 | — | ❌ 缺 |
| 验收活动（用例管理） | — | ❌ 缺 |

## 待补命令（按优先级）

### P0：需求侧质量门禁

```
qtcloud-product requirement audit
```

对照规格 R4/R5/R6/R8 检查全部故事：视角一致性（"用户要…"句式）、颗粒度一致性、素材来源可追溯、明确性（能写出规格）。门禁不达标退出码 1（复用现有 audit 架构）。

### P0：需求评审流程

```
qtcloud-product requirement review          # 地图级评审：待评审 → 已定稿
qtcloud-product requirement mark --no-user-perspective <id>   # 标记不符合用户视角内容
```

- 地图（活动目录）获得评审状态，定稿后进入下一阶段
- 评审是需求评审环节：校验视角一致性、格式确认

### P1：日志捕捉

```
qtcloud-product requirement capture --source <日志流/时间段>
```

- 从原始素材捕捉用户故事（先捕捉出格式），AI 辅助划分层级（活动/任务/故事细节）
- 产出带 `source` 的候选故事列表，经人工调整后入库

### P1：frontmatter 扩展

```
source: 2026-08-19/qtcloud-product   # 素材来源（R6）
persona: 产研负责人                   # 用户画像（R7）
```

## 演进原则

- 保持"用户故事文档是事实源、Studio 只渲染"的架构不变
- 捕捉/评审是对 `requirement` 模块的扩展，不引入新的领域抽象
- 需求侧 audit 复用 status / audit / action 三分法，与 release audit 并列
