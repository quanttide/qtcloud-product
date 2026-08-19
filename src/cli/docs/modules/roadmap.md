# 版本计划模块（roadmap）

## 职责

按发布阶段（MVP / 未来迭代）分组用户故事，生成版本计划文档。

## 命令

```bash
qtcloud-product roadmap status                # 版本计划状态
qtcloud-product roadmap plan                  # 生成 MVP / 未来迭代计划
qtcloud-product roadmap plan --output docs/dev-guide/prd/stories/roadmaps/README.md
```

## 版本分类

用户故事 frontmatter 的 `phase` 字段决定版本归属：

- `mvp` — 当前版本（MVP 发布线内）
- `future` — 未来迭代

`roadmap plan` 按 phase 分组生成计划文档；输出到指定路径（默认仅打印到 stdout）。
