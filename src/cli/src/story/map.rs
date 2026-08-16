/// story map — 生成三层用户故事地图视图。
use std::path::Path;

use crate::requirement::{scan_activities, scan_stories};
use crate::story::export::stories_root_for;

/// 向 stdout 输出故事地图（活动 → 任务 → 故事）。
/// product 省略时默认 qtcloud-product。
pub fn map(repo_path: &Path, product: Option<&str>) -> Result<(), String> {
    let product = product.unwrap_or(crate::story::export::DEFAULT_PRODUCT_ID);
    let root = stories_root_for(repo_path, product);
    if !root.is_dir() {
        return Err(format!("用户故事目录不存在: {}", root.display()));
    }
    let activities = scan_activities(&root);
    let stories = scan_stories(&root);
    if activities.is_empty() {
        println!("  暂无用户活动");
        return Ok(());
    }
    println!("用户故事地图 — {}\n{}", product, "-".repeat(50));
    for activity in &activities {
        println!("■ {} [{}]", activity.title, activity.dir);
        for (task_idx, task) in activity.tasks.iter().enumerate() {
            println!("  └ {} ({})", task, task_id(activity, task_idx));
            let task_stories: Vec<_> = stories
                .iter()
                .filter(|s| s.activity == activity.dir && s.task == *task)
                .collect();
            for s in &task_stories {
                println!(
                    "     ├ {} {} [{}] {}{}",
                    status_mark(s.status),
                    s.title,
                    s.id,
                    s.phase,
                    if s.status == crate::requirement::Status::Done { " ✅" } else { "" }
                );
            }
            if task_stories.is_empty() {
                println!("     └ （无用户故事）");
            }
        }
    }
    Ok(())
}

/// 任务 id 生成规则（与 export 保持一致）：
/// `<activity>-task-<序号>`。
pub fn task_id(activity: &crate::requirement::UserActivity, task_idx: usize) -> String {
    format!("{}-task-{}", activity.dir, task_idx + 1)
}

fn status_mark(status: crate::requirement::Status) -> &'static str {
    match status {
        crate::requirement::Status::Done => "✅",
        crate::requirement::Status::InProgress => "🔄",
        crate::requirement::Status::Todo => "⬜",
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_task_id() {
        let a = crate::requirement::UserActivity {
            dir: "user_story".to_string(),
            title: "管理用户故事".to_string(),
            tasks: vec!["细化".to_string()],
        };
        assert_eq!(task_id(&a, 0), "user_story-task-1");
        assert_eq!(task_id(&a, 2), "user_story-task-3");
    }

    #[test]
    fn test_map_missing_dir() {
        let d = tempfile::tempdir().unwrap();
        assert!(map(d.path(), None).is_err());
    }
}
