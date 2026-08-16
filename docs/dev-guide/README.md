# 开发指南

面向 QtCloud Studio 开发者的指南，覆盖定位与核心设计、架构设计、交互设计与产品需求。

## 定位与核心设计

- [产品定位与核心设计](positioning.md)：量潮产品云是产品决策平台——集中管理和可视化所有产品；核心设计是模型层级（产品组合 → 产品 → 用户故事地图）、视图体系与决策机制。

## 想法记录

想法升级都记录在这里，每条想法含背景、需求与演化路径，不代表承诺。

- [想法记录](ideas.md)：当前想法——多产品集中管理与可视化平台。

## 架构设计

领域模型（数据）与 UI 组件（视图）分离的命名规范。

- [架构设计](architecture.md)：领域模型类名（UserActivity / UserTask / UserStory / StoryMap）与 UI 组件类名（ActivitySection / TaskColumn / StoryCard / StoryMapCanvas）的命名映射、数据流向与组合逻辑。

## 交互设计

- [交互设计文档](design/README.md)：交互设计总览。
- [用户故事地图组件设计](design/components/story_map_canvas.md)：StoryMapCanvas 的布局结构、视觉元素、拖拽交互、数据流设计与性能优化策略。

## 产品需求

以用户故事为单位管理产品需求，包含用户故事管理、用户故事地图、原型绘制与版本计划。

- [产品需求文档](prd/README.md)：PRD 文档导航。
- [管理用户故事](prd/stories/stories/README.md)：以用户故事为单位管理产品需求。
- [管理用户故事地图](prd/stories/stories/user_story_mapping/README.md)：维护用户故事地图。
- [绘制原型](prd/stories/prototypes/README.md)：绘制产品原型。
- [制定版本计划](prd/stories/roadmaps/README.md)：制定版本计划。
