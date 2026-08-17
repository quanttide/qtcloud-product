package storage

import (
	"context"
	"os"
	"path/filepath"
	"testing"
)

func TestLocalStoreGetList(t *testing.T) {
	dir := t.TempDir()
	// 布局对齐种子数据：manifest.json + products/<id>.json
	if err := os.MkdirAll(filepath.Join(dir, "products"), 0o755); err != nil {
		t.Fatal(err)
	}
	manifest := `{"products": ["qtcloud-devops"]}`
	product := `{"id": "qtcloud-devops", "name": "qtcloud-devops"}`
	if err := os.WriteFile(filepath.Join(dir, "manifest.json"), []byte(manifest), 0o644); err != nil {
		t.Fatal(err)
	}
	if err := os.WriteFile(filepath.Join(dir, "products", "qtcloud-devops.json"), []byte(product), 0o644); err != nil {
		t.Fatal(err)
	}

	s, err := NewLocalStore(dir)
	if err != nil {
		t.Fatalf("创建本地存储失败: %v", err)
	}
	ctx := context.Background()

	got, err := s.Get(ctx, "manifest.json")
	if err != nil {
		t.Fatalf("Get manifest 失败: %v", err)
	}
	if string(got) != manifest {
		t.Errorf("manifest 内容不符: %s", got)
	}

	got, err = s.Get(ctx, "products/qtcloud-devops.json")
	if err != nil {
		t.Fatalf("Get product 失败: %v", err)
	}
	if string(got) != product {
		t.Errorf("product 内容不符: %s", got)
	}

	metas, err := s.List(ctx, "products/")
	if err != nil {
		t.Fatalf("List 失败: %v", err)
	}
	if len(metas) != 1 || metas[0].Key != "products/qtcloud-devops.json" {
		t.Errorf("List 结果不符: %+v", metas)
	}
	if metas[0].Size != int64(len(product)) {
		t.Errorf("Size 不符: %d", metas[0].Size)
	}

	if _, err := s.Get(ctx, "products/not-exist.json"); err != ErrNotFound {
		t.Errorf("不存在对象应返回 ErrNotFound，实际: %v", err)
	}
}

func TestLocalStoreRejectsTraversal(t *testing.T) {
	s, err := NewLocalStore(t.TempDir())
	if err != nil {
		t.Fatal(err)
	}
	ctx := context.Background()
	for _, key := range []string{"../secret.txt", "/etc/passwd", "products/../../x.json", ""} {
		if _, err := s.Get(ctx, key); err == nil {
			t.Errorf("非法键 %q 应被拒绝", key)
		}
	}
}

func TestLocalStoreBadDir(t *testing.T) {
	if _, err := NewLocalStore(filepath.Join(t.TempDir(), "not-exist")); err == nil {
		t.Error("不存在的目录应报错")
	}
}
