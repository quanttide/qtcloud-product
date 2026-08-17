# CHANGELOG

所有显著变更都将记录在此文件中。

格式基于 [Keep a Changelog](https://keepachangelog.com/zh-CN/1.0.0/)（发布规范见 qtcloud-devops `docs/tutorial/source/conventions/changelog.md`）。

版本遵循语义化版本规范：0.0.x（探索期）→ 0.x.y（验证期）→ x.y.z（正式期）

---

## [Unreleased]

（待发布内容将在此累积）

---

## [0.1.0-alpha.1] - 2026-08-16

### Added

- 服务端 `src/provider`（Go）：以 Studio 数据需求为基准的只读数据服务，结构对齐 qtcloud-secret provider
  - API：`GET /manifest`（产品清单）、`GET /products`（全部产品）、`GET /products/{name}`（单产品完整文档）、`GET /health`（健康检查）
  - 数据契约与 Studio 渲染模型一一对齐（Product/StoryMap/UserActivity/UserTask/UserStory），响应前整树校验（枚举、关系一致性、规模上限）
  - 存储：Store 接口（Get/List）+ 本地文件系统实现（`DATA_DIR` 直读仓库 `assets/data/`，开发/测试）+ 阿里云 OSS 实现（生产，STS 凭证）
  - CORS 中间件：OPTIONS 预检放行 + 白名单回显（默认 product.cloud.quanttide.com）
  - 审计日志（标准日志输出）+ 错误码区分（404 数据不存在 / 500 存储异常或数据损坏）
  - 部署：多阶段 Dockerfile（非 root，监听 8080，FC 3.0 custom-container 就绪）
  - 部署 IaC `manifests/terraform`：产品数据桶（`qtcloud-product-data`，版本控制 + SSE-OSS + 生命周期清理）+ FC 3.0 应用服务（custom-container，RAM 角色最小只读权限 Get/List，无密钥类变量——数据公开只读）
  - CI 流水线 `.github/workflows/deploy-provider.yml`：tag `provider/*` 触发（镜像双通道发布 Docker Hub + ACR → Terraform apply → `assets/data/` 种子数据同步进数据桶）
  - 文档：`docs/index.md` 服务端设计方案（定位/部署/数据契约/API/存储/代码结构/演进预留）
