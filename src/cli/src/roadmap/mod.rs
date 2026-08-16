/// roadmap 模块 — 版本计划。
///
/// 以用户故事的发布阶段（mvp / future）为输入，制定版本计划：
/// - status — 版本计划状态
/// - plan — 生成版本计划（MVP 版本 / 未来迭代的用户故事分组）
mod plan;
mod status;

pub use plan::*;
pub use status::*;

/// 版本计划目录（相对仓库根）。
pub const ROADMAPS_DIR: &str = "docs/dev-guide/prd/stories/roadmaps";
