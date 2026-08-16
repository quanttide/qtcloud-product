/// 用户故事文档模型：Markdown + YAML frontmatter 的解析与序列化。
///
/// 文档格式约定：
///
/// ```markdown
/// ---
/// title: 编辑用户故事
/// activity: user_story
/// task: 细化用户故事
/// phase: mvp
/// status: done
/// ---
///
/// 作为产品经理，我希望能够编辑用户故事的标题与描述……
/// ```
///
/// 兼容无 frontmatter 的旧文档：id=文件名（去 .md），title=首个 `# ` 标题。
use std::fmt;
use std::path::{Path, PathBuf};

/// 发布阶段（与 Studio `ReleasePhase` 对应）。
#[derive(Debug, Clone, Copy, PartialEq, Eq, Default)]
pub enum Phase {
    #[default]
    Mvp,
    Future,
}

impl Phase {
    pub fn as_str(&self) -> &'static str {
        match self {
            Phase::Mvp => "mvp",
            Phase::Future => "future",
        }
    }
}

impl fmt::Display for Phase {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        f.write_str(self.as_str())
    }
}

/// 故事状态（与 Studio `StoryStatus` 对应）。
#[derive(Debug, Clone, Copy, PartialEq, Eq, Default)]
pub enum Status {
    #[default]
    Todo,
    InProgress,
    Done,
}

impl Status {
    pub fn as_str(&self) -> &'static str {
        match self {
            Status::Todo => "todo",
            Status::InProgress => "inProgress",
            Status::Done => "done",
        }
    }
}

impl fmt::Display for Status {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        f.write_str(self.as_str())
    }
}

/// 用户故事（对应 Studio `UserStory`）。
#[derive(Debug, Clone, PartialEq)]
pub struct UserStory {
    /// id：文件名（去 .md），如 `edit_user_story`
    pub id: String,
    /// 标题
    pub title: String,
    /// 所属用户活动目录名
    pub activity: String,
    /// 所属用户任务标题
    pub task: String,
    /// 发布阶段
    pub phase: Phase,
    /// 故事状态
    pub status: Status,
    /// 描述（正文）
    pub description: String,
    /// 文档相对仓库根的路径
    pub path: String,
}

impl UserStory {
    /// 解析故事文档内容。
    pub fn parse(content: &str, rel_path: &str) -> UserStory {
        let id = story_id_from_path(rel_path);
        let (front, body) = split_frontmatter(content);
        let fields = parse_frontmatter(front);
        let title = fields
            .get("title")
            .map(|s| s.as_str())
            .filter(|s| !s.is_empty())
            .map(|s| s.to_string())
            .or_else(|| first_heading(body))
            .unwrap_or_else(|| id.clone());
        UserStory {
            id,
            title,
            activity: fields.get("activity").cloned().unwrap_or_default(),
            task: fields.get("task").cloned().unwrap_or_default(),
            phase: fields
                .get("phase")
                .map(|s| parse_phase(s))
                .unwrap_or_default(),
            status: fields
                .get("status")
                .map(|s| parse_status(s))
                .unwrap_or_default(),
            description: body.trim().to_string(),
            path: rel_path.to_string(),
        }
    }

    /// 序列化为文档内容（保留 frontmatter）。
    pub fn render(&self) -> String {
        let mut s = String::new();
        s.push_str("---\n");
        s.push_str(&format!("title: {}\n", self.title));
        s.push_str(&format!("activity: {}\n", self.activity));
        s.push_str(&format!("task: {}\n", self.task));
        s.push_str(&format!("phase: {}\n", self.phase));
        s.push_str(&format!("status: {}\n", self.status));
        s.push_str("---\n\n");
        s.push_str(self.description.trim());
        s.push('\n');
        s
    }
}

/// 从相对路径推断故事 id（文件名去 .md）。
pub fn story_id_from_path(rel_path: &str) -> String {
    Path::new(rel_path)
        .file_stem()
        .map(|s| s.to_string_lossy().to_string())
        .unwrap_or_else(|| rel_path.to_string())
}

/// 拆分 frontmatter 与正文。无 frontmatter 时 front 为 None。
fn split_frontmatter(content: &str) -> (Option<&str>, &str) {
    let trimmed = content.trim_start_matches('\u{feff}');
    if let Some(rest) = trimmed.strip_prefix("---") {
        if let Some(end) = rest.find("\n---") {
            return (Some(&rest[..end]), &rest[end + 4..]);
        }
    }
    (None, trimmed)
}

/// 解析 frontmatter 键值（简化 YAML：`key: value` 行）。
fn parse_frontmatter(front: Option<&str>) -> std::collections::HashMap<String, String> {
    let mut map = std::collections::HashMap::new();
    if let Some(f) = front {
        for line in f.lines() {
            let line = line.trim();
            if line.is_empty() || line.starts_with('#') {
                continue;
            }
            if let Some((k, v)) = line.split_once(':') {
                map.insert(k.trim().to_string(), v.trim().to_string());
            }
        }
    }
    map
}

