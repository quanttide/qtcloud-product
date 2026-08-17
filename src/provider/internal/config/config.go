// Package config 从环境变量加载服务端配置。
//
// 环境变量约定（与 qtcloud-secret provider 对齐）：
//
//	DATA_DIR            本地数据目录（开发/测试用；设置后使用本地文件系统存储，
//	                    指向仓库根 assets/data 即可离线运行）
//	OSS_BUCKET          OSS 数据桶名（生产；存放 manifest.json 与 products/<id>.json）
//	OSS_ENDPOINT        OSS endpoint（如 https://oss-cn-hangzhou.aliyuncs.com）
//	ENV                 环境（prod/dev；生产拒绝 fallback 默认值）
//	CORS_ALLOWED_ORIGINS 浏览器跨源白名单（逗号分隔；默认本产品 Web 站点）
//	PORT                监听端口（默认 8080，FC custom-container 约定）
package config

import (
	"fmt"
	"os"
	"strings"
)

// Config 服务端运行配置。
type Config struct {
	Env               string
	DataDir           string // 非空 → 本地文件系统存储（开发/测试）
	OSSBucket         string // 生产 → OSS 存储
	OSSEndpoint       string
	CORSAllowedOrigin []string
	Port              string
}

// Load 从环境变量加载配置并校验必填项。
func Load() (*Config, error) {
	env := os.Getenv("ENV")
	if env == "" {
		env = "dev"
	}

	cfg := &Config{
		Env:         env,
		DataDir:     os.Getenv("DATA_DIR"),
		OSSBucket:   os.Getenv("OSS_BUCKET"),
		OSSEndpoint: os.Getenv("OSS_ENDPOINT"),
		Port:        os.Getenv("PORT"),
	}
	if cfg.Port == "" {
		cfg.Port = "8080"
	}

	// 存储后端选择：DATA_DIR（本地文件系统，开发/测试）或 OSS（生产）。
	// 生产环境必须显式配置 OSS，拒绝回落本地目录（防止误用开发存储）。
	if cfg.DataDir == "" {
		if cfg.OSSBucket == "" {
			return nil, fmt.Errorf("存储未配置：请设置 DATA_DIR（本地开发）或 OSS_BUCKET/OSS_ENDPOINT（生产）")
		}
		if cfg.OSSEndpoint == "" {
			return nil, fmt.Errorf("环境变量 OSS_ENDPOINT 未设置")
		}
	} else if cfg.Env == "prod" {
		return nil, fmt.Errorf("生产环境必须配置 OSS_BUCKET/OSS_ENDPOINT（拒绝 DATA_DIR 本地存储）")
	}

	// 浏览器跨源白名单（Web 客户端站点）；未配置时默认本产品 Web 域名
	origins := os.Getenv("CORS_ALLOWED_ORIGINS")
	if origins == "" {
		origins = "https://product.cloud.quanttide.com,http://product.cloud.quanttide.com"
	}
	for _, o := range strings.Split(origins, ",") {
		if o = strings.TrimSpace(o); o != "" {
			cfg.CORSAllowedOrigin = append(cfg.CORSAllowedOrigin, o)
		}
	}

	return cfg, nil
}
