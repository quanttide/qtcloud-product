/// release audit — 发布预检（门禁判定）。
///
/// 检查项：
/// 1. 版本号格式（`vX.Y.Z` 或 `scope/vX.Y.Z`，semver 校验）
/// 2. Cargo.toml 版本一致（scope 为 cli 时）
/// 3. CHANGELOG 包含该版本
/// 4. git 工作区干净
/// 5. 本地 tag 不冲突
/// 6. 远程 tag 不冲突（网络）
use std::path::Path;

use crate::release::status::{changelog_version, crate_version};
use crate::source::git;

/// 审计项。
#[derive(Debug)]
pub struct AuditItem {
    pub name: String,
    pub passed: bool,
    pub detail: String,
}

/// 归一化版本：去掉 `v` 前缀与 scope 前缀，返回 (scope, semver)。
pub fn normalize_version(version: &str) -> Result<(Option<String>, String), String> {
    let v = version.trim();
    let (scope, rest) = match v.split_once('/') {
        Some((s, r)) => (Some(s.to_string()), r),
        None => (None, v),
    };
    let semver_part = rest.trim_start_matches('v');
    let parsed = semver::Version::parse(semver_part)
        .map_err(|e| format!("版本号格式错误 '{}': {}", version, e))?;
    Ok((scope, format!("{}.{}.{}", parsed.major, parsed.minor, parsed.patch)))
}

/// 版本对应的完整 tag 名（带 scope 前缀则 `scope/vX.Y.Z`，否则 `vX.Y.Z`）。
pub fn tag_for_version(version: &str) -> Result<String, String> {
    let (scope, semver) = normalize_version(version)?;
    Ok(match scope {
        Some(s) => format!("{}/v{}", s, semver),
        None => format!("v{}", semver),
    })
}

/// 执行发布预检。
pub fn audit(repo_path: &Path, version: &str) -> Result<Vec<AuditItem>, String> {
    let (scope, semver) = normalize_version(version)?;
    let tag = tag_for_version(version)?;
    let mut items = Vec::new();

    // 1. 版本号格式（normalize_version 已校验）
    items.push(AuditItem {
        name: "版本号格式".to_string(),
        passed: true,
        detail: format!("{} → {}", version, tag),
    });

    // 2. Cargo.toml 版本一致（仅当 scope 为 cli 或无 scope 时）
    let cargo_ver = crate_version(repo_path);
    let version_consistent = match &scope {
        Some(s) if s != "cli" => true, // 其他 scope（如 studio）不检查 Cargo.toml
        _ => cargo_ver.as_deref() == Some(semver.as_str()),
    };
    items.push(AuditItem {
        name: "Cargo.toml 版本一致".to_string(),
        passed: version_consistent,
        detail: match (&scope, &cargo_ver) {
            (Some(s), _) if s != "cli" => "非 cli scope，跳过 Cargo.toml 检查".to_string(),
            (_, Some(cv)) => format!("Cargo.toml 版本 {} vs 发布版本 {}", cv, semver),
            (_, None) => "未检测到 Cargo.toml".to_string(),
        },
    });

    // 3. CHANGELOG 包含版本
    let changelog_ok = changelog_version(repo_path).as_deref() == Some(semver.as_str());
    items.push(AuditItem {
        name: "CHANGELOG 版本一致".to_string(),
        passed: changelog_ok,
        detail: match changelog_version(repo_path) {
            Some(cv) => format!("CHANGELOG 版本 v{} vs 发布版本 v{}", cv, semver),
            None => "CHANGELOG 未检测到版本头".to_string(),
        },
    });

    // 4. 工作区干净
    let clean = git::is_clean(repo_path).unwrap_or(false);
    let dirty = git::dirty_entries(repo_path);
    items.push(AuditItem {
        name: "工作区干净".to_string(),
        passed: clean,
        detail: if clean {
            "无未提交变更".to_string()
        } else {
            format!("{} 项变更: {}", dirty.len(), dirty.join("; "))
        },
    });

    // 5. 本地 tag 不冲突
    let has_local = git::has_local_tag(repo_path, &tag).unwrap_or(false);
    items.push(AuditItem {
        name: "本地 tag 无冲突".to_string(),
        passed: !has_local,
        detail: if has_local { format!("tag 已存在: {}", tag) } else { format!("tag {} 可创建", tag) },
    });

    // 6. 远程 tag 不冲突（网络）
    match git::remote_has_tag(repo_path, &tag) {
        Ok(false) => items.push(AuditItem {
            name: "远程 tag 无冲突".to_string(),
            passed: true,
            detail: format!("远程无 tag {}", tag),
        }),
        Ok(true) => items.push(AuditItem {
            name: "远程 tag 无冲突".to_string(),
            passed: false,
            detail: format!("远程已存在 tag: {}", tag),
        }),
        Err(e) => items.push(AuditItem {
            name: "远程 tag 无冲突".to_string(),
            passed: false,
            detail: format!("检查失败（无远程或网络不可达）: {}", e),
        }),
    }

    Ok(items)
}

