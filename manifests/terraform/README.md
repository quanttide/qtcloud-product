# 部署 IaC：Studio Web 静态站点（product.cloud.quanttide.com）

对齐 qtcloud-secret 的部署模式（OSS 静态网站桶 + CDN + DNS）。

## 资源

| 资源 | 名称 | 说明 |
|------|------|------|
| OSS 桶 | `qtcloud-product-studio` | 静态网站托管（index/error = index.html），私有 ACL |
| CDN 域名 | `product.cloud.quanttide.com` | 私有回源（STS 同账号）+ 根路径改写 + 强制 HTTPS |
| DNS | CNAME `product.cloud.quanttide.com` | 指向 CDN 分配的 CNAME |

## 使用

```bash
export ALICLOUD_ACCESS_KEY=...   # RAM 用户 AccessKey（PowerUserAccess）
export ALICLOUD_SECRET_KEY=...

terraform init \
  -backend-config="bucket=quanttide-terraform-state" \
  -backend-config="key=qtcloud-product/terraform.tfstate" \
  -backend-config="region=cn-hangzhou"

terraform plan
terraform apply
```

## 部署链路（CI）

`.github/workflows/deploy-studio.yml`：推送 `studio/*` tag（如 `studio/v0.0.1`，由 qtcloud-devops release 流程创建）→
Flutter Web 构建 → ossutil 上传 OSS 桶 → 刷新 CDN 缓存。

## 手动步骤（无公开 OpenAPI）

- CDN 控制台开启「回源配置 → 阿里云OSS私有Bucket回源」（回源类型：同账号回源 STS）
- HTTPS 单域名证书：acme.sh 签发 `product.cloud.quanttide.com`（90 天自动续期），
  续期后重配 CDN 证书（`certificate_config` 或控制台）
