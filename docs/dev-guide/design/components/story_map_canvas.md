# 用户故事地图

> **⚠️ 已过时**：本文档描述早期「活动分组 → 任务列」嵌套布局与 Release Line 方案。
> 需求屏现采用「二维矩阵 + 跨列合并」布局（活动层 → 任务层 → Release 行，可折叠），
> 最新设计见 [需求屏设计](../../../../src/studio/doc/screens/requirement_screen.md)。

既然我们已经明确了“领域模型”与“UI组件”分离的设计哲学，那么 StoryMapCanvas 的设计重点就不再是“存数据”，而是“展示”与“交互”。

在 Flutter 中，StoryMapCanvas 应该是一个巨大的、可滚动的容器组件。它的核心职责是协调 ActivitySection（用户活动分组）与 TaskColumn（用户任务列）的布局，并处理复杂的拖拽排序逻辑。

以下是 StoryMapCanvas 的详细设计方案：

🧱 1. 核心布局结构

StoryMapCanvas 采用三层结构：**用户活动是上级分组，用户任务是最小列，用户故事是列内卡片**（取消“泳道”概念）。

*   外层容器：SingleChildScrollView (纵向滚动)
    *   作用：允许用户纵向浏览所有用户活动分组。
*   内层结构：Column
    *   作用：自上而下排列所有的 ActivitySection。
*   子元素：ActivitySection (多个)
    *   作用：每个 ActivitySection 代表一个 UserActivity 分组，组内横向排列 TaskColumn。
*   最小列：TaskColumn (多个)
    *   作用：每个 TaskColumn 代表一个 UserTask，列内纵向堆叠 StoryCard。

代码结构示意：
Widget build(BuildContext context) {
  return SingleChildScrollView(
    scrollDirection: Axis.vertical, // 纵向滚动
    child: Column(
      children: widget.mapData.activities.map((activity) {
        return ActivitySection( // 每一个用户活动分组
          activity: activity,
          onTaskReorder: _handleTaskReorder, // 传递拖拽排序的回调
          onStoryReorder: _handleStoryReorder,
        );
      }).toList(),
    ),
  );
}

🎨 2. 视觉元素构成

为了让这张“画布”不仅仅是白板，你需要绘制一些辅助视觉元素。建议使用 Stack 叠加在滚动视图之上：

*   背景网格线：
    *   使用 CustomPaint 绘制浅灰色的垂直线和水平线，帮助用户对齐卡片。
*   MVP 分界线 (Release Line)：
    *   视觉：一条细浅色虚线，表示上下阶段的切分（MVP 与未来迭代）。
    *   交互：这条线应该是可拖动的。用户上下拖动这条线，来界定哪些故事属于 MVP（上线版本），哪些属于后续迭代。
    *   实现：在 Stack 的顶层画一条线，并监听其 Drag 事件。
*   坐标轴标签：
    *   横轴 (X)：用户活动分组的标题（分组头部）。
    *   纵轴 (Y)：发布阶段（MVP 版本 / 未来迭代），以 Release Line 为界。

🖱️ 3. 核心交互逻辑

StoryMapCanvas 是交互的中枢，它需要处理复杂的拖拽事件。

A. 拖拽排序 (Drag and Drop)
这是画布的灵魂。用户应该能：
*   上下拖动：调整故事的发布阶段（从 MVP 拖到 Future，跨过 Release Line）。
*   左右拖动：将故事从一个任务列（TaskColumn）移动到另一个任务列（比如把“支付失败”的故事从“下单”列移到“售后”列）。

技术实现建议：
*   方案一（原生）：使用 Flutter 的 LongPressDraggable 和 DragTarget。
    *   LongPressDraggable 包裹每一个 StoryCard。
    *   DragTarget 包裹每一个 TaskColumn 的投放区域。
    *   优点：灵活，完全可控。
    *   缺点：代码量较大，需要处理复杂的坐标计算。
*   方案二（插件）：使用 syncfusion_flutter_kanban 或 flutter_staggered_grid_view。
    *   优点：自带看板布局和拖拽，开发速度快。
    *   缺点：定制化程度可能受限。

B. 缩放与视图控制
*   缩放：像 Figma 一样，支持双指缩放（Pinch Gesture），让用户既能看全貌（俯视图），也能看细节（特写）。
*   自动吸附：当用户拖动卡片时，卡片应该自动对齐到网格线或相邻卡片的边缘。

📦 4. 数据流设计

StoryMapCanvas 本身不应该持有数据状态（除非你用 StatefulWidget 搞原型），它应该是一个“纯展示组件”。

*   输入 (Props)：
    *   StoryMap mapData：从父组件或状态管理器（如 Provider/Bloc）传入的领域模型数据。
*   输出 (Events)：
    *   onActivityAdd：当用户点击“添加活动”时触发。
    *   onTaskMove：当任务被拖拽移动时，通知外部数据层更新顺序。
    *   onStoryPriorityChange：当故事被拖过 MVP 线时，通知外部更新其优先级属性。

🛠️ 5. 性能优化策略

由于故事地图可能包含成百上千张卡片，性能是关键。

*   懒加载 (Lazy Loading)：
    *   只渲染当前屏幕可视区域内的 ActivitySection / TaskColumn 和 StoryCard。
    *   使用 ListView.builder 替代 Column + List.generate，以实现纵向的懒加载。
*   防抖 (Debounce)：
    *   对于拖拽结束后的“保存数据”操作，增加防抖机制，避免用户频繁拖拽时频繁写库。
*   Immutable 数据：
    *   每次拖拽结束，生成一个新的 StoryMap 对象，而不是修改原对象，这有助于 Flutter 的 shouldRebuild 机制高效工作。

📌 总结：StoryMapCanvas 的职责清单

为了让你在写代码时不跑偏，StoryMapCanvas 应该只做以下几件事：

1.  画布：提供一个宽大的、可纵向滚动的平面。
2.  布局：把 ActivitySection 垂直排列（组内 TaskColumn 水平排列），并绘制背景网格。
3.  交互：处理卡片的拖拽、移动、排序。
4.  分界：展示并允许调整 MVP 虚线。
5.  通讯：把用户的操作转化为事件，告诉外面的“世界”：“数据变了，请更新”。

不要在 StoryMapCanvas 里做：
*   不要直接调用 API 保存数据（应该通过回调通知上层）。
*   不要包含复杂的业务逻辑（如“计算这个故事是否属于 MVP”，这应该在 UserStory 模型里计算好）。

这样设计，你的 StoryMapCanvas 就会是一个高性能、高内聚、低耦合的“画布”。
