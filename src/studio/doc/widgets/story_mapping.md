# 故事映射组件（Widget）设计

**更新日期**: 2026年8月16日  
**来源**: 合并 `doc/story_map_canvas.md` 与 `doc/release_line.md`，按「二维矩阵 + Flex colspan」方案重构组件树  
**技术栈**: Flutter 3.x + Dart

---

## 一、组件总览

```
StoryMapCanvasView（画布根：滚动 + 矩阵协调 + 拖拽分发）
├── ActivityLayerRow        活动层（橙色，跨列合并）
├── TaskLayerRow            任务层（紫色）
└── ReleaseRow × N          发布行（蓝色故事卡片，可折叠）
    └── StoryColumn × M     列容器（本列故事卡片纵向堆叠）
        └── StoryCard × K   故事卡片（最小单元）
```

| 组件 | 状态 | 职责 |
|------|------|------|
| `StoryCard` | ✅ 已实现 | 单个用户故事的最小视觉单元 |
| `ActivityLayerRow` | 🆕 新增 | 矩阵顶部橙色活动层，跨列合并 |
| `TaskLayerRow` | 🆕 新增 | 矩阵第二层紫色任务层 |
| `ReleaseRow` | 🆕 新增 | 一个 Release 版本的故事行，支持折叠 |
| `StoryColumn` | 🆕 新增 | 行内单列容器，堆叠故事卡片 |
| `StoryMapCanvasView` | ✅ 演进 | 画布根组件：滚动、布局、拖拽、发布线 |

> 演进说明：旧组件 `ActivitySection`（活动分组，组内任务列横排）与 `TaskColumn`（固定宽 280 的任务列）被矩阵化渲染取代——`ActivitySection` → `ActivityLayerRow`，`TaskColumn` → 矩阵列（`StoryColumn` + 紫色层标题）。

---

## 二、数据模型

领域模型（`story_map_models.dart`）与视图模型（`ColumnDef`）的完整定义、映射规则见独立文档：[models/story_mapping_models.md](../models/story_mapping_models.md)。本组件文档只引用其结论。

---

## 三、组件明细

### 🎫 StoryCard（故事卡片，✅ 已实现）

- 三层信息：标题（用户语言，动词开头）→ 描述（具体命令/细节，弱化）→ 发布阶段（极小灰色文字）
- 状态圆点：🟢 完成（`#27AE60`）/ 🟡 进行中（`#F39C12`）/ ⚪ 待办（`#B0BEC5`），右上角小圆点，不做大色块
- 白底 + 细浅边框（`grey[300]`）+ 圆角 6 + 极淡阴影，**不按阶段着色**（视觉减负）
- 交互：`onTap` 点击查看明细；`onLongPress` 触发拖拽起点

### 🟠 ActivityLayerRow（活动层，🆕 新增）

- 渲染矩阵顶部一行：对每个列定义输出一个 `Expanded(flex: col.flex)` 的橙色容器（`#FFB74D`，高 40）
- **跨列合并**：同一活动覆盖 N 列时，flex = N，标题块宽度自动等于 N 列之和，上下严格对齐

### 🟣 TaskLayerRow（任务层，🆕 新增）

- 第二行：对每个列定义输出 `Expanded(flex: col.flex)` 的紫色容器（`#B39DDB`，高 40，白字 11px）
- 与活动层的 flex 划分一致，保证列边界上下对齐

### 🔵 ReleaseRow（发布行，🆕 新增）

- 一个 Release 一个行，结构：
  - **行头**：版本号（加粗 14px）+ 日历图标（`Icons.calendar_today`，12px）+ 顶部细灰分隔线，行内左侧对齐
  - **行体**：`Row(crossAxisAlignment: start)`，每列 `Expanded(flex: col.flex)` 输出本列该版本的故事卡片列表
- **折叠**：行头小三角切换 `isExpanded`，收起时行体隐藏（详见第七节）

### 🎨 StoryMapCanvasView（画布根，✅ 演进）

**职责清单**：

1. **画布**：提供宽大、可滚动的平面（外层垂直 + 内层水平 `SingleChildScrollView`）
2. **布局**：自上而下渲染 活动层 → 任务层 → Release 行 × N
3. **交互**：分发故事拖拽（`LongPressDraggable` + `DragTarget`）与点击
4. **分界**：发布边界由 Release 行天然表达（旧 Release Line 虚线移除）
5. **通讯**：把操作转化为事件回调，通知外部更新数据模型

**不要在画布内做**：直接调 API 保存、业务判断（如「这个故事属于哪个版本」应在模型层算好）。

---

## 四、colspan 实现（核心技巧）

Flutter 原生 `Table` 不支持跨列，用 `Expanded` 的 `flex` 属性模拟：

```dart
// 每行（活动层 / 任务层 / Release 行）都按列定义划分
Row(
  children: columns.map((col) {
    return Expanded(
      flex: col.flex, // 跨 2 列的活动其列 flex = 2，单列 flex = 1
      child: Container(...),
    );
  }).toList(),
)
```

**对齐保证**：活动层、任务层、每个 Release 行使用同一组 `ColumnDef` 的同一 `flex` 序列 → 所有行的列边界完全一致。

**注意**：`flex` 同时也是列宽权重——跨列活动的列更宽（总宽 = 各列 flex 之和）。若需列宽严格均匀，可改为「活动层按活动合并（flex = 跨越列数）、任务/故事行每列 flex = 1」。

---

## 五、滚动与布局

```dart
SingleChildScrollView(scrollDirection: Axis.vertical,
  child: SingleChildScrollView(scrollDirection: Axis.horizontal,
    child: Column(crossAxisAlignment: start,
      children: [ActivityLayerRow, TaskLayerRow, ...releaseRows],
    ),
  ),
)
```

