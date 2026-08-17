// Package storage 定义产品数据对象存储接口与实现。
//
// 设计（docs/index.md「存储设计」）：
//   - 对象布局与 CLI 加工的种子数据完全同构：manifest.json 与 products/<id>.json
//   - 当前阶段 provider 只读服务（数据由 CLI 加工写入；写入约定见仓库根 AGENTS.md）
//   - 生产走 OSS 桶（版本控制 + SSE-OSS 静态加密）；开发/测试走本地目录
package storage

import (
	"context"
	"errors"
	"time"
)

// ErrNotFound 对象不存在。
var ErrNotFound = errors.New("对象不存在")

// ObjectMeta 对象摘要。
type ObjectMeta struct {
	Key       string // manifest.json / products/<id>.json
	Size      int64
	UpdatedAt time.Time
}

// Store 产品数据对象存储接口（只读）。
type Store interface {
	// Get 读取对象（键为存储路径，如 products/qtcloud-devops.json）。
	Get(ctx context.Context, key string) ([]byte, error)
	// List 列出前缀下全部对象摘要（manifest 全量列举用）。
	List(ctx context.Context, prefix string) ([]ObjectMeta, error)
}
