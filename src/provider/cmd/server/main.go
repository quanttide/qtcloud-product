// Command server 是 qtcloud-product 的服务端（provider）。
//
// 部署形态：阿里云函数计算 FC 3.0 custom-container（监听 8080）。
// 职责（见 docs/index.md）：配置加载 → 存储后端 → 只读服务产品数据。
// 数据契约以 Studio 渲染需求为基准（src/studio/lib/models），
// 结构对齐 qtcloud-secret provider（cmd/server + internal/{config,model,storage,handler}）。
package main

import (
	"log"
	"net/http"

	"github.com/quanttide/quanttide-product/provider/internal/config"
	"github.com/quanttide/quanttide-product/provider/internal/handler"
	"github.com/quanttide/quanttide-product/provider/internal/storage"
)

func main() {
	cfg, err := config.Load()
	if err != nil {
		log.Fatalf("加载配置失败: %v", err)
	}

	// 存储后端：DATA_DIR（本地文件系统，开发/测试）或 OSS（生产）
	var store storage.Store
	if cfg.DataDir != "" {
		store, err = storage.NewLocalStore(cfg.DataDir)
		if err != nil {
			log.Fatalf("初始化本地存储失败: %v", err)
		}
	} else {
		store, err = storage.NewOSSStore(cfg.OSSBucket, cfg.OSSEndpoint)
		if err != nil {
			log.Fatalf("初始化 OSS 存储失败: %v", err)
		}
	}

	h := handler.New(store, cfg.CORSAllowedOrigin)

	srv := &http.Server{
		Addr:    ":" + cfg.Port,
		Handler: h.Routes(),
	}
	log.Printf("qtcloud-product provider 启动，监听 :%s（env=%s）", cfg.Port, cfg.Env)
	if err := srv.ListenAndServe(); err != nil {
		log.Fatalf("服务退出: %v", err)
	}
}
