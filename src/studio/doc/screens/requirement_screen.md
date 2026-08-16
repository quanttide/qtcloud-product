# 需求屏（用户故事地图页面）设计

**更新日期**: 2026年8月16日  
**来源**: 合并 `doc/story_map_canvas.md` 与 `doc/release_line.md`，并按「二维矩阵 + Flex colspan」方案重构页面设计  
**技术栈**: Flutter 3.x + Dart

---

## 一、页面定位

需求屏是量潮产品云的产品空间「需求」模块（`ProductModule.requirements`），以**用户故事地图**的形式展示一个产品的全部用户故事。

- **宿主**：侧边导航内容区（`StoryMapCanvasView`，无 Scaffold，可嵌入任意布局）或独立路由（`StoryMapCanvasPage`，含 AppBar）
- **数据来源**：产品领域模型 `StoryMap`（`mapData`），种子数据见 `data/seed_data.dart`
- **内容区头部**：「量潮产品云 · 产品名」

---

## 二、设计目标：秒级渲染复杂故事地图

核心技巧：**把二维矩阵拆分为多个垂直滚动的行（Row），并利用 `Flex` 因子实现跨列合并（colspan）**。

三个关键决策：

1. **不用 `Table`**：Flutter 原生 `Table` 不支持跨列（colspan），列对齐成本高、难以做卡片堆叠与拖拽。
2. **不用「分组内横排」嵌套**：旧设计是「活动分组 → 组内任务列横排」的嵌套结构，活动越多，横向滚动嵌套越深，列对齐靠肉眼。
3. **数据列驱动**：整张地图固定为若干列（ColumnDef），每一列包含 Activity（橙）、Task（紫）以及按 Release 版本分组的故事列表；渲染时自上而下输出行，同一列在每行中的宽度由 `flex` 决定，天然对齐。

> 判据：无论地图多大（多少活动、任务、故事），页面都只渲染「列数 × 行数」个横向 Row，配合懒加载即可秒级首帧。

---

## 三、页面布局结构

### 3.1 二维矩阵总览

```
┌──────────────────────────────────────────────────────┐
│ 顶部：品牌栏 + 产品切换器（宿主提供）                  │
├──────────────────────────────────────────────────────┤
│ 1. 活动层   ┌─ 橙色，UserActivity 标题，可跨列合并 ─┐  │
│ 2. 任务层   │   紫色，UserTask 标题                │  │
│ 3. Release 行 × N（蓝色故事卡片行，可折叠）          │  │
│    · 1.0        · 2.0        · Unscheduled           │  │
└──────────────────────────────────────────────────────┘
```

- **X 轴（列）**：任务列。每列 = 活动（橙色层）+ 任务（紫色层）+ 该列在某个 Release 行中的故事卡片。
- **Y 轴（行）**：Release 版本行（`1.0` / `2.0` / `Unscheduled`…）。
- **跨列（colspan）**：同一 Activity 覆盖多个任务列时，活动标题跨列合并（如 `Find Job` 横跨「Browse Jobs」「Post Resume」两列）。

### 3.2 列驱动数据模型（ColumnDef）

每列由 `ColumnDef` 描述（flex 跨列系数 / activityTitle / taskTitle / 按 Release 分组的故事列表），完整定义与映射规则见 [models/story_mapping_models.md](../models/story_mapping_models.md)。

### 3.3 四层视觉

| 层 | 颜色 | 内容 | 说明 |
|----|------|------|------|
| 活动层 | 橙 `#FFB74D` | Activity 标题 | 跨列时 flex 取跨越列数，实现合并 |
| 任务层 | 紫 `#B39DDB` | Task 标题 | 白字，字号略小 |
| Release 标题行 | 灰分隔线 | 版本号 + 日历图标 | 标识一个发布行，行间留白 |
| 故事行 | 蓝 `#BBDEFB` | 故事卡片列表 | 白字黑标题，圆角卡片 |

---

## 四、滚动策略

```dart
SingleChildScrollView(           // 外层：垂直滚动
  child: SingleChildScrollView(  // 内层：水平滚动
    child: Column(...),          // 自上而下：活动层 / 任务层 / Release 行 × N
  ),
)
```

- **垂直滚动**：浏览不同 Release 行（Y 轴）。
- **水平滚动**：浏览不同任务列（X 轴）。
- 列很多时，将横向滚动容器放在顶部，确保操作流畅（`ListView` 懒加载替代 `Row + map` 属后续优化项）。

---

## 五、核心交互

