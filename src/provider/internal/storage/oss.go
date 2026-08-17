package storage

import (
	"context"
	"fmt"
	"io"
	"os"
	"strings"

	"github.com/aliyun/aliyun-oss-go-sdk/oss"
)

// OSSStore 基于阿里云 OSS 的 Store 实现（生产）。
//
// 凭证来源（见 qtcloud-secret provider）：本地开发用 OSS_ACCESS_KEY_*，
// FC 3.0 运行时用函数角色注入的 ALIBABA_CLOUD_*（STS 临时凭证）。
type OSSStore struct {
	bucket *oss.Bucket
}

// NewOSSStore 创建 OSS 存储客户端。
func NewOSSStore(bucketName, endpoint string) (*OSSStore, error) {
	ak := firstEnv("OSS_ACCESS_KEY_ID", "ALIBABA_CLOUD_ACCESS_KEY_ID")
	sk := firstEnv("OSS_ACCESS_KEY_SECRET", "ALIBABA_CLOUD_ACCESS_KEY_SECRET")
	token := os.Getenv("ALIBABA_CLOUD_SECURITY_TOKEN")

	var client *oss.Client
	var err error
	if token != "" {
		client, err = oss.New(endpoint, ak, sk, oss.SecurityToken(token))
	} else {
		client, err = oss.New(endpoint, ak, sk)
	}
	if err != nil {
		return nil, fmt.Errorf("创建 OSS 客户端失败: %w", err)
	}
	bucket, err := client.Bucket(bucketName)
	if err != nil {
		return nil, fmt.Errorf("获取 OSS 桶失败: %w", err)
	}
	return &OSSStore{bucket: bucket}, nil
}

// firstEnv 返回第一个非空环境变量的值。
func firstEnv(keys ...string) string {
	for _, k := range keys {
		if v := os.Getenv(k); v != "" {
			return v
		}
	}
	return ""
}

// key 规整：拒绝绝对路径与路径穿越，键保持种子数据相对布局。
func keyOf(key string) (string, error) {
	if key == "" || strings.HasPrefix(key, "/") || strings.Contains(key, "..") {
		return "", fmt.Errorf("非法对象键: %q", key)
	}
	return key, nil
}

func (s *OSSStore) Get(ctx context.Context, key string) ([]byte, error) {
	if err := ctx.Err(); err != nil {
		return nil, err
	}
	k, err := keyOf(key)
	if err != nil {
		return nil, err
	}
	body, err := s.bucket.GetObject(k)
	if err != nil {
		if isNotFound(err) {
			return nil, ErrNotFound
		}
		return nil, fmt.Errorf("读取对象失败: %w", err)
	}
	defer body.Close()
	return io.ReadAll(body)
}

func (s *OSSStore) List(ctx context.Context, prefix string) ([]ObjectMeta, error) {
	if err := ctx.Err(); err != nil {
		return nil, err
	}
	var metas []ObjectMeta
	marker := ""
	for {
		resp, err := s.bucket.ListObjects(oss.Prefix(prefix), oss.Marker(marker), oss.MaxKeys(1000))
		if err != nil {
			return nil, fmt.Errorf("列出对象失败: %w", err)
		}
		for _, obj := range resp.Objects {
			metas = append(metas, ObjectMeta{
				Key:       obj.Key,
				Size:      obj.Size,
				UpdatedAt: obj.LastModified,
			})
		}
		if !resp.IsTruncated {
			break
		}
		marker = resp.NextMarker
	}
	return metas, nil
}

func isNotFound(err error) bool {
	if ossErr, ok := err.(oss.ServiceError); ok {
		return ossErr.StatusCode == 404
	}
	return false
}