/// 向 stdout 输出审计结果；未通过时返回错误。
pub fn print_audit(repo_path: &Path, version: &str) -> Result<(), String> {
    let items = audit(repo_path, version)?;
    println!("发布审计 — {}\n{}", version, "-".repeat(50));
    let passed = items.iter().filter(|i| i.passed).count();
    for item in &items {
        println!("  {} {}", if item.passed { "✅" } else { "❌" }, item.name);
        println!("        {}", item.detail);
    }
    println!("{}\n  {}/{} 项通过", "-".repeat(50), passed, items.len());
    if passed == items.len() {
        println!("  全部检查通过，可以发布");
        Ok(())
    } else {
        Err(format!("{}/{} 项未通过", items.len() - passed, items.len()))
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_normalize_version() {
        assert_eq!(normalize_version("v1.2.3").unwrap(), (None, "1.2.3".to_string()));
        assert_eq!(
            normalize_version("cli/v0.5.0").unwrap(),
            (Some("cli".to_string()), "0.5.0".to_string())
        );
        assert_eq!(normalize_version("0.4.1-rc.1").unwrap(), (None, "0.4.1".to_string()));
        assert!(normalize_version("abc").is_err());
        assert!(normalize_version("v1.2").is_err());
    }

    #[test]
    fn test_tag_for_version() {
        assert_eq!(tag_for_version("v1.2.3").unwrap(), "v1.2.3");
        assert_eq!(tag_for_version("cli/v0.5.0").unwrap(), "cli/v0.5.0");
        assert_eq!(tag_for_version("cli/v0.5.0-rc.1").unwrap(), "cli/v0.5.0");
    }

    #[test]
    fn test_audit_version_format() {
        let d = tempfile::tempdir().unwrap();
        assert!(audit(d.path(), "bad-version").is_err());
        let items = audit(d.path(), "v0.1.0").unwrap();
        assert!(items[0].passed);
    }

    #[test]
    fn test_audit_cargo_mismatch() {
        let d = tempfile::tempdir().unwrap();
        std::fs::write(
            d.path().join("Cargo.toml"),
            "[package]\nname = \"x\"\nversion = \"0.2.0\"\n",
        )
        .unwrap();
        let items = audit(d.path(), "v0.1.0").unwrap();
        assert!(!items[1].passed, "Cargo.toml 版本不一致应失败");
    }

    #[test]
    fn test_audit_clean_repo_passes() {
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
            "# CHANGELOG\n\n## [0.1.0] - 2026-08-16\n\n- init\n",
        )
        .unwrap();
        run_git(d.path(), &["add", "."]).unwrap();
        run_git(d.path(), &["-c", "user.name=t", "-c", "user.email=t@t", "commit", "-m", "release files"]).unwrap();
        // 配置本地 bare remote，使远程检查可执行
        let remote = tempfile::tempdir().unwrap();
        run_git(remote.path(), &["init", "--bare"]).unwrap();
        run_git(d.path(), &["remote", "add", "origin", remote.path().to_str().unwrap()]).unwrap();
        let items = audit(d.path(), "v0.1.0").unwrap();
        for (idx, item) in items.iter().enumerate() {
            assert!(item.passed, "第 {} 项应通过: {} — {}", idx, item.name, item.detail);
        }
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
