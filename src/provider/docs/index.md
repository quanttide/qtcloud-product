# 服务端设计方案（provider）

> 本文档明确 qtcloud-product 服务端（src/provider，Go 实现）的设计方案。
> 数据契约以 Studio 渲染需求为基准（src/studio/lib/models/*.dart），结构对齐 qtcloud-secret provider。

## 1. 定位与职责边界

服务端是一个**只读数据代理层**：加载存储中的种子数据 → 整树校验 → 按 Studio 数据需求输出 JSON。它不参与任何数据加工。

| 职责 | 说明 |
|------|------|
| ✅ 服务数据 | manifest 清单 + 产品完整文档（含用户故事地图），JSON 与种子数据同构 |
| ✅ 校验 | 响应前整树校验（产品名/枚举/关系一致性/规模上限），拒绝结构错乱的数据 |
| ✅ CORS | 浏览器端 Web 客户端（Studio Web）跨源访问 |
| ✅ 审计 | 每次读取记录操作者、时间、对象、结果 |
| ❌ 数据加工 | 种子数据由 CLI 加工写入（生成/校验/更新 assets/data/，见仓库根 AGENTS.md） |
| ❌ 用户管理 | 当前数据为公开演示数据，无账号体系 |

**一句话：Provider 是 Studio 的线上数据源——Studio 只负责渲染，Provider 只负责服务，CLI 只负责加工。**

## 2. 部署形态

| 项 | 选型 | 说明 |
|----|------|------|
| 运行环境 | 阿里云函数计算 FC 3.0（custom-container） | 按调用计费、无需常驻；容器监听 8080（Dockerfile 与 manifests/terraform/fc.tf 已就绪） |
| 存储 | 阿里云 OSS 单桶（`qtcloud-product-data`） | 对象布局与种子数据同构（见 §5）；版本控制 + SSE-OSS 静态加密 |
| 数据库 | **当前阶段无** | 数据为文档型种子数据，OSS 即存储 |
| 网关 | 预留 | 系统级 API 网关统一接入 `api.quanttide.com/qtcloud-product` |

本地开发/测试：`DATA_DIR` 指向仓库根 `assets/data/` 即离线运行（LocalStore），
无需 OSS 凭证；生产 `ENV=prod` 时拒绝 DATA_DIR 回落（config.go）。

部署链路（CI）：推送 `provider/*` tag → `.github/workflows/deploy-provider.yml`
（镜像构建发布 → Terraform apply → `assets/data/` 同步进数据桶）。

## 3. 数据契约（Studio 需求基准）

数据模型与 Studio 渲染模型一一对齐（src/studio/lib/models/）：

| Studio 模型 | 字段 |
|------------|------|
| `Product` | id（=name）、name（唯一命名，URL/识别场景）、title（展示标题）、tagline（一句话定位）、designIdea（设计思路）、storyMap |
| `StoryMap` | id、name、mvpLinePosition（0.0-1.0）、activities |
| `UserActivity` | id、title、order、color?、tasks |
| `UserTask` | id、title、activityId（指向所属活动）、order、stories |
| `UserStory` | id、title、taskId（指向所属任务）、phase（mvp/future）、status（todo/inProgress/done）、description? |

校验规则（internal/model/product.go）：name 为小写短横线命名（`qtcloud-devops` 式）；
id 必须与 name 一致；phase/status 为枚举；task.activityId / story.taskId 必须与父级一致
（关系错乱会让 Studio 按活动/任务分组渲染错位）；mvpLinePosition ∈ [0,1]；
单文件 ≤ 1 MB、故事 ≤ 4096 等规模上限防御异常数据。

## 4. API 设计

全部端点只读、公开（当前演示数据），无版本前缀（小服务不引入版本化复杂度）。

| 方法 | 路径 | 说明 | 成功响应 |
|------|------|------|---------|
| GET | `/manifest` | 产品清单（`{"products": ["qtcloud-devops", ...]}`），对齐 assets/data/manifest.json | 200 JSON |
| GET | `/products` | 全部产品完整文档（按清单顺序，批量加载） | 200 JSON 数组 |
| GET | `/products/{name}` | 单个产品完整文档（与种子数据 JSON 同构，Studio `Product.fromJson` 直接解析） | 200 JSON |
| GET | `/health` | 健康检查（探活） | 200 |

错误码：`404` 数据不存在 / `500` 存储异常或数据损坏。

Studio 加载流程（seed_loader.dart 的线上形态）：先 `GET /manifest` 取清单，
再逐个 `GET /products/{name}` 渲染——与本地资产加载完全同构，切换数据源无需改模型。

## 5. 存储设计

```
oss://qtcloud-product-data/       # 桶：版本控制 + SSE-OSS 静态加密
  manifest.json                   # 产品清单（与 assets/data/manifest.json 同构）
  products/<唯一命名>.json         # 每个产品一个文件（与 assets/data/products/ 同构）
```

- 对象布局与 CLI 加工的种子数据**完全一致**：部署时 CI 把 `assets/data/` 同步进桶即上线
- 服务端只读（Store 接口仅 Get/List）；写入由 CLI 负责（CI 同步，见 deploy-provider.yml）
- 本地开发：LocalStore 直接读仓库 `assets/data/`（DATA_DIR），键与 OSS 一致
- 服务端经 RAM 角色（STS 临时凭证）访问，最小权限仅本桶 `Get/List`（manifests/terraform/fc.tf）

## 6. 代码结构

```
src/provider/
├── cmd/server/main.go          # 入口：配置加载、存储后端选择、启动 HTTP
├── internal/
│   ├── config/config.go        # 环境变量配置（DATA_DIR/OSS_BUCKET/OSS_ENDPOINT/ENV/PORT/CORS）
│   ├── model/product.go        # 产品数据模型（对齐 Studio）+ 整树校验
│   ├── storage/storage.go      # Store 接口（Get/List）
│   ├── storage/oss.go          # 阿里云 OSS 实现（生产，SDK）
│   ├── storage/local.go        # 本地文件系统实现（开发/测试，直接读 assets/data）
│   └── handler/
│       ├── products.go         # REST 处理器（manifest/products）+ 审计
│       └── cors.go             # CORS 中间件（预检放行 + 白名单回显）
├── docs/index.md               # 本文档
├── Dockerfile                  # 多阶段构建，非 root，监听 8080
└── go.mod / go.sum
```

## 7. 演进预留（当前不实现）

| 未来需求 | 预留方式 |
|----------|---------|
| Studio 在线编辑/写回 | 引入 qtcloud-auth JWT 验签（对齐 qtcloud-secret auth 包）+ Store 增加 Put/Delete；当前写入走 CLI |
| 私有数据/多团队 | JWT scope 细粒度权限；数据桶按团队前缀隔离 |
| 独立审计存储 | audit() 已集中，可平滑替换输出目标 |
| 配置中心 | config.Load() 已集中，可平滑切换来源 |
