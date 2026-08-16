# =============================================================================
# Studio CDN + DNS（product.cloud.quanttide.com）
#
# 链路：OSS 静态网站桶（studio-bucket.tf，私有）→ CDN 加速 + 私有回源鉴权
#   → CNAME 接入（云解析）→ 用户浏览器
#
# 说明（对齐 qtcloud-secret 的 secret.cloud.quanttide.com 部署模式）：
#   - 桶 ACL 私有，回源鉴权分两步：
#     ① 账号级授权：RAM 角色 AliyunCDNAccessingPrivateOSSRole 与策略
#        AliyunCDNAccessingPrivateOSSRolePolicy 为账号全局资源，已由
#        qtcloud-secret 的 manifests/terraform 创建，此处只读引用
#     ② 域名级开关：CDN 控制台「回源配置 → 阿里云OSS私有Bucket回源」开启，
#        回源类型选「同账号回源（STS）」——该开关无公开 OpenAPI，
#        且与 OSS 静态网站托管默认首页存在已知冲突，开启时按官方文档处理
#   - 证书：*.quanttide.com 泛域名证书不匹配两层子域 product.cloud.quanttide.com，
#     须用单域名证书（acme.sh 签发，90 天自动续期；续期后 reloadcmd 重配 CDN），
#     terraform 不管理证书内容（避免私钥入库）
#   - 前置：quanttide.com 已完成 ICP 备案
# =============================================================================

resource "alicloud_cdn_domain_new" "studio" {
  domain_name = "product.cloud.quanttide.com"
  cdn_type    = "web"

  # 源站：OSS 静态网站桶（私有回源鉴权见上方说明）
  sources {
    content  = "${var.oss_bucket_name}.oss-${var.region}.aliyuncs.com"
    type     = "oss"
    port     = 80
    priority = 20
  }

  # HTTPS 证书：单域名证书由 acme.sh 管理，terraform 不管理证书内容。
  # certificate_config {
  #   cert_type                  = "upload"
  #   server_certificate         = "<PEM 公钥，acme.sh 签发>"
  #   private_key                = "<PEM 私钥>"
  #   server_certificate_status  = "on"
  # }
}

# ── 私有 Bucket 回源开关（l2_oss_key：private_oss_auth=on，自动 STS 同账号回源） ──
# 说明：oss_auth 函数（FunctionID 10）由平台在配置 OSS 源站时自动添加，勿手动配置；
# 此处仅开启私有回源开关。
# 注意：与 OSS 静态网站托管默认首页存在已知冲突，若回源 403 需按官方文档处理。
resource "alicloud_cdn_domain_config" "studio_private_back" {
  domain_name   = alicloud_cdn_domain_new.studio.domain_name
  function_name = "l2_oss_key"
  function_args {
    arg_name  = "private_oss_auth"
    arg_value = "on"
  }
}

# 根路径改写为 /index.html：私有回源（签名请求）与 OSS 静态网站托管
# 默认首页重写存在已知冲突（/ 回源 403），改为 CDN 侧直接回源 index.html
resource "alicloud_cdn_domain_config" "studio_root_rewrite" {
  domain_name   = alicloud_cdn_domain_new.studio.domain_name
  function_name = "back_to_origin_url_rewrite"
  function_args {
    arg_name  = "source_url"
    arg_value = "^/$"
  }
  function_args {
    arg_name  = "target_url"
    arg_value = "/index.html"
  }
  function_args {
    arg_name  = "flag"
    arg_value = "break"
  }
}

# 强制 HTTPS：HTTP 请求 301 跳转 HTTPS
resource "alicloud_cdn_domain_config" "studio_https_force" {
  domain_name   = alicloud_cdn_domain_new.studio.domain_name
  function_name = "https_force"
  function_args {
    arg_name  = "enable"
    arg_value = "on"
  }
}

# ── 账号级授权：CDN 回源私有 OSS（账号全局资源，已由 qtcloud-secret 创建） ──
# RAM 角色 AliyunCDNAccessingPrivateOSSRole 与策略
# AliyunCDNAccessingPrivateOSSRolePolicy 为账号级共享资源（信任 CDN 服务
# sts:AssumeRole + OSS 只读），已由 qtcloud-secret 的 manifests/terraform 创建，
# 所有站点（secret.cloud / product.cloud 等）共用，此处无需重复创建。

# ── DNS：CNAME 接入 ─────────────────────────────────────────────────

resource "alicloud_alidns_record" "studio" {
  domain_name = "quanttide.com"
  rr          = "product.cloud"
  type        = "CNAME"
  value       = alicloud_cdn_domain_new.studio.cname
  ttl         = 600
}
