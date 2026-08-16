/// release publish — 发布版本。
///
/// 三阶段架构（与 qtcloud-devops 一致）：
/// 1. Plan（只读）：发布预检（audit）
/// 2. Confirm（交互）：展示操作清单，`-y` 跳过确认
/// 3. Execute（只写）：创建 tag → 推送 → 创建 GitHub Release
use std::io::Write;
use std::path::Path;

use crate::release::audit::{audit, tag_for_version};
use crate::release::status::print_status;
use crate::source::git;

/// 发布选项。
#[derive(Debug, Clone)]
pub struct PublishOptions {
    pub yes: bool,
    pub dry_run: bool,
    pub force: bool,
}

/// 执行发布。
pub fn publish(repo_path: &Path, version: &str, opts: &PublishOptions) -> Result<(), String> {
    let tag = tag_for_version(version)?;

    // 1. Plan：预检
    let items = audit(repo_path, version)?;
    let passed = items.iter().filter(|i| i.passed).count();
    if passed < items.len() {
        let failed: Vec<&str> = items
            .iter()
            .filter(|i| !i.passed)
            .map(|i| i.name.as_str())
            .collect();
        return Err(format!("发布预检未通过（{}/{}）：{}", items.len() - passed, items.len(), failed.join("、")));
    }
    println!("  ✅ 发布预检通过（{}/{}）", passed, items.len());

    // 2. Confirm（-y 跳过）
    if !opts.yes && !opts.dry_run && !confirm(&format!("创建并推送 tag {}？", tag))? {
        println!("  已取消");
        return Ok(());
    }
    if opts.dry_run {
        println!("  [dry-run] 将执行: git tag {} → git push origin {} → gh release create {}", tag, tag, tag);
        return Ok(());
    }

    // 3. Execute
    let has_local = git::has_local_tag(repo_path, &tag).unwrap_or(false);
    if has_local {
        if opts.force {
            git::delete_tag(repo_path, &tag)?;
            println!("  ♻ 已删除已存在的本地 tag {}", tag);
        } else {
            return Err(format!("本地 tag 已存在: {}（使用 --force 重新发布）", tag));
        }
    }
    git::create_tag(repo_path, &tag)?;
    println!("  ✅ 已创建 tag {}", tag);
    git::push_tag(repo_path, &tag)?;
    println!("  ✅ 已推送 tag {} → origin", tag);
    create_gh_release(repo_path, &tag, version)?;
    println!("  ✅ 已创建 GitHub Release {}", tag);
    Ok(())
}

/// 创建 GitHub Release（notes 取 CHANGELOG 对应版本节）。
fn create_gh_release(repo_path: &Path, tag: &str, version: &str) -> Result<(), String> {
    let notes = changelog_section(repo_path, version);
    let mut cmd = std::process::Command::new("gh");
    cmd.args(["release", "create", tag, "--title", tag]);
    if !notes.is_empty() {
        cmd.args(["--notes", &notes]);
    }
    let output = cmd
        .current_dir(repo_path)
        .output()
        .map_err(|e| format!("gh release create 失败: {}", e))?;
    if !output.status.success() {
        return Err(format!(
            "gh release create 失败: {}",
            String::from_utf8_lossy(&output.stderr).trim()
        ));
    }
    Ok(())
}

/// 提取 CHANGELOG 中指定版本的节内容（优先 `src/cli/CHANGELOG.md`）。
pub fn changelog_section(repo_path: &Path, version: &str) -> String {
    let candidates = [
        repo_path.join("src/cli/CHANGELOG.md"),
        repo_path.join("CHANGELOG.md"),
    ];
    let mut content = None;
    for c in candidates {
        if let Ok(text) = std::fs::read_to_string(c) {
            content = Some(text);
            break;
        }
    }
    let Some(content) = content else {
        return String::new();
    };
    let v = version.trim().trim_start_matches('v');
    let lines: Vec<&str> = content.lines().collect();
    let mut start = None;
    for (i, l) in lines.iter().enumerate() {
        let l = l.trim();
        if l.starts_with("## [") && l.contains(v) {
            start = Some(i);
            break;
        }
    }
    let start = match start {
        Some(i) => i,
        None => return String::new(),
    };
    let mut out = Vec::new();
    for l in &lines[start + 1..] {
        let l = l.trim();
        if l.starts_with("## ") {
            break;
        }
        if !l.is_empty() {
            out.push(l);
        }
    }
    out.join("\n")
}

