# 环境诊断模块（doctor）

## 职责

检查外部工具链状态，输出诊断报告。

## 命令

```bash
qtcloud-product doctor status                 # 检查外部工具链
```

## 依赖的工具链

| 工具 | 用途 |
|------|------|
| git | 仓库操作（tag / push / 工作区检测） |
| gh（可选） | `release publish` 创建 GitHub Release 时需要 |
