############################################
# IAM Role + Instance Profile for EC2
############################################

# Explanation: liberdade refuses to carry static keys—this role lets EC2 assume permissions safely.
resource "aws_iam_role" "liberdade_ec2_role01" {
  name     = "${local.liberdade_prefix}-ec2-role01"
  provider = aws.sao_paulo

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "ec2.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })
}

# Explanation: These policies are your Wookiee toolbelt—tighten them (least privilege) as a stretch goal.
resource "aws_iam_role_policy_attachment" "liberdade_ec2_ssm_attach" {
  role       = aws_iam_role.liberdade_ec2_role01.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
  provider   = aws.sao_paulo
}

# Explanation: EC2 must read secrets/params during recovery—give it access (students should scope it down).
resource "aws_iam_role_policy_attachment" "liberdade_ec2_secrets_attach" {
  role       = aws_iam_role.liberdade_ec2_role01.name
  policy_arn = aws_iam_policy.liberdade_secrets_policy.arn
  provider   = aws.sao_paulo
}

# Explanation: CloudWatch logs are the “ship’s black box”—you need them when things explode.
resource "aws_iam_role_policy_attachment" "liberdade_ec2_cw_attach" {
  role       = aws_iam_role.liberdade_ec2_role01.name
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
  provider   = aws.sao_paulo
}

# Explanation: Instance profile is the harness that straps the role onto the EC2 like bandolier ammo.
resource "aws_iam_instance_profile" "liberdade_instance_profile01" {
  name     = "${local.liberdade_prefix}-instance-profile01"
  role     = aws_iam_role.liberdade_ec2_role01.name
  provider = aws.sao_paulo
}

resource "aws_iam_policy" "liberdade_secrets_policy" {
  name        = "secrets_policy_lab3"
  description = "EC2 to RDS using Secrets Manager"
  provider    = aws.sao_paulo

  policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Sid" : "ReadSpecificSecret",
        "Effect" : "Allow",
        "Action" : [
          "secretsmanager:GetSecretValue"
        ],
        "Resource" : "arn:aws:secretsmanager:sa-east-1:461593447802:secret:lab3a/rds/mysql*"
      }
    ]
  })
}

# 1CBonus_A ##################################
# # Least-Privilege IAM (BONUS A)
# ############################################

# # Explanation: liberdade doesn’t hand out the Falcon keys—this policy scopes reads to your lab paths only.
resource "aws_iam_policy" "liberdade_leastpriv_read_params01" {
  name        = "${local.liberdade_prefix}-lp-ssm-read01"
  description = "Least-privilege read for SSM Parameter Store under /lab/db/*"
  provider    = aws.sao_paulo

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "ReadLabDbParams"
        Effect = "Allow"
        Action = [
          "ssm:GetParameter",
          "ssm:GetParameters",
          "ssm:GetParametersByPath"
        ]
        Resource = [
          "arn:aws:ssm:${data.aws_region.liberdade_region01.name}:${data.aws_caller_identity.liberdade_self01.account_id}:parameter/rds/mysql/*"
        ]
      }
    ]
  })
}

# # Explanation: liberdade only opens *this* vault—GetSecretValue for only your secret (not the whole planet).
resource "aws_iam_policy" "liberdade_leastpriv_read_secret01" {
  name        = "${local.liberdade_prefix}-lp-secrets-read01"
  description = "Least-privilege read for the lab DB secret"
  provider    = aws.sao_paulo

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "ReadOnlyLabSecret"
        Effect = "Allow"
        Action = [
          "secretsmanager:GetSecretValue",
          "secretsmanager:DescribeSecret"
        ]
        Resource = local.liberdade_secret_arn_guess
      }
    ]
  })
}

# # Explanation: When the Falcon logs scream, this lets liberdade ship logs to CloudWatch without giving away the Death Star plans.
resource "aws_iam_policy" "liberdade_leastpriv_cwlogs01" {
  name        = "${local.liberdade_prefix}-lp-cwlogs01"
  description = "Least-privilege CloudWatch Logs write for the app log group"
  provider    = aws.sao_paulo

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "WriteLogs"
        Effect = "Allow"
        Action = [
          "logs:CreateLogStream",
          "logs:PutLogEvents",
          "logs:DescribeLogStreams"
        ]
        Resource = [
          "${aws_cloudwatch_log_group.shinjuku_log_group01.arn}:*"
        ]
      }
    ]
  })
}

# # Explanation: Attach the scoped policies—liberdade loves power, but only the safe kind.
resource "aws_iam_role_policy_attachment" "liberdade_attach_lp_params01" {
  role       = aws_iam_role.liberdade_ec2_role01.name
  policy_arn = aws_iam_policy.liberdade_leastpriv_read_params01.arn
  provider   = aws.sao_paulo
}

resource "aws_iam_role_policy_attachment" "liberdade_attach_lp_secret01" {
  role       = aws_iam_role.liberdade_ec2_role01.name
  policy_arn = aws_iam_policy.liberdade_leastpriv_read_secret01.arn
  provider   = aws.sao_paulo
}

resource "aws_iam_role_policy_attachment" "liberdade_attach_lp_cwlogs01" {
  role       = aws_iam_role.liberdade_ec2_role01.name
  policy_arn = aws_iam_policy.liberdade_leastpriv_cwlogs01.arn
  provider   = aws.sao_paulo
}

# # Explanation: liberdade wants to know “who am I in this galaxy?” so ARNs can be scoped properly.
data "aws_caller_identity" "liberdade_self01" {
  provider = aws.sao_paulo
}

# # Explanation: Region matters—hyperspace lanes change per sector.
data "aws_region" "liberdade_region01" {
  provider = aws.sao_paulo
}

locals {
  #   # Explanation: Name prefix is the roar that echoes through every tag.
  liberdade_prefix = var.liberdade

  #   # TODO: Students should lock this down after apply using the real secret ARN from outputs/state
  liberdade_secret_arn_guess = "arn:aws:secretsmanager:${data.aws_region.liberdade_region01.name}:${data.aws_caller_identity.liberdade_self01.account_id}:secret:${local.liberdade_prefix}/rds/mysql*"
}

resource "aws_cloudwatch_log_group" "shinjuku_log_group01" {
  name              = "/aws/ec2/${local.liberdade_prefix}-rds-app"
  retention_in_days = 7
  provider          = aws.sao_paulo

  tags = {
    Name = "${local.liberdade_prefix}-log-group01"
  }
}