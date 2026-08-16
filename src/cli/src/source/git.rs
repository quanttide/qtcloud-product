/// git 命令封装。
///
/// 设计决策（与 qtcloud-devops 一致）：任何需要网络的 git 操作
/// （push、fetch、ls-remote 等）必须用 `std::process::Command::new("git")`，
/// 不使用 git2 crate —— 系统 git 命令使用用户已配置的 credential helper
/// （如 `gh auth setup-git`），不存在认证回调缺失问题。
use std::path::{Path, PathBuf};
use std::process::Command;

/// 解析仓库根目录：从当前目录向上查找 git 顶层。
/// 失败时回退到当前目录。
pub fn repo_path() -> PathBuf {
    let cwd = std::env::current_dir().unwrap_or_else(|_| PathBuf::from("."));
    let output = Command::new("git")
        .args(["rev-parse", "--show-toplevel"])
        .current_dir(&cwd)
        .output();
    match output {
        Ok(o) if o.status.success() => {
            PathBuf::from(std::str::from_utf8(&o.stdout).unwrap_or("").trim())
        }
        _ => cwd,
    }
}

/// 检查工作区是否干净（无未提交变更、无未跟踪文件）。
pub fn is_clean(repo_path: &Path) -> Result<bool, String> {
    let output = Command::new("git")
        .args(["status", "--porcelain"])
        .current_dir(repo_path)
        .output()
        .map_err(|e| format!("git status 失败: {}", e))?;
    if !output.status.success() {
        return Err(String::from_utf8_lossy(&output.stderr).trim().to_string());
    }
    Ok(output.stdout.is_empty())
}

/// 列出工作区未提交变更（porcelain 格式）。
pub fn dirty_entries(repo_path: &Path) -> Vec<String> {
    let output = Command::new("git")
        .args(["status", "--porcelain"])
        .current_dir(repo_path)
        .output();
    match output {
        Ok(o) if o.status.success() => String::from_utf8_lossy(&o.stdout)
            .lines()
            .map(|l| l.to_string())
            .collect(),
        _ => Vec::new(),
    }
}

/// 检查本地 tag 是否存在。
pub fn has_local_tag(repo_path: &Path, tag: &str) -> Result<bool, String> {
    let output = Command::new("git")
        .args(["tag", "-l", tag])
        .current_dir(repo_path)
        .output()
        .map_err(|e| format!("git tag 失败: {}", e))?;
    if !output.status.success() {
        return Err(String::from_utf8_lossy(&output.stderr).trim().to_string());
    }
    Ok(!String::from_utf8_lossy(&output.stdout).trim().is_empty())
}

/// 检查远程 tag 是否存在（网络操作）。
pub fn remote_has_tag(repo_path: &Path, tag: &str) -> Result<bool, String> {
    let output = Command::new("git")
        .args(["ls-remote", "--tags", "origin", tag])
        .current_dir(repo_path)
        .output()
        .map_err(|e| format!("git ls-remote 失败: {}", e))?;
    if !output.status.success() {
        return Err(String::from_utf8_lossy(&output.stderr).trim().to_string());
    }
    Ok(!String::from_utf8_lossy(&output.stdout).trim().is_empty())
}

/// 创建本地 tag（轻量，无注解）。
pub fn create_tag(repo_path: &Path, tag: &str) -> Result<(), String> {
    let output = Command::new("git")
        .args(["tag", tag])
        .current_dir(repo_path)
        .output()
        .map_err(|e| format!("git tag 失败: {}", e))?;
    if !output.status.success() {
        return Err(String::from_utf8_lossy(&output.stderr).trim().to_string());
    }
    Ok(())
}

/// 删除本地 tag。
pub fn delete_tag(repo_path: &Path, tag: &str) -> Result<(), String> {
    let output = Command::new("git")
        .args(["tag", "-d", tag])
        .current_dir(repo_path)
        .output()
        .map_err(|e| format!("git tag -d 失败: {}", e))?;
    if !output.status.success() {
        return Err(String::from_utf8_lossy(&output.stderr).trim().to_string());
    }
    Ok(())
}

/// 推送 tag 到 origin（网络操作）。
pub fn push_tag(repo_path: &Path, tag: &str) -> Result<(), String> {
    let output = Command::new("git")
        .args(["push", "origin", tag])
        .current_dir(repo_path)
        .output()
        .map_err(|e| format!("git push 失败: {}", e))?;
    if !output.status.success() {
        return Err(String::from_utf8_lossy(&output.stderr).trim().to_string());
    }
    Ok(())
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_is_clean_empty_repo() {
        let d = tempfile::tempdir().unwrap();
        run_git(d.path(), &["init", "-b", "main"]).unwrap();
        assert!(is_clean(d.path()).unwrap(), "空仓库应视为干净");
    }

    #[test]
    fn test_is_clean_with_dirty_file() {
        let d = tempfile::tempdir().unwrap();
        run_git(d.path(), &["init", "-b", "main"]).unwrap();
        std::fs::write(d.path().join("f"), "x").unwrap();
        assert!(!is_clean(d.path()).unwrap(), "未跟踪文件应视为脏");
        assert_eq!(dirty_entries(d.path()).len(), 1);
    }

    #[test]
    fn test_create_and_has_tag() {
        let d = tempfile::tempdir().unwrap();
        run_git(d.path(), &["init", "-b", "main"]).unwrap();
        std::fs::write(d.path().join("f"), "x").unwrap();
        run_git(d.path(), &["add", "."]).unwrap();
        run_git(
            d.path(),
            &["-c", "user.name=t", "-c", "user.email=t@t", "commit", "-m", "init"],
        )
        .unwrap();
        assert!(!has_local_tag(d.path(), "v0.1.0").unwrap());
        create_tag(d.path(), "v0.1.0").unwrap();
        assert!(has_local_tag(d.path(), "v0.1.0").unwrap());
        delete_tag(d.path(), "v0.1.0").unwrap();
        assert!(!has_local_tag(d.path(), "v0.1.0").unwrap());
    }

    fn run_git(dir: &Path, args: &[&str]) -> Result<(), String> {
        let output = Command::new("git")
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
