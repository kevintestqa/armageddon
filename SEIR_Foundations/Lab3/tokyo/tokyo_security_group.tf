locals {
  ports_http     = 80
  ports_ssh      = 22
  ports_https    = 443
  ports_dns      = 53
  db_port        = 3306
  tcp_protocol   = "tcp"
  udp_protocol   = "udp"
  all_ip_address = "0.0.0.0/0"
  all_ports      = 0
  all_protocol   = "-1"
}

# Explanation: RDS SG is the Rebel vault—only the app server gets a keycard.
resource "aws_security_group" "shinjuku_rds_sg01" {
  name        = "${local.shinjuku}-rds-sg01"
  description = "RDS security group"
  vpc_id      = aws_vpc.shinjuku_vpc01.id
  provider    = aws.tokyo

  tags = {
    Name = "${local.shinjuku}-rds-sg01"
  }
}

# Allow MySQL 3306 from the Sao Paulo VPC CIDR. The Tokyo app SG rule was removed because no Tokyo EC2 uses it.
resource "aws_security_group_rule" "shinjuku_rds_ingress_from_liberdade01" {
  type              = "ingress"
  security_group_id = aws_security_group.shinjuku_rds_sg01.id
  from_port         = local.db_port
  to_port           = local.db_port
  protocol          = "tcp"
  provider          = aws.tokyo

  cidr_blocks = [var.liberdade_vpc] # Sao Paulo VPC CIDR (example)
}