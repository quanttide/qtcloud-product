locals {
  # 应用级资源命名：<app>-<env>（系统级资源由 quanttide-platform 管理）
  app_name_prefix = "${var.project}-${var.environment}"

  # 静态网站桶：命名对齐站点规范 {repo}-{type}（如 qtdata-studio）；OSS 全局唯一
  oss_bucket = var.oss_bucket_name

  # 产品数据桶（provider 数据源，对齐 src/provider/docs/index.md「存储设计」）
  data_bucket = var.data_bucket_name

  oss_endpoint = "https://oss-${var.region}.aliyuncs.com"
}
