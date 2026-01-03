# Explanation: Outputs are your mission report—what got built and where to find it.
# output "chewbacca_vpc_id" {
#   value = aws_vpc.chewbacca_vpc01.id
# }

# output "chewbacca_public_subnet_ids" {
#   value = aws_subnet.chewbacca_public_subnets[*].id
# }

# output "chewbacca_private_subnet_ids" {
#   value = aws_subnet.chewbacca_private_subnets[*].id
# }

# output "chewbacca_ec2_instance_id" {
#   value = aws_instance.chewbacca_ec201.id
# }

# output "chewbacca_rds_endpoint" {
#   value = aws_db_instance.chewbacca_rds01.address
# }

# output "chewbacca_sns_topic_arn" {
#   value = aws_sns_topic.chewbacca_sns_topic01.arn
# }

# output "chewbacca_log_group_name" {
#   value = aws_cloudwatch_log_group.chewbacca_log_group01.name
# }

output "securityGroupOutputEgress" {
  description = "Key details for the EC2 security group egress rule"
  value = {
    id                      = aws_security_group_rule.chewbacca_ec2_sg_egress_db.id
    type                    = aws_security_group_rule.chewbacca_ec2_sg_egress_db.type
    protocol                = aws_security_group_rule.chewbacca_ec2_sg_egress_db.protocol
    from_port               = aws_security_group_rule.chewbacca_ec2_sg_egress_db.from_port
    to_port                 = aws_security_group_rule.chewbacca_ec2_sg_egress_db.to_port
    security_group_id        = aws_security_group_rule.chewbacca_ec2_sg_egress_db.security_group_id
    destination_sg_id        = aws_security_group_rule.chewbacca_ec2_sg_egress_db.source_security_group_id
  }
}

output "securityGroupOutputIngress_http" {
  description = "Key details for the EC2 security group for http"
  value = {
    id               = aws_security_group_rule.chewbacca_ec2_sg_ingress_http.id
    type             = aws_security_group_rule.chewbacca_ec2_sg_ingress_http.type
    protocol         = aws_security_group_rule.chewbacca_ec2_sg_ingress_http.protocol
    from_port        = aws_security_group_rule.chewbacca_ec2_sg_ingress_http.from_port
    to_port          = aws_security_group_rule.chewbacca_ec2_sg_ingress_http.to_port
    security_group_id = aws_security_group_rule.chewbacca_ec2_sg_ingress_http.security_group_id
    cidr_blocks      = aws_security_group_rule.chewbacca_ec2_sg_ingress_http.cidr_blocks
  }
}

output "securityGroupOutputIngress_ssh" {
  description = "Key details for the EC2 security group for ssh"
  value = {
    id               = aws_security_group_rule.chewbacca_ec2_sg_ingress_ssh.id
    type             = aws_security_group_rule.chewbacca_ec2_sg_ingress_ssh.type
    protocol         = aws_security_group_rule.chewbacca_ec2_sg_ingress_ssh.protocol
    from_port        = aws_security_group_rule.chewbacca_ec2_sg_ingress_ssh.from_port
    to_port          = aws_security_group_rule.chewbacca_ec2_sg_ingress_ssh.to_port
    security_group_id = aws_security_group_rule.chewbacca_ec2_sg_ingress_ssh.security_group_id
    cidr_blocks      = aws_security_group_rule.chewbacca_ec2_sg_ingress_ssh.cidr_blocks
  }
}

output "rds_security_group" {
  description = "Key details for the RDS security group"
  value = {
    id          = aws_security_group.chewbacca_rds_sg01.id
    name        = aws_security_group.chewbacca_rds_sg01.name
    arn         = aws_security_group.chewbacca_rds_sg01.arn
    vpc_id      = aws_security_group.chewbacca_rds_sg01.vpc_id
    description = aws_security_group.chewbacca_rds_sg01.description
  }
}
