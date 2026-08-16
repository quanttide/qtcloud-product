/// roadmap plan — 生成版本计划。
///
/// 按发布阶段分组用户故事：MVP 版本（上线范围）与未来迭代。
/// 输出到 stdout；`--output` 可写入版本计划文档。
use std::path::Path;

use clap::Args;

use crate::requirement::{scan_stories, stories_root_of, Phase, Status};

/// `roadmap plan` 选项。
#[derive(Debug, Clone, Default, Args)]
pub struct PlanOptions {
    /// 输出文件路径（默认仅打印到 stdout）
    #[arg(long)]
    pub output: Option<std::path::PathBuf>,
}

/// 生成版本计划文本。
pub fn render_plan(repo_path: &Path) -> String {
    let root = stories_root_of(repo_path);
    let stories = scan_stories(&root);
    let mut out = String::new();
    out.push_str("# 版本计划\n\n");
    out.push_str("## MVP 版本\n\n");
    let mvp: Vec<_> = stories.iter().filter(|s| s.phase == Phase::Mvp).collect();
    if mvp.is_empty() {
        out.push_str("（暂无 MVP 故事）\n\n");
    } else {
        for s in &mvp {
            out.push_str(&format!(
                "- [{}] {} — {}（{}）\n",
                match s.status {
                    Status::Done => "x",
                    Status::InProgress => "~",
                    Status::Todo => " ",
                },
                s.title,
                s.id,
                s.task
            ));
        }
        out.push('\n');
    }
    out.push_str("## 未来迭代\n\n");
    let future: Vec<_> = stories.iter().filter(|s| s.phase == Phase::Future).collect();
    if future.is_empty() {
        out.push_str("（暂无未来迭代故事）\n\n");
    } else {
        for s in &future {
            out.push_str(&format!("- [ ] {} — {}\n", s.title, s.id));
        }
        out.push('\n');
    }
    out
}

/// 生成并输出版本计划。
pub fn plan(repo_path: &Path, opts: &PlanOptions) -> Result<(), String> {
    let text = render_plan(repo_path);
    match &opts.output {
        Some(path) => {
            if let Some(parent) = path.parent() {
                std::fs::create_dir_all(parent)
                    .map_err(|e| format!("创建目录失败 {}: {}", parent.display(), e))?;
            }
            std::fs::write(path, text)
                .map_err(|e| format!("写入失败 {}: {}", path.display(), e))?;
            println!("  ✅ 已生成版本计划 → {}", path.display());
            Ok(())
        }
        None => {
            print!("{}", text);
            Ok(())
        }
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
            root.join("user_story/story-mvp.md"),
            "---\ntitle: MVP 故事\nphase: mvp\nstatus: done\n---\n\na\n",
        )
        .unwrap();
        std::fs::write(
            root.join("user_story/story-future.md"),
            "---\ntitle: 未来故事\nphase: future\nstatus: todo\n---\n\nb\n",
        )
        .unwrap();
        d
    }

    #[test]
    fn test_render_plan_groups_by_phase() {
        let d = setup();
        let text = render_plan(d.path());
        assert!(text.contains("## MVP 版本"));
        assert!(text.contains("## 未来迭代"));
        assert!(text.contains("MVP 故事"));
        assert!(text.contains("未来故事"));
        // MVP 故事 done → [x]
        assert!(text.contains("- [x] MVP 故事"));
    }

    #[test]
    fn test_render_plan_empty() {
        let d = tempfile::tempdir().unwrap();
        let text = render_plan(d.path());
        assert!(text.contains("暂无 MVP 故事"));
        assert!(text.contains("暂无未来迭代故事"));
    }

    #[test]
    fn test_plan_writes_file() {
        let d = setup();
        let opts = PlanOptions { output: Some(d.path().join(crate::roadmap::ROADMAPS_DIR).join("README.md")) };
        plan(d.path(), &opts).unwrap();
        let path = d.path().join(crate::roadmap::ROADMAPS_DIR).join("README.md");
        assert!(path.is_file());
        assert!(std::fs::read_to_string(path).unwrap().contains("版本计划"));
    }
}
