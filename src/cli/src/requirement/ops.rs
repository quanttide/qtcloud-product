/// requirement 命令实现：list / show / add / edit / remove / status。
use std::path::Path;

use clap::Args;

use super::model::{scan_stories, stories_root_of, Phase, Status, UserStory};

/// `requirement add` 选项。
#[derive(Debug, Clone, Args)]
pub struct AddOptions {
    /// 故事标题（必填）
    #[arg(long)]
    pub title: String,
    /// 所属用户活动目录名（默认 user_story）
    #[arg(long, default_value = "user_story")]
    pub activity: String,
    /// 所属用户任务标题
    #[arg(long)]
    pub task: Option<String>,
    /// 发布阶段 mvp|future
    #[arg(long, default_value = "mvp")]
    pub phase: String,
    /// 故事状态 todo|inProgress|done
    #[arg(long, default_value = "todo")]
    pub status: String,
    /// 故事描述（正文）
    #[arg(long)]
    pub description: Option<String>,
}

impl Default for AddOptions {
    fn default() -> Self {
        AddOptions {
            title: String::new(),
            activity: "user_story".to_string(),
            task: None,
            phase: "mvp".to_string(),
            status: "todo".to_string(),
            description: None,
        }
    }
}

/// `requirement edit` 选项（至少提供一个）。
#[derive(Debug, Clone, Default, Args)]
pub struct EditOptions {
    /// 新标题
    #[arg(long)]
    pub title: Option<String>,
    /// 所属用户活动目录名
    #[arg(long)]
    pub activity: Option<String>,
    /// 所属用户任务标题
    #[arg(long)]
    pub task: Option<String>,
    /// 发布阶段 mvp|future
    #[arg(long)]
    pub phase: Option<String>,
    /// 故事状态 todo|inProgress|done
    #[arg(long)]
    pub status: Option<String>,
    /// 故事描述（正文）
    #[arg(long)]
    pub description: Option<String>,
}

/// 列出全部用户故事。
pub fn list(repo_path: &Path) -> Result<(), String> {
    let root = stories_root_of(repo_path);
    let stories = scan_stories(&root);
    if stories.is_empty() {
        println!("  暂无用户故事");
        return Ok(());
    }
    println!("用户故事\n{}", "-".repeat(50));
    for s in &stories {
        println!(
            "  {} [{}] {} ({}) — {}/{}",
            status_mark(s.status),
            s.id,
            s.title,
            s.phase,
            s.activity,
            s.task
        );
        println!("        {}", s.path);
    }
    println!("{}\n  共 {} 个用户故事", "-".repeat(50), stories.len());
    Ok(())
}

/// 查看用户故事详情。
pub fn show(repo_path: &Path, id: &str) -> Result<(), String> {
    let story = find_story(repo_path, id)?;
    println!("用户故事\n{}", "-".repeat(50));
    println!("  id: {}", story.id);
    println!("  标题: {}", story.title);
    println!("  活动: {} ({})", story.activity, activity_title(repo_path, &story.activity));
    println!("  任务: {}", story.task);
    println!("  阶段: {}", story.phase);
    println!("  状态: {}", story.status);
    println!("  文档: {}", story.path);
    if !story.description.is_empty() {
        println!("  描述: {}", story.description.replace('\n', "\n        "));
    }
    Ok(())
}

/// 添加用户故事。
pub fn add(repo_path: &Path, opts: &AddOptions) -> Result<(), String> {
    if opts.title.trim().is_empty() {
        return Err("标题不能为空（--title）".to_string());
    }
    let phase = parse_phase_opt(Some(&opts.phase))?;
    let status = parse_status_opt(Some(&opts.status))?;
    let activity = normalize_activity(&opts.activity);
    let root = stories_root_of(repo_path);
    let activity_dir = root.join(&activity);
    if !activity_dir.is_dir() {
        return Err(format!("用户活动不存在: {}（先创建目录 {}/）", activity, activity_dir.display()));
    }
    let id = story_id_from_title(&opts.title);
    let rel = format!("{}/{}/{}.md", crate::requirement::STORIES_DIR, activity, id);
    let path = repo_path.join(&rel);
    if path.exists() {
        return Err(format!("用户故事已存在: {}（{}）", id, rel));
    }
    let task = match &opts.task {
        Some(t) if !t.trim().is_empty() => t.trim().to_string(),
        _ => default_task(&root, &activity),
    };
    let story = UserStory {
        id,
        title: opts.title.trim().to_string(),
        activity,
        task,
        phase,
        status,
        description: opts.description.clone().unwrap_or_default(),
        path: rel.clone(),
    };
    write_story(&path, &story)?;
    println!("  ✅ 已添加用户故事 {}（{}）", story.title, rel);
    Ok(())
}

