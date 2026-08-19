# qtcloud-product-cli 文档

## 总览

- [架构：以用户故事为中心的需求梳理](architecture.md) — 领域模型、模块划分、status/audit/action 三分法
- [规格对比：事件风暴规格 vs 当前 CLI](specification-gap.md) — 规格与实现的差距及演进方向

## 模块文档

按功能模块组织，每个模块一份文档（命令、数据格式、规则）：

| 模块 | 文档 | 职责 |
|------|------|------|
| requirement | [需求梳理](modules/requirement.md) | 用户故事文档管理 |
| story | [用户故事地图](modules/story.md) | 地图视图与渲染数据加工 |
| roadmap | [版本计划](modules/roadmap.md) | MVP / 未来迭代计划 |
| release | [发布管理](modules/release.md) | 版本预检与发布 |
| doctor | [环境诊断](modules/doctor.md) | 外部工具链检查 |

## 快速导览

```
qtcloud-product requirement list/show/add/edit/remove/status   # 需求梳理
qtcloud-product story status/map/export                        # 用户故事地图
qtcloud-product roadmap status/plan                            # 版本计划
qtcloud-product release status/audit/publish                   # 发布管理
qtcloud-product doctor status                                  # 环境诊断
qtcloud-product status / audit / help                          # 概览与导览
```
