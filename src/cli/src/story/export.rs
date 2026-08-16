/// story export — 导出故事地图数据（供 Studio 渲染）。
///
/// 从用户故事文档生成 Studio 渲染数据（仓库约定 `assets/data/`）：
/// - `assets/data/manifest.json` — 产品清单（products: [产品唯一命名...]）
/// - `assets/data/products/<id>.json` — 每个产品一个文件
///
/// 对应 Studio `Product → StoryMap → Activity → Task → Story` 模型。
/// 本 CLI 负责加工本产品（qtcloud-product）的文件，并同步 manifest；
/// 其他产品文件保留不动。人工维护的 `title` / `tagline` / `designIdea`
/// 在未显式覆盖时从现有文件保留。
use std::path::{Path, PathBuf};

use serde::{Deserialize, Serialize};

use crate::requirement::{scan_activities, scan_stories};

/// 默认产品唯一命名（本 CLI 所在仓库的产品）。
pub const DEFAULT_PRODUCT_ID: &str = "qtcloud-product";

/// 导出选项。
#[derive(Debug, Clone)]
pub struct ExportOptions {
    /// 产品唯一命名（默认 qtcloud-product）。
    /// 故事文档根为 `docs/stories/<id>/`；qtcloud-product 回退到
    /// `docs/dev-guide/prd/stories/stories/`（历史路径）。
    pub product: Option<String>,
    /// 前台展示标题（默认取仓库 README 标题，回退现有文件/产品名）
    pub title: Option<String>,
    /// 一句话定位（默认保留现有文件值）
    pub tagline: Option<String>,
    /// 设计思路（默认保留现有文件值）
    pub design_idea: Option<String>,
    /// 仅打印到 stdout，不写文件
    pub stdout: bool,
}

// ---------- Studio 渲染数据模型（camelCase JSON） ----------

/// 产品清单。
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct Manifest {
    pub products: Vec<String>,
}

