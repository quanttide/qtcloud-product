use clap::{Parser, Subcommand};
use std::path::{Path, PathBuf};
use std::process;

#[derive(Parser)]
#[command(
    name = "qtcloud-product",
    about = "量潮产品云 — 以用户故事为中心梳理需求",
    version,
    disable_help_subcommand(true)
)]
struct Cli {
    #[command(subcommand)]
    command: Commands,
}

#[derive(Subcommand)]
enum Commands {
    /// 需求梳理：以用户故事为单位管理产品需求
    Requirement {
        #[command(subcommand)]
        action: RequirementAction,
    },
    /// 用户故事地图：活动 → 任务 → 故事三层视图
    Story {
        #[command(subcommand)]
        action: StoryAction,
    },
    /// 版本计划：按发布阶段分组用户故事
    Roadmap {
        #[command(subcommand)]
        action: RoadmapAction,
    },
    /// 发布管理：版本预检与发布
    Release {
        #[command(subcommand)]
        action: ReleaseAction,
    },
    /// 环境诊断：检查外部工具链状态
    Doctor {
        #[command(subcommand)]
        action: DoctorAction,
    },
    /// 快速导览：按领域分组展示命令
    Help,
    /// 概览状态：聚合 requirement / story / roadmap / release / doctor 状态
    Status,
    /// 概览审计：聚合 seed 校验与发布预检
    Audit,
}

#[derive(Subcommand)]
enum RequirementAction {
    /// 列出用户故事
    List,
    /// 查看用户故事详情
    Show {
        /// 用户故事 id 或标题
        id: String,
    },
    /// 添加用户故事
    Add(qtcloud_product_cli::requirement::AddOptions),
    /// 编辑用户故事
    Edit {
        /// 用户故事 id 或标题
        id: String,
        #[command(flatten)]
        options: qtcloud_product_cli::requirement::EditOptions,
    },
    /// 删除用户故事
    Remove {
        /// 用户故事 id 或标题
        id: String,
    },
    /// 需求梳理状态（按活动聚合统计）
    Status,
}

#[derive(Subcommand)]
enum StoryAction {
    /// 故事地图状态：活动/任务/故事统计
    Status {
        /// 产品唯一命名（默认 qtcloud-product）
        #[arg(long)]
        product: Option<String>,
    },
    /// 生成三层故事地图视图
    Map {
        /// 产品唯一命名（默认 qtcloud-product）
        #[arg(long)]
        product: Option<String>,
    },
    /// 导出故事地图数据（供 Studio 渲染）
    Export {
        /// 产品唯一命名（默认 qtcloud-product）。
        /// 故事文档根为 docs/stories/<id>/；qtcloud-product 回退历史路径
        #[arg(long)]
        product: Option<String>,
        /// 前台展示标题
        #[arg(long)]
        title: Option<String>,
        /// 一句话定位
        #[arg(long)]
        tagline: Option<String>,
        /// 设计思路
        #[arg(long)]
        design_idea: Option<String>,
        /// 仅打印到 stdout，不写文件
        #[arg(long)]
        stdout: bool,
    },
}

#[derive(Subcommand)]
enum RoadmapAction {
    /// 版本计划状态
    Status,
    /// 生成版本计划（MVP 版本 / 未来迭代）
    Plan {
        /// 输出文件路径（默认仅打印到 stdout）
        #[arg(long)]
        output: Option<PathBuf>,
    },
}

#[derive(Subcommand)]
enum ReleaseAction {
    /// 发布预检审计：版本号、Cargo.toml、CHANGELOG、工作区、标签冲突、远程
    Audit {
        /// 版本号。格式 `vX.Y.Z` 或 `scope/vX.Y.Z`（如 `cli/v0.1.0`）
        #[arg(short = 'v', long)]
        version: Option<String>,
    },
    /// 发布版本：预检 → 确认 → tag → push → GitHub Release
    Publish {
        /// 版本号。格式 `vX.Y.Z` 或 `scope/vX.Y.Z`。省略时用 CHANGELOG 最新版本
        #[arg(short = 'v', long)]
        version: Option<String>,
        /// 跳过用户确认
        #[arg(long, short = 'y')]
        yes: bool,
        /// 强制重新发布：删除已存在的 tag 后重新创建
        #[arg(long, short = 'f')]
        force: bool,
        /// 仅预览，不执行任何操作
        #[arg(long)]
        dry_run: bool,
    },
    /// 查看发布状态：版本号、CHANGELOG、标签、工作区
    Status,
}

