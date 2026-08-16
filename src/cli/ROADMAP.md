# ROADMAP

## [0.2.0]

### 需求梳理

- [ ] `requirement` 支持用户任务管理：add / edit / remove 用户任务（活动 README 任务列表）
- [ ] `requirement` 支持用户活动管理：add 活动时自动创建目录与 README.md
- [ ] `requirement list` 支持 `--phase` / `--status` 过滤与 `--json` 输出

### 故事地图

- [ ] `story export` 支持 `--all`：为每个产品目录生成渲染数据
- [ ] `story map` 支持按 MVP 分界线可视化（mvp / future 分区展示）

### 发布

- [ ] `release publish` 支持 `--registry pypi`（maturin 构建并发布 wheel）
- [ ] `release` 支持 studio scope 的版本检查（pubspec.yaml 版本一致性）

### 质量

- [ ] 覆盖率门禁：`cargo llvm-cov` 接入 CI
- [ ] `preflight.sh` 接入 CI 工作流（校验版本一致性 + CHANGELOG + 干净工作区）

## [0.3.0]

- [ ] 与 Studio 交互闭环：拖拽修改的故事地图可回写用户故事文档
- [ ] 领域仓库扫描：从 `docs/` 子模块（specification / handbook / tutorial）提取产品结构
- [ ] 产品组合视图数据：manifest 之外的跨产品统计输出
