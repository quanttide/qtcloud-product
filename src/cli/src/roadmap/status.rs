/// roadmap status — 版本计划状态。
use std::path::Path;

use crate::requirement::{scan_stories, stories_root_of, Phase, Status};
use crate::roadmap::ROADMAPS_DIR;

/// 版本计划状态。
#[derive(Debug)]
pub struct RoadmapStatus {
    pub dir_exists: bool,
    pub readme_exists: bool,
    pub mvp_stories: usize,
    pub future_stories: usize,
    pub done_stories: usize,
}

/// 统计版本计划状态。
pub fn status(repo_path: &Path) -> RoadmapStatus {
    let dir = repo_path.join(ROADMAPS_DIR);
    let root = stories_root_of(repo_path);
    let stories = scan_stories(&root);
    RoadmapStatus {
        dir_exists: dir.is_dir(),
        readme_exists: dir.join("README.md").is_file(),
        mvp_stories: stories.iter().filter(|s| s.phase == Phase::Mvp).count(),
        future_stories: stories.iter().filter(|s| s.phase == Phase::Future).count(),
        done_stories: stories.iter().filter(|s| s.status == Status::Done).count(),
    }
}

/// 向 stdout 输出版本计划状态。
pub fn print_status(repo_path: &Path) {
    let s = status(repo_path);
    println!("版本计划\n{}", "-".repeat(50));
    println!(
        "  {} 目录: {}",
        if s.dir_exists { "✅" } else { "❌" },
        ROADMAPS_DIR
    );
    if s.readme_exists {
        println!("  ✅ 计划文档: {}/README.md", ROADMAPS_DIR);
    }
    println!("  MVP 故事: {} / 未来迭代: {}", s.mvp_stories, s.future_stories);
    println!("  已完成: {}", s.done_stories);
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_status_empty() {
        let d = tempfile::tempdir().unwrap();
        let s = status(d.path());
        assert!(!s.dir_exists);
        assert_eq!(s.mvp_stories, 0);
    }

    #[test]
    fn test_status_with_dir() {
        let d = tempfile::tempdir().unwrap();
        std::fs::create_dir_all(d.path().join(ROADMAPS_DIR)).unwrap();
        std::fs::write(d.path().join(ROADMAPS_DIR).join("README.md"), "# 制定版本计划\n").unwrap();
        let s = status(d.path());
        assert!(s.dir_exists);
        assert!(s.readme_exists);
    }
}
