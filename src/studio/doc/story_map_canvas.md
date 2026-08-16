# StoryMapCanvas 实现总结

**日期**: 2026年1月7日  
**项目**: QtCloud Product Studio  
**技术栈**: Flutter 3.x + Dart

---

## 一、项目结构

```
src/studio/lib/
├── main.dart                           # 应用入口，种子数据（三个产品）
├── data/
│   └── seed_data.dart                 # 种子数据：三个实验产品的故事地图
├── models/
│   ├── product_models.dart            # 领域模型：产品（组合层第二层）
│   └── story_map_models.dart          # 领域模型：数据层（核心业务逻辑）
└── widgets/
    ├── story_card.dart                # UI 组件：故事卡片（最小单元）
    ├── task_column.dart               # UI 组件：用户任务列（最小列）
    ├── activity_section.dart          # UI 组件：用户活动分组（上级分组）
    └── story_map_canvas.dart          # UI 组件：故事地图画布（根组件）
```

---

## 二、已实现功能

### 2.1 数据模型层（models/story_map_models.dart）

完整实现了三层领域模型 + 容器结构：

#### 1️⃣ 枚举类型
- **ReleasePhase**：发布阶段（MVP 版本 / 未来迭代）
- **StoryStatus**：故事状态（To Do/In Progress/Done）

#### 2️⃣ 数据类
| 类名 | 职责 | 主要属性 |
|------|------|--------|
| `UserStory` | 用户故事（细节层） | id, title, taskId, phase, status, description |
| `UserTask` | 用户任务（骨架层） | id, title, activityId, stories[], order |
| `UserActivity` | 用户活动（主干层） | id, title, tasks[], order, color |
| `StoryMap` | 故事地图（容器） | id, name, activities[], mvpLinePosition |

**设计特点**：
- 所有数据类都实现了 `copyWith()` 方法，支持创建修改后的副本
- 支持不可变数据模式，有利于 Flutter 的高效渲染
- 包含完整的 `toString()` 用于调试

### 2.2 UI 组件层

#### 📍 StoryCard（故事卡片）
**文件**: [widgets/story_card.dart](src/studio/lib/widgets/story_card.dart)

**职责**: 展示单个 UserStory 的最小视觉单元

**特点**:
- 三层信息展示：标题（用户语言）→ 描述（具体命令/细节）→ 发布阶段
- 状态用右上角小圆点（🟢 完成 / 🟡 进行中 / ⚪ 待办），不做大色块
- 支持长按（onLongPress）和点击（onTap）交互
- 拖拽时显示半透明效果

**代码示例**:
```dart
StoryCard(
  story: userStory,
  onTap: () => print('点击'),
  onLongPress: () => print('长按'),
)
```

#### 🎫 TaskColumn（用户任务列）
**文件**: [widgets/task_column.dart](src/studio/lib/widgets/task_column.dart)

**职责**: 展示单个 UserTask 的最小列，作为 StoryCard 的容器

**特点**:
- 任务标题显示在列头（白底）
- 列内使用 `DragTarget` 接收拖放的故事卡片
- 支持跨任务拖拽（从一个任务列拖到另一个任务列）
- 拖拽有效区域时显示绿色边框反馈
- 纵向堆叠所有属于该任务的故事

**代码示例**:
```dart
TaskColumn(
  task: userTask,
  onStoryMove: (story, newTaskId) => updateTask(story, newTaskId),
  onStoryTap: (story) => navigateToDetail(story),
)
```

#### 🗂️ ActivitySection（用户活动分组）
**文件**: [widgets/activity_section.dart](src/studio/lib/widgets/activity_section.dart)

**职责**: 展示单个 UserActivity 的上级分组，作为任务列的容器

**特点**:
- 用户活动是包含用户任务的上级分组（取消"泳道"概念）
- 分组标题 + 小色标（6 种配色循环，仅作轻度区隔）
- 组内任务列横向排列（可横向滚动），分组自上而下排列
- 浅色底 + 细边框，视觉减负

