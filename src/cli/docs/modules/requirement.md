# 需求梳理模块（requirement）

## 职责

以用户故事为单位管理产品需求：解析、增删改查、状态统计。用户故事文档是需求的事实源。

## 命令

```bash
qtcloud-product requirement list              # 列出用户故事
qtcloud-product requirement show <id>         # 查看用户故事详情（id 或标题）
qtcloud-product requirement add --title "..." # 添加用户故事
qtcloud-product requirement edit <id> --phase future
qtcloud-product requirement remove <id>       # 删除用户故事
qtcloud-product requirement status            # 需求梳理状态（按活动聚合）
```

## 文档格式

用户故事以 Markdown 文档管理，位于 `docs/dev-guide/prd/stories/stories/<activity>/`：

```markdown
---
title: 编辑用户故事
activity: user_story
task: 细化用户故事
phase: mvp        # mvp | future
status: done      # todo | inProgress | done
---

作为产品经理，我希望能够编辑用户故事的标题与描述，以便维护需求的最新状态。
```

- YAML frontmatter 为简化键值解析（title / activity / task / phase / status），支持的值有限且固定，不引入 serde_yaml 之外的格式依赖
- 无 frontmatter 的旧文档兼容：id 取文件名、标题取首个 `# ` 标题

## 规则

- 用户故事文档是需求的事实源；Studio 只渲染，不修改数据

## 演进方向

见 [规格对比](specification-gap.md)：计划补充 `requirement capture`（日志捕捉）、
`requirement review`（需求评审）、`requirement audit`（需求质量门禁），
frontmatter 扩展 `source`（素材来源）与 `persona`（用户画像）字段。
