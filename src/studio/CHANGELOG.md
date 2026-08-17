# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

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