#### 🎨 StoryMapCanvasPage（故事地图画布）
**文件**: [widgets/story_map_canvas.dart](src/studio/lib/widgets/story_map_canvas.dart)

**职责**: 整个地图的根组件，协调所有子组件的显示和交互

**特点**:
- 内容区头部显示"量潮产品云 · 产品名"
- **垂直滚动**：用户可以纵向浏览所有用户活动分组
- **三层结构**：用户活动（分组）→ 用户任务（最小列）→ 用户故事（卡片）
- **拖拽交互已实现**：
  - ✅ 使用 `LongPressDraggable` + `DragTarget` 架构
  - ✅ 故事卡片被拖动时显示反馈
  - ✅ 拖入 TaskColumn 的 DragTarget 区域时显示绿色高亮
  - ✅ 支持跨任务移动故事
- **发布线**：细浅色虚线，可拖动，区分 MVP 与未来迭代

**架构示意**:
```
SingleChildScrollView (纵向)
  └── Column (活动分组自上而下排列)
      └── ActivitySection × N (多个活动分组)
          └── SingleChildScrollView (横向)
              └── Row (任务列横向排列)
                  └── TaskColumn × M (多个任务列)
                      └── StoryCard × K (多个故事卡片)
```

---

## 三、核心交互实现

### 拖拽与放置（Drag and Drop）

**技术方案**：Flutter 原生 `LongPressDraggable` + `DragTarget`

```dart
// StoryCard 被包裹在 LongPressDraggable 中
LongPressDraggable<UserStory>(
  data: story,
  feedback: StoryCard(...),        // 拖动时显示
  childWhenDragging: Opacity(...), // 原位置显示半透明
  child: StoryCard(...),           // 正常状态
)

// TaskColumn 内部使用 DragTarget 接收故事
DragTarget<UserStory>(
  onAcceptWithDetails: (details) {
    // 故事被放入此任务
    onStoryMove?.call(details.data, task.id);
  },
  builder: (context, candidateData, rejectedData) {
    // 显示视觉反馈（绿色边框）
  },
)
```

**交互流程**：
1. 长按故事卡片（LongPress）→ 开始拖动
2. 拖动时显示卡片反馈（Material 卡片，elevation=5）
3. 悬停在目标任务上 → 显示绿色边框反馈
4. 释放鼠标 → DragTarget 的 `onAcceptWithDetails` 触发回调
5. 回调通知外部更新数据模型

---

## 四、示例数据

在 [main.dart](src/studio/lib/main.dart) 中预置了一个完整的电商平台用户故事地图示例：

### 3个活动 × 多个任务 × 多个故事

```
📦 电商平台用户故事地图
│
├── 订购流程（蓝色）
│   ├── 浏览商品
│   │   ├── [MUST] 显示商品列表 ✓ Done
│   │   └── [MUST] 搜索商品 🔄 InProgress
│   └── 加入购物车
│       ├── [MUST] 添加商品到购物车 ✓ Done
│       └── [SHOULD] 更新购物车数量 ⭕ To Do
│
├── 支付流程（绿色）
│   ├── 填写收货地址
│   │   ├── [MUST] 地址验证 🔄 InProgress
│   │   └── [SHOULD] 保存地址簿 ⭕ To Do
│   └── 选择支付方式
│       ├── [MUST] 支持微信支付 ✓ Done
│       ├── [SHOULD] 支持支付宝 ⭕ To Do
│       └── [COULD] 支持银行卡 ⭕ To Do
│
└── 售后服务（黄色）
    ├── 退货申请
    │   └── [SHOULD] 申请退货 ⭕ To Do
    └── 退款处理
        └── [COULD] 自动退款 ⭕ To Do
```

---

## 五、API 接口

### StoryMapCanvasPage 组件接口

