use std::process::Command;

fn cli() -> Command {
    Command::new(env!("CARGO_BIN_EXE_qtcloud-product"))
}

#[test]
fn test_cli_help_succeeds() {
    let output = cli().arg("--help").output().unwrap();
    assert!(output.status.success());
    let stdout = String::from_utf8_lossy(&output.stdout);
    assert!(stdout.contains("requirement"));
    assert!(stdout.contains("story"));
    assert!(stdout.contains("release"));
}

#[test]
fn test_cli_version_output() {
    let output = cli().arg("--version").output().unwrap();
    assert!(output.status.success());
}

#[test]
fn test_cli_help_command() {
    let output = cli().arg("help").output().unwrap();
    assert!(output.status.success());
    assert!(String::from_utf8_lossy(&output.stdout).contains("以用户故事为中心梳理需求"));
}

#[test]
fn test_cli_requirement_help() {
    let output = cli().args(["requirement", "--help"]).output().unwrap();
    assert!(output.status.success());
    let stdout = String::from_utf8_lossy(&output.stdout);
    assert!(stdout.contains("list"));
    assert!(stdout.contains("add"));
    assert!(stdout.contains("edit"));
}

#[test]
fn test_cli_story_help() {
    let output = cli().args(["story", "--help"]).output().unwrap();
    assert!(output.status.success());
    let stdout = String::from_utf8_lossy(&output.stdout);
    assert!(stdout.contains("export"));
    assert!(stdout.contains("map"));
}

#[test]
fn test_cli_release_help() {
    let output = cli().args(["release", "--help"]).output().unwrap();
    assert!(output.status.success());
    let stdout = String::from_utf8_lossy(&output.stdout);
    assert!(stdout.contains("publish"));
    assert!(stdout.contains("audit"));
}

#[test]
fn test_cli_unknown_command_fails() {
    let output = cli().arg("nonexistent-command").output().unwrap();
    assert!(!output.status.success());
}

#[test]
fn test_cli_requirement_add_edit_show_remove() {
    let d = tempfile::tempdir().unwrap();
    let root = d.path().join("docs/dev-guide/prd/stories/stories");
    std::fs::create_dir_all(root.join("user_story")).unwrap();
    std::fs::write(
        root.join("user_story/README.md"),
        "# 管理用户故事\n\n此用户活动的用户任务为：\n\n1. 细化用户故事\n",
    )
    .unwrap();

    // add
    let output = cli()
        .current_dir(d.path())
        .args(["requirement", "add", "--title", "Edit User Story", "--status", "done"])
        .output()
        .unwrap();
    assert!(output.status.success(), "add 应成功: {}", String::from_utf8_lossy(&output.stderr));
    let story_path = root.join("user_story/edit-user-story.md");
    assert!(story_path.is_file(), "故事文档应创建");

    // show
    let output = cli()
        .current_dir(d.path())
        .args(["requirement", "show", "edit-user-story"])
        .output()
        .unwrap();
    assert!(output.status.success());
    assert!(String::from_utf8_lossy(&output.stdout).contains("Edit User Story"));

    // edit
    let output = cli()
        .current_dir(d.path())
        .args(["requirement", "edit", "edit-user-story", "--phase", "future"])
        .output()
        .unwrap();
    assert!(output.status.success(), "edit 应成功: {}", String::from_utf8_lossy(&output.stderr));

    // remove
    let output = cli()
        .current_dir(d.path())
        .args(["requirement", "remove", "edit-user-story"])
        .output()
        .unwrap();
    assert!(output.status.success());
    assert!(!story_path.exists(), "故事文档应删除");
}

#[test]
fn test_cli_story_export_writes_manifest() {
    let d = tempfile::tempdir().unwrap();
    let root = d.path().join("docs/dev-guide/prd/stories/stories");
    std::fs::create_dir_all(root.join("user_story")).unwrap();
    std::fs::write(
        root.join("user_story/README.md"),
        "# 管理用户故事\n\n此用户活动的用户任务为：\n\n1. 细化用户故事\n",
    )
    .unwrap();
    std::fs::write(root.join("user_story/story-a.md"), "# 故事 A\n").unwrap();
    std::fs::create_dir_all(d.path().join("assets/data/products")).unwrap();
    std::fs::write(
        d.path().join("assets/data/manifest.json"),
        "{\"products\":[\"qtcloud-devops\"]}\n",
    )
    .unwrap();

    let output = cli()
        .current_dir(d.path())
        .args(["story", "export", "--title", "量潮产品云"])
        .output()
        .unwrap();
    assert!(output.status.success(), "export 应成功: {}", String::from_utf8_lossy(&output.stderr));
    let product_path = d.path().join("assets/data/products/qtcloud-product.json");
    assert!(product_path.is_file(), "产品文件应写入");
    let manifest = std::fs::read_to_string(d.path().join("assets/data/manifest.json")).unwrap();
    assert!(manifest.contains("qtcloud-product"), "manifest 应包含本产品");
    assert!(manifest.contains("qtcloud-devops"), "manifest 应保留其他产品");
}

#[test]
fn test_cli_release_audit_fails_on_bad_version() {
    let d = tempfile::tempdir().unwrap();
    let output = cli()
        .current_dir(d.path())
        .args(["release", "audit", "-v", "not-a-version"])
        .output()
        .unwrap();
    assert!(!output.status.success(), "非法版本应失败");
}

#[test]
fn test_cli_requirement_status_in_empty_repo() {
    let d = tempfile::tempdir().unwrap();
    let output = cli()
        .current_dir(d.path())
        .args(["requirement", "status"])
        .output()
        .unwrap();
    assert!(!output.status.success(), "缺少用户故事目录应失败");
}