- 外层垂直滚动浏览 Release 行；内层水平滚动浏览任务列
- 列很多时，把横向滚动容器放顶部，保证操作流畅

---

## 六、拖拽交互（✅ 已实现，保持不变）

`LongPressDraggable` + `DragTarget` 架构：

```dart
// 故事卡片（StoryCard）包裹在 LongPressDraggable 中
LongPressDraggable<UserStory>(
  data: story,
  feedback: Material(elevation: 5, child: StoryCard(story: story)), // 浮起反馈
  childWhenDragging: Opacity(opacity: 0.5, child: StoryCard(story: story)), // 原卡半透明
  child: StoryCard(story: story, onTap: ...),
)

// 矩阵列容器（StoryColumn）作为拖放目标
DragTarget<UserStory>(
  onAcceptWithDetails: (details) {
    if (details.data.taskId != task.id) onStoryMove?.call(details.data, task.id);
  },
  builder: (context, candidateData, rejectedData) {
    // candidateData 非空时显示绿色边框反馈
  },
)
```

**交互流程**：长按卡片 → 拖动（浮起 + 原卡半透明）→ 悬停目标任务列（绿色边框）→ 释放（`onAcceptWithDetails`）→ 回调 `onStoryMove(story, newTaskId)` → 外部 `copyWith` 更新模型。

---

## 七、折叠 / 展开实现（🆕 新增）

```dart
// 每个 Release 行维护一个布尔状态
bool _isExpanded = true;

// 方案一：AnimatedSize 平滑动画
AnimatedSize(
  duration: const Duration(milliseconds: 200),
  child: _isExpanded ? Row(/* 本行故事卡片 */) : const SizedBox.shrink(),
)

// 方案二：Visibility 保留状态
Visibility(
  visible: _isExpanded,
  maintainState: true,  // 保持子树状态，折叠后不丢失拖拽/滚动状态
  child: Row(/* 本行故事卡片 */),
)
```

核心数据逻辑只需在对应 Release 上维护 `isExpanded` 布尔值。

---

## 八、视觉规范

### 8.1 矩阵层颜色

| 层 | 色值 | 用途 |
|----|------|------|
| 活动层 | `#FFB74D`（橙） | 活动标题，加粗 12px，深色文字 |
| 任务层 | `#B39DDB`（紫） | 任务标题，11px 白字 |
| 故事卡片 | `#BBDEFB` 底 / `#90CAF9` 边框 | 故事标题 10px，黑色 87% |
| 分隔线 | `grey` 0.5px | Release 行头 |

### 8.2 状态圆点（卡片右上角）

| 状态 | 色值 | 含义 |
|------|------|------|
| done | `#27AE60` 绿 | 完成 |
| inProgress | `#F39C12` 琥珀 | 进行中 |
| todo | `#B0BEC5` 浅灰 | 待办 |

### 8.3 视觉减负约定

- 故事卡片不按阶段着色，阶段仅以极小灰色文字弱化提示
- 活动层 6 色循环小色标（`ActivitySection._getAccentColor`）在矩阵化后不再需要——活动标题本身占据整块橙色

---

## 九、组件接口（API）

```dart
class StoryMapCanvasView extends StatelessWidget {
  final List<ColumnDef> columns;          // 列定义（列驱动）
  final List<String> releases;            // Release 行列表
  final Function(UserStory, String)? onStoryMove; // 故事移动到新任务
  final Function(UserStory)? onStoryTap;          // 故事点击
}
```

> 兼容：旧接口 `mapData: StoryMap` 由投影逻辑（`projectToColumns`）在页面层完成，画布组件内部不再直接依赖领域模型结构。

---

## 十、已实现 / 待实现

### ✅ 已实现（保留）
- [x] 三层领域模型与视图分离（copyWith 不可变数据）
- [x] 拖拽交互（LongPressDraggable + DragTarget）与跨任务移动
- [x] 拖拽视觉反馈（浮起卡片、半透明原卡、绿色边框）
- [x] 故事卡片三层信息 + 状态圆点
- [x] 双滚动（垂直 + 水平）

### 🆕 待实现（矩阵化）
- [ ] `ActivityLayerRow` / `TaskLayerRow` / `ReleaseRow` / `StoryColumn` 组件
- [ ] `projectToColumns(StoryMap)` 列投影函数
- [ ] Release 行折叠 / 展开（isExpanded + AnimatedSize）
- [ ] 移除 Release Line 虚线（由 Release 行表达发布边界）
- [ ] 移除 `ActivitySection` 分组嵌套与 `TaskColumn` 固定宽度

### 🚀 后续优化方向

| 优先级 | 功能 | 说明 |
|--------|------|------|
| 高 | 懒加载 | `ListView.builder` 替代 `Row + map`，列多时横向懒加载 |
| 中 | 背景网格线 | `CustomPaint` 绘制辅助线 |
| 中 | 缩放 | `InteractiveViewer` 支持 Pinch |
| 中 | 数据持久化 | 与后端 API 集成 |
| 低 | 防抖保存 | 拖拽结束防抖写库 |
| 低 | 撤销 / 重做 | 命令模式 |

---

## 十一、参考

- 模型设计：[models/story_mapping_models.md](../models/story_mapping_models.md)
- 页面设计：[screens/requirement_screen.md](../screens/requirement_screen.md)
- 架构设计：[docs/dev-guide/architecture.md](../../../docs/dev-guide/architecture.md)
- 交互设计：[docs/dev-guide/design/components/story_map_canvas.md](../../../docs/dev-guide/design/components/story_map_canvas.md)
- Flutter 官方文档：https://flutter.dev
