# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.1.0-alpha.8] - 2026-08-17

### Added

- 规格页事件风暴 MVP：数据驱动的事件流时间线（领域事件按时间顺序展开，点击查看命令/参与者/聚合/策略/查询模型详情）。
- 事件风暴种子数据：6 个产品各注入事件流场景（含异常分支事件，红色警示并标注分岔来源）。
- 部署缓存策略：main.dart.js 与种子数据 JSON 改为 no-cache 上传，发布后浏览器普通刷新即可见新数据；Service Worker 卸载补丁自动清理旧缓存。

### Changed

- 时间线双轨结构：异常事件从源事件分岔（不占主线位置），详情展示"分岔自"关系。

## [0.1.0-alpha.7] - 2026-08-17

### Fixed

- 部署时禁用 Service Worker，修复发布后浏览器缓存旧种子数据的问题（硬刷新无效，需清缓存才可见新数据）。

## [0.1.0-alpha.6] - 2026-08-17

### Fixed

- 修正 phase 枚举值：将 next 和 research 改为 future。
- 修正 CHANGELOG 格式（Keep a Changelog 标准）。

### Changed

- 严格遵循 requirement.md 更新 qtcloud-product 需求故事地图：添加梳理产品需求和评审产品需求任务及故事点。
- 更新 qtcloud-product 需求故事地图：添加 AI 生成、反馈、颗粒度检查和编辑故事点。

## [0.1.0-alpha.5] - 2026-08-17

### Added

- 为 qtcloud、qtcloud-secret、qthealth 新增种子数据。
- 新增产品数据只读 Provider 及其部署流水线。
- 新增产品数据桶与函数计算容器应用的基础设施配置。

### Changed

- 重构 qtcloud-product 用户故事地图，更新产品定位与设计思想。
- 种子数据迁移至 `src/studio/assets/data` 真实目录（替换符号链接）。
- 组件测试改用内置夹具，与种子数据解耦。

### Removed

- 移除遗留的旧 assets 数据目录。

## [0.1.0-alpha.4] - 2026-08-16

### Fixed

- 滚动条拇指改为布局阶段计算（原 build 阶段早于布局导致拇指永不显示）；滚动条加宽加深。

## [0.1.0-alpha.3] - 2026-08-16

### Fixed

- 滚动条修复：矩阵看板双层滚动条改为视口叠加式（垂直在右、水平在底，常显可拖动），不再藏于内容底部。

## [0.1.0-alpha.2] - 2026-08-16

### Added

- 需求看板（二维矩阵）双层滚动条常显（垂直浏览 Release 行、水平浏览任务列），不再隐藏滚动指示。
- 种子数据更新为 stage/lifecycle 形态（qtcloud-devops：生命周期八阶段 + 平台治理），新增故事文档 `docs/stories/`；新增 `src/cli/`（qtcloud-product-cli，Rust）。

## [0.1.0-alpha.1] - 2026-08-16

### Added

- 重构为产品云形态（参考项目管理软件）：顶部产品切换器（每个产品 = 一个项目空间，展示标题如「量潮DevOps云」，唯一命名 qtcloud-devops 用于识别）。
- 需求模块：用户故事地图看板升级为「二维矩阵 + 跨列合并」（活动层橙 → 任务层紫 → Release 行，可折叠）。
- 规格模块：事件风暴占位页。
- 页面分解至 `lib/screens/`（ProductCloudScreen / RequirementScreen / SpecificationScreen）。
- 故事卡片精简为仅展示标题（描述/阶段/状态保留在数据模型中）。
- 种子数据提取至仓库根 `assets/data/`（manifest + 每产品一个 JSON），Studio 仅加载渲染；约定 CLI 负责加工种子数据。
- 新增 `src/cli/`（qtcloud-product-cli，Rust）：契约、需求、规格、种子数据加工等模块。
- 部署：新增 deploy-studio CI（`studio/*` tag → OSS + CDN）与 manifests/terraform IaC，上线 https://product.cloud.quanttide.com。

## [0.0.1] - 2026-01-07

### Added

- IxD：增加用户故事地图组件设计。
- ADD：增加用户故事地图领域模型设计。
- 前端：实现用户故事地图 Canvas 组件。
