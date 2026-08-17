package handler

import (
	"encoding/json"
	"net/http"
	"net/http/httptest"
	"os"
	"path/filepath"
	"strings"
	"testing"

	"github.com/quanttide/quanttide-product/provider/internal/storage"
)

// setupTestServer 构造临时数据目录 + 处理器（对齐种子数据布局）。
func setupTestServer(t *testing.T) *httptest.Server {
	t.Helper()
	dir := t.TempDir()
	if err := os.MkdirAll(filepath.Join(dir, "products"), 0o755); err != nil {
		t.Fatal(err)
	}
	manifest := `{"products": ["qtcloud-devops", "qtcloud-product"]}`
	devops := `{
  "id": "qtcloud-devops",
  "name": "qtcloud-devops",
  "title": "量潮DevOps云",
  "tagline": "把发布规范封装成 CLI",
  "designIdea": "八步流程驱动价值流动",
  "storyMap": {
    "id": "map-qtcloud-devops",
    "name": "qtcloud-devops",
    "mvpLinePosition": 0.5,
    "activities": [
      {
        "id": "lifecycle",
        "title": "阶段/生命周期管理",
        "order": 0,
        "tasks": [
          {
            "id": "lifecycle-task-1",
            "title": "plan 计划",
            "activityId": "lifecycle",
            "order": 0,
            "stories": [
              {
                "id": "lifecycle-plan-1",
                "title": "查看迭代计划与待办",
                "taskId": "lifecycle-task-1",
                "phase": "mvp",
                "status": "done",
                "description": "ROADMAP / BUGS / TODO"
              }
            ]
          }
        ]
      }
    ]
  }
}`
	for name, body := range map[string]string{
		"manifest.json":                 manifest,
		"products/qtcloud-devops.json":  devops,
		"products/qtcloud-product.json": `{"id": "qtcloud-product", "name": "qtcloud-product", "title": "量潮产品云", "tagline": "", "designIdea": "", "storyMap": {"id": "map-qtcloud-product", "name": "qtcloud-product", "mvpLinePosition": 0.33, "activities": []}}`,
	} {
		if err := os.WriteFile(filepath.Join(dir, name), []byte(body), 0o644); err != nil {
			t.Fatal(err)
		}
	}

	store, err := storage.NewLocalStore(dir)
	if err != nil {
		t.Fatal(err)
	}
	h := New(store, []string{"https://product.cloud.quanttide.com"})
	ts := httptest.NewServer(h.Routes())
	t.Cleanup(ts.Close)
	return ts
}

func get(t *testing.T, url string) (*http.Response, string) {
	t.Helper()
	resp, err := http.Get(url)
	if err != nil {
		t.Fatalf("GET %s 失败: %v", url, err)
	}
	defer resp.Body.Close()
	var sb strings.Builder
	buf := make([]byte, 4096)
	for {
		n, err := resp.Body.Read(buf)
		sb.Write(buf[:n])
		if err != nil {
			break
		}
	}
	return resp, sb.String()
}

func TestHealth(t *testing.T) {
	ts := setupTestServer(t)
	resp, _ := get(t, ts.URL+"/health")
	if resp.StatusCode != http.StatusOK {
		t.Errorf("health 应返回 200，实际 %d", resp.StatusCode)
	}
}

func TestManifest(t *testing.T) {
	ts := setupTestServer(t)
	resp, body := get(t, ts.URL+"/manifest")
	if resp.StatusCode != http.StatusOK {
		t.Fatalf("manifest 应返回 200，实际 %d: %s", resp.StatusCode, body)
	}
	var m struct {
		Products []string `json:"products"`
	}
	if err := json.Unmarshal([]byte(body), &m); err != nil {
		t.Fatalf("manifest 响应非法 JSON: %v", err)
	}
	if len(m.Products) != 2 || m.Products[0] != "qtcloud-devops" || m.Products[1] != "qtcloud-product" {
		t.Errorf("manifest 内容不符: %+v", m.Products)
	}
}

func TestListProducts(t *testing.T) {
	ts := setupTestServer(t)
	resp, body := get(t, ts.URL+"/products")
	if resp.StatusCode != http.StatusOK {
		t.Fatalf("products 应返回 200，实际 %d: %s", resp.StatusCode, body)
	}
	var products []map[string]any
	if err := json.Unmarshal([]byte(body), &products); err != nil {
		t.Fatalf("products 响应非法 JSON: %v", err)
	}
	if len(products) != 2 {
		t.Fatalf("products 数量不符: %d", len(products))
	}
	if products[0]["name"] != "qtcloud-devops" {
		t.Errorf("首个产品不符: %v", products[0]["name"])
	}
	sm := products[0]["storyMap"].(map[string]any)
	if sm["mvpLinePosition"] != 0.5 {
		t.Errorf("storyMap 输出不符: %v", sm["mvpLinePosition"])
	}
}

