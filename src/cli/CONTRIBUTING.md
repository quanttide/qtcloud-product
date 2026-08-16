# CONTRIBUTING

## 开发环境

- Rust 工具链（`rustup` + `cargo`）
- git（发布与集成测试需要）

## 常用命令

```bash
cargo build                 # 构建
cargo test                  # 单元测试 + CLI 集成测试
cargo run -- requirement list
cargo clippy -- -D warnings # 静态检查
```

## 代码约定

- 模块按命令组织：`src/<command>/mod.rs` + 子模块（status / audit / action 三分法）
- 用户故事文档解析在 `requirement` 模块内完成，其他模块不直接解析文档
- 网络 git 操作使用系统 `git` 命令（见 AGENTS.md 设计决策）
- 中文注释与中文输出
- 每个公开函数附文档注释；测试覆盖解析、校验与门禁逻辑

## 提交规范

- feat / fix / docs / refactor / chore 前缀，描述用中文
- 变更同时更新 `CHANGELOG.md`
- 涉及用户故事文档格式的变更必须同步 `docs/architecture.md` 与 `ROADMAP.md`

## 发布流程

```bash
# 1. 更新 CHANGELOG.md（新增版本节）与 Cargo.toml 版本
# 2. 预检
cargo test
cargo clippy -- -D warnings
# 3. 发布（自动检测 CHANGELOG 最新版本）
qtcloud-product release publish
```

## 测试组织

- `src/**` 内联单元测试：解析、校验、门禁逻辑
- `tests/cli.rs` 集成测试：以 `CARGO_BIN_EXE_qtcloud-product` 运行二进制
- 测试中 git 仓库操作使用 `tempfile::tempdir` 隔离，不触碰真实仓库
