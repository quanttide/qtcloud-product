# 发布管理模块（release）

## 职责

版本预检与发布：三阶段架构（Plan → Confirm → Execute），预检不通过即中止，绝不带病发布。

## 命令

```bash
qtcloud-product release status                # 版本号 / CHANGELOG / 标签 / 工作区
qtcloud-product release audit -v v0.1.0       # 发布预检
qtcloud-product release publish               # 自动检测版本 + 发布
qtcloud-product release publish -v cli/v0.1.0 # 指定版本（scope 前缀）
qtcloud-product release publish --dry-run     # 仅预览，不执行
qtcloud-product release publish -y            # 跳过确认
```

## 三阶段架构

```
release publish
  ├─ Plan    release audit（6 项门禁，不通过即中止）
  ├─ Confirm 交互确认（-y 跳过）
  └─ Execute git tag → git push origin <tag> → gh release create
```

- dry-run 只走 Plan + 预览，不产生任何副作用
- 版本号格式 `vX.Y.Z` 或 `scope/vX.Y.Z`（如 `cli/v0.1.0`，与 qtcloud-devops 的 tag 约定一致）
- 省略版本号时用 CHANGELOG 最新版本

## 预检项（release audit）

版本格式 / Cargo.toml / CHANGELOG / 工作区 / 本地 tag / 远程 tag 共 6 项。

## 规则

- 网络 git 操作（push / ls-remote）使用系统 git 命令，而非 git2
  （credential helper 兼容性，见 AGENTS.md）
