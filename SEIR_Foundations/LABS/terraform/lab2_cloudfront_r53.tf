# Explanation: DNS now points to CloudFront — nobody should ever see the ALB again.
resource "aws_route53_record" "pawserenity_apex_to_cf01" {
  zone_id = var.hosted_zone_id
  name    = trimsuffix(data.aws_route53_zone.pawserenity.name, ".")
  # name    = var.domain_name Kevin -Reusing arguments from original route53_apex
  type            = "A"
  allow_overwrite = true

  alias {
    name                   = aws_cloudfront_distribution.satellite_cf01.domain_name
    zone_id                = aws_cloudfront_distribution.satellite_cf01.hosted_zone_id
    evaluate_target_health = false
  }
}

# Explanation: app.satellite-growl.com also points to CloudFront — same doorway, different sign.
resource "aws_route53_record" "pawserenity_app_to_cf01" {
  zone_id = var.hosted_zone_id
  name    = "www.${trimsuffix(data.aws_route53_zone.pawserenity.name, ".")}"
  # name    = "${var.app_subdomain}.${var.domain_name}" Kevin -Reusing arguments from original route53_www
  type            = "A"
  allow_overwrite = true

  //ORIGINAL
  alias {
    name                   = aws_cloudfront_distribution.satellite_cf01.domain_name
    zone_id                = aws_cloudfront_distribution.satellite_cf01.hosted_zone_id
    evaluate_target_health = false
  }
}