/// 产品（对应 Studio `Product`）。
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct Product {
    pub id: String,
    /// 唯一命名（URL / 识别场景）
    pub name: String,
    /// 前台展示标题
    #[serde(default)]
    pub title: String,
    #[serde(default)]
    pub tagline: String,
    #[serde(rename = "designIdea", default)]
    pub design_idea: String,
    #[serde(rename = "storyMap")]
    pub story_map: StoryMap,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct StoryMap {
    pub id: String,
    pub name: String,
    #[serde(rename = "mvpLinePosition", default = "default_mvp_line_position")]
    pub mvp_line_position: f64,
    #[serde(default)]
    pub activities: Vec<Activity>,
}

fn default_mvp_line_position() -> f64 {
    0.5
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct Activity {
    pub id: String,
    pub title: String,
    #[serde(default)]
    pub order: i64,
    #[serde(default)]
    pub tasks: Vec<Task>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct Task {
    pub id: String,
    pub title: String,
    #[serde(rename = "activityId", default)]
    pub activity_id: String,
    #[serde(default)]
    pub order: i64,
    #[serde(default)]
    pub stories: Vec<Story>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct Story {
    pub id: String,
    pub title: String,
    #[serde(rename = "taskId", default)]
    pub task_id: String,
    #[serde(default)]
    pub phase: String,
    #[serde(default)]
    pub status: String,
    #[serde(default)]
    pub description: String,
}

// ---------- 生成与写出 ----------

/// 解析产品故事文档根：`docs/stories/<product_id>/`；
/// qtcloud-product 回退到 `docs/dev-guide/prd/stories/stories/`（历史路径）。
pub fn stories_root_for(repo_path: &Path, product_id: &str) -> PathBuf {
    let new_root = repo_path.join("docs/stories").join(product_id);
    if new_root.is_dir() {
        return new_root;
    }
    if product_id == DEFAULT_PRODUCT_ID {
        let legacy = repo_path.join(crate::requirement::STORIES_DIR);
        if legacy.is_dir() {
            return legacy;
        }
    }
    new_root
}

/// 从用户故事文档生成产品数据。
pub fn build_product(repo_path: &Path, product_id: &str, title: &str) -> Product {
    let root = stories_root_for(repo_path, product_id);
    let activities = scan_activities(&root);
    let stories = scan_stories(&root);

    let mut story_map_activities = Vec::new();
    for (act_idx, activity) in activities.iter().enumerate() {
        let mut tasks = Vec::new();
        for (task_idx, task_title) in activity.tasks.iter().enumerate() {
            let task_id = format!("{}-task-{}", activity.dir, task_idx + 1);
            let task_stories: Vec<Story> = stories
                .iter()
                .filter(|s| s.activity == activity.dir && s.task == *task_title)
                .map(|s| Story {
                    id: s.id.clone(),
                    title: s.title.clone(),
                    task_id: task_id.clone(),
                    phase: s.phase.as_str().to_string(),
                    status: s.status.as_str().to_string(),
                    description: s.description.clone(),
                })
                .collect();
            tasks.push(Task {
                id: task_id,
                title: task_title.clone(),
                activity_id: activity.dir.clone(),
                order: task_idx as i64,
                stories: task_stories,
            });
        }
        story_map_activities.push(Activity {
            id: activity.dir.clone(),
            title: activity.title.clone(),
            order: act_idx as i64,
            tasks,
        });
    }

    Product {
        id: product_id.to_string(),
        name: product_id.to_string(),
        title: title.to_string(),
        tagline: String::new(),
        design_idea: String::new(),
        story_map: StoryMap {
            id: format!("map-{}", product_id),
            name: product_id.to_string(),
            mvp_line_position: default_mvp_line_position(),
            activities: story_map_activities,
        },
    }
}

/// 导出故事地图数据：更新产品文件 + 同步 manifest。
pub fn export(repo_path: &Path, opts: &ExportOptions) -> Result<(), String> {
    let product_id = opts
        .product
        .clone()
        .unwrap_or_else(|| DEFAULT_PRODUCT_ID.to_string());
    let product_file_rel = format!("assets/data/products/{}.json", product_id);
    if opts.stdout {
        let product = build_product(repo_path, &product_id, &resolve_title(repo_path, None)?);
        println!(
            "{}",
            serde_json::to_string_pretty(&product).map_err(|e| format!("序列化失败: {}", e))?
        );
        return Ok(());
    }

    let product_path = repo_path.join(&product_file_rel);
    let manifest_path = repo_path.join("assets/data/manifest.json");

    // 保留人工维护字段（title/tagline/designIdea/mvpLinePosition）
    let existing = read_product(&product_path);
    let title = resolve_title(repo_path, opts.title.clone().or_else(|| existing.as_ref().map(|p| p.title.clone())))?;
    let mut product = build_product(repo_path, &product_id, &title);
    if let Some(existing) = &existing {
        product.tagline = opts
            .tagline
            .clone()
            .unwrap_or_else(|| existing.tagline.clone());
        product.design_idea = opts
            .design_idea
            .clone()
            .unwrap_or_else(|| existing.design_idea.clone());
        product.story_map.mvp_line_position = existing.story_map.mvp_line_position;
    }

    // 写产品文件
    if let Some(parent) = product_path.parent() {
        std::fs::create_dir_all(parent)
            .map_err(|e| format!("创建目录失败 {}: {}", parent.display(), e))?;
    }
    let json = serde_json::to_string_pretty(&product)
        .map_err(|e| format!("序列化失败: {}", e))?;
    std::fs::write(&product_path, format!("{}\n", json))
        .map_err(|e| format!("写入失败 {}: {}", product_path.display(), e))?;

    // 同步 manifest
    let mut manifest = read_manifest(&manifest_path);
    if !manifest.products.iter().any(|p| p == &product_id) {
        manifest.products.push(product_id.clone());
        manifest.products.sort();
        if let Some(parent) = manifest_path.parent() {
            std::fs::create_dir_all(parent)
                .map_err(|e| format!("创建目录失败 {}: {}", parent.display(), e))?;
        }
        let mjson = serde_json::to_string_pretty(&manifest)
            .map_err(|e| format!("序列化失败: {}", e))?;
        std::fs::write(&manifest_path, format!("{}\n", mjson))
            .map_err(|e| format!("写入失败 {}: {}", manifest_path.display(), e))?;
    }

    let total_stories: usize = product
        .story_map
        .activities
        .iter()
        .flat_map(|a| a.tasks.iter())
        .map(|t| t.stories.len())
        .sum();
    println!(
        "  ✅ 已导出故事地图数据 → {}（{} 个用户故事）",
        product_path.display(),
        total_stories
    );
    Ok(())
}

/// 解析展示标题：显式值 → 仓库 README 标题 → 现有文件 title → 产品名。
fn resolve_title(repo_path: &Path, explicit: Option<String>) -> Result<String, String> {
    if let Some(t) = explicit {
        if !t.trim().is_empty() {
            return Ok(t.trim().to_string());
        }
    }
    if let Some(t) = repo_title(repo_path) {
        return Ok(t);
    }
    Ok(DEFAULT_PRODUCT_ID.to_string())
}

/// 仓库标题：README.md 首个 `# ` 标题。
fn repo_title(repo_path: &Path) -> Option<String> {
    let readme = repo_path.join("README.md");
    let content = std::fs::read_to_string(readme).ok()?;
    content
        .lines()
        .map(|l| l.trim())
        .find(|l| l.starts_with("# ") && !l.starts_with("## "))
        .map(|l| l.trim_start_matches("# ").trim().to_string())
        .filter(|t| !t.is_empty())
}

fn read_product(path: &Path) -> Option<Product> {
    let content = std::fs::read_to_string(path).ok()?;
    serde_json::from_str::<Product>(&content).ok()
}

fn read_manifest(path: &Path) -> Manifest {
    match std::fs::read_to_string(path) {
        Ok(content) => serde_json::from_str::<Manifest>(&content).unwrap_or(Manifest { products: Vec::new() }),
        Err(_) => Manifest { products: Vec::new() },
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    fn setup() -> tempfile::TempDir {
        let d = tempfile::tempdir().unwrap();
        let root = d.path().join(crate::requirement::STORIES_DIR);
        std::fs::create_dir_all(root.join("user_story")).unwrap();
        std::fs::write(
            root.join("user_story/README.md"),
            "# 管理用户故事\n\n此用户活动的用户任务为：\n\n1. 细化用户故事\n",
        )
        .unwrap();
        std::fs::write(
            root.join("user_story/edit_user_story.md"),
            "---\ntitle: 编辑用户故事\nphase: mvp\nstatus: done\n---\n\n编辑故事。\n",
        )
        .unwrap();
        d
    }

    #[test]
    fn test_build_product_structure() {
        let d = setup();
        let p = build_product(d.path(), DEFAULT_PRODUCT_ID, "量潮产品云");
        assert_eq!(p.id, DEFAULT_PRODUCT_ID);
        assert_eq!(p.name, DEFAULT_PRODUCT_ID);
        assert_eq!(p.title, "量潮产品云");
        assert_eq!(p.story_map.activities.len(), 1);
        let act = &p.story_map.activities[0];
        assert_eq!(act.id, "user_story");
        assert_eq!(act.title, "管理用户故事");
        assert_eq!(act.tasks.len(), 1);
        let task = &act.tasks[0];
        assert_eq!(task.id, "user_story-task-1");
        assert_eq!(task.activity_id, "user_story");
        assert_eq!(task.stories.len(), 1);
        let s = &task.stories[0];
        assert_eq!(s.id, "edit_user_story");
        assert_eq!(s.task_id, "user_story-task-1");
        assert_eq!(s.phase, "mvp");
        assert_eq!(s.status, "done");
    }

    #[test]
    fn test_export_writes_files_and_manifest() {
        let d = setup();
        std::fs::create_dir_all(d.path().join("assets/data/products")).unwrap();
        std::fs::write(
            d.path().join("assets/data/manifest.json"),
            "{\"products\":[\"qtcloud-devops\"]}\n",
        )
        .unwrap();
        let opts = ExportOptions { product: None, title: Some("量潮产品云".to_string()), tagline: None, design_idea: None, stdout: false };
        export(d.path(), &opts).unwrap();
        let path = d.path().join("assets/data/products/qtcloud-product.json");
        assert!(path.is_file());
        let content = std::fs::read_to_string(&path).unwrap();
        let product: Product = serde_json::from_str(&content).unwrap();
        assert_eq!(product.title, "量潮产品云");
        let manifest = read_manifest(&d.path().join("assets/data/manifest.json"));
        assert!(manifest.products.contains(&DEFAULT_PRODUCT_ID.to_string()), "manifest 应包含本产品");
        assert!(manifest.products.contains(&"qtcloud-devops".to_string()), "其他产品应保留");
        assert_eq!(manifest.products.len(), 2);
    }

    #[test]
    fn test_export_preserves_manual_fields() {
        let d = setup();
        std::fs::create_dir_all(d.path().join("assets/data/products")).unwrap();
        std::fs::write(
            d.path().join("assets/data/products/qtcloud-product.json"),
            r#"{"id":"qtcloud-product","name":"qtcloud-product","title":"旧标题","tagline":"旧定位","designIdea":"旧思路","storyMap":{"id":"map-product","name":"qtcloud-product","mvpLinePosition":0.4,"activities":[]}}"#,
        )
        .unwrap();
        let opts = ExportOptions { product: None, title: None, tagline: None, design_idea: None, stdout: false };
        export(d.path(), &opts).unwrap();
        let product = read_product(&d.path().join("assets/data/products/qtcloud-product.json")).unwrap();
        assert_eq!(product.tagline, "旧定位", "人工维护的 tagline 应保留");
        assert_eq!(product.design_idea, "旧思路", "人工维护的 designIdea 应保留");
        assert!((product.story_map.mvp_line_position - 0.4).abs() < 1e-9, "mvpLinePosition 应保留");
    }

    #[test]
    fn test_export_stdout_no_write() {
        let d = setup();
        let opts = ExportOptions { product: None, title: None, tagline: None, design_idea: None, stdout: true };
        export(d.path(), &opts).unwrap();
        assert!(!d.path().join("assets/data/products/qtcloud-product.json").exists());
    }

    #[test]
    fn test_repo_title() {
        let d = tempfile::tempdir().unwrap();
        assert_eq!(repo_title(d.path()), None);
        std::fs::write(d.path().join("README.md"), "# 量潮产品云\n\n描述\n").unwrap();
        assert_eq!(repo_title(d.path()).unwrap(), "量潮产品云");
    }
}
