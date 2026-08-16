/// 示例：用库 API 生成 qtcloud-devops 的故事地图数据。
///
/// 案例背景（见 examples/seed-workflow.md）：
/// qtcloud-devops 的建模约定为「lifecycle 是一个 Activity、八个阶段是 Task、
/// 具体功能是 Story」，另有 platform（管理平台）Activity。
///
/// 运行：`cargo run --example devops_export`
use std::path::Path;

fn main() {
    let repo = Path::new("../../"); // qtcloud-product 仓库根

    // 1. 查看 qtcloud-devops 的故事地图状态（活动/任务/故事统计）
    let s = qtcloud_product_cli::story::status(repo, Some("qtcloud-devops"));
    println!(
        "qtcloud-devops 故事地图: {} 活动 / {} 任务 / {} 故事（MVP {}）",
        s.activities, s.tasks, s.stories, s.mvp_stories
    );

    // 2. 从故事文档构建产品数据（不写文件，仅打印）
    let opts = qtcloud_product_cli::story::ExportOptions {
        product: Some("qtcloud-devops".to_string()),
        title: None, // 省略时保留现有文件的 title
        tagline: None,
        design_idea: None,
        stdout: true,
    };
    match qtcloud_product_cli::story::export(repo, &opts) {
        Ok(()) => println!("\n✅ 故事地图数据已生成（stdout 预览）"),
        Err(e) => println!("  ⚠ {}", e),
    }
}
