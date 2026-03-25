resource "aws_wafv2_web_acl" "liberdade_waf_acl" {
  provider = aws.us_east_virginia
  name     = "liberdade-waf-acl"
  scope    = "CLOUDFRONT"

  default_action {
    allow {}
  }

  # Rule 1: Rate limiting (DDoS protection)
  rule {
    name     = "RateLimitRule"
    priority = 1

    action {
      block {}
    }

    statement {
      rate_based_statement {
        limit              = 2000
        aggregate_key_type = "IP"
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "RateLimitRule"
      sampled_requests_enabled   = true
    }
  }

  # Rule 2: AWS Managed Rules - Core Rule Set
  rule {
    name     = "AWSManagedRulesCommonRuleSet"
    priority = 2

    override_action {
      none {}
    }

    statement {
      managed_rule_group_statement {
        vendor_name = "AWS"
        name        = "AWSManagedRulesCommonRuleSet"
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "AWSManagedRulesCommonRuleSetMetric"
      sampled_requests_enabled   = true
    }
  }

  # Rule 3: AWS Managed Rules - Known Bad Inputs
  rule {
    name     = "AWSManagedRulesKnownBadInputsRuleSet"
    priority = 3

    override_action {
      none {}
    }

    statement {
      managed_rule_group_statement {
        vendor_name = "AWS"
        name        = "AWSManagedRulesKnownBadInputsRuleSet"
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "AWSManagedRulesKnownBadInputsRuleSetMetric"
      sampled_requests_enabled   = true
    }
  }

  visibility_config {
    cloudwatch_metrics_enabled = true
    metric_name                = "liberdadeWafAcl"
    sampled_requests_enabled   = true
  }

  tags = {
    Name       = "liberdade-waf-acl"
    Purpose    = "Security Evidence"
  }
}

resource "aws_cloudwatch_log_group" "liberdade_waf_logs" {
  provider          = aws.us_east_virginia
  name              = "aws-waf-logs-liberdade"
  retention_in_days = 7

  tags = {
    Name = "aws-waf-logs-liberdade"
  }
}

resource "aws_wafv2_web_acl_logging_configuration" "liberdade_waf_logging" {
  provider                = aws.us_east_virginia
  resource_arn            = aws_wafv2_web_acl.liberdade_waf_acl.arn
  log_destination_configs = [aws_cloudwatch_log_group.liberdade_waf_logs.arn]

  depends_on = [aws_cloudwatch_log_group.liberdade_waf_logs]
}