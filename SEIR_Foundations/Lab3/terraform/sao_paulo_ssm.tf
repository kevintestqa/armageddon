# ############################################
# # VPC Endpoints - SSM (Interface)
# ############################################

# # Explanation: SSM is your Force choke—remote control without SSH, and nobody sees your keys.
resource "aws_vpc_endpoint" "liberdade_vpce_ssm01" {
  vpc_id              = aws_vpc.liberdade_vpc01.id
  service_name        = "com.amazonaws.${data.aws_region.liberdade_region01.name}.ssm"
  vpc_endpoint_type   = "Interface"
  private_dns_enabled = true
  provider            = aws.sao_paulo

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
  provider            = aws.sao_paulo

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
  provider            = aws.sao_paulo

  subnet_ids         = aws_subnet.liberdade_private_subnets[*].id
  security_group_ids = [aws_security_group.liberdade_vpce_sg01.id]

  tags = {
    Name = "${local.liberdade_prefix}-vpce-ssmmessages01"
  }
}

############################################
# Parameter Store (SSM Parameters)
############################################

# Explanation: Parameter Store is satellite’s map—endpoints and config live here for fast recovery.
resource "aws_ssm_parameter" "satellite_db_endpoint" {
  name  = "/lab/db/endpoint"
  type  = "String"
  value = var.shinjuku_rds_endpoint
  provider = aws.sao_paulo

  tags = {
    Name = "${var.liberdade}-param-db-endpoint"
  }
}

# Explanation: Ports are boring, but even Wookiees need to know which door number to kick in.
resource "aws_ssm_parameter" "satellite_db_port" {
  name  = "/lab/db/port"
  type  = "String"
  value = tostring(var.shinjuku_rds_port)
  provider = aws.sao_paulo

  tags = {
    Name = "${var.liberdade}-param-db-port"
  }
}

# Explanation: DB name is the label on the crate—without it, you’re rummaging in the dark.
resource "aws_ssm_parameter" "satellite_db_name" {
  name  = "/lab/db/name"
  type  = "String"
  value = var.db_name
  provider = aws.sao_paulo

  tags = {
    Name = "${var.liberdade}-param-db-name"
  }
}

############################################
# Secrets Manager (DB Credentials)
############################################

# Explanation: Secrets Manager is satellite’s locked holster—credentials go here, not in code.
#Recovery_window_in_days forces deletion of secrets and allows re-deployment of secret without constantly changing name

resource "aws_secretsmanager_secret" "satellite_db_secret01" {
  name                    = "lab3a/rds/mysql"
  recovery_window_in_days = 0
  provider = aws.sao_paulo
}

# Explanation: Secret payload—students should align this structure with their app (and support rotation later).
resource "aws_secretsmanager_secret_version" "satellite_db_secret_version01" {
  secret_id = aws_secretsmanager_secret.satellite_db_secret01.id
  provider = aws.sao_paulo

  secret_string = jsonencode({
    username = var.db_username
    password = var.db_password
    host     = var.shinjuku_rds_endpoint
    port     = var.shinjuku_rds_port
    dbname   = var.db_name
  })
}