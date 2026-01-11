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
