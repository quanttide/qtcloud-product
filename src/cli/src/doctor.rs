/// 系统诊断：检查外部命令和工具链状态。
///
/// qtcloud-product 的产物是 Rust CLI 与 Flutter Studio，
/// 因此除 git/gh 外，重点检测 rust、dart/flutter 工具链。
/// 属于 CLI 上层编排，不依赖 source / platform 的实现细节。
use std::io::Write;
use std::path::Path;
use std::process::Command;

/// 向 stdout 输出系统诊断信息。
pub fn status(repo_path: &Path) {
    let mut stdout = std::io::stdout();
    let _ = status_to(&mut stdout, repo_path);
}

/// 将系统诊断信息写入指定的 writer。
pub fn status_to(writer: &mut impl Write, repo_path: &Path) -> std::io::Result<()> {
    let used_langs = detect_used_languages(repo_path);
    let mut o = build_tool_status_header();
    o.push_str(&build_language_sections(&used_langs));
    write!(writer, "{}", o)
}

fn detect_used_languages(repo_path: &Path) -> Vec<String> {
    // 检查仓库根及其常见子应用目录（src/cli = Rust CLI，src/studio = Flutter Studio）
    let mut roots: Vec<std::path::PathBuf> = vec![repo_path.to_path_buf()];
    for sub in ["src/cli", "src/studio"] {
        let p = repo_path.join(sub);
        if p.is_dir() {
            roots.push(p);
        }
    }
    let mut used_langs: Vec<String> = Vec::new();
    for root in roots {
        if root.join("Cargo.toml").is_file() && !used_langs.contains(&"rust".to_string()) {
            used_langs.push("rust".to_string());
        }
        if (root.join("pubspec.yaml").is_file() || root.join("pubspec.yml").is_file())
            && !used_langs.contains(&"dart".to_string())
        {
            used_langs.push("dart".to_string());
        }
        if root.join("package.json").is_file() && !used_langs.contains(&"typescript".to_string()) {
            used_langs.push("typescript".to_string());
        }
        if (root.join("pyproject.toml").is_file() || root.join("setup.py").is_file())
            && !used_langs.contains(&"python".to_string())
        {
            used_langs.push("python".to_string());
        }
        if root.join("go.mod").is_file() && !used_langs.contains(&"go".to_string()) {
            used_langs.push("go".to_string());
        }
    }
    used_langs
}

fn build_tool_status_header() -> String {
    let mut o = format!("系统诊断\n{}\n", "-".repeat(50));
    o.push_str(&format!(
        "  {:<12} {}\n",
        "git",
        check_command("git", &["--version"])
    ));
    let gh_ver = check_command("gh", &["--version"]);
    o.push_str(&format!("  {:<12} {}\n", "gh", gh_ver));
    if gh_ver.starts_with("✅") {
        o.push_str(&format!(
            "    {:<10} {}\n",
            "auth",
            check_command("gh", &["auth", "status"])
        ));
    }
    o
}

fn build_language_sections(used_langs: &[String]) -> String {
    let mut o = String::new();
    for lang in &["rust", "python", "go", "dart", "typescript"] {
        if !used_langs.iter().any(|l| l == lang) {
            continue;
        }
        o.push_str(&match *lang {
            "rust" => format!(
                "  {:<12} {}\n  {:<12} {}\n",
                "cargo",
                check_command("cargo", &["--version"]),
                "rustc",
                check_command("rustc", &["--version"]),
            ),
            "python" => {
                let mut s = format!(
                    "  {:<12} {}\n",
                    "python",
                    check_command("python", &["--version"])
                );
                for sub in &["uv", "pytest", "coverage"] {
                    s.push_str(&format!(
                        "    {:<10} {}\n",
                        sub,
                        check_command(sub, &["--version"])
                    ));
                }
                s
            }
            "go" => format!("  {:<12} {}\n", "go", check_command("go", &["version"])),
            "dart" => format!(
                "  {:<12} {}\n    {:<10} {}\n",
                "flutter",
                check_command("flutter", &["--version"]),
                "dart",
                check_command("dart", &["--version"]),
            ),
            "typescript" => {
                let mut s = format!(
                    "  {:<12} {}\n",
                    "node",
                    check_command("node", &["--version"])
                );
                for sub in &["npm", "npx"] {
                    s.push_str(&format!(
                        "    {:<10} {}\n",
                        sub,
                        check_command(sub, &["--version"])
                    ));
                }
                s
            }
            _ => String::new(),
        });
    }
    o
}

fn check_command(cmd: &str, args: &[&str]) -> String {
    match Command::new(cmd).args(args).output() {
        Ok(out) if out.status.success() => {
            let ver = String::from_utf8_lossy(&out.stdout)
                .lines()
                .next()
                .unwrap_or("")
                .trim()
                .to_string();
            format!("✅ {}", ver)
        }
        Ok(out) => {
            let msg = String::from_utf8_lossy(&out.stderr).trim().to_string();
            format!("❌ {}", msg)
        }
        Err(e) => match e.kind() {
            std::io::ErrorKind::NotFound => "❌ 未安装".to_string(),
            _ => format!("❌ {}", e),
        },
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_check_git_exists() {
        let result = check_command("git", &["--version"]);
        assert!(result.starts_with("✅"), "git 应存在: {}", result);
    }

    #[test]
    fn test_check_nonexistent() {
        let result = check_command("nonexistent_cmd_xyz", &["--version"]);
        assert!(
            result.contains("未安装"),
            "不存在的命令应报未安装: {}",
            result
        );
    }

    #[test]
    fn test_status_to_rust() {
        let d = tempfile::tempdir().unwrap();
        std::fs::write(d.path().join("Cargo.toml"), "[package]\n").unwrap();
        let mut buf = Vec::new();
        status_to(&mut buf, d.path()).unwrap();
        let output = String::from_utf8(buf).expect("非 UTF-8 输出");
        assert!(output.contains("git"), "应包含 git");
        assert!(output.contains("cargo"), "Rust 项目应显示 cargo");
        assert!(output.contains("rustc"), "Rust 项目应显示 rustc");
    }

    #[test]
    fn test_status_to_dart() {
        let d = tempfile::tempdir().unwrap();
        std::fs::write(d.path().join("pubspec.yaml"), "name: test\n").unwrap();
        let mut buf = Vec::new();
        status_to(&mut buf, d.path()).unwrap();
        let output = String::from_utf8(buf).expect("非 UTF-8 输出");
        assert!(output.contains("flutter"), "Dart 项目应显示 flutter 工具链");
    }

    #[test]
    fn test_status_to_no_lang() {
        let d = tempfile::tempdir().unwrap();
        let mut buf = Vec::new();
        status_to(&mut buf, d.path()).unwrap();
        let output = String::from_utf8(buf).expect("非 UTF-8 输出");
        assert!(output.contains("git"), "应始终显示 git");
        assert!(output.contains("gh"), "应始终显示 gh");
    }

    #[test]
    fn test_status_to_output() {
        let d = tempfile::tempdir().unwrap();
        std::fs::write(d.path().join("Cargo.toml"), "[package]\n").unwrap();
        let mut buf = Vec::new();
        status_to(&mut buf, d.path()).unwrap();
        let output = String::from_utf8(buf).expect("非 UTF-8 输出");
        assert!(output.contains("系统诊断"), "应包含标题");
        assert!(output.contains(&"-".repeat(50)), "应包含分隔线");
    }
}
