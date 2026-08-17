output "studio_bucket" {
  description = "Studio 静态网站桶名"
  value       = alicloud_oss_bucket.studio.bucket
}

output "cdn_domain" {
  description = "CDN 加速域名"
  value       = alicloud_cdn_domain_new.studio.domain_name
}

output "cdn_cname" {
  description = "CDN CNAME（DNS 接入目标）"
  value       = alicloud_cdn_domain_new.studio.cname
}

output "data_bucket" {
  description = "产品数据桶名（manifest.json + products/<id>.json，版本控制 + SSE-OSS）"
  value       = alicloud_oss_bucket.products.bucket
}

output "fc_function_name" {
  description = "函数计算函数名（qtcloud-product provider）"
  value       = alicloud_fcv3_function.this.function_name
}

output "fc_http_url" {
  description = "FC HTTP 触发器公网地址（系统级 API 网关接入前的直连入口）"
  value       = try(alicloud_fcv3_trigger.http.http_trigger[0].url_internet, "尚未创建")
}
