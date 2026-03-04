 locals {
  ports_http  = 80
  ports_ssh   = 22
  ports_https = 443
  ports_dns = 53
  db_port        = 3306
  tcp_protocol   = "tcp"
  udp_protocol   = "udp"
  all_ip_address = "0.0.0.0/0"
  all_ports    = 0
  all_protocol = "-1"
}
 
 #Explanation: EC2 SG is satellite’s bodyguard—only let in what you mean to.
resource "aws_security_group" "shinjuku_ec2_sg01" {
  name        = "${local.shinjuku}-ec2-sg01"
  description = "EC2 app security group"
  vpc_id      = aws_vpc.shinjuku_vpc01.id

  tags = {
    Name = "${local.shinjuku}-ec2-sg01"
  }
}
resource "aws_security_group" "shinjuku_ec2_sg02" {
  name        = "${local.shinjuku}-ec2-sg02"
  description = "EC2 app security group"
  vpc_id      = aws_vpc.shinjuku_vpc01.id

  tags = {
    Name = "${local.shinjuku}-ec2-sg02"
  }
}

# Adds inbound rules (HTTP 80, SSH 22 from their IP)

resource "aws_vpc_security_group_ingress_rule" "shinjuku_ec2_sg_ingress_http" {
  ip_protocol       = local.tcp_protocol
  security_group_id = aws_security_group.shinjuku_ec2_sg01.id
  from_port         = local.ports_http
  to_port           = local.ports_http
  cidr_ipv4         = local.all_ip_address
}

# resource "aws_vpc_security_group_ingress_rule" "satellite_bastion_host_sg_ingress_ssh" {
#   ip_protocol       = local.tcp_protocol
#   security_group_id = aws_security_group.satellite_ec2_sg02.id
#   from_port         = local.ports_ssh
#   to_port           = local.ports_ssh
#   cidr_ipv4         = var.my_ip_cidr
# }
# resource "aws_vpc_security_group_ingress_rule" "satellite_ec2_sg_ingress_private_ssh" {
#   ip_protocol                  = local.tcp_protocol
#   security_group_id            = aws_security_group.satellite_ec2_sg02.id
#   from_port                    = local.ports_ssh
#   to_port                      = local.ports_ssh
#   referenced_security_group_id = aws_security_group.satellite_ec2_sg02.id #allow traffic ONLY from specified SG
# }


# Ensures outbound allows DB port to RDS SG (or allow all outbound)
# Kevin- We should not need http, but keeping it
# resource "aws_vpc_security_group_egress_rule" "satellite_ec2_sg_egress_http" {
#   ip_protocol       = local.tcp_protocol
#   security_group_id = aws_security_group.satellite_ec2_sg01.id
#   from_port         = local.ports_http
#   to_port           = local.ports_http
#   cidr_ipv4         = local.all_ip_address
# }

#Kevin- My working click ops environment
# Fixed: When using all_protocol (-1), AWS requires from_port and to_port to be -1 (not 0)
resource "aws_vpc_security_group_egress_rule" "shinjuku_ec2_sg_egress_db" {
  ip_protocol       = local.all_protocol
  security_group_id = aws_security_group.shinjuku_ec2_sg01.id
  from_port         = -1
  to_port           = -1
  cidr_ipv4         = local.all_ip_address
}

# Explanation: RDS SG is the Rebel vault—only the app server gets a keycard.
resource "aws_security_group" "shinjuku_rds_sg01" {
  name        = "${local.shinjuku}-rds-sg01"
  description = "RDS security group"
  vpc_id      = aws_vpc.shinjuku_vpc01.id

  tags = {
    Name = "${local.shinjuku}-rds-sg01"
  }
}

# student adds inbound MySQL 3306 from aws_security_group.shinjuku_ec2_sg01.id

resource "aws_vpc_security_group_ingress_rule" "shinjuku_rds_sg_ingress_mysql" {
  ip_protocol                  = local.tcp_protocol
  security_group_id            = aws_security_group.shinjuku_rds_sg01.id
  from_port                    = local.db_port
  to_port                      = local.db_port
  referenced_security_group_id = aws_security_group.shinjuku_ec2_sg01.id #allow traffic ONLY from specified SG
}

# Explanation: Tokyoâ€™s vault opens only to approved clinicsâ€”Liberdade gets DB access, the public gets nothing.
resource "aws_security_group_rule" "shinjuku_rds_ingress_from_liberdade01" {
  type              = "ingress"
  security_group_id = aws_security_group.shinjuku_rds_sg01.id
  from_port         = local.db_port
  to_port           = local.db_port
  protocol          = "tcp"

  cidr_blocks = [var.liberdade_vpc] # Sao Paulo VPC CIDR (example)
}