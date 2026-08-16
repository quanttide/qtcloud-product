# CHANGELOG

## [0.1.0] - 2026-08-16

### Added

- 初始化 CLI 骨架：`qtcloud-product`（量潮产品云命令行工具），参照 qtcloud-devops 的 `src/cli` 约定
- `requirement` 需求梳理：以用户故事为中心，list / show / add / edit / remove / status
  - 用户故事文档约定：Markdown + YAML frontmatter（title / activity / task / phase / status），兼容无 frontmatter 旧文档
- `story` 用户故事地图：status（三层统计）、map（活动 → 任务 → 故事视图）、export（加工 `assets/data/` 渲染数据并同步 manifest）
  - 多产品支持：`story status / map / export --product <id>`，故事文档根 `docs/stories/<id>/`（qtcloud-product 兼容历史路径）
- 案例：`examples/seed-workflow.md`（qtcloud-devops 生命周期建模与 CLI 加工全流程）、`examples/devops_export.rs`（库 API 示例）
- `roadmap` 版本计划：status、plan（MVP 版本 / 未来迭代分组）
- `release` 发布管理：status、audit（6 项预检门禁）、publish（预检 → 确认 → tag → push → GitHub Release，支持 --dry-run / -y / -f）
- `doctor` 环境诊断：git / gh / rust / dart 工具链检测
- 概览命令：`status`、`audit`、`help`
- 分发脚手架：pyproject.toml（maturin）+ packages/python，与 qtcloud-devops 一致
- 脚本：scripts/preflight.sh、scripts/validate-changelog.sh、scripts/validate-version.sh
- 文档：README / AGENTS / ROADMAP / CONTRIBUTING / docs/architecture.md
