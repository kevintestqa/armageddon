# ############################################
# # VPC Endpoints - SSM (Interface)
# ############################################

# # Explanation: SSM is your Force choke—remote control without SSH, and nobody sees your keys.
resource "aws_vpc_endpoint" "liberdade_vpce_ssm01" {
  vpc_id              = aws_vpc.liberdade_vpc01.id
  service_name        = "com.amazonaws.${data.aws_region.liberdade_region01.name}.ssm"
  vpc_endpoint_type   = "Interface"
  private_dns_enabled = true
  provider = aws.sao_paulo

  subnet_ids         = aws_subnet.liberdade_private_subnets[*].id
  security_group_ids = [aws_security_group.liberdade_vpce_sg01.id]

  tags = {
    Name = "${local.liberdade_prefix}-vpce-ssm01"
  }
}

# # Explanation: ec2messages is the Wookiee messenger—SSM sessions won’t work without it.
resource "aws_vpc_endpoint" "liberdade_vpce_ec2messages01" {
  vpc_id              = aws_vpc.liberdade_vpc01.id
  service_name        = "com.amazonaws.${data.aws_region.liberdade_region01.name}.ec2messages"
  vpc_endpoint_type   = "Interface"
  private_dns_enabled = true
  provider = aws.sao_paulo

  subnet_ids         = aws_subnet.liberdade_private_subnets[*].id
  security_group_ids = [aws_security_group.liberdade_vpce_sg01.id]

  tags = {
    Name = "${local.liberdade_prefix}-vpce-ec2messages01"
  }
}

# # Explanation: ssmmessages is the holonet channel—Session Manager needs it to talk back.
resource "aws_vpc_endpoint" "liberdade_vpce_ssmmessages01" {
  vpc_id              = aws_vpc.liberdade_vpc01.id
  service_name        = "com.amazonaws.${data.aws_region.liberdade_region01.name}.ssmmessages"
  vpc_endpoint_type   = "Interface"
  private_dns_enabled = true
  provider = aws.sao_paulo

  subnet_ids         = aws_subnet.liberdade_private_subnets[*].id
  security_group_ids = [aws_security_group.liberdade_vpce_sg01.id]

  tags = {
    Name = "${local.liberdade_prefix}-vpce-ssmmessages01"
  }
}
