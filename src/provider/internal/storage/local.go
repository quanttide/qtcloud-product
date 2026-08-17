// Package storage 本地文件系统实现（开发/测试用）。
//
// DATA_DIR 指向仓库根 assets/data/ 即可离线运行：manifest.json 与
// products/<id>.json 一一映射为目录下的文件，键与种子数据布局完全一致。
package storage

import (
	"context"
	"fmt"
	"io/fs"
	"os"
	"path/filepath"
	"strings"
)

// LocalStore 基于本地目录的 Store 实现。
type LocalStore struct {
	dir string
}

// NewLocalStore 创建本地存储（dir 为数据目录，如 assets/data）。
func NewLocalStore(dir string) (*LocalStore, error) {
	info, err := os.Stat(dir)
	if err != nil {
		return nil, fmt.Errorf("数据目录不可用: %w", err)
	}
	if !info.IsDir() {
		return nil, fmt.Errorf("数据目录 %q 不是目录", dir)
	}
	return &LocalStore{dir: dir}, nil
}

// resolve 键 → 文件路径；拒绝路径穿越（键仅允许相对路径）。
func (s *LocalStore) resolve(key string) (string, error) {
	if key == "" || strings.HasPrefix(key, "/") || strings.Contains(key, "..") {
		return "", fmt.Errorf("非法对象键: %q", key)
	}
	return filepath.Join(s.dir, filepath.FromSlash(key)), nil
}

// Get 读取对象。
func (s *LocalStore) Get(ctx context.Context, key string) ([]byte, error) {
	if err := ctx.Err(); err != nil {
		return nil, err
	}
	path, err := s.resolve(key)
	if err != nil {
		return nil, err
	}
	data, err := os.ReadFile(path)
	if err != nil {
		if os.IsNotExist(err) {
			return nil, ErrNotFound
		}
		return nil, fmt.Errorf("读取对象失败: %w", err)
	}
	return data, nil
}

// List 列出前缀下全部对象摘要。
func (s *LocalStore) List(ctx context.Context, prefix string) ([]ObjectMeta, error) {
	if err := ctx.Err(); err != nil {
		return nil, err
	}
	root, err := s.resolve(prefix)
	if err != nil {
		return nil, err
	}
	var metas []ObjectMeta
	err = filepath.WalkDir(root, func(path string, d fs.DirEntry, err error) error {
		if err != nil {
			return err
		}
		if d.IsDir() {
			return nil
		}
		rel, err := filepath.Rel(s.dir, path)
		if err != nil {
			return err
		}
		info, err := d.Info()
		if err != nil {
			return err
		}
		metas = append(metas, ObjectMeta{
			Key:       filepath.ToSlash(rel),
			Size:      info.Size(),
			UpdatedAt: info.ModTime(),
		})
		return nil
	})
	if err != nil {
		if os.IsNotExist(err) {
			return nil, ErrNotFound
		}
		return nil, fmt.Errorf("列出对象失败: %w", err)
	}
	return metas, nil
}
