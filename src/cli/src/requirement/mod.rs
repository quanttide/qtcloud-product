/// requirement 模块 — 需求梳理（以用户故事为中心）。
///
/// 领域约定（对应 Studio 的三层故事地图模型）：
/// - **用户故事**是需求的最小管理单元，每个故事一个 Markdown 文档，
///   位于 `docs/dev-guide/prd/stories/stories/<activity>/` 下（README.md 除外）。
/// - 故事文档支持 YAML frontmatter 元数据：
///   `title` / `activity` / `task` / `phase`(mvp|future) / `status`(todo|inProgress|done)。
///   无 frontmatter 时回退推断：id=文件名、title=首个标题、默认 mvp/todo。
/// - **用户活动** = `stories/stories/` 下的子目录，标题取目录 README.md 的首个标题。
/// - **用户任务** = 活动 README.md 中「此用户活动的用户任务为：」列表项；
///   无任务列表时活动下只有一个默认任务。
///
/// 子命令：list / show / add / edit / remove / status
pub mod model;
pub mod ops;

pub use model::*;
pub use ops::*;

/// 用户故事文档根目录（相对仓库根）。
pub const STORIES_DIR: &str = "docs/dev-guide/prd/stories/stories";
