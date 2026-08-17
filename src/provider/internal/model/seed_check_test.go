package model

import (
	"os"
	"path/filepath"
	"testing"
)

// findSeedDir 从当前包目录向上查找仓库根 assets/data（种子数据契约的落点）。
func findSeedDir(t *testing.T) string {
	t.Helper()
	dir, err := os.Getwd()
	if err != nil {
		t.Fatal(err)
	}
	for {
		candidate := filepath.Join(dir, "assets", "data")
		if info, err := os.Stat(filepath.Join(candidate, "manifest.json")); err == nil && !info.IsDir() {
			return candidate
		}
		parent := filepath.Dir(dir)
		if parent == dir {
			return ""
		}
		dir = parent
	}
}

// TestRealSeedData 集成校验：provider 模型必须能解析仓库根的真实种子数据
// （CLI 加工 → assets/data/，Studio 渲染 ← 本模型校验，三方契约一致）。
func TestRealSeedData(t *testing.T) {
	seedDir := findSeedDir(t)
	if seedDir == "" {
		t.Skip("未找到 assets/data 种子数据目录，跳过集成校验")
	}
	entries, err := os.ReadDir(filepath.Join(seedDir, "products"))
	if err != nil {
		t.Fatal(err)
	}
	if len(entries) == 0 {
		t.Fatal("种子数据 products/ 为空")
	}
	for _, e := range entries {
		data, err := os.ReadFile(filepath.Join(seedDir, "products", e.Name()))
		if err != nil {
			t.Errorf("%s 读取失败: %v", e.Name(), err)
			continue
		}
		if _, err := ParseProduct(data); err != nil {
			t.Errorf("%s 校验失败: %v", e.Name(), err)
		}
	}
}