/// 数字编号列表项（如 "1. xxx"）→ 内容部分。
fn numbered_item(line: &str) -> Option<&str> {
    let bytes = line.as_bytes();
    let mut i = 0;
    while i < bytes.len() && bytes[i].is_ascii_digit() {
        i += 1;
    }
    if i > 0 && bytes.get(i) == Some(&b'.') {
        line.get(i + 1..)
    } else {
        None
    }
}

/// 取正文首个 `# ` 一级标题。
fn first_heading(body: &str) -> Option<String> {
    body.lines()
        .map(|l| l.trim())
        .find(|l| l.starts_with("# "))
        .map(|l| l.trim_start_matches("# ").trim().to_string())
}

fn parse_phase(s: &str) -> Phase {
    match s.trim() {
        "future" => Phase::Future,
        _ => Phase::Mvp,
    }
}

fn parse_status(s: &str) -> Status {
    match s.trim() {
        "inProgress" => Status::InProgress,
        "done" => Status::Done,
        _ => Status::Todo,
    }
}

/// 用户活动：`stories/stories/` 下的子目录。
#[derive(Debug, Clone)]
pub struct UserActivity {
    /// 目录名
    pub dir: String,
    /// 标题（目录 README.md 首个标题）
    pub title: String,
    /// 用户任务列表
    pub tasks: Vec<String>,
}

/// 扫描用户活动列表：遍历 stories/stories 子目录，读取各目录 README.md。
pub fn scan_activities(stories_root: &Path) -> Vec<UserActivity> {
    let mut activities = Vec::new();
    let entries = match std::fs::read_dir(stories_root) {
        Ok(e) => e,
        Err(_) => return activities,
    };
    for entry in entries.flatten() {
        let path = entry.path();
        if !path.is_dir() {
            continue;
        }
        let dir = entry.file_name().to_string_lossy().to_string();
        let readme = path.join("README.md");
        let (title, tasks) = if readme.is_file() {
            match std::fs::read_to_string(&readme) {
                Ok(content) => parse_activity_readme(&content, &dir),
                Err(_) => (dir.clone(), Vec::new()),
            }
        } else {
            (dir.clone(), Vec::new())
        };
        activities.push(UserActivity { dir, title, tasks });
    }
    activities.sort_by(|a, b| a.dir.cmp(&b.dir));
    activities
}

/// 解析活动 README：标题 = 首个 `# `；任务 = 「此用户活动的用户任务为：」后列表项。
fn parse_activity_readme(content: &str, fallback_title: &str) -> (String, Vec<String>) {
    let lines: Vec<&str> = content.lines().collect();
    let title = lines
        .iter()
        .find(|l| l.trim_start().starts_with("# "))
        .map(|l| l.trim().trim_start_matches("# ").trim().to_string())
        .unwrap_or_else(|| fallback_title.to_string());
    let mut tasks = Vec::new();
    let mut in_task_list = false;
    for line in lines {
        let l = line.trim();
        if l.starts_with("此用户活动的用户任务为") {
            in_task_list = true;
            continue;
        }
        if in_task_list {
            if l.is_empty() {
                continue;
            }
            // 列表项前缀：- 、* 、+ 或数字编号（如 "1. xxx"）
            let item = l
                .strip_prefix('-')
                .or_else(|| l.strip_prefix('*'))
                .or_else(|| l.strip_prefix('+'))
                .or_else(|| numbered_item(l));
            if let Some(item) = item {
                let t = item.trim();
                let t = t
                    .split_once(". ")
                    .map(|(_, rest)| rest.trim())
                    .unwrap_or(t)
                    .to_string();
                let t = t.trim_end_matches(['。', '.']).trim().to_string();
                if !t.is_empty() {
                    tasks.push(t);
                }
            } else {
                // 非列表行结束任务段（仅当已收集到任务时）
                if !tasks.is_empty() {
                    break;
                }
            }
        }
    }
    if tasks.is_empty() {
        tasks.push("梳理需求".to_string());
    }
    (title, tasks)
}

/// 扫描用户故事文档列表。
pub fn scan_stories(stories_root: &Path) -> Vec<UserStory> {
    let mut stories = Vec::new();
    for activity in scan_activities(stories_root) {
        let dir = stories_root.join(&activity.dir);
        let entries = match std::fs::read_dir(&dir) {
            Ok(e) => e,
            Err(_) => continue,
        };
        for entry in entries.flatten() {
            let path = entry.path();
            if !path.is_file() {
                continue;
            }
            let name = entry.file_name().to_string_lossy().to_string();
            if name == "README.md" || !name.ends_with(".md") {
                continue;
            }
            let rel = format!("{}/{}/{}", crate::requirement::STORIES_DIR, activity.dir, name);
            if let Ok(content) = std::fs::read_to_string(&path) {
                let mut story = UserStory::parse(&content, &rel);
                if story.activity.is_empty() {
                    story.activity = activity.dir.clone();
                }
                if story.task.is_empty() {
                    story.task = activity
                        .tasks
                        .first()
                        .cloned()
                        .unwrap_or_else(|| "梳理需求".to_string());
                }
                stories.push(story);
            }
        }
    }
    stories.sort_by(|a, b| a.path.cmp(&b.path));
    stories
}

