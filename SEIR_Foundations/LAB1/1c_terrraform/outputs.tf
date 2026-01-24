# Explanation: Outputs are your mission report—what got built and where to find it.
output "satellite_vpc_id" {
  value = aws_vpc.satellite_vpc01.id
}

output "satellite_public_subnet_ids" {
  value = aws_subnet.satellite_public_subnets[*].id
}

output "satellite_private_subnet_ids" {
  value = aws_subnet.satellite_private_subnets[*].id
}

# output "satellite_ec2_instance_id" {
#   value = aws_instance.satellite_ec201.id
# }

output "satellite_rds_endpoint" {
  value = aws_db_instance.satellite_rds01.address
}

output "satellite_sns_topic_arn" {
  value = aws_sns_topic.satellite_sns_topic01.arn
}

output "satellite_log_group_name" {
  value = aws_cloudwatch_log_group.satellite_log_group01.name
}

output "satellite_route53_zone_id" {
  value = var.hosted_zone_id
}

output "satellite_app_url_https" {
  value = "https://${var.app_subdomain}.${var.domain_name}"
}

output "satellite_pawserenity_cert_arn" {
  value = aws_acm_certificate.satellite_acm_cert01
  sensitive = true
}

output "satellite_pawserenity_cert_arn_region" {
  value = aws_acm_certificate.satellite_acm_cert01.region
  sensitive = false
}

output "pawserenity_apex_alias_record" {
  value = aws_route53_record.pawserenity_apex_alias.records
}

output "pawserenity_www_alias_record" {
  value = aws_route53_record.pawserenity_www_alias.records
}

output "pawserenity_apex_alias" {
  value = aws_route53_record.pawserenity_apex_alias.alias
}

output "pawserenity_www_alia_ttl" {
  value = aws_route53_record.pawserenity_www_alias.ttl
}