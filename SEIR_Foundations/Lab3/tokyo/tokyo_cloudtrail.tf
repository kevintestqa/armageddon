data "aws_caller_identity" "current" {}

resource "aws_s3_bucket" "shinjuku_cloudtrail_bucket" {
  bucket        = "shinjuku-cloudtrail-logs-${data.aws_caller_identity.current.account_id}"
  force_destroy = false
  provider = aws.tokyo
  tags = {
    Name       = "shinjuku-cloudtrail-logs"
    Compliance = "APPI"
  }
}

resource "aws_s3_bucket_versioning" "shinjuku_cloudtrail_versioning" {
  bucket = aws_s3_bucket.shinjuku_cloudtrail_bucket.id
  provider = aws.tokyo
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "shinjuku_cloudtrail_lifecycle" {
  bucket = aws_s3_bucket.shinjuku_cloudtrail_bucket.id
  provider = aws.tokyo

  rule {
    id     = "archive-old-trails"
    status = "Enabled"

    filter {
      prefix = ""
    }

    transition {
      days          = 120
      storage_class = "GLACIER"
    }

    expiration {
      days = 2555
    }
  }
}

resource "aws_s3_bucket_policy" "shinjuku_cloudtrail_policy" {
  bucket = aws_s3_bucket.shinjuku_cloudtrail_bucket.id
  provider = aws.tokyo
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AWSCloudTrailAclCheck"
        Effect = "Allow"
        Principal = {
          Service = "cloudtrail.amazonaws.com"
        }
        Action   = "s3:GetBucketAcl"
        Resource = aws_s3_bucket.shinjuku_cloudtrail_bucket.arn
      },
      {
        Sid    = "AWSCloudTrailWrite"
        Effect = "Allow"
        Principal = {
          Service = "cloudtrail.amazonaws.com"
        }
        Action   = "s3:PutObject"
        Resource = "${aws_s3_bucket.shinjuku_cloudtrail_bucket.arn}/*"
        Condition = {
          StringEquals = {
            "s3:x-amz-acl" = "bucket-owner-full-control"
          }
        }
      }
    ]
  })
}

# CloudFront Logs Bucket (Tokyo)
resource "aws_s3_bucket" "shinjuku_cloudfront_logs_bucket" {
  bucket        = "shinjuku-cloudfront-logs-${data.aws_caller_identity.current.account_id}"
  provider = aws.tokyo
  force_destroy = false
  tags = {
    Name       = "shinjuku-cloudfront-logs"
    Compliance = "APPI"
  }
}

resource "aws_s3_bucket_versioning" "shinjuku_cloudfront_logs_versioning" {
  bucket = aws_s3_bucket.shinjuku_cloudfront_logs_bucket.id
  provider = aws.tokyo
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_ownership_controls" "shinjuku_cloudfront_logs_ownership" {
  bucket = aws_s3_bucket.shinjuku_cloudfront_logs_bucket.id
  provider = aws.tokyo
  rule {
    object_ownership = "BucketOwnerPreferred"
  }
}

resource "aws_s3_bucket_acl" "shinjuku_cloudfront_logs_acl" {
  depends_on = [aws_s3_bucket_ownership_controls.shinjuku_cloudfront_logs_ownership]
  bucket     = aws_s3_bucket.shinjuku_cloudfront_logs_bucket.id
  provider = aws.tokyo
  acl        = "private"
}

# WAF Logs Bucket (Tokyo)
resource "aws_s3_bucket" "shinjuku_waf_logs_bucket" {
  bucket        = "shinjuku-waf-logs-${data.aws_caller_identity.current.account_id}"
  provider = aws.tokyo
  force_destroy = false
  tags = {
    Name       = "shinjuku-waf-logs"
    Purpose    = "Audit Evidence - Security Events"
    LogType  = "SecurityLog"
  }
}

resource "aws_s3_bucket_versioning" "shinjuku_waf_logs_versioning" {
  bucket = aws_s3_bucket.shinjuku_waf_logs_bucket.id
  provider = aws.tokyo
  versioning_configuration {
    status = "Enabled"
  }
}

# VPC Flow Logs Bucket (Tokyo)
resource "aws_s3_bucket" "shinjuku_flowlogs_bucket" {
  bucket        = "shinjuku-flowlogs-${data.aws_caller_identity.current.account_id}"
  provider = aws.tokyo
  force_destroy = false
  tags = {
    Name       = "shinjuku-flowlogs"
    Purpose    = "Audit Evidence - Network Corridor Proof"
    Compliance = "APPI"
    LogType  = "FlowLog"
  }
}

resource "aws_s3_bucket_versioning" "shinjuku_flowlogs_versioning" {
  bucket = aws_s3_bucket.shinjuku_flowlogs_bucket.id
  provider = aws.tokyo
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_policy" "shinjuku_flowlogs_policy" {
  bucket = aws_s3_bucket.shinjuku_flowlogs_bucket.id
  provider = aws.tokyo
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AWSLogDeliveryAclCheck"
        Effect = "Allow"
        Principal = {
          Service = "delivery.logs.amazonaws.com"
        }
        Action = [
          "s3:GetBucketAcl",
          "s3:GetBucketLocation"
        ]
        Resource = aws_s3_bucket.shinjuku_flowlogs_bucket.arn
      },
      {
        Sid    = "AWSLogDeliveryWrite"
        Effect = "Allow"
        Principal = {
          Service = "delivery.logs.amazonaws.com"
        }
        Action   = "s3:PutObject"
        Resource = "${aws_s3_bucket.shinjuku_flowlogs_bucket.arn}/AWSLogs/${data.aws_caller_identity.current.account_id}/*"
        Condition = {
          StringEquals = {
            "s3:x-amz-acl" = "bucket-owner-full-control"
          }
        }
      }
    ]
  })
}

resource "aws_cloudtrail" "shinjuku_trail_tokyo" {
  name                          = "shinjuku-audit-trail-tokyo"
  s3_bucket_name                = aws_s3_bucket.shinjuku_cloudtrail_bucket.id
  provider = aws.tokyo
  include_global_service_events = true
  is_multi_region_trail         = false
  enable_log_file_validation    = true # Immutability proof

  event_selector {
    read_write_type           = "All"
    include_management_events = true
  }

  tags = {
    Name       = "shinjuku-audit-trail-tokyo"
    Purpose    = "Change Trail Evidence"
    Region     = "ap-northeast-1"
    Compliance = "APPI"
  }

  depends_on = [aws_s3_bucket_policy.shinjuku_cloudtrail_policy]
}

resource "aws_flow_log" "shinjuku_vpc_flowlog" {
  vpc_id               = aws_vpc.shinjuku_vpc01.id
  provider = aws.tokyo
  traffic_type         = "ALL"
  log_destination_type = "s3"
  log_destination      = aws_s3_bucket.shinjuku_flowlogs_bucket.arn

  tags = {
    Name       = "shinjuku-vpc-flowlog-tokyo"
    Purpose    = "Network Corridor Evidence"
    Compliance = "APPI"
  }
}

