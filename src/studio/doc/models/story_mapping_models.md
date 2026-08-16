# 故事映射数据模型（Model）设计

**更新日期**: 2026年8月16日  
**来源**: 自 `screens/requirement_screen.md` 与 `widgets/story_mapping.md` 分离  
**代码位置**: `src/studio/lib/models/story_map_models.dart`

---

## 一、分层原则：领域模型 vs 视图模型

| | 领域模型 | 视图模型 |
|--|---------|---------|
| 代码 | `models/story_map_models.dart` | 页面层（建议 `models/column_def.dart`） |
| 语义 | 业务本质，唯一事实源 | 页面渲染所需的列驱动结构 |
| 稳定性 | 稳定，随业务演进 | 随页面设计演进 |
| 生成 | — | 由 `projectToColumns(StoryMap)` 投影生成 |

**约定**：

- 领域模型是唯一事实源，页面只消费列投影
- 不得在领域模型上附加 UI 概念（flex、颜色、折叠状态）
- 页面层不得绕过投影直接读领域模型结构

---

## 二、领域模型（`story_map_models.dart`）

### 2.1 枚举

| 枚举 | 值 | 说明 |
|------|----|------|
| `ReleasePhase` | `mvp('MVP 版本')` / `future('未来迭代')` | 发布阶段 |
| `StoryStatus` | `todo` / `inProgress` / `done` | 故事状态 |

### 2.2 数据类（三层 + 容器）

| 类名 | 层级 | 主要属性 |
|------|------|--------|
| `UserStory` | 细节层 | id, title, taskId, phase, status, description |
| `UserTask` | 骨架层 | id, title, activityId, stories[], order |
| `UserActivity` | 主干层 | id, title, tasks[], order, color |
| `StoryMap` | 容器 | id, name, activities[], mvpLinePosition |

**设计特点**：

- 所有数据类实现 `copyWith()`，支持不可变数据模式，利于 Flutter 高效重建
- 完整的 `toString()` 用于调试

---

## 三、视图模型：列定义（ColumnDef）

页面层按列驱动组织数据，每列描述矩阵中的一个任务列：

```dart
/// 列定义（包含跨列系数 flex）
class ColumnDef {
  final int flex;             // 跨列系数：跨越 N 列则 flex = N，否则为 1
  final String activityTitle; // 橙色层：用户活动标题
  final String taskTitle;     // 紫色层：用户任务标题
  final Map<String, List<String>> stories; // Key: Release 版本号, Value: 故事列表

  ColumnDef({
    required this.flex,
    this.activityTitle = "",
    required this.taskTitle,
    this.stories = const {},
  });
}
```

---

## 四、领域模型 → 列定义映射

| 领域模型 | 列定义 | 说明 |
|---------|--------|------|
| `UserActivity.title` | `activityTitle` | 相邻同活动列合并展示 |
| `UserTask.title` | `taskTitle` | 每列一个任务 |
| 跨列活动 | `flex = 跨越列数` | 活动标题在活动层跨列 |
| `UserStory.phase` / release 字段 | `stories` 的 Map Key | 故事按版本归入对应 Release 行 |

投影函数（建议）：

```dart
/// 领域模型 → 列驱动投影
List<ColumnDef> projectToColumns(StoryMap map) {
  // 1. 遍历 map.activities：相邻活动按 title 合并
  // 2. 每个 UserTask 生成一列，flex = 该活动覆盖的任务列数
  // 3. 每个 UserStory 按 phase/release 归入对应版本的 stories 列表
}
```

---

## 五、发布维度演进与迁移

### 5.1 演进史

| 阶段 | 模型 | 说明 |
|------|------|------|
| 之前 ❌ | `StoryPriority`（must / should / could） | 按优先级分类，已删除 |
| 现在 ✅ | `ReleasePhase`（mvp / future） | 两段式发布阶段 |
| 新设计 🆕 | release 版本行（`1.0` / `2.0` / `Unscheduled`） | 每个版本一行，见 5.2 |

### 5.2 多版本演进方向（待定）

- 两段式（mvp / future）→ 多版本行：每个版本一行，行间即发布边界
- 模型层可选方案：
  - **方案 A（建议）**：`UserStory` 新增 `String? release` 字段（如 `'1.0'`），保留 `phase` 兼容旧视角，投影时优先按 `release` 分组
  - 方案 B：`phase` 扩展为多值枚举（不推荐——枚举不适合承载动态版本列表）

### 5.3 迁移指南

```dart
// 旧数据（已删除的类型）
UserStory(..., priority: StoryPriority.must)

// 现在
UserStory(..., phase: ReleasePhase.mvp)

// 新设计（建议）
UserStory(..., phase: ReleasePhase.mvp, release: '1.0')
```

---

## 六、参考

- 页面设计：[screens/requirement_screen.md](../screens/requirement_screen.md)
- 组件设计：[widgets/story_mapping.md](../widgets/story_mapping.md)
- Flutter 官方文档：https://flutter.dev
