resource "aws_db_instance" "shinjuku_rds01" {
  identifier               = "${local.shinjuku}-rds01"
  engine                   = var.db_engine
  instance_class           = var.db_instance_class
  storage_type             = var.storage_type
  allocated_storage        = 20
  backup_retention_period  = 0 
  db_name                  = var.db_name
  username                 = var.db_username
  password                 = var.db_password
  multi_az                 = false
  delete_automated_backups = false

  db_subnet_group_name   = aws_db_subnet_group.shinjuku_rds_subnet_group01.name
  vpc_security_group_ids = [aws_security_group.shinjuku_rds_sg01.id]

  publicly_accessible = false
  skip_final_snapshot = true

  # student sets multi_az / backups / monitoring as stretch goals

  tags = {
    Name = "${local.shinjuku}-rds01"
  }

  depends_on = [aws_db_subnet_group.shinjuku_rds_subnet_group01, aws_security_group.shinjuku_rds_sg01]
}

resource "aws_db_subnet_group" "shinjuku_rds_subnet_group01" {
  name       = "${local.shinjuku}-rds-subnet-group01"
  subnet_ids = aws_subnet.shinjuku_private_subnets[*].id

  tags = {
    Name = "${local.shinjuku}-rds-subnet-group01"
  }
}