/// 故事文档绝对路径 → 仓库根。
pub fn stories_root_of(repo_path: &Path) -> PathBuf {
    repo_path.join(crate::requirement::STORIES_DIR)
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_parse_with_frontmatter() {
        let content = "---\ntitle: 编辑用户故事\nactivity: user_story\ntask: 细化用户故事\nphase: future\nstatus: done\n---\n\n作为产品经理，我希望能够编辑用户故事的标题与描述。\n";
        let s = UserStory::parse(content, "docs/dev-guide/prd/stories/stories/user_story/edit_user_story.md");
        assert_eq!(s.id, "edit_user_story");
        assert_eq!(s.title, "编辑用户故事");
        assert_eq!(s.activity, "user_story");
        assert_eq!(s.task, "细化用户故事");
        assert_eq!(s.phase, Phase::Future);
        assert_eq!(s.status, Status::Done);
        assert!(s.description.contains("作为产品经理"));
    }

    #[test]
    fn test_parse_without_frontmatter() {
        let content = "# 查看用户故事\n\n用户故事详情页。\n";
        let s = UserStory::parse(content, "docs/dev-guide/prd/stories/stories/user_story/show_user_story.md");
        assert_eq!(s.id, "show_user_story");
        assert_eq!(s.title, "查看用户故事");
        assert_eq!(s.phase, Phase::Mvp);
        assert_eq!(s.status, Status::Todo);
    }

    #[test]
    fn test_render_roundtrip() {
        let content = "---\ntitle: 编辑用户故事\nactivity: user_story\ntask: 细化用户故事\nphase: mvp\nstatus: done\n---\n\n作为产品经理，我希望能够编辑用户故事的标题与描述。\n";
        let s = UserStory::parse(content, "a.md");
        let rendered = s.render();
        let s2 = UserStory::parse(&rendered, "a.md");
        assert_eq!(s, s2);
    }

    #[test]
    fn test_parse_activity_readme() {
        let content = "# 管理用户故事\n\n以用户故事为单位管理产品需求。\n\n此用户活动的用户任务为：\n\n1. 使用用户故事地图建立产品全景图。\n2. 细化具体用户故事。\n";
        let (title, tasks) = parse_activity_readme(content, "user_story");
        assert_eq!(title, "管理用户故事");
        assert_eq!(tasks, vec!["使用用户故事地图建立产品全景图", "细化具体用户故事"]);
    }

    #[test]
    fn test_parse_activity_readme_no_tasks() {
        let (title, tasks) = parse_activity_readme("# 绘制原型\n", "prototypes");
        assert_eq!(title, "绘制原型");
        assert_eq!(tasks, vec!["梳理需求"]);
    }

    #[test]
    fn test_scan_activities_empty() {
        let d = tempfile::tempdir().unwrap();
        assert!(scan_activities(d.path()).is_empty());
    }

    #[test]
    fn test_scan_activities_with_dir() {
        let d = tempfile::tempdir().unwrap();
        std::fs::create_dir_all(d.path().join("user_story")).unwrap();
        std::fs::write(d.path().join("user_story/README.md"), "# 管理用户故事\n").unwrap();
        let acts = scan_activities(d.path());
        assert_eq!(acts.len(), 1);
        assert_eq!(acts[0].dir, "user_story");
        assert_eq!(acts[0].title, "管理用户故事");
    }

    #[test]
    fn test_scan_stories() {
        let d = tempfile::tempdir().unwrap();
        std::fs::create_dir_all(d.path().join("user_story")).unwrap();
        std::fs::write(d.path().join("user_story/README.md"), "# 管理用户故事\n\n此用户活动的用户任务为：\n\n1. 细化用户故事\n").unwrap();
        std::fs::write(d.path().join("user_story/edit_user_story.md"), "---\ntitle: 编辑用户故事\nphase: mvp\nstatus: done\n---\n\ndesc\n").unwrap();
        std::fs::write(d.path().join("user_story/show_user_story.md"), "# 查看用户故事\n").unwrap();
        let stories = scan_stories(d.path());
        assert_eq!(stories.len(), 2);
        let edit = stories.iter().find(|s| s.id == "edit_user_story").unwrap();
        assert_eq!(edit.activity, "user_story");
        assert_eq!(edit.task, "细化用户故事");
        let show = stories.iter().find(|s| s.id == "show_user_story").unwrap();
        assert_eq!(show.title, "查看用户故事");
    }
}
