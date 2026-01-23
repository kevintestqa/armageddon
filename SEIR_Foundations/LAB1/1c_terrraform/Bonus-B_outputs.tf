# # Explanation: Outputs are the mission coordinates — where to point your browser and your blasters.
output "satellite_alb_dns_name" {
  value = aws_lb.satellite_alb01.dns_name
}

output "satellite_app_fqdn" {
  value = "${var.app_subdomain}.${var.domain_name}"
}

output "satellite_target_group_arn" {
  value = aws_lb_target_group.satellite_tg01.arn
}

output "satellite_acm_cert_arn" {
  value = aws_acm_certificate.satellite_acm_cert01.arn
}

output "satellite_waf_arn" {
  value = var.enable_waf ? aws_wafv2_web_acl.satellite_waf01[0].arn : null
}

output "satellite_dashboard_name" {
  value = aws_cloudwatch_dashboard.satellite_dashboard01.dashboard_name
}
