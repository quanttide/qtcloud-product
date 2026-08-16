/// release 模块 — 发布管理。
///
/// 按 status / audit / action 三分法组织：
/// - status — 发布状态（版本号、标签、CHANGELOG、工作区）
/// - audit — 发布预检（门禁判定，不达标退出码 1）
/// - publish — 发布版本（预检 → 确认 → tag → push → GitHub Release）
///
/// 版本号格式：`vX.Y.Z`，可选 scope 前缀（如 `cli/v0.1.0`），
/// 与 qtcloud-devops 的 tag 前缀约定一致。
mod audit;
mod publish;
mod status;

pub use audit::*;
pub use publish::*;
pub use status::*;
