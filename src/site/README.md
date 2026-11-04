# 量潮产品云站点

量潮产品云站点（site），基于 React + TypeScript + Vite 构建，脚手架对齐 qtclass-site。

## 开发

```bash
# 安装依赖
npm install

# 启动开发服务器
npm run dev

# 构建生产版本
npm run build

# 运行测试
npm test

# 静态检查
npm run lint

# 预览生产版本
npm run preview
```

## 技术栈

- React 19
- TypeScript
- Vite
- Vitest
- ESLint

## 部署

`.github/workflows/deploy-site.yml`：推送 `site/*` tag（如 `site/v0.1.0`，由 `qtcloud-devops release publish` 创建）时构建静态站，上传 OSS 桶 `qtcloud-product-site` 并刷新 CDN `product.cloud.quanttide.com`。桶与子域尚未开通，首发前先在 `manifests/terraform` 补站点桶与 CDN。

## 项目结构

```
src/
├── App.tsx              # 首屏（定位一句话）
├── App.css / index.css  # 样式
├── main.tsx             # 入口文件
└── vite-env.d.ts        # Vite 类型声明
```
