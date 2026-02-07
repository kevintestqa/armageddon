# Explanation: CloudFront is the only public doorway — satellite stands behind it with private infrastructure.
resource "aws_cloudfront_distribution" "satellite_cf01" {
  enabled         = true
  is_ipv6_enabled = true
  comment         = "${var.project_name}-cf01"

  origin {
    origin_id   = "${var.project_name}-alb-origin01"
    domain_name = aws_lb.satellite_alb01.dns_name
   // domain_name = "origin.${var.domain_name}"

    custom_origin_config {
      http_port              = local.ports_http
      https_port             = local.ports_https
      origin_protocol_policy = "https-only"
      origin_ssl_protocols   = ["TLSv1.2"]
    }

    # Explanation: CloudFront whispers the secret growl — the ALB only trusts this.
    custom_header {
      name  = "X-pawserenity"
      value = random_password.satellite_origin_header_value01.result
    }
  }

  default_cache_behavior {
    target_origin_id       = "${var.project_name}-alb-origin01"
    viewer_protocol_policy = "redirect-to-https"

    allowed_methods = ["GET", "HEAD", "OPTIONS", "PUT", "POST", "PATCH", "DELETE"]
    cached_methods  = ["GET", "HEAD"]
    #TODO: ENABLE LINES 32 AND 33 FOR LAB 2B
    cache_policy_id          = aws_cloudfront_cache_policy.pawserenity_cache_api_disabled01.id
    origin_request_policy_id = aws_cloudfront_origin_request_policy.pawserenity_orp_api01.id

    # TODO: students choose cache policy / origin request policy for their app type
    # For APIs, typically forward all headers/cookies/querystrings.
    # forwarded_values {
    #   query_string = true
    #   headers      = ["*"]
    #   cookies { forward = "all" }
    # }
  }

ordered_cache_behavior {
  path_pattern           = "/api/*"
  target_origin_id       = "${var.project_name}-alb-origin01"
  viewer_protocol_policy = "redirect-to-https"

  allowed_methods = ["GET", "HEAD", "OPTIONS", "PUT", "POST", "PATCH", "DELETE"]
  cached_methods  = ["GET", "HEAD"]

  cache_policy_id          = aws_cloudfront_cache_policy.pawserenity_cache_api_disabled01.id
  origin_request_policy_id = aws_cloudfront_origin_request_policy.pawserenity_orp_api01.id
}
  ordered_cache_behavior {
    path_pattern           = "/api/public-feed*"
    target_origin_id       = "${var.project_name}-alb-origin01"
    viewer_protocol_policy = "redirect-to-https"

    allowed_methods = ["GET", "HEAD", "OPTIONS"]
    cached_methods  = ["GET", "HEAD"]

    # Honor Cache-Control from origin (and default to not caching without it). :contentReference[oaicite:8]{index=8}
    cache_policy_id = data.aws_cloudfront_cache_policy.satellite_use_origin_cache_headers01.id

    # Forward what origin needs. Keep it tight: don't forward everything unless required. :contentReference[oaicite:9]{index=9}
    origin_request_policy_id = data.aws_cloudfront_origin_request_policy.satellite_orp_all_viewer_except_host01.id
  }

  # Explanation: Static behavior is the speed lane—pawserenity caches it hard for performance.
  ordered_cache_behavior {
    path_pattern           = "/static/*"
    target_origin_id       = "${var.project_name}-alb-origin01"
    viewer_protocol_policy = "redirect-to-https"

    allowed_methods = ["GET", "HEAD", "OPTIONS"]
    cached_methods  = ["GET", "HEAD"]

    # forwarded_values {
    #   query_string = true
    #   headers      = ["Origin"]
    #   cookies { forward = "all" }
    # }

    #TODO: ENABLE LINES 54 - 56 FOR LAB 2B
    cache_policy_id            = aws_cloudfront_cache_policy.pawserenity_cache_static01.id
    origin_request_policy_id   = aws_cloudfront_origin_request_policy.pawserenity_orp_static01.id
    response_headers_policy_id = aws_cloudfront_response_headers_policy.pawserenity_rsp_static01.id
  }

  # Explanation: Attach WAF at the edge — now WAF moved to CloudFront.
  web_acl_id = aws_wafv2_web_acl.satellite_cf_waf01.arn

  # TODO: students set aliases for satellite-growl.com and app.satellite-growl.com
  aliases = [
    var.domain_name,
   // "${var.app_subdomain}.${var.domain_name}"
  ]

  # TODO: students must use ACM cert in us-east-1 for CloudFront
  viewer_certificate {
    acm_certificate_arn      =  var.cloudfront_acm_cert_arn
    ssl_support_method       = "sni-only"
    minimum_protocol_version = "TLSv1.2_2021"
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }
}

//You’ll need this variable:
variable "cloudfront_acm_cert_arn" {
  description = "ACM certificate ARN in us-east-1 for CloudFront (covers www.pawserenity.click and pawserenity.click)."
  type        = string
  default     = "arn:aws:acm:us-east-1:461593447802:certificate/69731be3-1d7c-450c-bf34-1fafb3810008"
}

