// Package handler 实现产品数据的只读 REST 处理器。
//
// 端点（docs/index.md「API 设计」）：
//
//	GET /health            健康检查（探活用，免鉴权）
//	GET /manifest          产品清单（对齐 assets/data/manifest.json）
//	GET /products          全部产品完整文档（批量加载）
//	GET /products/{name}   单个产品完整文档（与种子数据 JSON 同构，Studio 直接解析）
//
// 数据由 CLI 加工写入存储（见仓库根 AGENTS.md），本服务只读代理；
// 当前数据为公开演示数据，不做鉴权——若开放编辑/私有数据，引入
// qtcloud-auth JWT 验签（结构对齐 qtcloud-secret provider 的 auth 包）。
package handler

import (
	"encoding/json"
	"fmt"
	"log"
	"net/http"

	"github.com/quanttide/quanttide-product/provider/internal/model"
	"github.com/quanttide/quanttide-product/provider/internal/storage"
)

const (
	manifestKey = "manifest.json"
	productsDir = "products/"
	objectKey   = "name" // URL 路径参数名
)

// Handler 聚合依赖的 REST 处理器。
type Handler struct {
	store          storage.Store
	allowedOrigins []string
}

// New 创建处理器。
func New(store storage.Store, allowedOrigins []string) *Handler {
	return &Handler{store: store, allowedOrigins: allowedOrigins}
}

// Routes 注册路由（Go 1.22+ 方法路由）。数据只读公开，无需鉴权；
// CORS 中间件在最外层：OPTIONS 预检直接放行。
func (h *Handler) Routes() http.Handler {
	mux := http.NewServeMux()
	mux.HandleFunc("GET /health", func(w http.ResponseWriter, _ *http.Request) {
		w.WriteHeader(http.StatusOK)
	})
	mux.HandleFunc("GET /manifest", h.manifest)
	mux.HandleFunc("GET /products", h.list)
	mux.HandleFunc("GET /products/{name}", h.get)
	return corsMiddleware(h.allowedOrigins, mux)
}

// manifest GET /manifest：返回产品清单（products: [唯一命名...]），
// Studio 先读清单再逐个加载产品。
func (h *Handler) manifest(w http.ResponseWriter, r *http.Request) {
	data, err := h.store.Get(r.Context(), manifestKey)
	if err != nil {
		h.audit(r, "manifest", "", "失败: "+err.Error())
		writeStoreError(w, err)
		return
	}
	var m model.Manifest
	if err := json.Unmarshal(data, &m); err != nil {
		h.audit(r, "manifest", "", "清单解析失败: "+err.Error())
		http.Error(w, "清单数据损坏", http.StatusInternalServerError)
		return
	}
	if err := m.Validate(); err != nil {
		h.audit(r, "manifest", "", "清单校验失败: "+err.Error())
		http.Error(w, "清单数据非法: "+err.Error(), http.StatusInternalServerError)
		return
	}
	h.audit(r, "manifest", "", "成功")
	writeJSON(w, http.StatusOK, m)
}

// list GET /products：按清单顺序返回全部产品完整文档。
func (h *Handler) list(w http.ResponseWriter, r *http.Request) {
	names, ok := h.loadManifest(w, r)
	if !ok {
		return
	}
	products := make([]model.Product, 0, len(names))
	for _, name := range names {
		p, err := h.loadProduct(r, name)
		if err != nil {
			if err == storage.ErrNotFound {
				h.audit(r, "list", name, "清单与产品文件不一致: 对象不存在")
				http.Error(w, fmt.Sprintf("产品 %q 数据缺失", name), http.StatusInternalServerError)
				return
			}
			h.audit(r, "list", name, "失败: "+err.Error())
			http.Error(w, fmt.Sprintf("产品 %q 数据损坏", name), http.StatusInternalServerError)
			return
		}
		products = append(products, *p)
	}
	h.audit(r, "list", "", fmt.Sprintf("成功 产品数=%d", len(products)))
	writeJSON(w, http.StatusOK, products)
}

// get GET /products/{name}：返回单个产品完整文档。
func (h *Handler) get(w http.ResponseWriter, r *http.Request) {
	name := r.PathValue(objectKey)
	p, err := h.loadProduct(r, name)
	if err != nil {
		h.audit(r, "get", name, "失败: "+err.Error())
		if err == storage.ErrNotFound {
			http.Error(w, "产品不存在", http.StatusNotFound)
		} else {
			http.Error(w, "读取失败", http.StatusInternalServerError)
		}
		return
	}
	h.audit(r, "get", name, "成功")
	writeJSON(w, http.StatusOK, p)
}

// ── 辅助 ─────────────────────────────────────────────

// loadManifest 读取并校验清单；失败时已写响应，返回 ok=false。
func (h *Handler) loadManifest(w http.ResponseWriter, r *http.Request) ([]string, bool) {
	data, err := h.store.Get(r.Context(), manifestKey)
	if err != nil {
		h.audit(r, "manifest", "", "失败: "+err.Error())
		writeStoreError(w, err)
		return nil, false
	}
	var m model.Manifest
	if err := json.Unmarshal(data, &m); err != nil {
		h.audit(r, "manifest", "", "清单解析失败: "+err.Error())
		http.Error(w, "清单数据损坏", http.StatusInternalServerError)
		return nil, false
	}
	if err := m.Validate(); err != nil {
		h.audit(r, "manifest", "", "清单校验失败: "+err.Error())
		http.Error(w, "清单数据非法: "+err.Error(), http.StatusInternalServerError)
		return nil, false
	}
	return m.Products, true
}

// loadProduct 读取并整树校验产品文档（响应前拒绝结构错乱的数据）。
func (h *Handler) loadProduct(r *http.Request, name string) (*model.Product, error) {
	data, err := h.store.Get(r.Context(), productsDir+name+".json")
	if err != nil {
		return nil, err
	}
	p, err := model.ParseProduct(data)
	if err != nil {
		return nil, fmt.Errorf("产品数据校验失败: %w", err)
	}
	return p, nil
}

// writeStoreError 按存储错误类型写响应。
func writeStoreError(w http.ResponseWriter, err error) {
	if err == storage.ErrNotFound {
		http.Error(w, "数据不存在", http.StatusNotFound)
		return
	}
	http.Error(w, "存储异常", http.StatusInternalServerError)
}

// audit 审计日志（当前阶段：标准日志输出；团队版/合规要求时落独立审计存储）。
func (h *Handler) audit(r *http.Request, action, id, result string) {
	log.Printf("audit method=%s action=%s id=%s result=%s remote=%s", r.Method, action, id, result, r.RemoteAddr)
}

func writeJSON(w http.ResponseWriter, status int, v any) {
	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(status)
	_ = json.NewEncoder(w).Encode(v)
}
