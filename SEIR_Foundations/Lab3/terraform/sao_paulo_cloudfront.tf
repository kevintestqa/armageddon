locals {
  ports_http     = 80
  ports_https    = 443
  db_port        = 3306
  tcp_protocol   = "tcp"
  all_ip_address = "0.0.0.0/0"
  all_ports      = 0
  all_protocol   = "-1"
}

resource "aws_cloudfront_distribution" "liberdade_cf01" {
  enabled             = true
  is_ipv6_enabled     = true
  comment             = "Liberdade CloudFront distribution"

  # logging_config {
  #   include_cookies = false
  #   bucket          = "liberdade-cloudfront-logs-${data.aws_caller_identity.liberdade_self01.account_id}.s3.amazonaws.com"
  #   prefix          = "liberdade-cf/"
  # }

  web_acl_id = aws_wafv2_web_acl.liberdade_waf_acl.arn

  origin {
    domain_name = aws_lb.liberdade_alb01.dns_name
    origin_id   = "${var.liberdade}-alb-origin"

    custom_origin_config {
      http_port              = local.ports_http
      https_port             = local.ports_https
      origin_protocol_policy = "http-only"
      origin_ssl_protocols   = ["TLSv1.2"]
    }

    custom_header {
      name  = var.origin_header_name
      value = var.origin_header_value
    }
  }

  default_cache_behavior {
    allowed_methods  = ["GET", "HEAD", "OPTIONS", "PUT", "POST", "PATCH", "DELETE"]
    cached_methods   = ["GET", "HEAD", "OPTIONS"]
    target_origin_id = "${var.liberdade}-alb-origin"

    forwarded_values {
      query_string = true
      headers      = ["*"]
      cookies {
        forward = "all"
      }
    }

    viewer_protocol_policy = "redirect-to-https"
    min_ttl                = 0
    default_ttl            = 0
    max_ttl                = 0
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    cloudfront_default_certificate = true
  }

  tags = {
    Name = "${var.liberdade}-cf01"
  }
}