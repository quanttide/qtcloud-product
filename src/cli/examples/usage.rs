/// 示例：使用 qtcloud-product-cli 库梳理需求。
///
/// 运行：`cargo run --example usage`
use std::path::Path;

fn main() {
    // 1. 列出用户故事
    let repo = Path::new(".");
    match qtcloud_product_cli::requirement::list(repo) {
        Ok(()) => {}
        Err(e) => println!("  ⚠ {}", e),
    }

    // 2. 生成故事地图数据（不写文件，仅打印）
    let opts = qtcloud_product_cli::story::ExportOptions {
        product: None,
        title: Some("量潮产品云".to_string()),
        tagline: None,
        design_idea: None,
        stdout: true,
    };
    match qtcloud_product_cli::story::export(repo, &opts) {
        Ok(()) => {}
        Err(e) => println!("  ⚠ {}", e),
    }

    // 3. 生成版本计划
    let plan = qtcloud_product_cli::roadmap::render_plan(repo);
    println!("{}", plan);
}
