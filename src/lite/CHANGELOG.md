# CHANGELOG

## [0.1.0] - 2026-11-04

### Added

- 工程初始化：React 19 + TypeScript + Vite + ESLint + Vitest，与 `src/site` 同构（对齐 qtclass-lite 脚手架）
- 首屏：轻量端标题一句话
- 部署工作流 `deploy-lite.yml`：`lite/*` tag 构建后上传 OSS 桶 `qtcloud-product-lite` 并刷新 CDN `lite.product.cloud.quanttide.com`（桶与子域待开通）