#[derive(Subcommand)]
enum DoctorAction {
    /// 检查系统依赖命令状态
    Status,
}

fn main() {
    let cli = Cli::parse();
    if let Err(e) = dispatch(cli) {
        eprintln!("错误: {}", e);
        process::exit(1);
    }
}

fn dispatch(cli: Cli) -> Result<(), String> {
    let rp = repo_path();
    match cli.command {
        Commands::Requirement { action } => run_requirement(&rp, action),
        Commands::Story { action } => run_story(&rp, action),
        Commands::Roadmap { action } => run_roadmap(&rp, action),
        Commands::Release { action } => run_release(&rp, action),
        Commands::Doctor { action } => run_doctor(&rp, action),
        Commands::Help => run_help(),
        Commands::Status => run_overall_status(&rp),
        Commands::Audit => run_overall_audit(&rp),
    }
}

fn run_requirement(rp: &Path, action: RequirementAction) -> Result<(), String> {
    match action {
        RequirementAction::List => qtcloud_product_cli::requirement::list(rp),
        RequirementAction::Show { id } => qtcloud_product_cli::requirement::show(rp, &id),
        RequirementAction::Add(opts) => qtcloud_product_cli::requirement::add(rp, &opts),
        RequirementAction::Edit { id, options } => {
            qtcloud_product_cli::requirement::edit(rp, &id, &options)
        }
        RequirementAction::Remove { id } => qtcloud_product_cli::requirement::remove(rp, &id),
        RequirementAction::Status => qtcloud_product_cli::requirement::status(rp),
    }
}

fn run_story(rp: &Path, action: StoryAction) -> Result<(), String> {
    match action {
        StoryAction::Status { product } => {
            qtcloud_product_cli::story::print_status(rp, product.as_deref());
            Ok(())
        }
        StoryAction::Map { product } => qtcloud_product_cli::story::map(rp, product.as_deref()),
        StoryAction::Export { product, title, tagline, design_idea, stdout } => {
            let opts = qtcloud_product_cli::story::ExportOptions {
                product,
                title,
                tagline,
                design_idea,
                stdout,
            };
            qtcloud_product_cli::story::export(rp, &opts)
        }
    }
}

fn run_roadmap(rp: &Path, action: RoadmapAction) -> Result<(), String> {
    match action {
        RoadmapAction::Status => {
            qtcloud_product_cli::roadmap::print_status(rp);
            Ok(())
        }
        RoadmapAction::Plan { output } => {
            let opts = qtcloud_product_cli::roadmap::PlanOptions { output };
            qtcloud_product_cli::roadmap::plan(rp, &opts)
        }
    }
}

fn run_release(rp: &Path, action: ReleaseAction) -> Result<(), String> {
    match action {
        ReleaseAction::Status => {
            qtcloud_product_cli::release::print_status(rp);
            Ok(())
        }
        ReleaseAction::Audit { version } => {
            let v = resolve_version(rp, version)?;
            qtcloud_product_cli::release::print_audit(rp, &v)
        }
        ReleaseAction::Publish { version, yes, force, dry_run } => {
            let v = resolve_version(rp, version)?;
            let opts = qtcloud_product_cli::release::PublishOptions { yes, dry_run, force };
            qtcloud_product_cli::release::publish_with_status(rp, &v, &opts)
        }
    }
}

fn run_doctor(rp: &Path, action: DoctorAction) -> Result<(), String> {
    match action {
        DoctorAction::Status => {
            qtcloud_product_cli::doctor::status(rp);
            Ok(())
        }
    }
}

/// 解析版本号：显式提供或取 CHANGELOG 最新版本。
fn resolve_version(rp: &Path, version: Option<String>) -> Result<String, String> {
    match version {
        Some(v) if !v.trim().is_empty() => Ok(v),
        _ => match qtcloud_product_cli::release::changelog_version(rp) {
            Some(v) => Ok(format!("v{}", v)),
            None => Err("未指定版本号，且 CHANGELOG 中无版本头（用 -v vX.Y.Z 指定）".to_string()),
        },
    }
}

