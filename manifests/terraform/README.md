# 部署 IaC（qtcloud-product）

对齐 qtcloud-secret 的部署模式。包含两部分：

- **Studio Web 静态站点**（product.cloud.quanttide.com）：OSS 静态网站桶 + CDN + DNS
- **Provider 数据服务**（src/provider，Go）：OSS 产品数据桶 + FC 3.0 custom-container

## 资源

| 资源 | 名称 | 说明 |
|------|------|------|
| OSS 桶 | `qtcloud-product-studio` | Studio 静态网站托管（index/error = index.html），私有 ACL |
| CDN 域名 | `product.cloud.quanttide.com` | 私有回源（STS 同账号）+ 根路径改写 + 强制 HTTPS |
| DNS | CNAME `product.cloud.quanttide.com` | 指向 CDN 分配的 CNAME |
| OSS 桶 | `qtcloud-product-data` | Provider 产品数据桶（版本控制 + SSE-OSS + 生命周期），私有 ACL |
| FC 函数 | `qtcloud-product-prod` | Provider 服务（custom-container，监听 8080），HTTP 触发器直连通道 |
| RAM 角色 | `qtcloud-product-prod-fc` | FC 代入角色 + 数据桶最小只读策略（Get/List，provider 无写入职责） |

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

> FC 镜像通过 `image` 变量注入（`terraform.tfvars` 或 CI 的 `TF_VAR_image`）；
> 实例地址属敏感信息不写默认值，见 `terraform.tfvars.example`。

## 部署链路（CI）

| 流水线 | 触发 | 说明 |
|--------|------|------|
| `.github/workflows/deploy-studio.yml` | `studio/*` tag | Flutter Web 构建 → ossutil 上传 OSS 桶 → 刷新 CDN 缓存 |
| `.github/workflows/deploy-provider.yml` | `provider/*` tag | 镜像构建发布（Docker Hub + ACR 双通道）→ Terraform apply → 种子数据同步进数据桶 |

## 手动步骤（无公开 OpenAPI）

- CDN 控制台开启「回源配置 → 阿里云OSS私有Bucket回源」（回源类型：同账号回源 STS）
- HTTPS 单域名证书：acme.sh 签发 `product.cloud.quanttide.com`（90 天自动续期），
  续期后重配 CDN 证书（`certificate_config` 或控制台）