func TestGetProduct(t *testing.T) {
	ts := setupTestServer(t)
	resp, body := get(t, ts.URL+"/products/qtcloud-devops")
	if resp.StatusCode != http.StatusOK {
		t.Fatalf("单产品应返回 200，实际 %d: %s", resp.StatusCode, body)
	}
	var p map[string]any
	if err := json.Unmarshal([]byte(body), &p); err != nil {
		t.Fatalf("单产品响应非法 JSON: %v", err)
	}
	if p["title"] != "量潮DevOps云" {
		t.Errorf("title 不符: %v", p["title"])
	}
	sm := p["storyMap"].(map[string]any)
	acts := sm["activities"].([]any)
	tasks := acts[0].(map[string]any)["tasks"].([]any)
	stories := tasks[0].(map[string]any)["stories"].([]any)
	story := stories[0].(map[string]any)
	if story["phase"] != "mvp" || story["status"] != "done" {
		t.Errorf("story 输出不符: %v", story)
	}
	if story["description"] != "ROADMAP / BUGS / TODO" {
		t.Errorf("description 输出不符: %v", story["description"])
	}
}

func TestGetProductNotFound(t *testing.T) {
	ts := setupTestServer(t)
	resp, _ := get(t, ts.URL+"/products/not-exist")
	if resp.StatusCode != http.StatusNotFound {
		t.Errorf("不存在产品应返回 404，实际 %d", resp.StatusCode)
	}
}

func TestCorruptedProductRejected(t *testing.T) {
	dir := t.TempDir()
	if err := os.MkdirAll(filepath.Join(dir, "products"), 0o755); err != nil {
		t.Fatal(err)
	}
	// 关系错乱的产品（story.taskId 指向不存在的任务）必须被拒绝
	corrupt := `{"id": "qtcloud-bad", "name": "qtcloud-bad", "title": "坏数据", "tagline": "", "designIdea": "", "storyMap": {"id": "m", "name": "m", "mvpLinePosition": 0.3, "activities": [{"id": "a1", "title": "活动", "order": 0, "tasks": [{"id": "t1", "title": "任务", "activityId": "a1", "order": 0, "stories": [{"id": "s1", "title": "故事", "taskId": "t2", "phase": "mvp", "status": "todo"}]}]}]}}`
	if err := os.WriteFile(filepath.Join(dir, "products", "qtcloud-bad.json"), []byte(corrupt), 0o644); err != nil {
		t.Fatal(err)
	}
	if err := os.WriteFile(filepath.Join(dir, "manifest.json"), []byte(`{"products": ["qtcloud-bad"]}`), 0o644); err != nil {
		t.Fatal(err)
	}

	store, err := storage.NewLocalStore(dir)
	if err != nil {
		t.Fatal(err)
	}
	h := New(store, nil)
	ts := httptest.NewServer(h.Routes())
	defer ts.Close()

	resp, _ := get(t, ts.URL+"/products/qtcloud-bad")
	if resp.StatusCode != http.StatusInternalServerError {
		t.Errorf("损坏产品应返回 500，实际 %d", resp.StatusCode)
	}
}

func TestCORSPreflight(t *testing.T) {
	ts := setupTestServer(t)
	req, err := http.NewRequest(http.MethodOptions, ts.URL+"/products", nil)
	if err != nil {
		t.Fatal(err)
	}
	req.Header.Set("Origin", "https://product.cloud.quanttide.com")
	resp, err := http.DefaultClient.Do(req)
	if err != nil {
		t.Fatal(err)
	}
	defer resp.Body.Close()
	if resp.StatusCode != http.StatusNoContent {
		t.Errorf("预检应返回 204，实际 %d", resp.StatusCode)
	}
	if got := resp.Header.Get("Access-Control-Allow-Origin"); got != "https://product.cloud.quanttide.com" {
		t.Errorf("Allow-Origin 应按白名单回显，实际 %q", got)
	}

	// 白名单外 origin 不回显
	req2, _ := http.NewRequest(http.MethodOptions, ts.URL+"/products", nil)
	req2.Header.Set("Origin", "https://evil.example.com")
	resp2, err := http.DefaultClient.Do(req2)
	if err != nil {
		t.Fatal(err)
	}
	defer resp2.Body.Close()
	if got := resp2.Header.Get("Access-Control-Allow-Origin"); got != "" {
		t.Errorf("白名单外 origin 不应回显，实际 %q", got)
	}
}
