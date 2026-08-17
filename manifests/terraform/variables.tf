variable "region" {
  description = "阿里云地域"
  type        = string
  default     = "cn-hangzhou"
}

variable "project" {
  description = "项目名（资源命名前缀）"
  type        = string
  default     = "qtcloud-product"
}

variable "environment" {
  description = "环境：dev / prod"
  type        = string
  default     = "prod"
}

variable "oss_bucket_name" {
  description = "Studio 静态网站桶名（OSS 全局唯一）"
  type        = string
  default     = "qtcloud-product-studio"
}

variable "data_bucket_name" {
  description = "产品数据桶名（provider 数据源；版本控制 + SSE-OSS，见 provider-bucket.tf）"
  type        = string
  default     = "qtcloud-product-data"
}

variable "oss_version_retention_days" {
  description = "OSS 生命周期：非当前版本（历史版本）保留天数，超过后清理，防止版本膨胀"
  type        = number
  default     = 30
}

variable "image" {
  description = "FC 容器镜像。由 CI 注入（TF_VAR_image 拼接 secret ALIYUN_ACR_REGISTRY 的实例地址）或 terraform.tfvars 提供；实例地址属敏感信息不写默认值"
  type        = string
}

variable "fc_memory" {
  description = "FC 函数内存（MB）"
  type        = number
  default     = 512
}

variable "fc_timeout" {
  description = "FC 函数超时（秒）"
  type        = number
  default     = 60
}
