/// story 模块 — 用户故事地图。
///
/// 故事地图是需求梳理的三层视图（对应 Studio 渲染模型）：
/// 用户活动（脊柱）→ 用户任务（行走的骨骼）→ 用户故事（卡片）。
///
/// 子命令：
/// - status — 故事地图状态（活动/任务/故事统计）
/// - map — 生成三层故事地图视图
/// - export — 导出故事地图数据（JSON，供 Studio 渲染）
mod export;
mod map;
mod status;

pub use export::*;
pub use map::*;
pub use status::*;
