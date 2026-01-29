resource "aws_s3_bucket" "satellite_alb_logs_bucket01" {
    bucket = var.satellite_s3_bucket_name
    tags = {
      "Name" = "alb_logs"
    }
}

resource "aws_s3_bucket_ownership_controls" "satellite_alb_logs_bucket01_ownership" {
  bucket = aws_s3_bucket.satellite_alb_logs_bucket01.id

  rule {
    object_ownership = "BucketOwnerPreferred" #will have to try Bucket owner enforced
  }
}

resource "aws_s3_bucket_acl" "satellite_alb_logs_bucket01_acl" {
  bucket = aws_s3_bucket.satellite_alb_logs_bucket01.id
  acl    = "private"

  depends_on = [aws_s3_bucket_ownership_controls.satellite_alb_logs_bucket01_ownership]
}

resource "aws_s3_bucket_policy" "satellite_alb_logs_bucket01_access" {
    bucket = aws_s3_bucket.satellite_alb_logs_bucket01.id
    policy = data.aws_iam_policy_document.satellite_s3_access_from_alb.json
}


data "aws_caller_identity" "current" {}

data "aws_iam_policy_document" "satellite_s3_access_from_alb" {
  statement {
    sid     = "AllowALBLogDelivery"
    effect  = "Allow"

    principals {
      type        = "Service"
      identifiers = ["logdelivery.elasticloadbalancing.amazonaws.com"]
    }

    actions = ["s3:PutObject"]

    # ALB writes to: <prefix>/AWSLogs/<account-id>/...
    resources = [
      "${aws_s3_bucket.satellite_alb_logs_bucket01.arn}/${var.alb_access_logs_prefix}/AWSLogs/${data.aws_caller_identity.current.account_id}/*"
    ]

    condition {
      test     = "StringEquals"
      variable = "s3:x-amz-acl"
      values   = ["bucket-owner-full-control"]
    }
  }
}
