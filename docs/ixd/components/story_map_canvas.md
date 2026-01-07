# 用户故事地图

既然我们已经明确了“领域模型”与“UI组件”分离的设计哲学，那么 StoryMapCanvas 的设计重点就不再是“存数据”，而是“展示”与“交互”。

在 Flutter 中，StoryMapCanvas 应该是一个巨大的、可滚动的容器组件。它的核心职责是协调 ActivityLane（泳道）的布局，并处理复杂的拖拽排序逻辑。

以下是 StoryMapCanvas 的详细设计方案：

🧱 1. 核心布局结构

StoryMapCanvas 本质上是一个 “横向滚动的列表，里面装着纵向堆叠的卡片”。

*   外层容器：SingleChildScrollView (横向滚动)
    *   作用：允许用户横向浏览整个用户旅程。
*   内层结构：Row
    *   作用：水平排列所有的 ActivityLane。
*   子元素：ActivityLane (多个)
    *   作用：每个 ActivityLane 代表一个 UserActivity，它内部是一个纵向的 Column。

代码结构示意：
Widget build(BuildContext context) {
  return SingleChildScrollView(
    scrollDirection: Axis.horizontal, // 横向滚动
    child: Row(
      children: widget.mapData.activities.map((activity) {
        return ActivityLane( // 每一个泳道
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
    *   视觉：一条醒目的红色/橙色虚线，贯穿整个画布的纵向。
    *   交互：这条线应该是可拖动的。用户上下拖动这条线，来界定哪些故事属于 MVP（上线版本），哪些属于后续迭代。
    *   实现：在 Stack 的顶层画一条线，并监听其 Drag 事件。
*   坐标轴标签：
    *   横轴 (X)：UserActivity 的标题（通常在泳道顶部）。
    *   纵轴 (Y)：优先级刻度（如：Must Have, Should Have, Could Have），可以作为画布左侧的侧边栏。

🖱️ 3. 核心交互逻辑

StoryMapCanvas 是交互的中枢，它需要处理复杂的拖拽事件。

A. 拖拽排序 (Drag and Drop)
这是画布的灵魂。用户应该能：
*   上下拖动：调整故事的优先级（从“Must”拖到“Could”）。
*   左右拖动：将故事从一个活动（泳道）移动到另一个活动（比如把“支付失败”的故事从“下单”移到“售后”）。

技术实现建议：
*   方案一（原生）：使用 Flutter 的 LongPressDraggable 和 DragTarget。
    *   LongPressDraggable 包裹每一个 StoryCard。
    *   DragTarget 包裹每一个 ActivityLane 的投放区域。
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
    *   只渲染当前屏幕可视区域内的 ActivityLane 和 StoryCard。
    *   使用 ListView.builder 替代 Row + List.generate，以实现横向的懒加载。
*   防抖 (Debounce)：
    *   对于拖拽结束后的“保存数据”操作，增加防抖机制，避免用户频繁拖拽时频繁写库。
*   Immutable 数据：
    *   每次拖拽结束，生成一个新的 StoryMap 对象，而不是修改原对象，这有助于 Flutter 的 shouldRebuild 机制高效工作。

📌 总结：StoryMapCanvas 的职责清单

为了让你在写代码时不跑偏，StoryMapCanvas 应该只做以下几件事：

1.  画布：提供一个宽大的、可横向滚动的平面。
2.  布局：把 ActivityLane 水平排列，并绘制背景网格。
3.  交互：处理卡片的拖拽、移动、排序。
4.  分界：展示并允许调整 MVP 虚线。
5.  通讯：把用户的操作转化为事件，告诉外面的“世界”：“数据变了，请更新”。

不要在 StoryMapCanvas 里做：
*   不要直接调用 API 保存数据（应该通过回调通知上层）。
*   不要包含复杂的业务逻辑（如“计算这个故事是否属于 MVP”，这应该在 UserStory 模型里计算好）。

这样设计，你的 StoryMapCanvas 就会是一个高性能、高内聚、低耦合的“画布”。
