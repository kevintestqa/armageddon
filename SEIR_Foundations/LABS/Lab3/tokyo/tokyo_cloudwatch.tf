############################################
# CloudWatch Logs (Log Group)
############################################

# Explanation: When the Falcon is on fire, logs tell you *which* wire sparked—ship them centrally.
resource "aws_cloudwatch_log_group" "shinjuku_log_group01" {
  name              = "/aws/ec2/${local.shinjuku}-rds-app"
  retention_in_days = 7
  provider          = aws.tokyo

  tags = {
    Name = "${local.shinjuku}-log-group01"
  }
}

############################################
# Custom Metric + Alarm (Skeleton)
############################################

# Explanation: Metrics are shinjuku’s growls—when they spike, something is wrong.
# NOTE: Students must emit the metric from app/agent; this just declares the alarm.
resource "aws_cloudwatch_metric_alarm" "shinjuku_db_alarm01" {
  alarm_name          = "${local.shinjuku}-db-connection-failure"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 1
  metric_name         = "DBConnectionErrors"
  namespace           = "Lab/RDSApp"
  period              = 300
  statistic           = "Sum"
  threshold           = 3
  provider            = aws.tokyo

  alarm_actions = [aws_sns_topic.shinjuku_sns_topic01.arn]

  tags = {
    Name = "${local.shinjuku}-alarm-db-fail"
  }
}

# 1C_Bonus_B #################################
# # CloudWatch Alarm: ALB 5xx -> SNS
# ############################################

# # Explanation: When the ALB starts throwing 5xx, that’s the Falcon coughing — page the on-call Wookiee.
resource "aws_cloudwatch_metric_alarm" "shinjuku_alb_5xx_alarm01" {
  alarm_name          = "${local.shinjuku}-alb-5xx-alarm01"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = var.alb_5xx_evaluation_periods
  threshold           = var.alb_5xx_threshold
  period              = var.alb_5xx_period_seconds
  statistic           = "Sum"
  provider            = aws.tokyo

  namespace   = "AWS/ApplicationELB"
  metric_name = "HTTPCode_ELB_5XX_Count"

  alarm_actions = [aws_sns_topic.shinjuku_sns_topic01.arn]

  tags = {
    Name = "${local.shinjuku}-alb-5xx-alarm01"
  }
}
