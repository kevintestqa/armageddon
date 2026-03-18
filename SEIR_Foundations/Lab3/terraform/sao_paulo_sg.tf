

resource "aws_security_group" "liberdade_asg_sg01" {
  name        = "${var.liberdade}-asg-sg01"
  description = "ASG instance security group"
  vpc_id      = aws_vpc.liberdade_vpc01.id
  provider    = aws.sao_paulo

  tags = {
    Name = "${var.liberdade}-asg-sg01"
  }
}

resource "aws_security_group" "liberdade_alb_sg01" {
  name        = "${var.liberdade}-alb-sg01"
  description = "ALB security group"
  vpc_id      = aws_vpc.liberdade_vpc01.id
  provider    = aws.sao_paulo

  tags = {
    Name = "${var.liberdade}-alb-sg01"
  }
}

resource "aws_security_group" "liberdade_ec2_sg01" {
  name        = "${var.liberdade}-ec2-sg01"
  description = "EC2 app security group"
  vpc_id      = aws_vpc.liberdade_vpc01.id
  provider    = aws.sao_paulo

  tags = {
    Name = "${var.liberdade}-ec2-sg01"
  }
}

# # Explanation: Even endpoints need guards—liberdade posts a Wookiee at every airlock.
resource "aws_security_group" "liberdade_vpce_sg01" {
  name        = "${local.liberdade_prefix}-vpce-sg01"
  description = "SG for VPC Interface Endpoints"
  vpc_id      = aws_vpc.liberdade_vpc01.id
  provider    = aws.sao_paulo

  # TODO: Students must allow inbound 443 FROM the EC2 SG (or VPC CIDR) to endpoints.
  # NOTE: Interface endpoints ENIs receive traffic on 443.

  tags = {
    Name = "${local.liberdade_prefix}-vpce-sg01"
  }
}

resource "aws_vpc_security_group_ingress_rule" "liberdade_alb_sg_ingress_http" {
  ip_protocol       = local.tcp_protocol
  security_group_id = aws_security_group.liberdade_alb_sg01.id
  from_port         = local.ports_http
  to_port           = local.ports_http
  cidr_ipv4         = local.all_ip_address
  provider          = aws.sao_paulo
}

resource "aws_vpc_security_group_ingress_rule" "liberdade_vpce_ingress_https_from_asg" {
  security_group_id            = aws_security_group.liberdade_vpce_sg01.id
  referenced_security_group_id = aws_security_group.liberdade_asg_sg01.id
  ip_protocol                  = "tcp"
  from_port                    = local.ports_https
  to_port                      = local.ports_https
  provider                     = aws.sao_paulo
}

resource "aws_vpc_security_group_ingress_rule" "liberdade_vpce_ingress_https_from_ec2" {
  security_group_id            = aws_security_group.liberdade_vpce_sg01.id
  referenced_security_group_id = aws_security_group.liberdade_ec2_sg01.id
  ip_protocol                  = "tcp"
  from_port                    = 443
  to_port                      = 443
  provider                     = aws.sao_paulo
}

resource "aws_vpc_security_group_egress_rule" "liberdade_alb_sg_egress_all" {
  ip_protocol       = local.all_protocol
  security_group_id = aws_security_group.liberdade_alb_sg01.id
  from_port         = -1
  to_port           = -1
  cidr_ipv4         = local.all_ip_address
  provider          = aws.sao_paulo
}

resource "aws_vpc_security_group_egress_rule" "liberdade_ec2_sg_egress_all" {
  ip_protocol       = local.all_protocol
  security_group_id = aws_security_group.liberdade_ec2_sg01.id
  from_port         = -1
  to_port           = -1
  cidr_ipv4         = local.all_ip_address
  provider          = aws.sao_paulo
}

resource "aws_vpc_security_group_egress_rule" "liberdade_asg_sg_egress_all" {
  ip_protocol       = local.all_protocol
  security_group_id = aws_security_group.liberdade_asg_sg01.id
  from_port         = -1
  to_port           = -1
  cidr_ipv4         = local.all_ip_address
  provider          = aws.sao_paulo
}