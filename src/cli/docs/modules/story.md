# 用户故事地图模块（story）

## 职责

故事地图视图与渲染数据加工：活动 → 任务 → 故事三层统计、地图视图生成、Studio 渲染数据导出。

## 命令

```bash
qtcloud-product story status                  # 活动/任务/故事统计
qtcloud-product story status --product qtcloud-devops
qtcloud-product story map                     # 生成三层故事地图视图
qtcloud-product story map --product qtcloud-devops
qtcloud-product story export                  # 导出 Studio 渲染数据
qtcloud-product story export --product qtcloud-devops
qtcloud-product story export --stdout         # 仅打印，不写文件
```

## 渲染数据加工

`story export` 按仓库约定加工 `assets/data/`：

- 更新 `products/<id>.json`（保留人工维护的 title / tagline / designIdea / mvpLinePosition）
- 同步 `manifest.json` 产品清单
- 其他产品文件不受影响
- 只重建故事地图结构（activities / tasks / stories），防止加工过程破坏演示数据

## 多产品约定

每个产品的故事文档位于 `docs/stories/<产品id>/<活动>/`（活动目录含 README.md 任务列表 + 故事文档）。
qtcloud-product 兼容历史路径 `docs/dev-guide/prd/stories/stories/`（`stories_root_for` 回退）。
`story status / map / export` 均支持 `--product`。

建模参考（qtcloud-devops 案例，见 examples/seed-workflow.md）：
「lifecycle 是一个 Activity、八个阶段是 Task、具体功能是 Story」——一个活动承载生命周期
（plan → code → build → test → release → deploy → operate → monitor 八阶段任务），
其他活动（如 platform 管理平台）承载底座能力。

## 数据流

```
docs/stories/<产品id>/<活动>/    （事实源：用户故事文档）
        │  requirement 模块解析
        ▼
用户故事结构化数据（id/title/activity/task/phase/status）
        │  story export 生成
        ▼
assets/data/products/<id>.json   （Studio 渲染数据）
assets/data/manifest.json        （产品清单，同步更新）
        │  Studio 加载
        ▼
StoryMapCanvas 渲染（活动分组 → 任务列 → 故事卡片）
```
