/// story status — 故事地图状态。
use std::path::Path;

use crate::requirement::{scan_activities, scan_stories};
use crate::story::export::stories_root_for;

/// 故事地图状态：三层结构统计。
#[derive(Debug)]
pub struct StoryMapStatus {
    pub activities: usize,
    pub tasks: usize,
    pub stories: usize,
    pub mvp_stories: usize,
    pub done_stories: usize,
}

/// 统计故事地图状态（product 省略时默认 qtcloud-product）。
pub fn status(repo_path: &Path, product: Option<&str>) -> StoryMapStatus {
    let product = product.unwrap_or(crate::story::export::DEFAULT_PRODUCT_ID);
    let root = stories_root_for(repo_path, product);
    let activities = scan_activities(&root);
    let stories = scan_stories(&root);
    StoryMapStatus {
        activities: activities.len(),
        tasks: activities.iter().map(|a| a.tasks.len()).sum(),
        stories: stories.len(),
        mvp_stories: stories.iter().filter(|s| s.phase == crate::requirement::Phase::Mvp).count(),
        done_stories: stories.iter().filter(|s| s.status == crate::requirement::Status::Done).count(),
    }
}

/// 向 stdout 输出故事地图状态（product 省略时默认 qtcloud-product）。
pub fn print_status(repo_path: &Path, product: Option<&str>) {
    let product = product.unwrap_or(crate::story::export::DEFAULT_PRODUCT_ID);
    let root = stories_root_for(repo_path, product);
    let s = status(repo_path, Some(product));
    println!("用户故事地图 — {}\n{}", product, "-".repeat(50));
    if !root.is_dir() {
        println!("  ❌ 用户故事目录不存在: {}", root.display());
        return;
    }
    println!("  用户活动: {}", s.activities);
    println!("  用户任务: {}", s.tasks);
    println!("  用户故事: {}", s.stories);
    println!("  MVP 故事: {} / 已完成: {}", s.mvp_stories, s.done_stories);
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_status_empty() {
        let d = tempfile::tempdir().unwrap();
        let s = status(d.path(), None);
        assert_eq!(s.activities, 0);
        assert_eq!(s.stories, 0);
    }

    #[test]
    fn test_status_with_data() {
        let d = tempfile::tempdir().unwrap();
        let root = d.path().join(crate::requirement::STORIES_DIR);
        std::fs::create_dir_all(root.join("user_story")).unwrap();
        std::fs::write(
            root.join("user_story/README.md"),
            "# 管理用户故事\n\n此用户活动的用户任务为：\n\n1. 细化用户故事\n2. 建立全景图\n",
        )
        .unwrap();
        std::fs::write(
            root.join("user_story/story-a.md"),
            "---\nphase: mvp\nstatus: done\n---\n\na\n",
        )
        .unwrap();
        std::fs::write(
            root.join("user_story/story-b.md"),
            "---\nphase: future\nstatus: todo\n---\n\nb\n",
        )
        .unwrap();
        let s = status(d.path(), None);
        assert_eq!(s.activities, 1);
        assert_eq!(s.tasks, 2);
        assert_eq!(s.stories, 2);
        assert_eq!(s.mvp_stories, 1);
        assert_eq!(s.done_stories, 1);
    }

    #[test]
    fn test_status_other_product() {
        let d = tempfile::tempdir().unwrap();
        let root = d.path().join("docs/stories/qtcloud-devops");
        std::fs::create_dir_all(root.join("lifecycle")).unwrap();
        std::fs::write(
            root.join("lifecycle/README.md"),
            "# 阶段/生命周期管理\n\n此用户活动的用户任务为：\n\n1. plan 计划\n2. code 编码\n",
        )
        .unwrap();
        std::fs::write(
            root.join("lifecycle/lifecycle-plan-1.md"),
            "---\ntask: plan 计划\nphase: mvp\nstatus: done\n---\n\nx\n",
        )
        .unwrap();
        let s = status(d.path(), Some("qtcloud-devops"));
        assert_eq!(s.activities, 1);
        assert_eq!(s.tasks, 2);
        assert_eq!(s.stories, 1);
    }
}
