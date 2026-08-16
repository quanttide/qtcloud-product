# 架构设计文档

这套规则的核心原则是：领域模型（数据）与 UI 组件（视图）分离。

1. 领域模型命名（数据层 / 业务逻辑）

这一层代表了业务的本质，名字要严谨、准确，符合用户故事地图的方法论。

*   第一层：主干流程
    *   类名：UserActivity
    *   含义：代表用户为了达成目标所经历的宏观阶段。它是地图的“脊柱”。
    *   属性：id, title, order (排序), tasks (包含的任务列表)。

*   第二层：用户任务
    *   类名：UserTask
    *   含义：代表用户在某个活动下为了完成目标所要执行的具体动作。它是地图的“行走的骨骼”。
    *   属性：id, title, activityId (所属活动), stories (包含的故事列表)。

*   第三层：用户故事
    *   类名：UserStory
    *   含义：代表为了实现某个任务而需要开发的具体功能点或技术细节。
    *   属性：id, title, taskID (所属任务), priority (优先级), status (状态)。

*   顶层容器
    *   类名：StoryMap
    *   含义：整个用户故事地图的根对象。
    *   属性：id, name, activities (活动列表)。

2. UI 组件命名（展示层 / Flutter Widget）

这一层代表了屏幕上的像素和交互，名字要直观、体现形态。

*   第一层：泳道容器
    *   组件名：ActivityLane
    *   含义：用于展示一个 UserActivity 的横向容器。它像一条泳道，里面装着该活动下的所有任务和故事。
    *   职责：横向布局、背景色区分、标题展示。

*   第二层：任务卡片组
    *   组件名：TaskCard
    *   含义：用于展示一个 UserTask 的视觉卡片。
    *   职责：显示任务标题、作为故事卡片的容器、处理拖拽交互。

*   第三层：故事明细卡
    *   组件名：StoryCard
    *   含义：用于展示一个 UserStory 的最小视觉单元。
    *   职责：显示故事标题、优先级标签、状态标签。

*   顶层画布
    *   组件名：StoryMapCanvas
    *   含义：整个地图的根组件。
    *   职责：整体滚动、背景网格绘制、MVP分界线绘制。

3. 命名映射对照表

为了让你更直观地理解，我做了一个映射表：
层级   业务概念 (What)   领域模型类名   UI 组件类名 (How)   备注
第一层   用户活动 (主干)   UserActivity   ActivityLane   逻辑上叫活动，视觉上叫泳道。
第二层   用户任务 (骨架)   UserTask   TaskCard   逻辑上叫任务，视觉上叫卡片。
第三层   用户故事 (细节)   UserStory   StoryCard   逻辑上叫故事，视觉上叫卡片。
容器   故事地图   StoryMap   StoryMapCanvas   逻辑上叫地图，视觉上叫画布。

4. 数据流向与组合逻辑

在代码中，它们的组合关系是这样的：

1.  数据层：
    *   StoryMap 包含多个 UserActivity。
    *   每个 UserActivity 包含多个 UserTask。
    *   每个 UserTask 包含多个 UserStory。

2.  视图层：
    *   StoryMapCanvas 接收 StoryMap 数据。
    *   StoryMapCanvas 遍历数据，为每个 UserActivity 创建一个 ActivityLane。
    *   ActivityLane 接收 UserActivity 数据，为每个 UserTask 创建一个 TaskCard。
    *   TaskCard 接收 UserTask 数据，为每个 UserStory 创建一个 StoryCard。

5. 为什么这样命名最好？

1.  职责清晰：
    *   当你看到 UserActivity 时，你知道它是数据，里面可能有复杂的业务逻辑。
    *   当你看到 ActivityLane 时，你知道它是视图，里面只负责怎么把数据画得好看。

2.  避免混淆：
    *   不会把“业务上的活动”和“界面上的卡片”混为一谈。

3.  易于维护：
    *   如果未来 UI 改版，比如把 ActivityLane 改成 ActivityColumn，你只需要改组件名，不需要动业务逻辑里的 UserActivity。

4.  符合直觉：
    *   Lane（泳道）这个词非常形象地表达了“横向流程、纵向堆叠”的视觉特征。