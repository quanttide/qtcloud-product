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
    *   属性：id, title, taskID (所属任务), phase (发布阶段), status (状态), description。

*   顶层容器
    *   类名：StoryMap
    *   含义：整个用户故事地图的根对象。
    *   属性：id, name, activities (活动列表)。

2. UI 组件命名（展示层 / Flutter Widget）

这一层代表了屏幕上的像素和交互，名字要直观、体现形态。

需求屏采用「二维矩阵 + 跨列合并」布局（详见 [需求屏设计](../../../src/studio/doc/screens/requirement_screen.md)）：

*   第一层：活动层行
    *   组件名：ActivityLayerRow
    *   含义：橙色层，展示 UserActivity 标题；同一活动覆盖多个任务列时跨列合并（flex = 跨越列数）。
    *   职责：活动标题展示、跨列合并。

*   第二层：任务层行
    *   组件名：TaskLayerRow
    *   含义：紫色层，展示 UserTask 标题，每列一个任务。
    *   职责：任务标题展示、列对齐。

*   第三层：Release 行
    *   组件名：ReleaseRow
    *   含义：按发布版本（如 'MVP 版本' / '未来迭代'）分组的行，行内为各列的故事卡片。
    *   职责：版本行头（可折叠）、故事卡片列表、拖放目标。

*   故事明细卡
    *   组件名：StoryCard
    *   含义：用于展示一个 UserStory 的最小视觉单元。
    *   职责：显示故事标题、描述、状态圆点。

*   视图模型（页面层）
    *   类名：ColumnDef
    *   含义：列驱动视图模型，不是领域模型。领域模型（StoryMap）经 `projectToColumns()` 投影为列定义数组，每列含活动标题、任务标题、任务 id 与按 Release 分组的故事。
    *   职责：把二维矩阵拆为「列数 × 行数」个横向 Row，配合懒加载保证秒级渲染。

*   顶层画布
    *   组件名：StoryMapCanvas
    *   含义：整个地图的根组件。
    *   职责：整体滚动（垂直 + 水平）、矩阵行渲染、拖拽交互。

3. 命名映射对照表

为了让你更直观地理解，我做了一个映射表：
层级   业务概念 (What)   领域模型类名   UI 组件类名 (How)   备注
第一层   用户活动 (主干)   UserActivity   ActivityLayerRow   橙色层，跨列合并。
第二层   用户任务 (骨架)   UserTask   TaskLayerRow   紫色层，每列一个任务。
第三层   用户故事 (细节)   UserStory   StoryCard   逻辑上叫故事，视觉上叫卡片。
发布行  发布版本 (MVP/未来)   UserStory.phase   ReleaseRow   按版本分组的可折叠行。
容器   故事地图   StoryMap   StoryMapCanvas   逻辑上叫地图，视觉上叫画布。

4. 数据流向与组合逻辑

在代码中，它们的组合关系是这样的：

1.  数据层：
    *   StoryMap 包含多个 UserActivity。
    *   每个 UserActivity 包含多个 UserTask。
    *   每个 UserTask 包含多个 UserStory。

2.  视图层：
    *   StoryMapCanvas 接收 StoryMap 数据，经 `projectToColumns()` 投影为 `ColumnDef[]`。
    *   ActivityLayerRow 遍历列定义，为连续同活动的列渲染跨列合并的活动标题。
    *   TaskLayerRow 遍历列定义，为每个任务列渲染任务标题。
    *   ReleaseRow 遍历列定义，按 Release 版本取出各列故事，为每个 UserStory 创建一个 StoryCard。

5. 为什么这样命名最好？

1.  职责清晰：
    *   当你看到 UserActivity 时，你知道它是数据，里面可能有复杂的业务逻辑。
    *   当你看到 ActivityLayerRow 时，你知道它是视图，只负责怎么把数据画得好看。

2.  避免混淆：
    *   不会把“业务上的活动”和“界面上的行/卡片”混为一谈。

3.  易于维护：
    *   如果未来 UI 改版，比如把 ActivityLayerRow 改成别的行组件，你只需要改组件名，不需要动业务逻辑里的 UserActivity。

4.  符合直觉：
    *   层（Layer）与行（Row）直接对应渲染结构：活动层跨列、任务层每列一个、Release 行按版本分组，视觉层级与业务层级一致。
