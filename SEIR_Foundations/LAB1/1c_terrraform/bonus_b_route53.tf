############################################
# Domain delegation (Route 53 Registrar)
# Fixes/avoids broken DNS delegation by ensuring the registered domain uses
# ONLY the Route 53 hosted zone name servers (not an ALB DNS name, etc.).
############################################

# Look up the hosted zone so we can reuse its assigned name servers.
# (This uses your existing var.hosted_zone_id.)
data "aws_route53_zone" "pawserenity" {
  zone_id = var.hosted_zone_id
}

locals {
  # Route 53 zone names usually include a trailing dot (e.g., "pawserenity.click.")
  registered_domain_name = trimsuffix(data.aws_route53_zone.pawserenity.name, ".")
}

# NOTE: This resource only works if the domain is registered with Route 53 Domains.
# You'll need to import it into state once:
#   terraform import aws_route53domains_registered_domain.pawserenity pawserenity.click
resource "aws_route53domains_registered_domain" "pawserenity" {
  domain_name = local.registered_domain_name

  dynamic "name_server" {
    for_each = data.aws_route53_zone.pawserenity.name_servers
    content {
      name = name_server.value
    }
  }
}

############################################
# ALIAS record: app.pawserenity.click -> ALB
############################################

# resource "aws_route53_record" "satellite_app_alias01" {
#   zone_id = var.hosted_zone_id
#   name    = local.satellite_fqdn
#   type    = "A"

#   alias {
#     name                   = aws_lb.satellite_alb01.dns_name
#     zone_id                = aws_lb.satellite_alb01.zone_id
#     evaluate_target_health = true
#   }
# }

############################################
# Optional: apex + www -> ALB
# (So pawserenity.click and www.pawserenity.click resolve)
############################################

resource "aws_route53_record" "pawserenity_apex_alias" {
  zone_id = var.hosted_zone_id
  name    = trimsuffix(data.aws_route53_zone.pawserenity.name, ".")
  type    = "A"

  alias {
    name                   = aws_lb.satellite_alb01.dns_name
    zone_id                = aws_lb.satellite_alb01.zone_id
    evaluate_target_health = true
  }
}

resource "aws_route53_record" "pawserenity_www_alias" {
  zone_id = var.hosted_zone_id
  name    = "www.${trimsuffix(data.aws_route53_zone.pawserenity.name, ".")}" 
  type    = "A"

  alias {
    name                   = aws_lb.satellite_alb01.dns_name
    zone_id                = aws_lb.satellite_alb01.zone_id
    evaluate_target_health = true
  }
}