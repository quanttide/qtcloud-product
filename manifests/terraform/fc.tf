# =============================================================================
# 应用服务（对齐 src/provider/docs/index.md）
#
# FC 3.0 custom-container：只读服务产品数据（manifest + 产品文档）。
# 客户端不直连 OSS：应用服务持有最小权限 RAM 角色（STS），仅 Get/List。
#
# 与 qtcloud-secret provider 的差异（本应用数据为公开演示数据，见 provider docs）：
#   - 无 JWT 验签 / MASTER_KEY：数据只读公开，无密钥类环境变量
#   - 写入由 CLI 负责（种子数据经 CI 同步进桶，见 .github/workflows/deploy-provider.yml）
# =============================================================================

# FC 默认角色：允许 FC 服务代入（应用级）
resource "alicloud_ram_role" "fc" {
  role_name                   = "${local.app_name_prefix}-fc"
  assume_role_policy_document = <<EOF
{
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Effect": "Allow",
      "Principal": {
        "Service": ["fc.aliyuncs.com"]
      }
    }
  ],
  "Version": "1"
}
EOF
  description                 = "Function Compute 默认角色（qtcloud-product）"
}

# 最小权限策略：仅允许只读本应用数据桶（provider 无写入职责）
resource "alicloud_ram_policy" "oss_products" {
  policy_name     = "${local.app_name_prefix}-oss-products"
  description     = "qtcloud-product 产品数据桶最小只读权限"
  policy_document = <<EOF
{
  "Statement": [
    {
      "Action": [
        "oss:GetObject",
        "oss:ListObjects"
      ],
      "Effect": "Allow",
      "Resource": [
        "acs:oss:*:*:${local.data_bucket}",
        "acs:oss:*:*:${local.data_bucket}/*"
      ]
    }
  ],
  "Version": "1"
}
EOF
}

resource "alicloud_ram_role_policy_attachment" "fc_oss" {
  policy_name = alicloud_ram_policy.oss_products.policy_name
  policy_type = "Custom"
  role_name   = alicloud_ram_role.fc.role_name
}

# 函数计算（FC 3.0）：custom-container 容器镜像，公网访问 OSS
# （当前阶段无 RDS，不挂 VPC；internet_access 必须显式开启）
resource "alicloud_fcv3_function" "this" {
  function_name     = local.app_name_prefix
  description       = "qtcloud-product 产品云 API（只读服务种子数据）"
  runtime           = "custom-container"
  handler           = "index.handler" # custom-container 必填占位，实际由容器监听端口决定
  cpu               = 0.5
  memory_size       = var.fc_memory
  disk_size         = 512 # FC 3.0 必填（MB）
  timeout           = var.fc_timeout
  internet_access   = true
  role              = alicloud_ram_role.fc.arn
  resource_group_id = data.terraform_remote_state.platform.outputs.resource_group_id

  custom_container_config {
    image = var.image
    port  = 8080
  }

  # 运行时约定（见 src/provider/docs/index.md）：
  #   OSS_BUCKET / OSS_ENDPOINT：产品数据桶访问（provider 只读）
  #   CORS_ALLOWED_ORIGINS：浏览器跨源白名单（Studio Web 站点）
  #   ENV：环境标识（prod 时拒绝 DATA_DIR 本地存储回落）
  environment_variables = {
    OSS_BUCKET           = alicloud_oss_bucket.products.bucket
    OSS_ENDPOINT         = local.oss_endpoint
    CORS_ALLOWED_ORIGINS = "https://product.cloud.quanttide.com,http://product.cloud.quanttide.com"
    ENV                  = var.environment
  }

  tags = {
    project     = var.project
    environment = var.environment
  }
}

# HTTP 触发器：使服务可直接访问（后续由系统级 API 网关统一接入，此触发器保留为直连通道）
resource "alicloud_fcv3_trigger" "http" {
  function_name = alicloud_fcv3_function.this.function_name
  trigger_name  = "http"
  trigger_type  = "http"
  qualifier     = "LATEST"
  trigger_config = jsonencode({
    authType = "anonymous"
    methods  = ["GET", "HEAD", "OPTIONS"] # 只读 API + CORS 预检
  })
}
