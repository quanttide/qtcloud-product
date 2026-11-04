# 量潮产品云 Lite

量潮产品云轻量端（lite），React + Vite + TypeScript，与 `src/site` 同构。页面与数据契约待定位后接入。

## 开发

```bash
npm install
npm run dev      # 本地预览
npm run build    # tsc + vite 构建
npm run lint
npm test
npm run preview
```

## 结构

```
src/
├── App.tsx          # 首屏
├── App.css / index.css
├── main.tsx         # 入口文件
└── vite-env.d.ts    # Vite 类型声明
```

## 部署

`.github/workflows/deploy-lite.yml`：推送 `lite/*` tag（如 `lite/v0.1.0`，由 `qtcloud-devops release publish` 创建）时构建静态站，上传 OSS 桶 `qtcloud-product-lite` 并刷新 CDN `lite.product.cloud.quanttide.com`。桶与子域尚未开通，首发前先在 `manifests/terraform` 补站点桶与 CDN。