/// 编辑用户故事。
pub fn edit(repo_path: &Path, id: &str, opts: &EditOptions) -> Result<(), String> {
    let story = find_story(repo_path, id)?;
    let path = repo_path.join(&story.path);
    let mut updated = story.clone();
    if let Some(t) = &opts.title {
        updated.title = t.trim().to_string();
    }
    if let Some(a) = &opts.activity {
        updated.activity = normalize_activity(a);
    }
    if let Some(t) = &opts.task {
        updated.task = t.trim().to_string();
    }
    if let Some(p) = &opts.phase {
        updated.phase = parse_phase_opt(Some(p))?;
    }
    if let Some(s) = &opts.status {
        updated.status = parse_status_opt(Some(s))?;
    }
    if let Some(d) = &opts.description {
        updated.description = d.trim().to_string();
    }
    write_story(&path, &updated)?;
    println!("  ✅ 已更新用户故事 {}（{}）", updated.id, updated.path);
    Ok(())
}

/// 删除用户故事。
pub fn remove(repo_path: &Path, id: &str) -> Result<(), String> {
    let story = find_story(repo_path, id)?;
    let path = repo_path.join(&story.path);
    std::fs::remove_file(&path)
        .map_err(|e| format!("删除失败 {}: {}", path.display(), e))?;
    println!("  ✅ 已删除用户故事 {}（{}）", story.title, story.path);
    Ok(())
}

/// 需求梳理状态：按活动/任务聚合统计。
pub fn status(repo_path: &Path) -> Result<(), String> {
    let root = stories_root_of(repo_path);
    let stories = scan_stories(&root);
    println!("需求梳理\n{}", "-".repeat(50));
    if !root.is_dir() {
        println!("  ❌ 用户故事目录不存在: {}", root.display());
        return Err("缺少用户故事目录".to_string());
    }
    println!("  用户故事总数: {}", stories.len());
    let mvp = stories.iter().filter(|s| s.phase == Phase::Mvp).count();
    let future = stories.iter().filter(|s| s.phase == Phase::Future).count();
    let done = stories.iter().filter(|s| s.status == Status::Done).count();
    let in_progress = stories.iter().filter(|s| s.status == Status::InProgress).count();
    let todo = stories.iter().filter(|s| s.status == Status::Todo).count();
    println!("  发布阶段: mvp {} / future {}", mvp, future);
    println!("  故事状态: done {} / inProgress {} / todo {}", done, in_progress, todo);
    // 按活动聚合
    let mut by_activity: Vec<(&str, usize)> = Vec::new();
    for s in &stories {
        if let Some((_, n)) = by_activity.iter_mut().find(|(a, _)| *a == s.activity) {
            *n += 1;
        } else {
            by_activity.push((s.activity.as_str(), 1));
        }
    }
    println!("  按活动:");
    for (a, n) in by_activity {
        println!("    {}: {} 个用户故事", a, n);
    }
    Ok(())
}

/// 查找用户故事（按 id 或标题）。
pub fn find_story(repo_path: &Path, id: &str) -> Result<UserStory, String> {
    let root = stories_root_of(repo_path);
    let stories = scan_stories(&root);
    stories
        .into_iter()
        .find(|s| s.id == id || s.title == id)
        .ok_or_else(|| format!("未找到用户故事: {}（用 `qtcloud-product requirement list` 查看）", id))
}

fn write_story(path: &Path, story: &UserStory) -> Result<(), String> {
    if let Some(parent) = path.parent() {
        std::fs::create_dir_all(parent)
            .map_err(|e| format!("创建目录失败 {}: {}", parent.display(), e))?;
    }
    std::fs::write(path, story.render())
        .map_err(|e| format!("写入失败 {}: {}", path.display(), e))
}

/// 从标题生成 id：ASCII 词间以 `-` 连接，非 ASCII（中文等）直接保留。
fn story_id_from_title(title: &str) -> String {
    let mut id = String::new();
    let mut prev_dash = false;
    for ch in title.trim().chars() {
        if ch.is_ascii_alphanumeric() {
            id.push(ch.to_ascii_lowercase());
            prev_dash = false;
        } else if ch == '_' || ch == '-' || ch == ' ' {
            if !prev_dash && !id.is_empty() {
                id.push('-');
                prev_dash = true;
            }
        } else if !ch.is_ascii() {
            // 非 ASCII（中文等）：直接保留，不插入分隔符
            id.push(ch);
            prev_dash = false;
        }
    }
    let id = id.trim_matches('-').to_string();
    if id.is_empty() { "story".to_string() } else { id }
}

fn normalize_activity(activity: &str) -> String {
    activity.trim().trim_matches('/').to_string()
}

/// 活动缺省任务：活动 README 的任务列表首个，否则「梳理需求」。
fn default_task(stories_root: &Path, activity: &str) -> String {
    super::model::scan_activities(stories_root)
        .into_iter()
        .find(|a| a.dir == activity)
        .and_then(|a| a.tasks.into_iter().next())
        .unwrap_or_else(|| "梳理需求".to_string())
}