### 5.1 拖拽移动故事（✅ 已实现）

使用 `LongPressDraggable` + `DragTarget`：

1. 长按故事卡片 → 开始拖动，显示半透明原卡 + 浮起卡片反馈
2. 悬停在目标任务列上 → 绿色边框反馈
3. 释放 → `onAcceptWithDetails` 触发 `onStoryMove(story, newTaskId)`
4. 回调通知外部更新数据模型（`story.copyWith(taskId: ...)`）

实现细节见 `widgets/story_mapping.md` 第六节。

### 5.2 Release 行折叠 / 展开（🆕 新增）

- 故事行带小三角，点击折叠/展开该 Release 的整行故事卡片。
- 每个 Release 行维护一个 `isExpanded` 布尔值；用 `AnimatedSize` 或 `Visibility(maintainState: true)` 实现平滑动画。

### 5.3 故事点击（✅ 已实现）

点击故事卡片 → `onStoryTap(story)` → 打开故事明细页（标题、描述、阶段、状态）。

### 5.4 发布维度演进（此前 → 现在 → 新设计）

| 阶段 | 分类维度 | 视觉呈现 |
|------|---------|---------|
| 之前 ❌ | 优先级（MUST / SHOULD / COULD） | 左侧标签栏 + 卡片按优先级着色 |
| 现在 ✅ | 发布阶段（MVP / Future） | 可拖动的细浅色虚线（Release Line）+ MVP/Future 标签 |
| 新设计 🆕 | Release 版本行（1.0 / 2.0 / Unscheduled） | 每版本一行，行头版本号 + 日历图标，可折叠 |

演进要点：

- 领域模型的 `StoryPriority` 已删除，改为 `ReleasePhase`（`mvp('MVP 版本')` / `future('未来迭代')`）；故事卡片精简为仅展示标题。
- 新设计把「一条虚线 + 两段」升级为「多 Release 行」：行与行之间天然是发布边界，不再需要可拖动的绝对定位线，滚动场景下也不会错位。

---

## 六、数据模型

领域模型（`StoryMap` → `UserActivity` → `UserTask` → `UserStory`）、视图模型（`ColumnDef`）及二者映射规则已分离至独立文档：[models/story_mapping_models.md](../models/story_mapping_models.md)。

---

## 七、页面骨架（集成示例）

```dart
// 需求屏页面（建议命名：RequirementScreen）
class RequirementScreen extends StatelessWidget {
  final StoryMap mapData;

  // 1. 将领域模型投影为列驱动结构（映射规则见 models/story_mapping_models.md 第四节）
  final List<ColumnDef> columns = projectToColumns(mapData);
  final List<String> releases = ['1.0', '2.0', 'Unscheduled'];

  @override
  Widget build(BuildContext context) {
    return StoryMapCanvasView(
      columns: columns,
      releases: releases,
      onStoryMove: (story, newTaskId) { /* 更新数据模型 */ },
      onStoryTap: (story) { /* 打开明细 */ },
    );
  }
}
```

`main.dart` 集成：`ProductModule.requirements => StoryMapCanvasView(mapData: product.storyMap, ...)` 保持不变，页面内部改为消费列投影。

---

## 八、迁移路线（现有实现 → 二维矩阵）

1. **数据层**：领域模型不变；新增 `projectToColumns(StoryMap) → List<ColumnDef>` 投影函数。
2. **布局层**：`ActivitySection`（分组内横排）与 `TaskColumn`（固定 280 宽列）改为全局列矩阵渲染：
   - `ActivitySection` → `ActivityLayerRow`（活动层，跨列合并）
   - `TaskColumn` → `TaskLayerRow`（任务层，flex 对齐）
   - 新增 `ReleaseRow`（故事行，可折叠）
3. **交互层**：拖拽（`DragTarget` 目标从 TaskColumn 变为矩阵列容器）、Release Line 虚线移除、折叠展开新增。
4. **视觉层**：活动/任务层改用橙/紫规范色；故事卡片精简为仅展示标题（白底细边框）。

---

## 九、参考

- 模型设计：[models/story_mapping_models.md](../models/story_mapping_models.md)
- 组件设计：[widgets/story_mapping.md](../widgets/story_mapping.md)
- 架构设计：[docs/dev-guide/architecture.md](../../../docs/dev-guide/architecture.md)
- 交互设计：[docs/dev-guide/design/components/story_map_canvas.md](../../../docs/dev-guide/design/components/story_map_canvas.md)
- Flutter 官方文档：https://flutter.dev
