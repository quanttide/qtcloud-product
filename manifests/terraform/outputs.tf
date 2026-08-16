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