/// 确认交互：`-y` 跳过；返回是否继续。
fn confirm(prompt: &str) -> Result<bool, String> {
    print!("{} [y/N] ", prompt);
    std::io::stdout()
        .flush()
        .map_err(|e| format!("写入失败: {}", e))?;
    let mut line = String::new();
    std::io::stdin()
        .read_line(&mut line)
        .map_err(|e| format!("读取输入失败: {}", e))?;
    let a = line.trim().to_ascii_lowercase();
    Ok(a == "y" || a == "yes")
}

/// 发布后打印状态（供 main 调用）。
pub fn publish_with_status(repo_path: &Path, version: &str, opts: &PublishOptions) -> Result<(), String> {
    print_status(repo_path);
    println!();
    let result = publish(repo_path, version, opts);
    println!();
    print_status(repo_path);
    result
}

#[cfg(test)]
mod tests {
    use super::*;

    fn setup() -> (tempfile::TempDir, tempfile::TempDir) {
        let d = tempfile::tempdir().unwrap();
        run_git(d.path(), &["init", "-b", "main"]).unwrap();
        std::fs::write(d.path().join("f"), "x").unwrap();
        run_git(d.path(), &["add", "."]).unwrap();
        run_git(d.path(), &["-c", "user.name=t", "-c", "user.email=t@t", "commit", "-m", "init"]).unwrap();
        std::fs::write(
            d.path().join("Cargo.toml"),
            "[package]\nname = \"x\"\nversion = \"0.1.0\"\n",
        )
        .unwrap();
        std::fs::write(
            d.path().join("CHANGELOG.md"),
            "# CHANGELOG\n\n## [0.1.0] - 2026-08-16\n\n### Added\n\n- 初始化\n\n## [0.0.1] - 2026-01-01\n\n- 旧版\n",
        )
        .unwrap();
        run_git(d.path(), &["add", "."]).unwrap();
        run_git(d.path(), &["-c", "user.name=t", "-c", "user.email=t@t", "commit", "-m", "release files"]).unwrap();
        // 本地 bare remote：远程检查与 push 可执行
        let remote = tempfile::tempdir().unwrap();
        run_git(remote.path(), &["init", "--bare"]).unwrap();
        run_git(d.path(), &["remote", "add", "origin", remote.path().to_str().unwrap()]).unwrap();
        (d, remote)
    }

    #[test]
    fn test_changelog_section() {
        let (d, _remote) = setup();
        let notes = changelog_section(d.path(), "v0.1.0");
        assert!(notes.contains("初始化"), "应提取 0.1.0 节: {}", notes);
        assert!(!notes.contains("旧版"), "不应包含其他版本内容");
    }

    #[test]
    fn test_publish_dry_run() {
        let (d, _remote) = setup();
        let opts = PublishOptions { yes: true, dry_run: true, force: false };
        publish(d.path(), "v0.1.0", &opts).unwrap();
        assert!(!crate::source::git::has_local_tag(d.path(), "v0.1.0").unwrap(), "dry-run 不应创建 tag");
    }

    #[test]
    fn test_publish_creates_tag() {
        let (d, _remote) = setup();
        let opts = PublishOptions { yes: true, dry_run: false, force: false };
        let result = publish(d.path(), "v0.1.0", &opts);
        let tag_created = crate::source::git::has_local_tag(d.path(), "v0.1.0").unwrap();
        assert!(tag_created, "预检通过后应创建本地 tag");
        // push 到本地 bare remote 应成功；gh release create 在非 GitHub 环境可能失败
        match result {
            Ok(()) => {
                let pushed = crate::source::git::remote_has_tag(d.path(), "v0.1.0").unwrap();
                assert!(pushed, "tag 应已推送到远程");
            }
            Err(e) => {
                // gh 不可用不算失败，本地 tag 与 push 已完成
                assert!(e.contains("gh") || e.contains("Release"), "失败原因应为 gh 相关: {}", e);
            }
        }
    }

    #[test]
    fn test_publish_audit_gate() {
        let (d, _remote) = setup();
        // 改 Cargo.toml 版本使预检失败
        std::fs::write(
            d.path().join("Cargo.toml"),
            "[package]\nname = \"x\"\nversion = \"0.9.9\"\n",
        )
        .unwrap();
        let opts = PublishOptions { yes: true, dry_run: false, force: false };
        assert!(publish(d.path(), "v0.1.0", &opts).is_err(), "预检未通过应中止");
    }

    fn run_git(dir: &Path, args: &[&str]) -> Result<(), String> {
        let output = std::process::Command::new("git")
            .args(args)
            .current_dir(dir)
            .output()
            .map_err(|e| format!("git {} 失败: {}", args.join(" "), e))?;
        if !output.status.success() {
            return Err(String::from_utf8_lossy(&output.stderr).trim().to_string());
        }
        Ok(())
    }
}
