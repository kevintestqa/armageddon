# Explanation: Outputs are your mission report—what got built and where to find it.
# output "satellite_vpc_id" {
#   value = aws_vpc.satellite_vpc01.id
# }

# output "satellite_public_subnet_ids" {
#   value = aws_subnet.satellite_public_subnets[*].id
# }

# output "satellite_private_subnet_ids" {
#   value = aws_subnet.satellite_private_subnets[*].id
# }

# output "satellite_ec2_instance_id" {
#   value = aws_instance.satellite_ec201.id
# }

# output "satellite_rds_endpoint" {
#   value = aws_db_instance.satellite_rds01.address
# }

# output "satellite_sns_topic_arn" {
#   value = aws_sns_topic.satellite_sns_topic01.arn
# }

# output "satellite_log_group_name" {
#   value = aws_cloudwatch_log_group.satellite_log_group01.name
# }

output "securityGroupOutputEgress" {
  description = "Key details for the EC2 security group egress rule (DB)"
  value = {
    id                       = aws_vpc_security_group_egress_rule.satellite_ec2_sg_egress_db.id
    ip_protocol              = aws_vpc_security_group_egress_rule.satellite_ec2_sg_egress_db.ip_protocol
    from_port                = aws_vpc_security_group_egress_rule.satellite_ec2_sg_egress_db.from_port
    to_port                  = aws_vpc_security_group_egress_rule.satellite_ec2_sg_egress_db.to_port
    security_group_id        = aws_vpc_security_group_egress_rule.satellite_ec2_sg_egress_db.security_group_id
    referenced_security_group_id = aws_vpc_security_group_egress_rule.satellite_ec2_sg_egress_db.referenced_security_group_id
  }
}

output "securityGroupOutputIngress_http" {
  description = "Key details for the EC2 security group ingress rule (HTTP)"
  value = {
    id                = aws_vpc_security_group_ingress_rule.satellite_ec2_sg_ingress_http.id
    ip_protocol       = aws_vpc_security_group_ingress_rule.satellite_ec2_sg_ingress_http.ip_protocol
    from_port         = aws_vpc_security_group_ingress_rule.satellite_ec2_sg_ingress_http.from_port
    to_port           = aws_vpc_security_group_ingress_rule.satellite_ec2_sg_ingress_http.to_port
    security_group_id = aws_vpc_security_group_ingress_rule.satellite_ec2_sg_ingress_http.security_group_id
    cidr_ipv4         = aws_vpc_security_group_ingress_rule.satellite_ec2_sg_ingress_http.cidr_ipv4
  }
}

output "securityGroupOutputIngress_ssh" {
  description = "Key details for the EC2 security group ingress rule (SSH)"
  value = {
    id                = aws_vpc_security_group_ingress_rule.satellite_ec2_sg_ingress_ssh.id
    ip_protocol       = aws_vpc_security_group_ingress_rule.satellite_ec2_sg_ingress_ssh.ip_protocol
    from_port         = aws_vpc_security_group_ingress_rule.satellite_ec2_sg_ingress_ssh.from_port
    to_port           = aws_vpc_security_group_ingress_rule.satellite_ec2_sg_ingress_ssh.to_port
    security_group_id = aws_vpc_security_group_ingress_rule.satellite_ec2_sg_ingress_ssh.security_group_id
    cidr_ipv4         = aws_vpc_security_group_ingress_rule.satellite_ec2_sg_ingress_ssh.cidr_ipv4
  }
}

output "rds_security_group" {
  description = "Key details for the RDS security group"
  value = {
    id          = aws_security_group.satellite_rds_sg01.id
    name        = aws_security_group.satellite_rds_sg01.name
    arn         = aws_security_group.satellite_rds_sg01.arn
    vpc_id      = aws_security_group.satellite_rds_sg01.vpc_id
    description = aws_security_group.satellite_rds_sg01.description
  }
}

output "securityGroupOutputIngress_mysql" {
  description = "Key details for the RDS security group ingress rule (MySQL from EC2 SG)"
  value = {
    id                          = aws_vpc_security_group_ingress_rule.satellite_rds_sg_ingress_mysql.id
    ip_protocol                 = aws_vpc_security_group_ingress_rule.satellite_rds_sg_ingress_mysql.ip_protocol
    from_port                   = aws_vpc_security_group_ingress_rule.satellite_rds_sg_ingress_mysql.from_port
    to_port                     = aws_vpc_security_group_ingress_rule.satellite_rds_sg_ingress_mysql.to_port
    security_group_id           = aws_vpc_security_group_ingress_rule.satellite_rds_sg_ingress_mysql.security_group_id
    referenced_security_group_id = aws_vpc_security_group_ingress_rule.satellite_rds_sg_ingress_mysql.referenced_security_group_id
  }
}