```dart
class StoryMapCanvasPage extends StatelessWidget {
  // 输入：故事地图数据
  final StoryMap mapData;
  
  // 输出：事件回调
  final Function(UserStory, String)? onStoryMove;      // 故事被移动到新任务
  final Function(UserStory)? onStoryTap;               // 故事被点击
  
  const StoryMapCanvasPage({...});
}
```

### 使用示例

```dart
StoryMapCanvasPage(
  mapData: storyMap,
  onStoryMove: (story, newTaskId) {
    setState(() {
      // 更新数据模型
      final newStory = story.copyWith(taskId: newTaskId);
      updateStory(newStory);
    });
  },
  onStoryTap: (story) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => StoryDetailPage(story)),
    );
  },
)
```

---

## 六、关键技术特性

### ✅ 已实现
- [x] 三层数据模型与视图分离
- [x] 彩色编码（优先级、活动、状态）
- [x] 拖拽交互（LongPressDraggable + DragTarget）
- [x] 跨任务移动故事
- [x] 视觉反馈（拖动、放置）
- [x] 响应式布局（横向滚动）
- [x] 不可变数据模式（copyWith）

### 🚀 后续优化方向

| 优先级 | 功能 | 说明 |
|--------|------|------|
| 高 | MVP 分界线拖动 | 红色虚线，可拖动调整优先级分界 |
| 高 | 背景网格线 | 使用 CustomPaint 绘制辅助线 |
| 中 | 缩放功能 | InteractiveViewer 支持 Pinch 缩放 |
| 中 | 懒加载 | ListView.builder 替代 Row + map |
| 中 | 数据持久化 | 与后端 API 集成 |
| 低 | 防抖与性能 | 拖拽结束时的防抖保存 |
| 低 | 撤销/重做 | 命令模式支持操作历史 |

---

## 七、编译与运行

### 编译状态
✅ **无编译错误**

### 运行命令
```bash
cd /Users/mac/repos/qtcloud-product/src/studio

# Web 浏览器
flutter run -d chrome

# iOS 模拟器
flutter run -d ios

# Android 模拟器
flutter run -d android
```

### 成功运行
应用已在 Chrome 中成功启动，展示了完整的用户故事地图界面。

---

## 八、文件统计

| 文件 | 行数 | 职责 |
|------|------|------|
| main.dart | — | 应用入口 + 侧边导航 + 产品画布视图 |
| seed_data.dart | — | 种子数据（三个实验产品） |
| product_models.dart | — | 产品领域模型 |
| story_map_models.dart | ~157 | 数据模型定义 |
| story_card.dart | ~114 | 故事卡片组件 |
| task_column.dart | — | 用户任务列组件 |
| activity_section.dart | — | 用户活动分组组件 |
| story_map_canvas.dart | ~120 | 画布根组件 |

---

## 九、下一步行动项

### Phase 2：交互增强
- [ ] 实现 MVP 分界线拖动功能
- [ ] 添加背景网格线（CustomPaint）
- [ ] 实现缩放功能（InteractiveViewer）
- [ ] 添加动画过渡（AnimatedContainer）

### Phase 3：性能优化
- [ ] 使用 ListView.builder 实现懒加载
- [ ] 添加防抖机制（Timer + debounce）
- [ ] 优化重建次数（const、RepaintBoundary）

### Phase 4：功能完善
- [ ] 添加创建/编辑活动、任务、故事的 UI
- [ ] 实现数据持久化（SQLite 或 API）
- [ ] 添加撤销/重做功能
- [ ] 支持主题切换

---

## 十、参考文档

- 📋 架构设计指南：[StoryMapCanvas_Implementation_Guide.md](../StoryMapCanvas_Implementation_Guide.md)
- 📐 架构设计：[docs/dev-guide/architecture.md](../docs/dev-guide/architecture.md)
- 🎨 交互设计：[docs/dev-guide/design/components/story_map_canvas.md](../docs/dev-guide/design/components/story_map_canvas.md)
- 📚 Flutter 官方文档：https://flutter.dev

---

**状态**: ✅ MVP 阶段完成，可交互演示  
**最后更新**: 2026年1月7日
