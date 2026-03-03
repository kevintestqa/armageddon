locals {
  db_port = 3306
  ports_http     = 80
  ports_ssh      = 22
  ports_https    = 443
  tcp_protocol   = "tcp"
  all_ip_address = "0.0.0.0/0"
  all_ports      = 0
  all_protocol   = "-1"
}

# Explanation: Tokyo’s vault opens only to approved clinics—Liberdade gets DB access, the public gets nothing.
resource "aws_security_group_rule" "shinjuku_rds_ingress_from_liberdade01" {
  type              = "ingress"
  security_group_id = aws_security_group.shinjuku_rds_ingres_sg01.id
  from_port         = local.db_port
  to_port           = local.db_port
  protocol          = "tcp"

  cidr_blocks = var.liberdade_public_cidrs # Sao Paulo VPC CIDR (students supply)
}

resource "aws_security_group" "shinjuku_rds_ingres_sg01" {
  description = "RDS security group"
  vpc_id      = aws_vpc.shinjuku_vpc01.id
}

resource "aws_security_group" "liberdade_asg_sg01" {
  name        = "${vars.liberdade}-asg-sg01"
  description = "ASG instance security group"
  vpc_id      = aws_vpc.liberdade_vpc01.id

  tags = {
    Name = "${vars.liberdade}-asg-sg01"
  }
}

resource "aws_security_group" "liberdade_alb_sg01" {
  name        = "${vars.liberdade}-alb-sg01"
  description = "ALB security group"
  vpc_id      = aws_vpc.liberdade_vpc01.id

  tags = {
    Name = "${vars.liberdade}-alb-sg01"
  }
}

resource "aws_vpc_security_group_ingress_rule" "liberdade_alb_sg_ingress_http" {
  ip_protocol       = local.tcp_protocol
  security_group_id = aws_security_group.liberdade_alb_sg01.id
  from_port         = local.ports_http
  to_port           = local.ports_http
  cidr_ipv4         = local.all_ip_address
}

resource "aws_vpc_security_group_egress_rule" "liberdade_alb_sg_egress_all" {
  ip_protocol       = local.all_protocol
  security_group_id = aws_security_group.liberdade_alb_sg01.id
  from_port         = -1
  to_port           = -1
  cidr_ipv4         = local.all_ip_address
}