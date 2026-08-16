/// release status — 发布状态。
use std::path::Path;

use crate::source::git;

/// 发布状态。
#[derive(Debug)]
pub struct ReleaseStatus {
    pub crate_version: Option<String>,
    pub changelog_version: Option<String>,
    pub latest_tag: Option<String>,
    pub clean: bool,
    pub remote: Option<String>,
}

/// 读取 Cargo.toml 的 version 字段（本 crate 版本）。
///
/// 本 CLI 位于仓库 `src/cli/`，因此依次检查 `src/cli/Cargo.toml` 与仓库根
/// `Cargo.toml`，取先存在者。
pub fn crate_version(repo_path: &Path) -> Option<String> {
    let candidates = [
        repo_path.join("src/cli/Cargo.toml"),
        repo_path.join("Cargo.toml"),
    ];
    for cargo in candidates {
        let Ok(content) = std::fs::read_to_string(&cargo) else {
            continue;
        };
        for line in content.lines() {
            let l = line.trim();
            if let Some(rest) = l.strip_prefix("version =") {
                let v = rest.trim().trim_matches('"').trim_matches('\'');
                if !v.is_empty() {
                    return Some(v.to_string());
                }
            }
        }
    }
    None
}

/// 读取 CHANGELOG 首个版本头（`## [x.y.z]` 或 `## [vx.y.z]`）。
///
/// 本 CLI 的 CHANGELOG 位于仓库 `src/cli/`，因此依次检查 `src/cli/CHANGELOG.md`
/// 与仓库根 `CHANGELOG.md`，取先存在者。
pub fn changelog_version(repo_path: &Path) -> Option<String> {
    let candidates = [
        repo_path.join("src/cli/CHANGELOG.md"),
        repo_path.join("CHANGELOG.md"),
    ];
    for changelog in candidates {
        let Ok(content) = std::fs::read_to_string(&changelog) else {
            continue;
        };
        if let Some(v) = content.lines().find_map(|l| {
            let l = l.trim();
            if let Some(rest) = l.strip_prefix("## [") {
                if let Some(v) = rest.split(']').next() {
                    let v = v.trim().trim_start_matches('v');
                    if !v.is_empty() {
                        return Some(v.to_string());
                    }
                }
            }
            None
        }) {
            return Some(v);
        }
    }
    None
}

/// 列出最近的版本标签（`cli/vX.Y.Z` 或 `vX.Y.Z`）。
pub fn latest_tag(repo_path: &Path) -> Option<String> {
    let output = std::process::Command::new("git")
        .args(["tag", "-l", "cli/v*", "--sort=-version:refname"])
        .current_dir(repo_path)
        .output()
        .ok()?;
    if !output.status.success() {
        return None;
    }
    let tags: Vec<String> = String::from_utf8_lossy(&output.stdout)
        .lines()
        .map(|l| l.to_string())
        .collect();
    if tags.is_empty() {
        // 回退到无前缀标签
        let output = std::process::Command::new("git")
            .args(["tag", "-l", "v*", "--sort=-version:refname"])
            .current_dir(repo_path)
            .output()
            .ok()?;
        if output.status.success() {
            return String::from_utf8_lossy(&output.stdout)
                .lines()
                .next()
                .map(|l| l.to_string());
        }
        None
    } else {
        tags.into_iter().next()
    }
}

/// 读取 git 远程地址（origin）。
pub fn remote_url(repo_path: &Path) -> Option<String> {
    let output = std::process::Command::new("git")
        .args(["remote", "get-url", "origin"])
        .current_dir(repo_path)
        .output()
        .ok()?;
    if output.status.success() {
        Some(String::from_utf8_lossy(&output.stdout).trim().to_string())
    } else {
        None
    }
}

/// 聚合发布状态。
pub fn status(repo_path: &Path) -> ReleaseStatus {
    ReleaseStatus {
        crate_version: crate_version(repo_path),
        changelog_version: changelog_version(repo_path),
        latest_tag: latest_tag(repo_path),
        clean: git::is_clean(repo_path).unwrap_or(false),
        remote: remote_url(repo_path),
    }
}

/// 向 stdout 输出发布状态。
pub fn print_status(repo_path: &Path) {
    let s = status(repo_path);
    println!("发布状态\n{}", "-".repeat(50));
    println!(
        "  crate 版本: {}",
        s.crate_version.as_deref().unwrap_or("（未检测到 Cargo.toml）")
    );
    println!(
        "  CHANGELOG: {}",
        s.changelog_version
            .map(|v| format!("v{}", v))
            .unwrap_or_else(|| "（未检测到版本头）".to_string())
    );
    println!(
        "  最新标签: {}",
        s.latest_tag.as_deref().unwrap_or("（无标签）")
    );
    println!("  工作区: {}", if s.clean { "✅ 干净" } else { "⚠ 有未提交变更" });
    println!(
        "  远程: {}",
        s.remote.as_deref().unwrap_or("（未配置 origin）")
    );
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_crate_version() {
        let d = tempfile::tempdir().unwrap();
        assert_eq!(crate_version(d.path()), None);
        std::fs::write(
            d.path().join("Cargo.toml"),
            "[package]\nname = \"x\"\nversion = \"0.1.0\"\n",
        )
        .unwrap();
        assert_eq!(crate_version(d.path()).unwrap(), "0.1.0");
    }

    #[test]
    fn test_changelog_version() {
        let d = tempfile::tempdir().unwrap();
        assert_eq!(changelog_version(d.path()), None);
        std::fs::write(
            d.path().join("CHANGELOG.md"),
            "# CHANGELOG\n\n## [0.2.0] - 2026-08-16\n\n### Added\n\n- x\n",
        )
        .unwrap();
        assert_eq!(changelog_version(d.path()).unwrap(), "0.2.0");
    }

    #[test]
    fn test_latest_tag_in_repo() {
        let d = tempfile::tempdir().unwrap();
        run_git(d.path(), &["init", "-b", "main"]).unwrap();
        std::fs::write(d.path().join("f"), "x").unwrap();
        run_git(d.path(), &["add", "."]).unwrap();
        run_git(d.path(), &["-c", "user.name=t", "-c", "user.email=t@t", "commit", "-m", "init"]).unwrap();
        run_git(d.path(), &["tag", "cli/v0.1.0"]).unwrap();
        run_git(d.path(), &["tag", "cli/v0.2.0"]).unwrap();
        assert_eq!(latest_tag(d.path()).unwrap(), "cli/v0.2.0");
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