fn run_help() -> Result<(), String> {
    println!("qtcloud-product — 量潮产品云命令行工具");
    println!();
    println!("以用户故事为中心梳理需求:");
    println!("  requirement list / show / add / edit / remove / status");
    println!("  story status / map / export");
    println!("  roadmap status / plan");
    println!();
    println!("生命周期:");
    println!("  release status / audit / publish");
    println!();
    println!("Cross-stage:");
    println!("  doctor status");
    println!();
    println!("Overview:");
    println!("  status    聚合所有 status");
    println!("  audit     聚合所有 audit");
    println!();
    println!("Use `--help` on any command for detailed options.");
    Ok(())
}

fn run_overall_status(rp: &Path) -> Result<(), String> {
    println!("概览状态\n{}", "-".repeat(50));
    qtcloud_product_cli::doctor::status(rp);
    println!();
    qtcloud_product_cli::requirement::status(rp).ok();
    println!();
    qtcloud_product_cli::story::print_status(rp, None);
    println!();
    qtcloud_product_cli::roadmap::print_status(rp);
    println!();
    qtcloud_product_cli::release::print_status(rp);
    Ok(())
}

fn run_overall_audit(rp: &Path) -> Result<(), String> {
    println!("概览审计\n{}", "-".repeat(50));
    let mut all_passed = true;
    // 种子数据校验：产品文件与 manifest 一致
    match validate_seed(rp) {
        Ok(()) => {}
        Err(_) => all_passed = false,
    }
    println!();
    // 发布预检：CHANGELOG 最新版本
    if let Some(v) = qtcloud_product_cli::release::changelog_version(rp) {
        if qtcloud_product_cli::release::print_audit(rp, &format!("v{}", v)).is_err() {
            all_passed = false;
        }
    } else {
        println!("  ⚠ 未检测到 CHANGELOG 版本头，跳过发布预检");
    }
    if all_passed {
        Ok(())
    } else {
        Err("概览审计未全部通过".to_string())
    }
}

/// 种子数据校验：产品文件存在、manifest 包含本产品。
fn validate_seed(rp: &Path) -> Result<(), String> {
    println!("种子数据\n{}", "-".repeat(50));
    let product_path = rp.join("assets/data/products/qtcloud-product.json");
    let manifest_path = rp.join("assets/data/manifest.json");
    let mut passed = 0usize;
    let total = 2usize;
    let product_ok = product_path.is_file();
    println!("  {} 产品文件: {}", if product_ok { "✅" } else { "❌" }, product_path.display());
    if product_ok {
        passed += 1;
    }
    let manifest_ok = manifest_path.is_file()
        && std::fs::read_to_string(&manifest_path)
            .ok()
            .and_then(|c| serde_json::from_str::<serde_json::Value>(&c).ok())
            .and_then(|v| v.get("products").cloned())
            .map(|v| {
                v.as_array()
                    .map(|a| a.iter().any(|p| p.as_str() == Some(qtcloud_product_cli::story::DEFAULT_PRODUCT_ID)))
                    .unwrap_or(false)
            })
            .unwrap_or(false);
    println!("  {} manifest 包含本产品", if manifest_ok { "✅" } else { "❌" });
    if manifest_ok {
        passed += 1;
    }
    println!("{}\n  {}/{} 项通过", "-".repeat(50), passed, total);
    if passed == total {
        Ok(())
    } else {
        Err(format!("{}/{} 项未通过", total - passed, total))
    }
}

fn repo_path() -> PathBuf {
    let cwd = std::env::current_dir().unwrap_or_else(|_| PathBuf::from("."));
    let output = std::process::Command::new("git")
        .args(["rev-parse", "--show-toplevel"])
        .current_dir(&cwd)
        .output();
    match output {
        Ok(o) if o.status.success() => {
            PathBuf::from(std::str::from_utf8(&o.stdout).unwrap_or("").trim())
        }
        _ => cwd,
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_resolve_version_from_changelog() {
        let d = tempfile::tempdir().unwrap();
        std::fs::write(
            d.path().join("CHANGELOG.md"),
            "# CHANGELOG\n\n## [0.3.0] - 2026-08-16\n\n- x\n",
        )
        .unwrap();
        assert_eq!(resolve_version(d.path(), None).unwrap(), "v0.3.0");
        assert_eq!(resolve_version(d.path(), Some("cli/v0.1.0".to_string())).unwrap(), "cli/v0.1.0");
    }

    #[test]
    fn test_resolve_version_missing() {
        let d = tempfile::tempdir().unwrap();
        assert!(resolve_version(d.path(), None).is_err());
    }
}