/// 活动标题（README 标题），用于展示。
fn activity_title(repo_path: &Path, activity: &str) -> String {
    let root = stories_root_of(repo_path);
    super::model::scan_activities(&root)
        .into_iter()
        .find(|a| a.dir == activity)
        .map(|a| a.title)
        .unwrap_or_else(|| activity.to_string())
}

pub fn parse_phase_opt(s: Option<&str>) -> Result<Phase, String> {
    match s.map(str::trim) {
        None | Some("") | Some("mvp") => Ok(Phase::Mvp),
        Some("future") => Ok(Phase::Future),
        Some(other) => Err(format!("非法阶段: {}（可选 mvp|future）", other)),
    }
}

pub fn parse_status_opt(s: Option<&str>) -> Result<Status, String> {
    match s.map(str::trim) {
        None | Some("") | Some("todo") => Ok(Status::Todo),
        Some("inProgress") => Ok(Status::InProgress),
        Some("done") => Ok(Status::Done),
        Some(other) => Err(format!("非法状态: {}（可选 todo|inProgress|done）", other)),
    }
}

fn status_mark(status: Status) -> &'static str {
    match status {
        Status::Done => "✅",
        Status::InProgress => "🔄",
        Status::Todo => "⬜",
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
        d
    }

    #[test]
    fn test_story_id_from_title() {
        assert_eq!(story_id_from_title("Edit User Story"), "edit-user-story");
        assert_eq!(story_id_from_title("编辑用户故事"), "编辑用户故事");
        assert_eq!(story_id_from_title("  "), "story");
        assert_eq!(story_id_from_title("Story v2!"), "story-v2");
    }

    #[test]
    fn test_add_and_list() {
        let d = setup();
        let opts = AddOptions {
            title: "Edit User Story".to_string(),
            ..Default::default()
        };
        add(d.path(), &opts).unwrap();
        let stories = scan_stories(&d.path().join(crate::requirement::STORIES_DIR));
        assert_eq!(stories.len(), 1);
        assert_eq!(stories[0].id, "edit-user-story");
        assert_eq!(stories[0].task, "细化用户故事");
        assert_eq!(stories[0].phase, Phase::Mvp);
    }

    #[test]
    fn test_add_duplicate_fails() {
        let d = setup();
        let opts = AddOptions { title: "Edit User Story".to_string(), ..Default::default() };
        add(d.path(), &opts).unwrap();
        assert!(add(d.path(), &opts).is_err(), "重复 id 应失败");
    }

    #[test]
    fn test_add_missing_activity_fails() {
        let d = setup();
        let opts = AddOptions {
            title: "X".to_string(),
            activity: "ghost".to_string(),
            ..Default::default()
        };
        assert!(add(d.path(), &opts).is_err(), "不存在的活动应失败");
    }

    #[test]
    fn test_add_empty_title_fails() {
        let d = setup();
        let opts = AddOptions::default();
        assert!(add(d.path(), &opts).is_err());
    }

    #[test]
    fn test_edit_roundtrip() {
        let d = setup();
        add(d.path(), &AddOptions { title: "Edit User Story".to_string(), ..Default::default() }).unwrap();
        let opts = EditOptions {
            status: Some("done".to_string()),
            phase: Some("future".to_string()),
            title: Some("Edit Story".to_string()),
            ..Default::default()
        };
        edit(d.path(), "edit-user-story", &opts).unwrap();
        let story = find_story(d.path(), "edit-user-story").unwrap();
        assert_eq!(story.status, Status::Done);
        assert_eq!(story.phase, Phase::Future);
        assert_eq!(story.title, "Edit Story");
    }

    #[test]
    fn test_edit_not_found() {
        let d = setup();
        assert!(edit(d.path(), "ghost", &EditOptions::default()).is_err());
    }

    #[test]
    fn test_remove() {
        let d = setup();
        add(d.path(), &AddOptions { title: "Edit User Story".to_string(), ..Default::default() }).unwrap();
        remove(d.path(), "edit-user-story").unwrap();
        let stories = scan_stories(&d.path().join(crate::requirement::STORIES_DIR));
        assert!(stories.is_empty());
    }

    #[test]
    fn test_parse_phase_status() {
        assert_eq!(parse_phase_opt(Some("future")).unwrap(), Phase::Future);
        assert!(parse_phase_opt(Some("backlog")).is_err());
        assert_eq!(parse_status_opt(Some("inProgress")).unwrap(), Status::InProgress);
        assert!(parse_status_opt(Some("wip")).is_err());
    }

    #[test]
    fn test_status_counts() {
        let d = setup();
        add(d.path(), &AddOptions { title: "Story A".to_string(), ..Default::default() }).unwrap();
        add(d.path(), &AddOptions { title: "Story B".to_string(), status: "done".to_string(), ..Default::default() }).unwrap();
        // status 打印到 stdout，此处验证扫描结果
        let stories = scan_stories(&d.path().join(crate::requirement::STORIES_DIR));
        assert_eq!(stories.len(), 2);
    }
}
