# =============================================================================
# 产品数据存储（对齐 src/provider/docs/index.md「存储设计」）
#
# 对象布局与 CLI 加工的种子数据完全同构（部署时把 assets/data/ 同步进桶即可上线）：
#   - manifest.json            产品清单（products: [唯一命名...]）
#   - products/<唯一命名>.json  每个产品一个文件（含用户故事地图）
#
# 当前阶段（小数据量、纯 OSS、无 PG）：
#   - 桶开启版本控制：误删/误写可回滚（删除产生 delete marker，覆盖写保留历史版本）
#   - SSE-OSS 服务端加密：数据静态加密兜底（OSS 托管密钥、自动轮换、免费）
#   - 生命周期：清理非当前版本，防止版本无限膨胀
#   - ACL 私有：客户端永不直接接触 OSS，读取经 FC 代理（STS 最小权限，见 fc.tf）
# =============================================================================

# 主存储桶：manifest.json + products/<id>.json
resource "alicloud_oss_bucket" "products" {
  bucket            = local.data_bucket
  storage_class     = "Standard"
  resource_group_id = data.terraform_remote_state.platform.outputs.resource_group_id
  tags = {
    project     = var.project
    environment = var.environment
  }

  # 版本控制：恢复保险（误删/误写回滚任意历史版本）
  versioning {
    status = "Enabled"
  }

  # 服务端加密：SSE-OSS（OSS 托管密钥、自动轮换、免费）
  server_side_encryption_rule {
    sse_algorithm = "AES256"
  }

  # 生命周期：非当前版本保留 N 天后清理；删除标记过期后自动移除
  lifecycle_rule {
    id      = "version-cleanup"
    enabled = true

    noncurrent_version_expiration {
      days = var.oss_version_retention_days
    }

    expiration {
      expired_object_delete_marker = true
    }
  }
}

# 桶私有：客户端不直接接触 OSS，读取经 FC 代理（STS 临时凭证）
resource "alicloud_oss_bucket_acl" "products" {
  bucket = alicloud_oss_bucket.products.bucket
  acl    = "private"
}
