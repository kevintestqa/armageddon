locals {
  db_port = 3306
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